import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- HELPER WIDGET FOR TEXT ROWS ---
class HistoryDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const HistoryDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  color: valueColor,
                  fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- INDIVIDUAL HISTORY CARD WIDGET ---
class HistoryCard extends StatelessWidget {
  final DocumentSnapshot document;

  const HistoryCard({super.key, required this.document});

  Future<Map<String, String>> _fetchDetails(DocumentReference? bookRef, DocumentReference? studentRef) async {
    String bookTitle = 'Unknown Book';
    String studentName = 'Unknown Student';

    try {
      if (bookRef != null) {
        final bookSnap = await bookRef.get();
        if (bookSnap.exists) {
          bookTitle = (bookSnap.data() as Map<String, dynamic>)['title'] ?? 'Unknown Book';
        }
      }
      if (studentRef != null) {
        final studentSnap = await studentRef.get();
        if (studentSnap.exists) {
          final data = studentSnap.data() as Map<String, dynamic>;
          final first = data['first_name'] ?? '';
          final middle = data['middle_name'] ?? '';
          final last = data['last_name'] ?? '';
          studentName = '$first ${middle.isNotEmpty ? '$middle ' : ''}$last'.trim();
        }
      }
    } catch (e) {
      // Ignore
    }

    return {'book': bookTitle, 'student': studentName};
  }

  String _formatDate(dynamic dateData) {
    if (dateData == null) return 'N/A';

    if (dateData is Timestamp) {
      DateTime dt = dateData.toDate();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } else if (dateData is String) {
      if (dateData.contains('T')) {
        return dateData.split('T').first;
      }
      return dateData;
    }
    return dateData.toString();
  }

  @override
  Widget build(BuildContext context) {
    final data = document.data() as Map<String, dynamic>;

    final bookRef = data['book_id'] as DocumentReference?;
    final studentRef = data['student_id'] as DocumentReference?;

    final status = data['status']?.toString() ?? 'unknown';

    final borrowDate = _formatDate(data['borrow_date']);
    final returnDate = status == 'active'
        ? 'Not returned'
        : _formatDate(data['return_date']);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, String>>(
          future: _fetchDetails(bookRef, studentRef),
          builder: (context, detailsSnapshot) {

            String bookTitle = 'Loading...';
            String studentName = 'Loading...';

            if (detailsSnapshot.connectionState == ConnectionState.done) {
              bookTitle = detailsSnapshot.data?['book'] ?? 'Unknown Book';
              studentName = detailsSnapshot.data?['student'] ?? 'Unknown Student';
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bookTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                const SizedBox(height: 8),
                HistoryDetailRow(label: 'Borrower', value: studentName),
                HistoryDetailRow(label: 'Borrow Date', value: borrowDate),
                HistoryDetailRow(
                  label: 'Return Date',
                  value: returnDate,
                  valueColor: status == 'active' ? Colors.red : Colors.green,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w500)),
                    Chip(
                      label: Text(
                        status.toUpperCase(),
                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: status == 'active' ? Colors.orange : Colors.green,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                )
              ],
            );
          },
        ),
      ),
    );
  }
}

// --- MAIN LIST WIDGET ---
class HistoryListWidget extends StatelessWidget {
  final AsyncSnapshot<QuerySnapshot> snapshot;
  final String selectedFilter;

  const HistoryListWidget({
    super.key,
    required this.snapshot,
    required this.selectedFilter,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) {
      return const Center(child: Text('Something went wrong.'));
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Center(child: Text('No history found.'));
    }

    // Filter the results locally based on the selected chip
    final borrowDocs = snapshot.data!.docs.where((doc) {
      if (selectedFilter == 'all') return true; // Show everything

      final data = doc.data() as Map<String, dynamic>;
      final status = data['status']?.toString() ?? 'unknown';

      return status == selectedFilter; // Match 'active' or 'returned'
    }).toList();

    if (borrowDocs.isEmpty) {
      return Center(
        child: Text(
          'No ${selectedFilter == 'active' ? 'active' : 'returned'} borrows found.',
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16.0),
      itemCount: borrowDocs.length,
      itemBuilder: (context, index) {
        return HistoryCard(document: borrowDocs[index]);
      },
    );
  }
}