import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/widgets_history.dart';

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
    return StreamBuilder<QuerySnapshot>(
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
                    selectedColor: Colors.greenAccent.shade100,
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
              child: HistoryListWidget(
                snapshot: snapshot,
                selectedFilter: _selectedFilter,
              ),
            ),
          ],
        );
      },
    );
  }
}