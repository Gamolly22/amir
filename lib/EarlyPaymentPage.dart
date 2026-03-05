import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/paymob_payment_screen.dart';
import 'package:flutter_application_1/paymob_service.dart';

class EarlyPaymentPage extends StatefulWidget {
  final String loanId;

  const EarlyPaymentPage({super.key, required this.loanId});

  @override
  State<EarlyPaymentPage> createState() => _EarlyPaymentPageState();
}

class _EarlyPaymentPageState extends State<EarlyPaymentPage> {
  double dueAmount = 0.0;
  double _lateFee = 0.0;
  double _payfee = 0.0;
  bool isLoading = true;

  final TextEditingController phoneController = TextEditingController();
  DateTime? startDate;

  final paymob = PaymobService();
  String paymentMethod = "wallet"; 

  
  final String successUrl = "https://srv896663.hstgr.cloud/success/";
  final String failedUrl = "https://srv896663.hstgr.cloud/fail/";

  @override
  void initState() {
    super.initState();
    fetchPaymentData();
  }

  Future<void> fetchPaymentData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final loanDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('loans')
          .doc(widget.loanId)
          .get();

      if (loanDoc.exists) {
        final loanData = loanDoc.data()!;
        final monthlyInstallment =
            (loanData['monthlyInstallment'] ?? 0).toDouble();

        Timestamp? ts = loanData['startDate'];
        if (ts != null) startDate = ts.toDate();

        double lateFee = 0.0;
        if (startDate != null) {
          final now = DateTime.now();
          final dueDate =
              DateTime(startDate!.year, startDate!.month + 1, startDate!.day);

          if (now.isAfter(dueDate)) {
            final diffDays = now.difference(dueDate).inDays;
            final weeksLate = (diffDays / 7).floor();
            lateFee = monthlyInstallment * 0.10 * weeksLate;
          }
        }

        setState(() {
          dueAmount = monthlyInstallment;
          _lateFee = lateFee;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  Future<void> markInstallmentAsPaid() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final loanRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('loans')
        .doc(widget.loanId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(loanRef);
      if (!snapshot.exists) return;

      final currentPaid = (snapshot['paidInstallments'] ?? 0) as int;
      transaction.update(loanRef, {"paidInstallments": currentPaid + 1});
    });
  }

  Future<void> processPayment({required bool isWallet}) async {

    final total1 = dueAmount + _lateFee + 3;
    final payfee = total1 * 0.027;
    final total = dueAmount + _lateFee + payfee;
    final amountCents = (total * 100).toInt();

    try {
      setState(() => isLoading = true);

      int? txId; 

      final token = await paymob.getAuthToken();
      final orderId = await paymob.createOrder(token, amountCents);

      final paymentKey = await paymob.getPaymentKey(
        token,
        orderId,
        amountCents,
        isWallet ? paymob.walletIntegrationId : paymob.cardIntegrationId,
      );

      String paymentUrl;
      if (isWallet) {
        final phone = phoneController.text.trim();
        if (phone.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("من فضلك أدخل رقم المحفظة")),
          );
          setState(() => isLoading = false);
          return;
        }

        final result = await paymob.payWithWallet(paymentKey, phone);

        if (result["redirect_url"] == null) {
          throw "حدث خطأ في رابط الدفع";
        }

      
        final dynamic maybeId = result["id"] ?? result["transaction_id"];
        txId = int.tryParse(maybeId?.toString() ?? "");

        paymentUrl = result["redirect_url"];
      } else {
        paymentUrl = paymob.getCardPaymentUrl(paymentKey);
      }

      final success = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymobPaymentScreen(
            paymentUrl: paymentUrl,
            successUrl: successUrl,
            failedUrl: failedUrl,

           
            orderId: orderId,
            amountCents: amountCents,
            transactionId: txId,
          ),
        ),
      );

      if (success == true) {
        await markInstallmentAsPaid();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ تم الدفع بنجاح")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ فشل الدفع")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ أثناء الدفع: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total1 = dueAmount + _lateFee + 3;
    _payfee = total1 * 0.027;
    final total = dueAmount + _lateFee + _payfee;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text('الأقساط المستحقة'),
      ),
      backgroundColor: const Color(0xFFF2F7FB),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("قسط هذا الشهر",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          _infoRow("القيمة المستحقة",
                              "${dueAmount.toStringAsFixed(2)} ج.م"),
                          if (_lateFee > 0)
                            _infoRow("غرامة التأخير",
                                "${_lateFee.toStringAsFixed(2)} ج.م",
                                isBold: true, isMain: true),
                          _infoRow(" ضريبة الدفع",
                              "${_payfee.toStringAsFixed(2)} ج.م",
                              isBold: true, isMain: true),
                          const Divider(),
                          _infoRow(
                              "المبلغ الكلي", "${total.toStringAsFixed(2)} ج.م",
                              isBold: true, isMain: true),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile(
                                  value: "wallet",
                                  groupValue: paymentMethod,
                                  onChanged: (val) =>
                                      setState(() => paymentMethod = val!),
                                  title: const Text("محفظة"),
                                ),
                              ),
                              Expanded(
                                child: RadioListTile(
                                  value: "card",
                                  groupValue: paymentMethod,
                                  onChanged: (val) =>
                                      setState(() => paymentMethod = val!),
                                  title: const Text("فيزا"),
                                ),
                              ),
                            ],
                          ),
                          if (paymentMethod == "wallet")
                            TextField(
                              controller: phoneController,
                              decoration: const InputDecoration(
                                labelText: "رقم المحفظة",
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                processPayment(
                                    isWallet: paymentMethod == "wallet");
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text("ادفع الآن"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text("أقساط 2025", style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
    );
  }

  Widget _infoRow(String title, String value,
      {bool isBold = false, bool isMain = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value,
              style: TextStyle(
                  color: isMain ? Colors.black : Colors.grey[700],
                  fontSize: isMain ? 18 : 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(title, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
