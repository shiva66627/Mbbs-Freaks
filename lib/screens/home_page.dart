import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile.dart';
import 'user_content_browser.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String fullName = '';
  String email = '';
  String phone = '';
  bool isLoading = true;

  Map<String, dynamic>? dailyQuestion;
  String? selectedOption;
  String? correctAnswer;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchDailyQuestion();
  }

  Future<void> fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (doc.exists && doc.data() != null) {
          setState(() {
            fullName = doc.data()?['fullName'] ?? '';
            email = doc.data()?['email'] ?? '';
            phone = doc.data()?['phone'] ?? '';
            isLoading = false;
          });
        } else {
          setState(() {
            fullName = FirebaseAuth.instance.currentUser?.displayName ?? '';
            email = FirebaseAuth.instance.currentUser?.email ?? '';
            phone = '';
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          fullName = '';
          email = '';
          phone = '';
          isLoading = false;
        });
      }
    } else {
      setState(() {
        fullName = '';
        email = '';
        phone = '';
        isLoading = false;
      });
    }
  }

  Future<void> fetchDailyQuestion() async {
   final snapshot = await FirebaseFirestore.instance
    .collection("daily_question")
    .orderBy("createdAt", descending: true)
    .limit(1)
    .get();

if (snapshot.docs.isNotEmpty) {
  final doc = snapshot.docs.first; // DocumentSnapshot
  setState(() {
    dailyQuestion = doc.data() as Map<String, dynamic>;  // ✅ Correct
    correctAnswer = dailyQuestion?["correctAnswer"];
  });
}

  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          isLoading
              ? "Hi..."
              : "Hi, ${fullName.isNotEmpty ? fullName : 'User'}",
          style: const TextStyle(color: Colors.white),
        ),
      ),

      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              accountName: Text(fullName.isNotEmpty ? fullName : "User"),
              accountEmail: Text(email),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blue),
              ),
              otherAccountsPictures: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfilePage(),
                      ),
                    ).then((_) => fetchUserData());
                  },
                ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.library_books),
              title: const Text("Study Materials"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserContentBrowser(),
                  ),
                );
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: () => logout(),
            ),
          ],
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // ✅ Grid of 4 tabs
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      children: [
                        _buildGridItem(context, "NOTES", Icons.book, "Notes", [
                          "Anatomy",
                          "Physiology",
                          "Biochemistry",
                        ]),
                        _buildGridItem(
                            context, "PYQS", Icons.description, "PYQs", [
                          "2019",
                          "2020",
                          "2021",
                          "2022",
                        ]),
                        _buildGridItem(
                          context,
                          "Question Bank",
                          Icons.library_books,
                          "Question Bank",
                          ["Subject 1", "Subject 2", "Subject 3"],
                        ),
                        _buildGridItem(context, "Quiz", Icons.quiz, "Quiz", [
                          "MCQ Test 1",
                          "MCQ Test 2",
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ Inline Daily Question
                  if (dailyQuestion != null) _buildDailyQuestion()
                  else const Text(
                    "⚡ No Daily Question today",
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
    );
  }

 Widget _buildDailyQuestion() {
  final options = List<String>.from(dailyQuestion?["options"] ?? []);

  return Card(
    elevation: 2,
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Container(
      constraints: const BoxConstraints(minHeight: 310), 
      // ⬅️ Adjust height (220–250) to reach your green line
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            children: const [
              Icon(Icons.flash_on, color: Colors.orange, size: 18),
              SizedBox(width: 5),
              Text(
                "Daily Question",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Question
          Text(
            dailyQuestion?["question"] ?? "",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Options
          ...options.map((opt) {
            final isSelected = selectedOption == opt;
            final isCorrect = correctAnswer == opt;

            Color? tileColor;
            if (isSelected) {
              tileColor = isCorrect ? Colors.green[100] : Colors.red[100];
            }

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: tileColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: RadioListTile<String>(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(opt, style: const TextStyle(fontSize: 14)),
                value: opt,
                groupValue: selectedOption,
                onChanged: (val) {
                  setState(() {
                    selectedOption = val;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        val == correctAnswer
                            ? "✅ Correct Answer!"
                            : "❌ Wrong Answer. Correct: $correctAnswer",
                      ),
                      backgroundColor:
                          val == correctAnswer ? Colors.green : Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    ),
  );
}



  Widget _buildGridItem(
    BuildContext context,
    String title,
    IconData icon,
    String pageTitle,
    List<String> data,
  ) {
    return GestureDetector(
      onTap: () {
        switch (pageTitle) {
          case 'Notes':
            Navigator.pushNamed(context, '/notes');
            break;
          case 'PYQs':
            Navigator.pushNamed(context, '/pyqs');
            break;
          case 'Question Bank':
            Navigator.pushNamed(context, '/question_bank');
            break;
          case 'Quiz':
            Navigator.pushNamed(context, '/quiz');
            break;
          default:
            Navigator.pushNamed(
              context,
              '/dropdown',
              arguments: {'title': pageTitle, 'data': data},
            );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
