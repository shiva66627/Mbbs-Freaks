import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_content_manager.dart';
import 'admin_hierarchical_content_manager.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String adminName = '';
  String adminEmail = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            adminName = doc['fullName'] ?? 'Admin';
            adminEmail = doc['email'] ?? user.email ?? '';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading admin data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.red[600]),
              accountName: Text(adminName),
              accountEmail: Text(adminEmail),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.admin_panel_settings,
                  size: 40,
                  color: Colors.red,
                ),
              ),
            ),
            const ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              selected: true,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Upload PDFs'),
              onTap: () {
                Navigator.pop(context);
                _showUploadDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_tree),
              title: const Text('Hierarchical Content'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const AdminHierarchicalContentManager(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts),
              title: const Text('Manage Users'),
              onTap: () {
                Navigator.pop(context);
                _showManageUsers();
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Promote User to Admin'),
              onTap: () {
                Navigator.pop(context);
                _showPromoteUserDialog();
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $adminName!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Content Management Dashboard',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Quick Statistics',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child:
                              _buildStatCard('Notes', Icons.book, Colors.blue),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'PYQs',
                            Icons.description,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Question Banks',
                            Icons.library_books,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Quick Actions',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            'Upload Notes',
                            Icons.upload_file,
                            Colors.blue,
                            () => _showUploadDialog(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            'Upload PYQs',
                            Icons.upload_file,
                            Colors.green,
                            () => _showUploadDialog(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            'Upload Question Bank',
                            Icons.upload_file,
                            Colors.orange,
                            () => _showUploadDialog(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            'View All Content',
                            Icons.list,
                            Colors.purple,
                            () => _viewAllContent(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Realtime Counter Cards
  Widget _buildStatCard(String title, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection(title.toLowerCase().replaceAll(' ', '_'))
                  .snapshots(),
              builder: (context, snapshot) {
                int count = 0;
                if (snapshot.hasData) {
                  count = snapshot.data!.docs.length;
                }
                return Text(
                  '$count files',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Card Widgets
  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Upload PDF Dialog (with Year → Subject → Chapter → Link)
  void _showUploadDialog() {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController chapterController = TextEditingController();
    final TextEditingController titleController = TextEditingController();
    final TextEditingController linkController = TextEditingController();

    String selectedYear = "1st Year";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Upload PDF'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedYear,
                  decoration: const InputDecoration(labelText: "Select Year"),
                  items: const [
                    DropdownMenuItem(value: "1st Year", child: Text("1st Year")),
                    DropdownMenuItem(value: "2nd Year", child: Text("2nd Year")),
                    DropdownMenuItem(value: "3rd Year", child: Text("3rd Year")),
                    DropdownMenuItem(value: "4th Year", child: Text("4th Year")),
                  ],
                  onChanged: (val) {
                    selectedYear = val!;
                  },
                ),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: "Subject Name"),
                ),
                TextField(
                  controller: chapterController,
                  decoration: const InputDecoration(labelText: "Chapter Name"),
                ),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "PDF Title"),
                ),
                TextField(
                  controller: linkController,
                  decoration:
                      const InputDecoration(labelText: "Paste Google Drive Link"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (linkController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please fill all required fields')),
                  );
                  return;
                }

                // ✅ Auto-generate filename if empty
                final generatedTitle = titleController.text.trim().isNotEmpty
                    ? titleController.text.trim()
                    : "${subjectController.text.trim()} ${chapterController.text.trim()}".trim();

                await _firestore
                    .collection('notes')
                    .add({
                  'year': selectedYear,
                  'subject': subjectController.text.trim(),
                  'chapter': chapterController.text.trim(),
                  'title': generatedTitle,
                  'fileName': generatedTitle, // ✅ Save fileName
                  'link': linkController.text.trim(),
                  'uploadedBy': adminEmail,
                  'uploadedAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PDF uploaded successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showManageUsers() {
    Navigator.pushNamed(context, '/manage_users');
  }

  void _viewAllContent() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Content Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.book, color: Colors.blue),
                title: const Text('Manage Notes'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const AdminContentManager(category: 'notes'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.description, color: Colors.green),
                title: const Text('Manage PYQs'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const AdminContentManager(category: 'pyqs'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.library_books, color: Colors.orange),
                title: const Text('Manage Question Banks'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const AdminContentManager(category: 'question_bank'),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showPromoteUserDialog() {
    final _formKey = GlobalKey<FormState>();
    String email = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Promote User to Admin'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'User Email'),
              validator: (value) => value == null || !value.contains('@')
                  ? 'Enter valid email'
                  : null,
              onChanged: (value) => email = value,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  await _promoteUserToAdmin(email);
                }
              },
              child: const Text('Promote'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _promoteUserToAdmin(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not found!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _firestore.collection('users').doc(query.docs.first.id).update({
        'role': 'admin',
        'promotedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User promoted to Admin successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error promoting user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
