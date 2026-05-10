import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/widgets_dashboard.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const appBarColor = Colors.greenAccent;
    final themeColor = appBarColor.shade700;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- INVENTORY PIE CHART CARD ---
          TitledCard(
            title: 'Inventory Status',
            themeColor: themeColor,
            height: 220,
            child: const InventoryPieChart(),
          ),
          const SizedBox(height: 16),

          // --- 2x2 STATS GRID ---
          Row(
            children: [
              Expanded(
                child: TitledCard(
                  title: 'Total Books',
                  themeColor: themeColor,
                  height: 110,
                  child: StatStreamWidget(
                    stream: FirebaseFirestore.instance.collection('books').snapshots(),
                    themeColor: themeColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TitledCard(
                  title: 'Total Students',
                  themeColor: themeColor,
                  height: 110,
                  child: StatStreamWidget(
                    stream: FirebaseFirestore.instance.collection('students').snapshots(),
                    themeColor: themeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TitledCard(
                  title: 'Active Borrows',
                  themeColor: themeColor,
                  height: 110,
                  child: StatStreamWidget(
                    stream: FirebaseFirestore.instance
                        .collection('borrows')
                        .where('status', isEqualTo: 'active')
                        .snapshots(),
                    themeColor: themeColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TitledCard(
                  title: 'Books Available',
                  themeColor: themeColor,
                  height: 110,
                  child: StatStreamWidget(
                    stream: FirebaseFirestore.instance.collection('books').snapshots(),
                    themeColor: themeColor,
                    customCount: (docs) {
                      return docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['is_available'] == true;
                      }).length;
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- INDIVIDUAL LIST / CHART CARDS ---
          TitledCard(
            title: '5 Most Popular Books',
            themeColor: themeColor,
            height: 220,
            child: const PopularBooksList(),
          ),
          const SizedBox(height: 16),

          TitledCard(
            title: 'Top 5 Borrowers',
            themeColor: themeColor,
            height: 220,
            child: const TopBorrowersList(),
          ),
          const SizedBox(height: 16),

          TitledCard(
            title: 'Borrowing Activity (${DateTime.now().year})',
            themeColor: themeColor,
            height: 220,
            child: BorrowingActivityChart(themeColor: themeColor),
          ),
          const SizedBox(height: 16),

          TitledCard(
            title: 'Borrows by Grade',
            themeColor: themeColor,
            height: 220,
            child: const BorrowsByGradeChart(),
          ),
        ],
      ),
    );
  }
}