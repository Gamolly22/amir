import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/InstallmentDetailsView.dart';
import 'package:flutter_application_1/StatisticsPage.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  String? selectedUserId;
  String? selectedLoanId;
  bool showLoanDetails = false;
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  void _openLoansList(String userId) {
    setState(() {
      selectedUserId = userId;
      selectedLoanId = null;
      showLoanDetails = false;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const Text(
                    'تمويلات العميل',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('loans')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        // فلترة التمويلات حسب isEnd
                        final loans = snapshot.data!.docs
                            .where((loan) => loan['isEnd'] == false)
                            .toList();

                        if (loans.isEmpty) {
                          return const Center(child: Text('لا يوجد تمويلات'));
                        }

                        return ListView.builder(
                          itemCount: loans.length,
                          itemBuilder: (context, index) {
                            final loan = loans[index];
                            final product = loan['productType'] ?? 'بدون اسم';
                            final loanId = loan.id;

                            final Timestamp? startDateTimestamp =
                                loan['startDate'];
                            final int paidInstallments =
                                loan['paidInstallments'] ?? 0;

                            bool isLate = false;
                            bool isPaidThisMonth = false;
                            int overdueInstallments = 0;

                            if (startDateTimestamp != null) {
                              final startDate = startDateTimestamp.toDate();
                              final now = DateTime.now();

                              // عدد الشهور اللي عدّت
                              final monthsElapsed =
                                  (now.year - startDate.year) * 12 +
                                      (now.month - startDate.month);

                              // تاريخ استحقاق القسط في الشهر الحالي
                              final currentDueDate =
                                  DateTime(now.year, now.month, startDate.day);

                              if (paidInstallments < monthsElapsed ||
                                  (paidInstallments == monthsElapsed &&
                                      now.isAfter(currentDueDate))) {
                                // متأخر
                                isLate = true;
                                overdueInstallments = monthsElapsed -
                                    paidInstallments +
                                    (now.isAfter(currentDueDate) ? 1 : 0);
                              } else if (paidInstallments == monthsElapsed) {
                                // مدفوع هذا الشهر
                                isPaidThisMonth = true;
                              }
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('منتج: $product'),
                                    const SizedBox(height: 4),
                                    if (isLate)
                                      Row(
                                        children: [
                                          const Icon(Icons.warning,
                                              color: Colors.red, size: 18),
                                          const SizedBox(width: 4),
                                          Text(
                                            'متأخر بـ $overdueInstallments قسط',
                                            style: const TextStyle(
                                                color: Colors.red,
                                                fontSize: 12),
                                          ),
                                        ],
                                      )
                                    else if (isPaidThisMonth)
                                      Row(
                                        children: const [
                                          Icon(Icons.check_circle,
                                              color: Colors.green, size: 18),
                                          SizedBox(width: 4),
                                          Text(
                                            'مدفوع هذا الشهر',
                                            style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        child: const Text('التفاصيل'),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          setState(() {
                                            selectedUserId = userId;
                                            selectedLoanId = loanId;
                                            showLoanDetails = true;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          showLoanDetails = false;
                          selectedLoanId = null;
                          selectedUserId = null;
                        });
                      },
                      child: const Text('إغلاق'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _backToUsersList() {
    setState(() {
      showLoanDetails = false;
      selectedLoanId = null;
      selectedUserId = null;
    });
  }

  void _showFinanceForm(BuildContext context, String userId) {
    final productController = TextEditingController();
    final amountController = TextEditingController();
    final monthlyController = TextEditingController();
    final monthsController = TextEditingController();
    DateTime? selectedStartDate;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة تمويل جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: productController,
                decoration: const InputDecoration(labelText: 'نوع المنتج'),
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'سعر التمويل'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: monthlyController,
                decoration: const InputDecoration(labelText: 'القسط الشهري'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: monthsController,
                decoration: const InputDecoration(labelText: 'عدد الأشهر'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    selectedStartDate = pickedDate;
                  }
                },
                child: const Text('اختيار تاريخ بداية القسط'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final productType = productController.text;
              final amount = double.tryParse(amountController.text) ?? 0;
              final monthly = double.tryParse(monthlyController.text) ?? 0;
              final months = int.tryParse(monthsController.text) ?? 0;
              final startDate = selectedStartDate ?? DateTime.now();

              // 🔥 1) تجهيز Array الأقساط
              List<Map<String, dynamic>> installments = [];

              DateTime installmentDate = startDate;

              for (int i = 0; i < months; i++) {
                installments.add({
                  'date': Timestamp.fromDate(installmentDate),
                  'isPaid': false,
                });

                installmentDate = DateTime(
                  installmentDate.year,
                  installmentDate.month + 1,
                  installmentDate.day,
                );
              }

              
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('loans')
                  .add({
                'productType': productType,
                'amount': amount,
                'monthlyInstallment': monthly,
                'months': months,
                'paidInstallments': 0,
                'startDate': Timestamp.fromDate(startDate),
                'isEnd': false,

                
                'installments': installments,
              });

              Navigator.pop(context);

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('تمت إضافة التمويل وجدول الأقساط')),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _payInstallment(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'اختر تمويل للدفع',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('loans')
                          .where('isEnd', isEqualTo: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final loans = snapshot.data!.docs;
                        if (loans.isEmpty) {
                          return const Center(
                              child: Text('لا يوجد تمويلات نشطة'));
                        }

                        return ListView.builder(
                          itemCount: loans.length,
                          itemBuilder: (context, index) {
                            final loan = loans[index];
                            final product = loan['productType'] ?? 'بدون اسم';
                            final loanId = loan.id;

                            return ListTile(
                              title: Text('منتج: $product'),
                              trailing: ElevatedButton(
                                child: const Text('دفع القسط'),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final scaffoldContext = this.context;

                                  try {
                                    final loanRef = FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(userId)
                                        .collection('loans')
                                        .doc(loanId);

                                    final loanDoc = await loanRef.get();
                                    if (!loanDoc.exists) {
                                      ScaffoldMessenger.of(scaffoldContext)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('التمويل غير موجود')),
                                      );
                                      return;
                                    }

                                    final data = loanDoc.data()!;
                                    final monthlyInstallment =
                                        (data['monthlyInstallment'] ?? 0)
                                            .toDouble();

                                    List installments =
                                        List.from(data['installments']);
                                    int paidInstallments =
                                        data['paidInstallments'] ?? 0;

                                  
                                    int currentIndex = installments.indexWhere(
                                        (i) => i['isPaid'] == false);

                                    if (currentIndex == -1) {
                                      ScaffoldMessenger.of(scaffoldContext)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'كل الأقساط مدفوعة بالفعل')),
                                      );
                                      return;
                                    }

                                    final installment =
                                        installments[currentIndex];
                                    DateTime dueDate =
                                        (installment['date'] as Timestamp)
                                            .toDate();

                                 
                                    double lateFee = 0.0;
                                    int delayDays = DateTime.now()
                                        .difference(dueDate)
                                        .inDays;

                                    if (delayDays > 7) {
                                      int weeksLate = (delayDays / 7).floor();
                                      lateFee =
                                          monthlyInstallment * 0.10 * weeksLate;
                                    }

                                    double totalAmount =
                                        monthlyInstallment + lateFee;

                                    showDialog(
                                      context: scaffoldContext,
                                      builder: (_) => Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: AlertDialog(
                                          title: const Text('تأكيد دفع القسط'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text('المنتج: $product'),
                                              Text(
                                                  'قيمة القسط: ${monthlyInstallment.toStringAsFixed(2)}'),
                                              Text(
                                                'غرامة التأخير: ${lateFee.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: lateFee > 0
                                                      ? Colors.red
                                                      : Colors.green,
                                                ),
                                              ),
                                              const Divider(),
                                              Text(
                                                'الإجمالي: ${totalAmount.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(
                                                  scaffoldContext),
                                              child: const Text('إلغاء'),
                                            ),
                                            ElevatedButton(
                                              child: const Text('تأكيد الدفع'),
                                              onPressed: () async {
                                                Navigator.pop(scaffoldContext);

                                                try {
                                             
                                                  installments[currentIndex]
                                                      ['isPaid'] = true;

                                           
                                                  paidInstallments++;

                                        
                                                  bool isEnd =
                                                      paidInstallments ==
                                                          installments.length;

                                    
                                                  await loanRef.update({
                                                    'installments':
                                                        installments,
                                                    'paidInstallments':
                                                        paidInstallments,
                                                    'isEnd': isEnd,
                                                  });

                                                  final message = isEnd
                                                      ? 'تم سداد آخر قسط وإنهاء التمويل'
                                                      : 'تم تسجيل دفع القسط';

                                                  ScaffoldMessenger.of(
                                                          scaffoldContext)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(message)),
                                                  );
                                                } catch (e) {
                                                  ScaffoldMessenger.of(
                                                          scaffoldContext)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content:
                                                            Text('خطأ: $e')),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(scaffoldContext)
                                        .showSnackBar(
                                      SnackBar(content: Text('خطأ: $e')),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleUserActive(String userId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isActive': !currentStatus,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(!currentStatus ? 'تم تفعيل المستخدم' : 'تم تعطيل المستخدم'),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحديث الحالة: $e')),
      );
    }
  }

  Future<bool> _checkUserPaidThisMonth(String userId) async {
    final loansSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('loans')
        .get();

    for (var doc in loansSnapshot.docs) {
      final data = doc.data();
      final Timestamp? startTimestamp = data['startDate'];
      final int paid = data['paidInstallments'] ?? 0;

      if (startTimestamp != null) {
        final startDate = startTimestamp.toDate();
        final now = DateTime.now();

      
        final monthsElapsed =
            (now.year - startDate.year) * 12 + (now.month - startDate.month);

        final currentDueDate = DateTime(now.year, now.month, startDate.day);

        if (paid < monthsElapsed ||
            (paid == monthsElapsed && now.isAfter(currentDueDate))) {
          return false; 
        }
      }
    }

    return true; 
  }

  @override
  Widget build(BuildContext context) {
    if (showLoanDetails && selectedUserId != null && selectedLoanId != null) {
      return InstallmentDetailsView(
        userId: selectedUserId!,
        loanId: selectedLoanId!,
        onBack: _backToUsersList,
      );
    }
    Future<int> countUnseenRequestsForUser(
        List<QueryDocumentSnapshot> loans, String userId) async {
      int totalUnseen = 0;
      for (final loan in loans) {
        final loanId = loan.id;
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('loans')
            .doc(loanId)
            .collection('payments')
            .where('isSeen', isEqualTo: false)
            .get();
        totalUnseen += snapshot.docs.length;
      }
      return totalUnseen;
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('لوحة تحكم المشرف'),
          actions: [
            IconButton(
              icon: const Icon(Icons.bar_chart),
              tooltip: 'الإحصائيات',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StatisticsPage()),
                );
              },
            ),
          ],
          backgroundColor: Colors.teal,
        ),
        body: Column(
          children: [
         
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث عن اسم المستخدم...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.trim().toLowerCase();
                  });
                },
              ),
            ),

          
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

    
                  final users = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nationalId =
                        data['nationalId']?.toString().toLowerCase() ?? '';
                    final name =
                        data['username']?.toString().toLowerCase() ?? '';
                    final query = searchQuery.toLowerCase();

                    return nationalId.contains(query) || name.contains(query);
                  }).toList();

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final userId = user.id;
                      final name = user['username'] ?? 'بدون اسم';
                      final nat = user['nationalId'] ?? '';
                      final phone = user['phone'] ?? '';
                      final balance = (user['initialBalance'] ?? 0).toDouble();
                      final data = user.data() as Map<String, dynamic>? ?? {};
                      final isActive = data.containsKey('isActive')
                          ? data['isActive'] as bool
                          : true;

                      final controller = TextEditingController(
                          text: balance.toStringAsFixed(2));

                      return FutureBuilder<bool>(
                        future: _checkUserPaidThisMonth(userId),
                        builder: (context, paymentSnapshot) {
                          final paidThisMonth = paymentSnapshot.data ?? false;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ExpansionTile(
                              leading: IconButton(
                                icon: Icon(Icons.person,
                                    color:
                                        isActive ? Colors.teal : Colors.grey),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return StreamBuilder<
                                          DocumentSnapshot<
                                              Map<String, dynamic>>>(
                                        stream: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(userId)
                                            .snapshots(),
                                        builder: (context, userSnapshot) {
                                          return StreamBuilder<
                                              QuerySnapshot<
                                                  Map<String, dynamic>>>(
                                            stream: FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(userId)
                                                .collection('loans')
                                                .snapshots(),
                                            builder: (context, loansSnapshot) {
                                              if (!userSnapshot.hasData ||
                                                  !loansSnapshot.hasData) {
                                                return const Center(
                                                    child:
                                                        CircularProgressIndicator());
                                              }

                                              double toDouble(dynamic v) {
                                                if (v == null) return 0.0;
                                                if (v is num) {
                                                  return v.toDouble();
                                                }
                                                if (v is String) {
                                                  return double.tryParse(v) ??
                                                      0.0;
                                                }
                                                return 0.0;
                                              }

                                              int toInt(dynamic v) {
                                                if (v == null) return 0;
                                                if (v is int) return v;
                                                if (v is num) return v.toInt();
                                                if (v is String) {
                                                  return int.tryParse(v) ?? 0;
                                                }
                                                return 0;
                                              }

                                         
                                              final userData =
                                                  userSnapshot.data!.data() ??
                                                      {};
                                              double initialBalance = toDouble(
                                                  userData['initialBalance']);

                                              double totalLoansAmount = 0.0;
                                              double totalPaidBack = 0.0;

                                              for (var loanDoc
                                                  in loansSnapshot.data!.docs) {
                                                final loan = loanDoc.data();
                                                double amount = toDouble(loan[
                                                    'amount']); 
                                                double monthlyInstallment =
                                                    toDouble(loan[
                                                        'monthlyInstallment']);
                                                int paidInstallments = toInt(
                                                    loan['paidInstallments']);

                                                totalLoansAmount += amount;
                                                totalPaidBack +=
                                                    paidInstallments *
                                                        monthlyInstallment;
                                              }

                                        
                                              double availableBalance =
                                                  initialBalance -
                                                      totalLoansAmount +
                                                      totalPaidBack;

                                              return AlertDialog(
                                                title: const Text(
                                                    'معلومات العميل'),
                                                content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text('الاسم: $name'),
                                                    const SizedBox(height: 8),
                                                    Text('رقم الهاتف: $phone'),
                                                    const SizedBox(height: 8),
                                                    Text('الرقم القومي: $nat'),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                        'الرصيد المتاح: ${availableBalance.toStringAsFixed(2)}'),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    child: const Text('إغلاق'),
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize:
                                                12, 
                                            fontWeight: FontWeight.w900,
                                            color: isActive
                                                ? Colors.black
                                                : Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        StreamBuilder<QuerySnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(userId)
                                              .collection('loans')
                                              .snapshots(),
                                          builder: (context, loanSnapshot) {
                                            if (!loanSnapshot.hasData) {
                                              return SizedBox();
                                            }
                                            final loans =
                                                loanSnapshot.data!.docs;

                                            return FutureBuilder<int>(
                                              future:
                                                  countUnseenRequestsForUser(
                                                      loans, userId),
                                              builder: (context, snapshot) {
                                                int unseenCount =
                                                    snapshot.data ?? 0;
                                                return unseenCount > 0
                                                    ? Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 6,
                                                                vertical: 2),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.red,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Text(
                                                          unseenCount
                                                              .toString(),
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 12),
                                                        ),
                                                      )
                                                    : const SizedBox();
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    paidThisMonth ? '✅' : '❌',
                                    style: TextStyle(
                                      color: paidThisMonth
                                          ? Colors.green
                                          : Colors.redAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                nat,
                                style: TextStyle(
                                    color: isActive
                                        ? Colors.black54
                                        : Colors.grey),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: controller,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                            labelText: 'الرصيد',
                                            border: OutlineInputBorder(),
                                          ),
                                          enabled: isActive,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.save,
                                            color: isActive
                                                ? Colors.green
                                                : Colors.grey),
                                        onPressed: isActive
                                            ? () async {
                                                final newBalance =
                                                    double.tryParse(
                                                            controller.text) ??
                                                        0;
                                                await FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(userId)
                                                    .update({
                                                  'initialBalance': newBalance
                                                });
                                                if (!mounted) return;
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'تم تحديث الرصيد')),
                                                );
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.attach_money),
                                      label: const Text('إضافة تمويل'),
                                      onPressed: isActive
                                          ? () =>
                                              _showFinanceForm(context, userId)
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isActive
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.payment),
                                      label: const Text('دفع قسط'),
                                      onPressed: isActive
                                          ? () =>
                                              _payInstallment(context, userId)
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isActive
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.list_alt),
                                      label: const Text('تمويلات العميل'),
                                      onPressed: isActive
                                          ? () => _openLoansList(userId)
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isActive
                                            ? Colors.orange
                                            : Colors.grey,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      icon: Icon(isActive
                                          ? Icons.toggle_on
                                          : Icons.toggle_off),
                                      label: Text(isActive
                                          ? 'تعطيل المستخدم'
                                          : 'تفعيل المستخدم'),
                                      onPressed: () =>
                                          _toggleUserActive(userId, isActive),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            isActive ? Colors.red : Colors.teal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ));
  }
}
