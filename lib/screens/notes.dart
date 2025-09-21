import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import 'payment_screen.dart';

/// Convert Google Drive /view links into direct download
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

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  String? selectedYear;
  String? selectedSubjectId;
  String? selectedSubjectName;
  String? selectedChapterId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedSubjectName != null
            ? "${selectedSubjectName!} Notes"
            : "Notes"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (selectedYear == null) {
      return _buildYearSelection();
    } else if (selectedSubjectId == null) {
      return _buildSubjectList();
    } else if (selectedChapterId == null) {
      return _buildChapterList();
    } else {
      return _buildPdfList();
    }
  }

  // =================== YEAR ===================
  Widget _buildYearSelection() {
    final years = ["1st Year", "2nd Year", "3rd Year", "4th Year"];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: years.map((year) {
        return Card(
          child: ListTile(
            title: Text(year),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => setState(() => selectedYear = year),
          ),
        );
      }).toList(),
    );
  }

  // =================== SUBJECT ===================
  Widget _buildSubjectList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("notesSubjects") // ✅ separate collection
          .where("year", isEqualTo: selectedYear)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No subjects found"));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final subject = snapshot.data!.docs[index];
            final imageUrl = subject['imageUrl'] ?? '';
            final subjectName = subject['name'] ?? 'Subject';

            return GestureDetector(
              onTap: () => setState(() {
                selectedSubjectId = subject.id;
                selectedSubjectName = subjectName;
              }),
              child: Card(
                elevation: 4,
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              normalizeDriveUrl(imageUrl),
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.blue[100],
                              child: const Icon(Icons.book,
                                  size: 60, color: Colors.blue),
                            ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        color: Colors.blueAccent.withOpacity(0.7),
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          subjectName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =================== CHAPTER ===================
  Widget _buildChapterList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("notesChapters") // ✅ separate collection
          .where("subjectId", isEqualTo: selectedSubjectId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No chapters found"));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final chapter = snapshot.data!.docs[index];
            return Card(
              child: ListTile(
                title: Text(chapter['name'] ?? 'Chapter'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => setState(() => selectedChapterId = chapter.id),
              ),
            );
          },
        );
      },
    );
  }

  // =================== PDFs ===================
  Widget _buildPdfList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("notesPdfs") // ✅ separate collection
          .where("chapterId", isEqualTo: selectedChapterId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No Notes found"));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final pdf = snapshot.data!.docs[index];
            final url = pdf['downloadUrl'] ?? '';
            final isFree = pdf['isFree'] ?? false;

            return Card(
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(pdf['title'] ?? 'Untitled'),
                subtitle: Text(isFree ? "Tap to view" : "Premium · Unlock"),
                trailing: isFree
                    ? null
                    : const Icon(Icons.lock, color: Colors.grey),
                onTap: () {
                  if (isFree && url.isNotEmpty) {
                    _openPdf(context, url, pdf['title'] ?? 'PDF');
                  } else if (!isFree) {
                    _openPayment(context, pdf['title'] ?? 'Premium PDF');
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  // =================== HELPERS ===================
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
          amount: 100,
        ),
      ),
    );
  }
}

// =================== PDF VIEWER ===================
// =================== PDF VIEWER ===================
// =================== PDF VIEWER ===================
class PdfViewerPage extends StatefulWidget {
  final String url;
  final String title;

  const PdfViewerPage({super.key, required this.url, required this.title});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  PdfController? _controller;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _initPdf();
  }

  Future<void> _initPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode != 200) {
        throw Exception("Failed to load PDF");
      }

      final bytes = response.bodyBytes;
      final doc = await PdfDocument.openData(bytes);

      setState(() {
        _controller = PdfController(
          document: PdfDocument.openData(bytes),
          initialPage: 1,
        );
        _totalPages = doc.pagesCount;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to open PDF: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.blue,
      ),
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                PdfView(
                  controller: _controller!,
                  scrollDirection: Axis.vertical,
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                  builders: PdfViewBuilders<DefaultBuilderOptions>(
                    options: const DefaultBuilderOptions(),
                    documentLoaderBuilder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                    pageLoaderBuilder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                    errorBuilder: (_, error) =>
                        Center(child: Text("Error: $error")),
                  ),
                ),

                /// Page counter overlay
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$_currentPage / $_totalPages",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
