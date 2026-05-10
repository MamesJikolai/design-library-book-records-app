import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- HELPER WIDGET FOR TEXT ROWS ---
class StudentDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const StudentDetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
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

// --- WIDGET FOR FETCHING ACTIVE BORROWS ---
class BorrowedBooksList extends StatelessWidget {
  final DocumentReference studentRef;

  const BorrowedBooksList({super.key, required this.studentRef});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
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
            ...borrowDocs.map((borrowDoc) {
              final data = borrowDoc.data() as Map<String, dynamic>;

              final borrowDateRaw = data['borrow_date']?.toString() ?? 'Unknown Date';
              final borrowDate = borrowDateRaw.contains('T')
                  ? borrowDateRaw.split('T').first
                  : borrowDateRaw;

              final bookRef = data['book_id'] as DocumentReference?;

              if (bookRef == null) {
                return Text('• Unknown Book (Borrowed: $borrowDate)');
              }

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

// --- MAIN STUDENT LIST WIDGET ---
class StudentListWidget extends StatelessWidget {
  final String searchTerm;

  const StudentListWidget({super.key, required this.searchTerm});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
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

        // Filter based on the search term passed from the parent widget
        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          final firstName = (data['first_name'] ?? '').toString().toLowerCase();
          final middleName = (data['middle_name'] ?? '').toString().toLowerCase();
          final lastName = (data['last_name'] ?? '').toString().toLowerCase();
          final studentNumber = (data['student_number'] ?? '').toString().toLowerCase();

          final fullName = '$firstName $middleName $lastName';

          if (searchTerm.isEmpty) return true;

          return fullName.contains(searchTerm) || studentNumber.contains(searchTerm);
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(child: Text('No matches found.'));
        }

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          children: filteredDocs.map((DocumentSnapshot document) {
            Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

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
                    StudentDetailRow(label: 'Student Number', value: studentNumber),
                    StudentDetailRow(label: 'Grade', value: grade),
                    const Divider(height: 20),
                    BorrowedBooksList(studentRef: document.reference),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}