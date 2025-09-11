import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminContentManager extends StatefulWidget {
  final String category;
  const AdminContentManager({super.key, required this.category});

  @override
  State<AdminContentManager> createState() => _AdminContentManagerState();
}

class _AdminContentManagerState extends State<AdminContentManager> {
  String? selectedYear;
  String? selectedSubject;
  String? selectedChapter;

  List<String> years = ["1st Year", "2nd Year", "3rd Year", "4th Year"];
  List<String> subjects = [];
  List<String> chapters = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage ${widget.category}"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // Year Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<String>(
              value: selectedYear,
              hint: const Text("Select Year"),
              isExpanded: true,
              items: years
                  .map((y) => DropdownMenuItem<String>(
                        value: y,
                        child: Text(y),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedYear = val;
                  selectedSubject = null;
                  selectedChapter = null;
                  _loadSubjects();
                });
              },
            ),
          ),

          const SizedBox(height: 12),
          // Subject Dropdown
          if (selectedYear != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButton<String>(
                value: selectedSubject,
                hint: const Text("Select Subject"),
                isExpanded: true,
                items: subjects
                    .map((s) => DropdownMenuItem<String>(
                          value: s,
                          child: Text(s),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedSubject = val;
                    selectedChapter = null;
                    _loadChapters();
                  });
                },
              ),
            ),

          const SizedBox(height: 12),
          // Chapter Dropdown
          if (selectedSubject != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButton<String>(
                value: selectedChapter,
                hint: const Text("Select Chapter"),
                isExpanded: true,
                items: chapters
                    .map((c) => DropdownMenuItem<String>(
                          value: c,
                          child: Text(c),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedChapter = val;
                  });
                },
              ),
            ),

          const Divider(),
          Expanded(
            child: (selectedYear == null ||
                    selectedSubject == null ||
                    selectedChapter == null)
                ? const Center(
                    child: Text("Please select Year → Subject → Chapter"),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection(widget.category)
                        .where('year', isEqualTo: selectedYear)
                        .where('subject', isEqualTo: selectedSubject)
                        .where('chapter', isEqualTo: selectedChapter)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No content found"));
                      }

                      final docs = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: ListTile(
                              leading: const Icon(Icons.picture_as_pdf,
                                  color: Colors.red),
                              title: Text(
                                data['title'] ?? 'Untitled',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Uploaded by: ${data['uploadedBy'] ?? ''}"),
                                  if (data['uploadedAt'] != null)
                                    Text(
                                      "Uploaded on: ${(data['uploadedAt'] as Timestamp).toDate().toString().split(' ')[0]}",
                                    ),
                                ],
                              ),
                              trailing: Switch(
                                value: data['isFree'] ?? false,
                                onChanged: (val) async {
                                  await FirebaseFirestore.instance
                                      .collection(widget.category)
                                      .doc(doc.id)
                                      .update({'isFree': val});
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSubjects() async {
    final snapshot = await FirebaseFirestore.instance
        .collection(widget.category)
        .where('year', isEqualTo: selectedYear)
        .get();

    final allSubjects =
        snapshot.docs.map((d) => d['subject'] as String).toSet().toList();

    setState(() {
      subjects = allSubjects;
    });
  }

  Future<void> _loadChapters() async {
    final snapshot = await FirebaseFirestore.instance
        .collection(widget.category)
        .where('year', isEqualTo: selectedYear)
        .where('subject', isEqualTo: selectedSubject)
        .get();

    final allChapters =
        snapshot.docs.map((d) => d['chapter'] as String).toSet().toList();

    setState(() {
      chapters = allChapters;
    });
  }
}
