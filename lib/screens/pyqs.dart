import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;

String normalizeDriveUrl(String url) {
  if (url.contains("drive.google.com")) {
    final regex = RegExp(r"/d/([a-zA-Z0-9_-]+)");
    final match = regex.firstMatch(url);
    if (match != null) {
      return "https://drive.google.com/uc?export=download&id=${match.group(1)}";
    }
  }
  return url;
}

class PyqsPage extends StatefulWidget {
  const PyqsPage({super.key});
  @override
  State<PyqsPage> createState() => _PyqsPageState();
}

class _PyqsPageState extends State<PyqsPage> {
  String? selectedYear, selectedSubjectId, selectedSubjectName, selectedChapterId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedSubjectName != null ? "${selectedSubjectName!} PYQs" : "PYQs"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (selectedYear == null) return _buildYearSelection();
    if (selectedSubjectId == null) return _buildSubjectList();
    if (selectedChapterId == null) return _buildChapterList();
    return _buildPdfList();
  }

  // =================== YEAR ===================
  Widget _buildYearSelection() {
    final years = ["1st Year", "2nd Year", "3rd Year", "4th Year"];
    return ListView(
      children: years.map((year) {
        return Card(
          child: ListTile(
            title: Text(year),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => setState(() => selectedYear = year),
          ),
        );
      }).toList(),
    );
  }

  // =================== SUBJECTS ===================
 // =================== SUBJECTS ===================
Widget _buildSubjectList() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection("pyqsSubjects") // ✅ separate collection for PYQs
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
          crossAxisCount: 1, // ✅ One subject per row
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
                            color: Colors.red[100],
                            child: const Icon(
                              Icons.book,
                              size: 60,
                              color: Colors.red,
                            ),
                          ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      color: Colors.redAccent.withOpacity(0.7),
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

  // =================== CHAPTERS ===================
  
// =================== CHAPTERS ===================
Widget _buildChapterList() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection("pyqsChapters") // ✅ separate collection
        .where("subjectId", isEqualTo: selectedSubjectId)
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final docs = snapshot.data!.docs;
      if (docs.isEmpty) return const Center(child: Text("No chapters"));

      return ListView.builder(
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final chapter = docs[index];
          final chapterName = chapter['name'] ?? 'Chapter';

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(chapterName),
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
          .collection("pyqsPdfs") // ✅ separate collection
          .where("chapterId", isEqualTo: selectedChapterId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No PYQs PDFs"));

        return ListView(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final url = data['downloadUrl'] ?? '';
            final title = data['title'] ?? 'Untitled';

            return Card(
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(title),
                onTap: () {
                  if (url.isNotEmpty) _openPdf(context, url, title);
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // =================== PDF VIEWER ===================
  void _openPdf(BuildContext context, String rawUrl, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(url: normalizeDriveUrl(rawUrl), title: title),
      ),
    );
  }
}

class PdfViewerPage extends StatefulWidget {
  final String url, title;
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
      final res = await http.get(Uri.parse(widget.url));
      if (res.statusCode != 200) {
        throw Exception("Failed to load PDF");
      }

      final bytes = res.bodyBytes;
      final doc = await PdfDocument.openData(bytes);

      setState(() {
        _controller = PdfController(
          document: Future.value(doc), // ✅ FIX for pdfx ^2.9.2
          initialPage: 1,
        );
        _totalPages = doc.pagesCount;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading PDF: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(widget.title, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red),
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
