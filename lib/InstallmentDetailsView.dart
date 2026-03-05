import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class InstallmentDetailsView extends StatefulWidget {
  final String loanId;
  final String? userId;
  final VoidCallback? onBack;

  const InstallmentDetailsView({
    super.key,
    required this.loanId,
    this.userId,
    this.onBack,
  });

  @override
  _InstallmentDetailsViewState createState() => _InstallmentDetailsViewState();
}

class _InstallmentDetailsViewState extends State<InstallmentDetailsView> {
  DocumentSnapshot<Map<String, dynamic>>? userSnapshot;
  DocumentSnapshot<Map<String, dynamic>>? loanSnapshot;
  bool hasError = false;
  String errorMessage = '';
  late String userId;

  Future<void> fetchData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null && widget.userId == null) {
        throw 'لم يتم تسجيل الدخول.';
      }
      userId = widget.userId ?? currentUser!.uid;

      userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      loanSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('loans')
          .doc(widget.loanId)
          .get();

      if (!userSnapshot!.exists || !loanSnapshot!.exists) {
        throw 'البيانات غير موجودة.';
      }
    } catch (e) {
      hasError = true;
      errorMessage = e.toString();
    }
  }


  DateTime addMonths(DateTime date, int monthsToAdd) {
    int year = date.year + ((date.month + monthsToAdd - 1) ~/ 12);
    int month = (date.month + monthsToAdd - 1) % 12 + 1;
    int day = date.day;


    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    if (day > lastDayOfMonth) day = lastDayOfMonth;

    return DateTime(year, month, day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('تفاصيل الأقساط'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
      ),
      body: FutureBuilder(
        future: fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.teal));
          }

          if (hasError) {
            return Center(
              child: Text(
                'خطأ: $errorMessage',
                style: const TextStyle(color: Colors.red, fontSize: 18),
              ),
            );
          }

          final userData = userSnapshot!.data()!;
          final loanData = loanSnapshot!.data()!;

          final customerName = userData['username'] ?? '---';
          final productType = loanData['productType'] ?? '---';
          final total = loanData['amount'] ?? 0;
          final paidCount = loanData['paidInstallments'] ?? 0;
          final monthlyInstallment = loanData['monthlyInstallment'] ?? 0;
          final months = loanData['months'] ?? 1;
          final paidAmount = paidCount * monthlyInstallment;
          final remaining = total - paidAmount;

          DateTime start;
          try {
            start = (loanData['startDate'] as Timestamp).toDate();
          } catch (e) {
            start = DateTime.now();
          }

          final startDate = DateFormat('yyyy-MM-dd').format(start);
          final endDate = DateFormat('yyyy-MM-dd')
              .format(addMonths(start, months - 1)); 

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  childAspectRatio: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    infoCard(Icons.person, "العميل", customerName),
                    infoCard(Icons.shopping_cart, "اسم المنتج", productType),
                    infoCard(Icons.attach_money, "الإجمالي", "$total جنيه"),
                    infoCard(
                        Icons.money_off, "القسط", "$monthlyInstallment جنيه"),
                    infoCard(Icons.check_circle, "المدفوع", "$paidAmount جنيه",
                        color: Colors.blue),
                    infoCard(Icons.pending, "المتبقي", "$remaining جنيه",
                        color: Colors.red),
                    infoCard(Icons.date_range, "أول قسط", startDate),
                    infoCard(Icons.event, "آخر قسط", endDate),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'جدول الأقساط',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: months,
                    itemBuilder: (context, index) {
                      final date = DateFormat('yyyy-MM-dd').format(
                        addMonths(start, index), 
                      );
                      final isPaid = index < paidCount;

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Icon(
                            isPaid
                                ? Icons.check_circle
                                : Icons.hourglass_bottom,
                            color: isPaid ? Colors.green : Colors.orange,
                          ),
                          title: Text('تاريخ القسط: $date'),
                          subtitle: Text('المبلغ: $monthlyInstallment جنيه'),
                          trailing: Text(
                            isPaid ? 'تم الدفع' : 'معلق',
                            style: TextStyle(
                              color: isPaid ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    })
              ],
            ),
          );
        },
      ),
    );
  }

  Widget infoCard(IconData icon, String title, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.1) ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(3, 3),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: color ?? Colors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 9, color: Colors.grey[700]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
