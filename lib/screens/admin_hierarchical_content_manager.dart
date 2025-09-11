import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/hierarchical_content_model.dart';

class AdminHierarchicalContentManager extends StatefulWidget {
  const AdminHierarchicalContentManager({super.key});

  @override
  State<AdminHierarchicalContentManager> createState() =>
      _AdminHierarchicalContentManagerState();
}

class _AdminHierarchicalContentManagerState
    extends State<AdminHierarchicalContentManager> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ContentCategory? selectedCategory;
  AcademicYear? selectedYear;
  ContentSubject? selectedSubject;
  ContentChapter? selectedChapter;

  List<ContentSubject> subjects = [];
  List<ContentChapter> chapters = [];
  List<ContentPDF> pdfs = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedCategory = ContentCategory.notes; // default Notes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Management'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (selectedCategory == null) {
      return const Center(child: Text("Select a Category"));
    } else if (selectedYear == null) {
      return _buildYearSelection();
    } else if (selectedSubject == null) {
      return _buildSubjectList();
    } else if (selectedChapter == null) {
      return _buildChapterList();
    } else {
      return _buildPDFList();
    }
  }

  // =================== YEAR ===================
  Widget _buildYearSelection() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: AcademicYear.values.map((year) {
        return Card(
          child: ListTile(
            title: Text(year.displayName),
            onTap: () => _selectYear(year),
          ),
        );
      }).toList(),
    );
  }

  void _selectYear(AcademicYear? year) {
    setState(() {
      selectedYear = year;
      selectedSubject = null;
      selectedChapter = null;
      subjects.clear();
      chapters.clear();
      pdfs.clear();
    });
    if (year != null) _loadSubjects();
  }

  // =================== SUBJECT ===================
  Widget _buildSubjectList() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _addSubject,
          child: const Text("Add Subject"),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return Card(
                child: ListTile(
                  title: Text(subject.name),
                  subtitle: Text(subject.description),
                  onTap: () => _selectSubject(subject),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  void _selectSubject(ContentSubject? subject) {
    setState(() {
      selectedSubject = subject;
      selectedChapter = null;
      chapters.clear();
      pdfs.clear();
    });
    if (subject != null) _loadChapters();
  }

  // =================== CHAPTER ===================
  Widget _buildChapterList() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _addChapter,
          child: const Text("Add Chapter"),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              return Card(
                child: ListTile(
                  title: Text(chapter.name),
                  subtitle: Text(chapter.description),
                  onTap: () => _selectChapter(chapter),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  void _selectChapter(ContentChapter? chapter) {
    setState(() {
      selectedChapter = chapter;
      pdfs.clear();
    });
    if (chapter != null) _loadPDFs();
  }

  // =================== PDF ===================
  Widget _buildPDFList() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _uploadPDF,
          child: const Text("Upload PDF (Paste Link)"),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: pdfs.length,
            itemBuilder: (context, index) {
              final pdf = pdfs[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: Text(pdf.title),
                  subtitle: Text(pdf.downloadUrl),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  // =================== Add Subject ===================
  void _addSubject() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Add Subject"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Subject Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                await _firestore.collection("subjects").add({
                  "name": nameController.text.trim(),
                  "description": "",
                  "category": selectedCategory!.name,
                  "year": selectedYear!.name,
                  "createdAt": FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                _loadSubjects();
              },
              child: const Text("Save"),
            )
          ],
        );
      },
    );
  }

  // =================== Add Chapter ===================
  void _addChapter() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Add Chapter"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Chapter Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                await _firestore.collection("chapters").add({
                  "name": nameController.text.trim(),
                  "description": "",
                  "subjectId": selectedSubject!.id,
                  "createdAt": FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                _loadChapters();
              },
              child: const Text("Save"),
            )
          ],
        );
      },
    );
  }

  // =================== Upload PDF (Paste Link) ===================
  Future<void> _uploadPDF() async {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Add PDF Link"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "PDF Title"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: "Paste Google Drive Link",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty ||
                    urlController.text.trim().isEmpty) return;

                await _firestore.collection("pdfs").add({
                  "title": titleController.text.trim(),
                  "chapterId": selectedChapter!.id,
                  "downloadUrl": urlController.text.trim(),
                  "uploadedBy": _auth.currentUser?.email ?? "admin",
                  "uploadedAt": FieldValue.serverTimestamp(),
                  "isActive": true,
                  "isPublic": true,
                  "downloadCount": 0,
                });

                Navigator.pop(context);
                _loadPDFs();
              },
              child: const Text("Save"),
            )
          ],
        );
      },
    );
  }

  // =================== Load Data ===================
  Future<void> _loadSubjects() async {
    final querySnapshot = await _firestore
        .collection('subjects')
        .where('category', isEqualTo: selectedCategory!.name)
        .where('year', isEqualTo: selectedYear!.name)
        .get();

    setState(() {
      subjects = querySnapshot.docs
          .map((doc) => ContentSubject.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  Future<void> _loadChapters() async {
    final querySnapshot = await _firestore
        .collection('chapters')
        .where('subjectId', isEqualTo: selectedSubject!.id)
        .get();

    setState(() {
      chapters = querySnapshot.docs
          .map((doc) => ContentChapter.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  Future<void> _loadPDFs() async {
    final querySnapshot = await _firestore
        .collection('pdfs')
        .where('chapterId', isEqualTo: selectedChapter!.id)
        .get();

    setState(() {
      pdfs = querySnapshot.docs
          .map((doc) => ContentPDF.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }
}
