import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RepresentativePaymentsPage extends StatefulWidget {
  const RepresentativePaymentsPage({super.key});

  @override
  State<RepresentativePaymentsPage> createState() =>
      _RepresentativePaymentsPageState();
}

class _RepresentativePaymentsPageState
    extends State<RepresentativePaymentsPage> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6fdf9),
      appBar: AppBar(
        title: const Text(
          '🏦 مدفوعات المندوبين',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        elevation: 6,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
      ),
      body: Column(
        children: [
       
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "ابحث باسم المندوب...",
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim();
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

                final reps = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final isAdmin = data['isAdmin'] ?? false;
                  final isSemiAdmin = data['isSemiAdmin'] ?? false;
                  if (!(isAdmin || isSemiAdmin)) return false;

                  final repName =
                      (data['username'] ?? '').toString().toLowerCase();
                  if (searchQuery.isEmpty) return true;
                  return repName.contains(searchQuery.toLowerCase());
                }).toList();

                if (reps.isEmpty) {
                  return const Center(
                    child: Text(
                      '🚫 لا يوجد مندوبين مطابقين للبحث',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: reps.length,
                  itemBuilder: (context, index) {
                    final rep = reps[index];
                    final repId = rep.id;
                    final repData = rep.data() as Map<String, dynamic>;
                    final repName = repData['username'] ?? 'بدون اسم';

                    return Card(
                      elevation: 8,
                      shadowColor: Colors.green.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      child: _RepPaymentsTile(repId: repId, repName: repName),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RepPaymentsTile extends StatefulWidget {
  final String repId;
  final String repName;

  const _RepPaymentsTile({required this.repId, required this.repName});

  @override
  State<_RepPaymentsTile> createState() => _RepPaymentsTileState();
}

class _RepPaymentsTileState extends State<_RepPaymentsTile> {
  String filterType = "monthly"; 

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: Colors.green[600],
        child: const Icon(Icons.person, color: Colors.white, size: 28),
      ),
      title: Text(
        widget.repName,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      iconColor: Colors.green[700],
      childrenPadding: const EdgeInsets.all(12),
      children: [
       
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text("شهري"),
              selected: filterType == "monthly",
              onSelected: (_) {
                setState(() => filterType = "monthly");
              },
            ),
            const SizedBox(width: 12),
            ChoiceChip(
              label: const Text("سنوي"),
              selected: filterType == "yearly",
              onSelected: (_) {
                setState(() => filterType = "yearly");
              },
            ),
          ],
        ),
        const SizedBox(height: 10),

    
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.repId)
              .collection('representativePayments')
              .orderBy('date', descending: true)
              .snapshots(),
          builder: (context, paymentsSnapshot) {
            if (!paymentsSnapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final now = DateTime.now();
            final payments = paymentsSnapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp).toDate();

              if (filterType == "monthly") {
                return date.month == now.month && date.year == now.year;
              } else {
                return date.year == now.year;
              }
            }).toList();

            if (payments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  '⚠️ لا يوجد مدفوعات مسجلة',
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              );
            }

            return Column(
              children: payments.map((paymentDoc) {
                final data = paymentDoc.data() as Map<String, dynamic>;
                final clientName = data['clientName'] ?? '';
                final amount = (data['installmentAmount'] ?? 0.0).toDouble();
                final lateFee = (data['lateFee'] ?? 0.0).toDouble();
                final total = amount + lateFee;
                final productName = data['productName'] ?? '';
                (data['date'] as Timestamp).toDate();

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[100]!, Colors.green[50]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            clientName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 18, thickness: 0.7),
                      Row(
                        children: [
                          const Icon(Icons.shopping_bag,
                              color: Colors.teal, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "المنتج: $productName",
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.payments,
                              color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "القسط: $amount ج.م",
                            style: const TextStyle(
                                fontSize: 15, color: Colors.black87),
                          ),
                        ],
                      ),
                      if (lateFee > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.warning,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "غرامة: $lateFee ج.م",
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.red),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.summarize,
                              color: Colors.teal, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "الإجمالي: $total ج.م",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
