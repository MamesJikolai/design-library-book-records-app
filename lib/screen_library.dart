import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
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
        toolbarHeight: 60.0, // Increase this value to make it taller
        title: const Text(
          'Library Books',
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
                labelText: 'Enter book title',
                hintText: 'Search for a book...',
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

          // --- ACCORDION LIST SECTION ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('books')
                  .orderBy('title')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong.'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No books found.'));
                }

                // Filter the results locally based on the search term
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();

                  if (_searchTerm.isEmpty) return true;
                  return title.contains(_searchTerm);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('No matches found.'));
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  children: filteredDocs.map((DocumentSnapshot document) {
                    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

                    // Extract Book Data
                    String title = data['title'] as String? ?? 'N/A';
                    String author = data['author'] as String? ?? 'N/A';
                    String isbn = data['isbn'] as String? ?? 'N/A';
                    String publisher = data['publisher'] as String? ?? 'N/A';
                    String publishingDate = data['publishing_date'] as String? ?? 'N/A';
                    String bookId = data['bookID']?.toString() ?? 'N/A';
                    bool isAvailable = data['is_available'] as bool? ?? false;

                    final borrowerRef = data['borrower'] is DocumentReference
                        ? data['borrower'] as DocumentReference
                        : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      elevation: 2.0,
                      child: ExpansionTile(
                        key: PageStorageKey(document.id),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        children: <Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('Author', author),
                              _buildDetailRow('ISBN', isbn),
                              _buildDetailRow('Publisher', publisher),
                              _buildDetailRow('Publishing Date', publishingDate),
                              _buildDetailRow('Book ID', bookId),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text(
                                    'Available: ',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Icon(
                                    isAvailable ? Icons.check_circle : Icons.cancel,
                                    color: isAvailable ? Colors.green : Colors.red,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isAvailable ? 'Yes' : 'No',
                                    style: TextStyle(
                                      color: isAvailable ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              // Borrower Info
                              if (!isAvailable && borrowerRef != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: StreamBuilder<DocumentSnapshot>(
                                    stream: borrowerRef.snapshots(),
                                    builder: (context, studentSnapshot) {
                                      if (studentSnapshot.connectionState == ConnectionState.waiting) return const Text('Borrower: Loading...');
                                      if (studentSnapshot.hasError || !studentSnapshot.hasData || !studentSnapshot.data!.exists) return const Text('Borrower: Not Found');

                                      final studentData = studentSnapshot.data!.data() as Map<String, dynamic>;
                                      final studentFirstName = studentData['first_name'] ?? '';
                                      final studentMiddleName = studentData['middle_name'] ?? '';
                                      final studentLastName = studentData['last_name'] ?? '';
                                      final studentName = '$studentFirstName ${studentMiddleName.isNotEmpty ? '$studentMiddleName ' : ''}$studentLastName'.trim();
                                      final studentNumber = studentData['student_number'] ?? 'N/A';
                                      final studentGrade = studentData['grade']?.toString() ?? 'N/A';

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Borrowed by: $studentName', style: const TextStyle(fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 4),
                                          Text('Student Number: $studentNumber', style: const TextStyle(fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 4),
                                          Text('Grade: $studentGrade', style: const TextStyle(fontWeight: FontWeight.w500)),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ],
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
}