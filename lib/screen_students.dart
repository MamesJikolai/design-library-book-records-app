import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = "";

  @override
  void initState() {
    super.initState();
    // Listen to changes in the search bar
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const appBarColor = Colors.greenAccent;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70.0,
        title: const Text(
          'Students',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: appBarColor.shade700,
      ),
      body: Column(
        children: [
          // --- SEARCH BAR SECTION ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Enter student name or number',
                hintText: 'Search for a student...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    FocusScope.of(context).unfocus(); // Dismiss keyboard
                  },
                )
                    : null,
              ),
            ),
          ),

          // --- LIST SECTION ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .orderBy('last_name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong.'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No students found.'));
                }

                // Filter the results locally based on the search term
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final firstName = (data['first_name'] ?? '').toString().toLowerCase();
                  final middleName = (data['middle_name'] ?? '').toString().toLowerCase();
                  final lastName = (data['last_name'] ?? '').toString().toLowerCase();
                  final studentNumber = (data['student_number'] ?? '').toString().toLowerCase();

                  final fullName = '$firstName $middleName $lastName';

                  if (_searchTerm.isEmpty) return true;

                  return fullName.contains(_searchTerm) || studentNumber.contains(_searchTerm);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('No matches found.'));
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  children: filteredDocs.map((DocumentSnapshot document) {
                    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

                    // Extract Data for Display
                    final firstName = data['first_name'] as String? ?? '';
                    final middleName = data['middle_name'] as String? ?? '';
                    final lastName = data['last_name'] as String? ?? '';

                    final displayName = '$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName'.trim();
                    final studentNumber = data['student_number']?.toString() ?? 'N/A';
                    final grade = data['grade']?.toString() ?? 'N/A';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      elevation: 2.0,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow('Student Number', studentNumber),
                            _buildDetailRow('Grade', grade),
                            const Divider(height: 20),

                            // Load Borrowed Books from the 'borrows' collection
                            _buildBorrowedBooksList(document.reference),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for text rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // Helper widget to query and display borrowed books dynamically
  Widget _buildBorrowedBooksList(DocumentReference studentRef) {
    return StreamBuilder<QuerySnapshot>(
      // Query the 'borrows' collection for active borrows by this specific student
      stream: FirebaseFirestore.instance
          .collection('borrows')
          .where('student_id', isEqualTo: studentRef)
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading borrowed books...', style: TextStyle(color: Colors.grey));
        }

        if (snapshot.hasError) {
          return const Text('Error loading books.', style: TextStyle(color: Colors.red));
        }

        final borrowDocs = snapshot.data?.docs ?? [];

        if (borrowDocs.isEmpty) {
          return const Text('Borrowed Books: None', style: TextStyle(fontWeight: FontWeight.w500));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Borrowed Books (${borrowDocs.length}):',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            // Loop through each borrow document to get the date and book title
            ...borrowDocs.map((borrowDoc) {
              final data = borrowDoc.data() as Map<String, dynamic>;

              // Clean up the date string (e.g., "2026-05-10T09:04:36" -> "2026-05-10")
              final borrowDateRaw = data['borrow_date']?.toString() ?? 'Unknown Date';
              final borrowDate = borrowDateRaw.contains('T')
                  ? borrowDateRaw.split('T').first
                  : borrowDateRaw;

              final bookRef = data['book_id'] as DocumentReference?;

              if (bookRef == null) {
                return Text('• Unknown Book (Borrowed: $borrowDate)');
              }

              // Fetch the actual book document to get the title
              return FutureBuilder<DocumentSnapshot>(
                future: bookRef.get(),
                builder: (context, bookSnapshot) {
                  if (bookSnapshot.connectionState == ConnectionState.waiting) {
                    return Text('• Loading title... (Borrowed: $borrowDate)');
                  }

                  final bookData = bookSnapshot.data?.data() as Map<String, dynamic>?;
                  final title = bookData?['title'] ?? 'Unknown Title';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text('• $title (Borrowed: $borrowDate)'),
                  );
                },
              );
            }),
          ],
        );
      },
    );
  }
}