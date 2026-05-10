import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const appBarColor = Colors.greenAccent;
    final themeColor = appBarColor.shade700;

    // Return the SingleChildScrollView directly instead of a Scaffold
    return SingleChildScrollView(
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
                              titleStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            PieChartSectionData(
                              color: Colors.orange.shade400,
                              value: borrowedCount.toDouble(),
                              title: '$borrowedCount',
                              radius: 40,
                              titleStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
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
                          _buildLegendItem(
                              color: Colors.green.shade400, text: 'Available'),
                          const SizedBox(height: 8),
                          _buildLegendItem(
                              color: Colors.orange.shade400, text: 'Borrowed'),
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
                child: _buildTitledCard(
                  title: 'Books Available',
                  themeColor: themeColor,
                  height: 110,
                  child: _buildStatStream(
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
          _buildTitledCard(
            title: '5 Most Popular Books',
            themeColor: themeColor,
            height: 220,
            child: _buildPopularBooks(),
          ),
          const SizedBox(height: 16),

          _buildTitledCard(
            title: 'Top 5 Borrowers',
            themeColor: themeColor,
            height: 220,
            child: _buildTopBorrowers(),
          ),
          const SizedBox(height: 16),

          _buildTitledCard(
            title: 'Borrowing Activity (${DateTime.now().year})',
            themeColor: themeColor,
            height: 220,
            child: _buildBorrowingActivityChart(themeColor),
          ),
          const SizedBox(height: 16),

          _buildTitledCard(
            title: 'Borrows by Grade',
            themeColor: themeColor,
            height: 220,
            child: _buildBorrowsByGradeChart(),
          ),
        ],
      ),
    );
  }

  // --- HELPER METHOD FOR TITLED CARDS ---
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: themeColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER METHOD FOR STAT NUMBERS ---
  Widget _buildStatStream({
    required Stream<QuerySnapshot> stream,
    required Color themeColor,
    int Function(List<QueryDocumentSnapshot>)? customCount,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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

  // --- 1. MOST POPULAR BOOKS ---
  Widget _buildPopularBooks() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('borrows').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No borrow data available.');
        }

        // Count frequency of each book reference
        final Map<String, int> bookCounts = {};
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final bookRef = data['book_id'] as DocumentReference?;
          if (bookRef != null) {
            bookCounts[bookRef.path] = (bookCounts[bookRef.path] ?? 0) + 1;
          }
        }

        // Sort by highest borrows and take top 5
        final sortedBooks = bookCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topBooks = sortedBooks.take(5).toList();

        if (topBooks.isEmpty) return const Text('No active book data.');

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: topBooks.length,
          itemBuilder: (context, index) {
            final bookPath = topBooks[index].key;
            final count = topBooks[index].value;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.doc(bookPath).get(),
              builder: (context, bookSnap) {
                String title = 'Loading...';
                if (bookSnap.connectionState == ConnectionState.done && bookSnap.hasData) {
                  final bookData = bookSnap.data!.data() as Map<String, dynamic>?;
                  title = bookData?['title'] ?? 'Unknown Book';
                }

                return ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -4),
                  minVerticalPadding: 0,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.book, color: Colors.green),
                  title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(
                    '$count borrows',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- 2. TOP BORROWERS ---
  Widget _buildTopBorrowers() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('borrows').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No borrow data available.');
        }

        // Count frequency of each student reference
        final Map<String, int> studentCounts = {};
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final studentRef = data['student_id'] as DocumentReference?;
          if (studentRef != null) {
            studentCounts[studentRef.path] = (studentCounts[studentRef.path] ?? 0) + 1;
          }
        }

        // Sort by highest borrows and take top 5
        final sortedStudents = studentCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topStudents = sortedStudents.take(5).toList();

        if (topStudents.isEmpty) return const Text('No active student data.');

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: topStudents.length,
          itemBuilder: (context, index) {
            final studentPath = topStudents[index].key;
            final count = topStudents[index].value;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.doc(studentPath).get(),
              builder: (context, studentSnap) {
                String name = 'Loading...';
                if (studentSnap.connectionState == ConnectionState.done && studentSnap.hasData) {
                  final studentData = studentSnap.data!.data() as Map<String, dynamic>?;
                  final first = studentData?['first_name'] ?? '';
                  final last = studentData?['last_name'] ?? '';
                  name = '$first $last'.trim();
                  if (name.isEmpty) name = 'Unknown Student';
                }

                return ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -4),
                  minVerticalPadding: 0,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person, color: Colors.green),
                  title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(
                    '$count borrows',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- 3. BORROWING ACTIVITY (BAR CHART) ---
  // --- 3. BORROWING ACTIVITY (BAR CHART) ---
  Widget _buildBorrowingActivityChart(Color themeColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('borrows').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No borrow data available.');
        }

        // Initialize 12 months with 0 borrows
        Map<int, int> monthlyBorrows = {for (var i = 1; i <= 12; i++) i: 0};

        // Get the current year as a string (e.g., "2026")
        final currentYearStr = DateTime.now().year.toString();

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final dateStr = data['borrow_date'] as String?;

          if (dateStr != null && dateStr.length >= 7) {
            try {
              // Extract the year (first 4 characters) and month (characters 5 to 7)
              final yearStr = dateStr.substring(0, 4);
              final monthStr = dateStr.substring(5, 7);

              // Only count it if it belongs to the current year
              if (yearStr == currentYearStr) {
                final month = int.parse(monthStr);
                if (monthlyBorrows.containsKey(month)) {
                  monthlyBorrows[month] = monthlyBorrows[month]! + 1;
                }
              }
            } catch (_) {}
          }
        }

        if (monthlyBorrows.values.every((v) => v == 0)) {
          return const Text('No dates logged for this year yet.');
        }

        List<BarChartGroupData> barGroups = [];
        for (int i = 1; i <= 12; i++) {
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: monthlyBorrows[i]!.toDouble(),
                  color: themeColor,
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                )
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: barGroups,
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                      int index = value.toInt() - 1;
                      if (index >= 0 && index < 12) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            months[index],
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- 4. BORROWS BY GRADE (PIE CHART) ---
  Widget _buildBorrowsByGradeChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('students').snapshots(),
      builder: (context, studentSnap) {
        if (studentSnap.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (!studentSnap.hasData) return const Text('Loading students...');

        final students = studentSnap.data!.docs;
        Map<String, String> studentGrades = {};
        for (var s in students) {
          final data = s.data() as Map<String, dynamic>;
          studentGrades[s.reference.path] = data['grade']?.toString() ?? 'Unknown';
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('borrows').snapshots(),
          builder: (context, borrowSnap) {
            if (borrowSnap.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (!borrowSnap.hasData || borrowSnap.data!.docs.isEmpty) {
              return const Text('No borrows available.');
            }

            final borrows = borrowSnap.data!.docs;
            Map<String, int> gradeCounts = {};

            for (var b in borrows) {
              final data = b.data() as Map<String, dynamic>;
              final studentRef = data['student_id'] as DocumentReference?;
              if (studentRef != null) {
                final grade = studentGrades[studentRef.path] ?? 'Unknown';
                gradeCounts[grade] = (gradeCounts[grade] ?? 0) + 1;
              }
            }

            if (gradeCounts.isEmpty) return const Text('No grade data mapped.');

            final Map<String, Color> gradeColors = {
              '1': Colors.blue.shade400,
              '2': Colors.red.shade400,
              '3': Colors.green.shade400,
              '4': Colors.orange.shade400,
              '5': Colors.purple.shade400,
              '6': Colors.teal.shade400,
              '7': Colors.pink.shade400,
              '8': Colors.amber.shade400,
              '9': Colors.indigo.shade400,
              '10': Colors.cyan.shade400,
              '11': Colors.deepOrange.shade400,
              '12': Colors.deepPurple.shade400,
              'Unknown': Colors.grey.shade400,
            };

            final sortedGrades = gradeCounts.keys.toList()..sort((a, b) {
              if (a == 'Unknown') return 1;
              if (b == 'Unknown') return -1;
              int numA = int.tryParse(a) ?? 0;
              int numB = int.tryParse(b) ?? 0;
              return numA.compareTo(numB);
            });

            return Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 25,
                      sections: sortedGrades.map((grade) {
                        final count = gradeCounts[grade]!;
                        final color = gradeColors[grade] ?? Colors.blueGrey;

                        return PieChartSectionData(
                          color: color,
                          value: count.toDouble(),
                          title: '$count',
                          radius: 40,
                          titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                    flex: 1,
                    child: ListView(
                      shrinkWrap: true,
                      children: sortedGrades.map((grade) {
                        final color = gradeColors[grade] ?? Colors.blueGrey;
                        final gradeLabel = grade == 'Unknown' ? '?' : 'Gr $grade';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: _buildLegendItem(color: color, text: gradeLabel),
                        );
                      }).toList(),
                    )
                )
              ],
            );
          },
        );
      },
    );
  }

  // --- HELPER METHOD FOR CHART LEGENDS ---
  Widget _buildLegendItem({required Color color, required String text}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}