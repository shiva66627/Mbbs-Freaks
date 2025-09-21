import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? selectedYear;
  String? selectedSubjectId;
  String? selectedSubjectName;
  String? selectedChapterId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quizzes"),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "My Results",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyResultsPage(
                    userId: FirebaseAuth.instance.currentUser!.uid,
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    if (selectedYear == null) {
      return _buildYearSelection();
    } else if (selectedSubjectId == null) {
      return _buildSubjectList();
    } else if (selectedChapterId == null) {
      return _buildChapterList();
    } else {
      return _buildQuizList();
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

  // =================== SUBJECTS ===================
  Widget _buildSubjectList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection("quizSubjects")
          .where("year", isEqualTo: selectedYear)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No subjects"));

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3 / 2,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final subjectName = doc['name'] ?? 'Subject';
            final imageUrl = doc['imageUrl'] ?? "";

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedSubjectId = doc.id;
                  selectedSubjectName = subjectName;
                });
              },
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) =>
                                    const Icon(Icons.book,
                                        size: 40, color: Colors.grey),
                              ),
                            )
                          : const Icon(Icons.book,
                              size: 40, color: Colors.grey),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        subjectName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
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
      stream: _firestore
          .collection("quizChapters")
          .where("subjectId", isEqualTo: selectedSubjectId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No chapters"));

        return ListView(
          children: docs.map((doc) {
            final chapterName = doc['name'] ?? 'Chapter';
            return Card(
              child: ListTile(
                title: Text(chapterName),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => setState(() => selectedChapterId = doc.id),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // =================== QUIZ LIST ===================
  Widget _buildQuizList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection("quizPdfs") // ✅ fix: correct collection name
          .where("chapterId", isEqualTo: selectedChapterId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("No quizzes available"));
        }

        final quizDoc = docs.first.data() as Map<String, dynamic>;
        final List<Map<String, dynamic>> questions =
            List<Map<String, dynamic>>.from(quizDoc["questions"] ?? []);

        return Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: Text("Start Quiz (${questions.length} Questions)"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizAttemptPage(
                    quizId: docs.first.id,
                    chapterId: selectedChapterId!,
                    subjectId: selectedSubjectId!,
                    year: selectedYear!,
                    userId: FirebaseAuth.instance.currentUser!.uid,
                    questions: questions,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// =================== QUIZ ATTEMPT PAGE ===================
class QuizAttemptPage extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final String quizId;
  final String chapterId;
  final String subjectId;
  final String year;
  final String userId;

  const QuizAttemptPage({
    super.key,
    required this.questions,
    required this.quizId,
    required this.chapterId,
    required this.subjectId,
    required this.year,
    required this.userId,
  });

  @override
  State<QuizAttemptPage> createState() => _QuizAttemptPageState();
}

class _QuizAttemptPageState extends State<QuizAttemptPage> {
  int currentIndex = 0;
  int score = 0;
  String? selectedOption;
  final Map<int, String> userAnswers = {};

  void _nextQuestion() {
    final currentQuestion = widget.questions[currentIndex];
    if (selectedOption != null) {
      userAnswers[currentIndex] = selectedOption!;
      if (selectedOption == currentQuestion["correctAnswer"]) {
        score++;
      }
    }

    if (currentIndex < widget.questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedOption = null;
      });
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
  final firestore = FirebaseFirestore.instance;

  // 🔑 convert int keys → String
  final answersAsStringKeys = userAnswers.map((key, value) => MapEntry(key.toString(), value));

  await firestore.collection("quiz_results").add({
    "userId": widget.userId,
    "quizId": widget.quizId,
    "score": score,
    "total": widget.questions.length,
    "answers": answersAsStringKeys,
    "attemptedAt": FieldValue.serverTimestamp(),
  });

  if (mounted) {
    _showResult();
  }
}


void _showResult() {
  if (!mounted) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text("Quiz Completed"),
      content: Text("Your score: $score / ${widget.questions.length}"),
      actions: [
        TextButton(
          onPressed: () {
            // ✅ Only close the dialog
            Navigator.of(ctx).pop();
            // ✅ Go back safely
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          child: const Text("Close"),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(ctx).pop(); // close dialog
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuizReviewPage(
                  questions: widget.questions,
                  userAnswers: userAnswers,
                ),
              ),
            );
          },
          child: const Text("Review"),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final q = widget.questions[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text("Question ${currentIndex + 1}/${widget.questions.length}"),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q["question"],
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if ((q["imageUrl"] ?? "").isNotEmpty) ...[
              const SizedBox(height: 12),
              Image.network(q["imageUrl"],
                  height: 150,
                  errorBuilder: (c, e, s) =>
                      const Icon(Icons.image, size: 40, color: Colors.grey)),
            ],
            const SizedBox(height: 16),
            ...q["options"].entries.map<Widget>((entry) {
              return RadioListTile<String>(
                value: entry.key,
                groupValue: selectedOption,
                onChanged: (val) {
                  setState(() => selectedOption = val);
                },
                title: Text("${entry.key}. ${entry.value}"),
              );
            }).toList(),
            const Spacer(),
            ElevatedButton(
              onPressed: selectedOption == null ? null : _nextQuestion,
              child: Text(currentIndex == widget.questions.length - 1
                  ? "Finish"
                  : "Next"),
            )
          ],
        ),
      ),
    );
  }
}

// =================== QUIZ REVIEW PAGE ===================
class QuizReviewPage extends StatelessWidget {
  final List<Map<String, dynamic>> questions;
  final Map<int, String> userAnswers;

  const QuizReviewPage({
    super.key,
    required this.questions,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz Review"),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final q = questions[index];
          final userAnswer = userAnswers[index];
          final correctAnswer = q["correctAnswer"];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Q${index + 1}. ${q["question"]}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  if ((q["imageUrl"] ?? "").isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Image.network(q["imageUrl"],
                        height: 100,
                        errorBuilder: (c, e, s) => const Icon(Icons.image)),
                  ],
                  const SizedBox(height: 8),
                  ...q["options"].entries.map<Widget>((entry) {
                    final isCorrect = entry.key == correctAnswer;
                    final isChosen = entry.key == userAnswer;
                    return Row(
                      children: [
                        Icon(
                          isCorrect
                              ? Icons.check_circle
                              : isChosen
                                  ? Icons.cancel
                                  : Icons.radio_button_unchecked,
                          color: isCorrect
                              ? Colors.green
                              : isChosen
                                  ? Colors.red
                                  : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text("${entry.key}. ${entry.value}"),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// =================== MY RESULTS PAGE ===================
class MyResultsPage extends StatelessWidget {
  final String userId;
  const MyResultsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Results"),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("quiz_results")
            .where("userId", isEqualTo: userId)
            .orderBy("attemptedAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final results = snapshot.data!.docs;

          if (results.isEmpty) {
            return const Center(child: Text("No quiz attempts yet."));
          }

          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index].data() as Map<String, dynamic>;
              final score = result["score"];
              final total = result["total"];
              final attemptedAt = result["attemptedAt"]?.toDate();

              return Card(
                child: ListTile(
                  title: Text("Score: $score / $total"),
                  subtitle: Text("Attempted: ${attemptedAt ?? "Unknown"}"),
                  leading: const Icon(Icons.assignment),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
