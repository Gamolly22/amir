import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  double totalAmount = 0;
  double totalMonthlyInstallment = 0;
  double totalRemainingInMarket = 0;
  int totalUsers = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStatistics();
  }

  Future<void> fetchStatistics() async {
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    double amountSum = 0;
    double installmentSum = 0;
    double remainingInMarket = 0;
    int usersCount = 0;

    for (var userDoc in usersSnapshot.docs) {
      final userData = userDoc.data();

      final bool isAdmin = userData['isAdmin'] ?? false;
      final bool isSemiAdmin = userData['isSemiAdmin'] ?? false;
      if (isAdmin || isSemiAdmin) continue;

      usersCount++;

      final loansSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .collection('loans')
          .get();

      for (var loanDoc in loansSnapshot.docs) {
        final data = loanDoc.data();

        final bool isEnd = data['isEnd'] ?? false;
        if (isEnd) continue;

        final double amount = (data['amount'] ?? 0).toDouble();
        final double monthly = (data['monthlyInstallment'] ?? 0).toDouble();
        final int paidInstallments = (data['paidInstallments'] ?? 0).toInt();

        amountSum += amount;

        installmentSum += monthly;

        final double paidSoFar = paidInstallments * monthly;
        final double remaining = amount - paidSoFar;

        remainingInMarket += remaining;
      }
    }

    setState(() {
      totalUsers = usersCount;
      totalAmount = amountSum;
      totalMonthlyInstallment = installmentSum;
      totalRemainingInMarket = remainingInMarket;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 إحصائيات النظام'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  buildStatCard(
                      '👥 عدد العملاء', totalUsers.toString(), Colors.teal),
                  buildStatCard('💰 إجمالي التمويل',
                      '${totalAmount.toStringAsFixed(2)} ج.م', Colors.blue),
                  buildStatCard(
                      '🧾 إجمالي الأقساط الشهرية',
                      '${totalMonthlyInstallment.toStringAsFixed(2)} ج.م',
                      Colors.deepPurple),
                  buildStatCard(
                      '🏦 المتبقي في السوق',
                      '${totalRemainingInMarket.toStringAsFixed(2)} ج.م',
                      Colors.redAccent),
                ],
              ),
            ),
    );
  }

  Widget buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
