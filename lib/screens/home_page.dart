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

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

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
                    ).then((_) => fetchUserData()); // refresh after edit
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
                  _buildGridItem(context, "PYQS", Icons.description, "PYQs", [
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
        // Navigate to specific pages based on the title
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
            // Fallback to the generic dropdown with converted data
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
