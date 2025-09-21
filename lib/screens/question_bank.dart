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

class QuestionBankPage extends StatefulWidget {
  const QuestionBankPage({super.key});
  @override
  State<QuestionBankPage> createState() => _QuestionBankPageState();
}

class _QuestionBankPageState extends State<QuestionBankPage> {
  String? selectedYear, selectedSubjectId, selectedSubjectName, selectedChapterId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedSubjectName != null
            ? "${selectedSubjectName!} Question Bank"
            : "Question Bank"),
        backgroundColor: Colors.green,
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
  Widget _buildSubjectList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("qbSubjects")
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
                              color: Colors.green[100],
                              child: const Icon(
                                Icons.book,
                                size: 60,
                                color: Colors.green,
                              ),
                            ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        color: Colors.green.withOpacity(0.7),
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
  Widget _buildChapterList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("qbChapters")
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
          .collection("qbPdfs")
          .where("chapterId", isEqualTo: selectedChapterId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No Question Bank PDFs"));

        return ListView(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final url = data['downloadUrl'] ?? '';
            final title = data['title'] ?? 'Untitled';

            return Card(
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.green),
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
    final res = await http.get(Uri.parse(widget.url));

    setState(() {
      _controller = PdfController(
        document: PdfDocument.openData(res.bodyBytes), // ✅ pass Future
        initialPage: 1,
      );
    });

    // Get total pages once doc is loaded
    final doc = await PdfDocument.openData(res.bodyBytes);
    setState(() {
      _totalPages = doc.pagesCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.green,
      ),
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                /// Continuous PDF Viewer
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

                /// Page number overlay
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
