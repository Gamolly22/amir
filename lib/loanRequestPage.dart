import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/paymob_payment_screen.dart';
import 'package:flutter_application_1/paymob_service.dart';

class LoanRequestPage extends StatefulWidget {
  const LoanRequestPage({super.key});

  @override
  State<LoanRequestPage> createState() => _LoanRequestPageState();
}

class _LoanRequestPageState extends State<LoanRequestPage> {
  final String transferNumber = "01008272587"; 
  final double requestFee = 210.0; 

  final TextEditingController phoneController = TextEditingController();
  final paymob = PaymobService();

  bool isLoading = false;
  String paymentMethod = "wallet"; 

 
  final String successUrl = "https://srv896663.hstgr.cloud/success/";
  final String failedUrl = "https://srv896663.hstgr.cloud/fail/";

  Future<void> submitLoanRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) return;

    final userData = userDoc.data()!;

    final requestData = {
      'username': userData['username'] ?? '',
      'nationalId': userData['nationalId'] ?? '',
      'phone': userData['phone'] ?? '',
      'transferNumber': transferNumber,
      'fee': requestFee,
      'date': Timestamp.now(),
      'status': 'pending',
      'userId': user.uid,
    };

    await FirebaseFirestore.instance
        .collection('loanRequests')
        .add(requestData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ تم إرسال طلب التمويل بنجاح")),
    );
  }

  Future<void> processPayment({required bool isWallet}) async {
    final amountCents = (requestFee * 100).toInt();

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
        await submitLoanRequest();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ تم الدفع وإرسال الطلب")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ لم يتم تأكيد الدفع")),
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

  Future<void> showConfirmationDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد طلب التمويل"),
        content: Text(
            "ستتم إضافة طلب التمويل الخاص بك برسوم ${requestFee.toStringAsFixed(2)} ج.م.\nهل تريد المتابعة والدفع؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await processPayment(isWallet: paymentMethod == "wallet");
            },
            child: const Text("تأكيد والدفع"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("طلب الحصول على تمويل"),
        backgroundColor: Colors.teal,
      ),
      backgroundColor: const Color(0xFFF2F7FB),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${requestFee.toStringAsFixed(2)} ج.م",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "رسوم تقديم الطلب",
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile(
                          value: "wallet",
                          groupValue: paymentMethod,
                          onChanged: (val) {
                            setState(() => paymentMethod = val!);
                          },
                          title: const Text("محفظة"),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile(
                          value: "card",
                          groupValue: paymentMethod,
                          onChanged: (val) {
                            setState(() => paymentMethod = val!);
                          },
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
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: showConfirmationDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("طلب الحصول على تمويل"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
