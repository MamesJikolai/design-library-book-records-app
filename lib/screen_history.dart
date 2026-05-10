import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Keeps track of the currently selected filter: 'all', 'active', or 'returned'
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    const appBarColor = Colors.greenAccent;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60.0,
        title: const Text(
          'History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: appBarColor.shade700,
      ),
      // Move StreamBuilder to the top level of the body
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('borrows')
            .orderBy('borrow_date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Calculate Counts First
          int allCount = 0;
          int activeCount = 0;
          int returnedCount = 0;

          if (snapshot.hasData) {
            allCount = snapshot.data!.docs.length;
            for (var doc in snapshot.data!.docs) {
              final status = (doc.data() as Map<String, dynamic>)['status']?.toString() ?? 'unknown';
              if (status == 'active') {
                activeCount++;
              } else if (status == 'returned') {
                returnedCount++;
              }
            }
          }

          // 2. Build the Layout using the calculated counts
          return Column(
            children: [
              // --- FILTER CHIPS SECTION ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: Text('All ($allCount)', style: const TextStyle(fontWeight: FontWeight.bold)),
                      selected: _selectedFilter == 'all',
                      onSelected: (bool selected) {
                        setState(() => _selectedFilter = 'all');
                      },
                      selectedColor: appBarColor.shade100,
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: Text('Active ($activeCount)', style: const TextStyle(fontWeight: FontWeight.bold)),
                      selected: _selectedFilter == 'active',
                      onSelected: (bool selected) {
                        setState(() => _selectedFilter = 'active');
                      },
                      selectedColor: Colors.orange.shade100,
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: Text('Returned ($returnedCount)', style: const TextStyle(fontWeight: FontWeight.bold)),
                      selected: _selectedFilter == 'returned',
                      onSelected: (bool selected) {
                        setState(() => _selectedFilter = 'returned');
                      },
                      selectedColor: Colors.green.shade100,
                    ),
                  ],
                ),
              ),

              // --- HISTORY LIST SECTION ---
              Expanded(
                child: Builder(
                  builder: (context) {
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
                      if (_selectedFilter == 'all') return true; // Show everything

                      final data = doc.data() as Map<String, dynamic>;
                      final status = data['status']?.toString() ?? 'unknown';

                      return status == _selectedFilter; // Match 'active' or 'returned'
                    }).toList();

                    if (borrowDocs.isEmpty) {
                      return Center(
                        child: Text(
                          'No ${_selectedFilter == 'active' ? 'active' : 'returned'} borrows found.',
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      itemCount: borrowDocs.length,
                      itemBuilder: (context, index) {
                        final document = borrowDocs[index];
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
                                    _buildDetailRow('Borrower', studentName),
                                    _buildDetailRow('Borrow Date', borrowDate),
                                    _buildDetailRow(
                                      'Return Date',
                                      returnDate,
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
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor, fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

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
}