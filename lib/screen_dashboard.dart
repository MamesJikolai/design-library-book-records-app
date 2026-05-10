import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const appBarColor = Colors.greenAccent;
    final themeColor = appBarColor.shade700;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70.0,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: themeColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // --- INVENTORY PIE CHART CARD ---
            _buildTitledCard(
              title: 'Inventory Status',
              themeColor: themeColor,
              height: 220,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('books').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Text('Error loading chart data.');
                  }

                  final books = snapshot.data!.docs;
                  int availableCount = 0;
                  int borrowedCount = 0;

                  for (var doc in books) {
                    final data = doc.data() as Map<String, dynamic>;
                    final isAvailable = data['is_available'] as bool? ?? false;
                    if (isAvailable) {
                      availableCount++;
                    } else {
                      borrowedCount++;
                    }
                  }

                  if (availableCount == 0 && borrowedCount == 0) {
                    return const Text('No books in database.');
                  }

                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                            sections: [
                              PieChartSectionData(
                                color: Colors.green.shade400,
                                value: availableCount.toDouble(),
                                title: '$availableCount',
                                radius: 40,
                                titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              PieChartSectionData(
                                color: Colors.orange.shade400,
                                value: borrowedCount.toDouble(),
                                title: '$borrowedCount',
                                radius: 40,
                                titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLegendItem(color: Colors.green.shade400, text: 'Available'),
                            const SizedBox(height: 8),
                            _buildLegendItem(color: Colors.orange.shade400, text: 'Borrowed'),
                          ],
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // --- 2x2 STATS GRID ---
            // --- 2x2 STATS GRID ---
            Row(
              children: [
                Expanded(
                  child: _buildTitledCard(
                    title: 'Total Books',
                    themeColor: themeColor,
                    height: 110,
                    child: _buildStatStream(
                      stream: FirebaseFirestore.instance.collection('books').snapshots(),
                      themeColor: themeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTitledCard(
                    title: 'Total Students',
                    themeColor: themeColor,
                    height: 110,
                    child: _buildStatStream(
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
                  child: _buildTitledCard(
                    title: 'Active Borrows',
                    themeColor: themeColor,
                    height: 110,
                    child: _buildStatStream(
                      // Filter the query directly so it only counts active ones
                      stream: FirebaseFirestore.instance.collection('borrows').where('status', isEqualTo: 'active').snapshots(),
                      themeColor: themeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTitledCard(
                    title: 'Books Available',
                    themeColor: themeColor,
                    height: 110,
                    child: _buildStatStream(
                      stream: FirebaseFirestore.instance.collection('books').snapshots(),
                      themeColor: themeColor,
                      // Custom counter to only tally books that are actually available
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
            _buildTitledCard(
              title: 'Most Popular Books',
              themeColor: themeColor,
              height: 180, // Taller to accommodate a list later
              child: const Text('List coming soon...', style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 16),

            _buildTitledCard(
              title: 'Top Borrowers',
              themeColor: themeColor,
              height: 180,
              child: const Text('List coming soon...', style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 16),

            _buildTitledCard(
              title: 'Borrowing Activity',
              themeColor: themeColor,
              height: 180,
              child: const Text('Chart coming soon...', style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 16),

            _buildTitledCard(
              title: 'Borrows by Grade',
              themeColor: themeColor,
              height: 180,
              child: const Text('Chart coming soon...', style: TextStyle(color: Colors.grey)),
            ),

          ],
        ),
      ),
    );
  }

  // --- NEW HELPER METHOD FOR TITLED CARDS ---
  Widget _buildTitledCard({
    required String title,
    required Color themeColor,
    required double height,
    required Widget child,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: themeColor,
          width: 2.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Aligns title to the left
        children: [
          // Upper-left Title
          Text(
            title,
            style: TextStyle(
              color: themeColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          // Centered Content
          Expanded(
            child: Center(
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW HELPER METHOD FOR STAT NUMBERS ---
  // This listens to Firestore in real-time and displays the total count.
  Widget _buildStatStream({
    required Stream<QuerySnapshot> stream,
    required Color themeColor,
    int Function(List<QueryDocumentSnapshot>)? customCount,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a tiny loading spinner while fetching data
          return SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(color: themeColor, strokeWidth: 2.0),
          );
        }
        if (snapshot.hasError) {
          return const Text('!', style: TextStyle(color: Colors.red, fontSize: 24));
        }

        final docs = snapshot.data?.docs ?? [];

        // If a custom counter logic was passed (like for Books Available), use it.
        // Otherwise, just count the total number of documents.
        final count = customCount != null ? customCount(docs) : docs.length;

        return Text(
          count.toString(),
          style: TextStyle(
            color: themeColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }

  // Helper method for the chart legend
  Widget _buildLegendItem({required Color color, required String text}) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}