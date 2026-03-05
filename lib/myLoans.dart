import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/EarlyPaymentPage.dart';
import 'package:flutter_application_1/InstallmentDetailsView.dart';
import 'package:flutter_application_1/UsersPage.dart';
import 'package:flutter_application_1/loanRequestPage.dart';


class MyInstallmentsPage extends StatefulWidget {
  const MyInstallmentsPage({super.key});

  @override
  State<MyInstallmentsPage> createState() => _MyInstallmentsPageState();
}

class _MyInstallmentsPageState extends State<MyInstallmentsPage> {
  final userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _listenAndEndLoans(); 
  }

  void _listenAndEndLoans() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('loans')
        .snapshots()
        .listen((snapshot) {
      for (var loanDoc in snapshot.docs) {
        final loanData = loanDoc.data();
        final paidInstallments = (loanData['paidInstallments'] ?? 0).toInt();
        final months = (loanData['months'] ?? 0).toInt();
        final isEnd = loanData['isEnd'] ?? false;

        if (!isEnd && paidInstallments >= months) {
          loanDoc.reference.update({'isEnd': true});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final initialBalance = (userData['initialBalance'] ?? 0).toDouble();
        final isActive = userData['isActive'] ?? true;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('loans')
              .where('isEnd', isEqualTo: false)
              .snapshots(),
          builder: (context, loanSnapshot) {
            if (!loanSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final loans = loanSnapshot.data!.docs;
            double totalLoanAmount = 0;
            double totalPaidInstallmentsAmount = 0;

            for (var loan in loans) {
              final amount = (loan['amount'] ?? 0).toDouble();
              final monthlyInstallment =
                  (loan['monthlyInstallment'] ?? 0).toDouble();
              final paidInstallments = (loan['paidInstallments'] ?? 0).toInt();

              totalLoanAmount += amount;
              totalPaidInstallmentsAmount +=
                  paidInstallments * monthlyInstallment;
            }

            final availableBalance =
                initialBalance - totalLoanAmount + totalPaidInstallmentsAmount;

            return Scaffold(
              backgroundColor: const Color(0xFFF2F7FB),
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF00796B), Color(0xFF009688)],
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(
                            width: 48), 
                        const Text(
                          'كارت التقسيط',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        if (userData['isAdmin'] == true)
                          IconButton(
                            icon: const Icon(Icons.group, color: Colors.white),
                            tooltip: "إدارة العملاء",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const UsersPage()),
                              );
                            },
                          )
                        else
                          const SizedBox(
                              width: 48), 
                      ],
                    ),
                  ),
                ),
              ),
              body: Column(
                children: [
                 
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF009688), Color(0xFF4DB6AC)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(30)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("رصيدك الحالي",
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(
                          "${availableBalance.toStringAsFixed(2)} جنيه مصري",
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                isActive ? Colors.teal[800] : Colors.red[700],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.settings,
                                      color: Colors.white),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          isActive ? Colors.green : Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isActive
                                          ? "البطاقة مفعلة"
                                          : "البطاقة غير مفعلة",
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                userData['nationalId'] ?? 'لا يوجد رقم قومي',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 20),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                userData['username'] ?? 'لا يوجد اسم',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LoanRequestPage(), // here
                              ),
                            );
                          },
                          child: _iconButton(Icons.request_quote, "طلب تمويل"),
                        ),
                        const SizedBox(width: 150),
                        GestureDetector(
                          onTap: () async {
                            if (loans.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("لا يوجد تمويلات متاحة.")),
                              );
                              return;
                            }
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16)),
                              ),
                              builder: (context) {
                                return ListView(
                                  shrinkWrap: true,
                                  children: loans.map((doc) {
                                    final loanId = doc.id;
                                    final amount =
                                        (doc['amount'] ?? 0).toDouble();
                                    final productType =
                                        doc['productType'] ?? 'غير محدد';
                                    return ListTile(
                                      title: Text("تمويل بـ $amount جنيه"),
                                      subtitle:
                                          Text("نوع المنتج: $productType"),
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EarlyPaymentPage(
                                                    loanId: loanId),
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                                );
                              },
                            );
                          },
                          child:
                              _iconButton(Icons.card_giftcard, "تسديد الأقساط"),
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text("آخر مشترياتك",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('loans')
                          .where('isEnd', isEqualTo: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final loans = snapshot.data?.docs ?? [];

                        if (loans.isEmpty) {
                          return const Center(
                              child: Text('لا يوجد بيانات تمويل حالياً.'));
                        }

                        return ListView.builder(
                          itemCount: loans.length,
                          itemBuilder: (context, index) {
                            final loan = loans[index];
                            final productType =
                                loan['productType'] ?? 'غير محدد';
                            final code = loan.id;

                            final Timestamp startTimestamp = loan['startDate'];
                            final DateTime startDate = startTimestamp.toDate();
                            final DateTime now = DateTime.now();

                            final int daysElapsed =
                                now.difference(startDate).inDays;

                            final int installmentsElapsed = (daysElapsed > 0)
                                ? ((daysElapsed / 30).ceil())
                                : 0;

                            final int paidInstallments =
                                loan['paidInstallments'] ?? 0;

                            final bool isLate =
                                paidInstallments < installmentsElapsed;

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        InstallmentDetailsView(loanId: code),
                                  ),
                                );
                              },
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.receipt_long,
                                              color: Colors.teal),
                                          const SizedBox(width: 8),
                                          Text("نوع المنتج: $productType",
                                              style: const TextStyle(
                                                  color: Colors.teal)),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isLate
                                                  ? Colors.red
                                                  : Colors.green,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              isLate ? "متأخر" : "مدفوع",
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(),
                                      Text(
                                        "عدد الأيام منذ البداية: $daysElapsed يوم",
                                        style:
                                            const TextStyle(color: Colors.grey),
                                      ),
                                      const Text("اضغط لعرض التفاصيل",
                                          style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _iconButton(IconData icon, String text) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.teal[100],
          child: Icon(icon, color: Colors.teal[800]),
        ),
        const SizedBox(height: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
