import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;

import 'payment_screen.dart'; // ✅ import payment screen

/// Helper to convert Google Drive /view or /preview links into direct download
String normalizeDriveUrl(String url) {
  if (url.contains("drive.google.com")) {
    final regex = RegExp(r"/d/([a-zA-Z0-9_-]+)");
    final match = regex.firstMatch(url);
    if (match != null) {
      final fileId = match.group(1);
      return "https://drive.google.com/uc?export=download&id=$fileId";
    }
  }
  return url;
}

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  void _openPdf(BuildContext context, String rawUrl, String title) {
    final directUrl = normalizeDriveUrl(rawUrl);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(url: directUrl, title: title),
      ),
    );
  }

  void _openPayment(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          pdfTitle: title,
          amount: 100, // ₹1 for testing
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notes"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('notes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notes available"));
          }

          final notes = snapshot.data!.docs;

          // Group: Year → Subject → PDFs
          Map<String, Map<String, List<Map<String, dynamic>>>> groupedData = {};

          for (var doc in notes) {
            final data = doc.data() as Map<String, dynamic>;

            String year = data['year'] ?? "Unknown Year";
            String subject = data['subject'] ?? "Unknown Subject";

            groupedData.putIfAbsent(year, () => {});
            groupedData[year]!.putIfAbsent(subject, () => []);

            groupedData[year]![subject]!.add(data);
          }

          return ListView(
            children: groupedData.entries.map((yearEntry) {
              return ExpansionTile(
                title: Text(
                  yearEntry.key,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                children: yearEntry.value.entries.map((subjectEntry) {
                  return ExpansionTile(
                    title: Text(
                      subjectEntry.key,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: subjectEntry.value.map((pdf) {
                      final url = pdf['fileUrl'] ??
                          pdf['downloadUrl'] ??
                          pdf['link'] ??
                          '';
                      final isFree = pdf['isFree'] ?? false; // ✅ from Firestore

                      return ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        title: Text(pdf['title'] ?? 'Untitled'),
                        subtitle: Text(
                          isFree ? "Tap to view PDF" : "Premium · Subscribe to unlock",
                          style: TextStyle(
                            color: isFree ? Colors.black54 : Colors.orange,
                            fontStyle: isFree ? FontStyle.normal : FontStyle.italic,
                          ),
                        ),
                        trailing: isFree
                            ? null
                            : const Icon(Icons.lock, color: Colors.grey), // 🔒 lock icon
                        onTap: () {
                          if (isFree && url.isNotEmpty) {
                            _openPdf(context, url, pdf['title'] ?? 'Document');
                          } else if (!isFree) {
                            _openPayment(context, pdf['title'] ?? 'Premium PDF');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("No file linked")),
                            );
                          }
                        },
                      );
                    }).toList(),
                  );
                }).toList(),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class PdfViewerPage extends StatefulWidget {
  final String url;
  final String title;

  const PdfViewerPage({super.key, required this.url, required this.title});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  PdfControllerPinch? _pdfController;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.url));
      final bytes = response.bodyBytes;

      setState(() {
        _pdfController = PdfControllerPinch(
          document: PdfDocument.openData(bytes),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load PDF: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _pdfController == null
          ? const Center(child: CircularProgressIndicator())
          : PdfViewPinch(controller: _pdfController!),
    );
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }
}
