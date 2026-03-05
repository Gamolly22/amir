import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  Future<void> updateUserResponse(String userId, String response) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'response': response});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F5),
      appBar: AppBar(
        title: const Text("👥 قائمة العملاء"),
        backgroundColor: const Color(0xFF004D40),
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('isAdmin', isEqualTo: false)
            .where('isSemiAdmin', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "لا يوجد عملاء حتى الآن 🚫",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final user = userDoc.data() as Map<String, dynamic>;
              final name = user['username'] ?? "مجهول";
              final phone = user['phone'] ?? "غير مسجل";
              final response = user['response'] ?? "غير محدد";

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00695C), Color(0xFF004D40)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Color(0xFF004D40)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "📞 $phone",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "المندوب: $response",
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        color: Colors.white,
                        onSelected: (value) {
                          updateUserResponse(userDoc.id, value);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem<String>(
                            enabled: false,
                            child: Text(
                              "تعيين المندوب",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          PopupMenuItem<String>(
                            enabled: false,
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .where(Filter.or(
                                    Filter('isAdmin', isEqualTo: true),
                                    Filter('isSemiAdmin', isEqualTo: true),
                                  ))
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Text(
                                    "جاري التحميل...",
                                    style: TextStyle(color: Colors.black),
                                  );
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return const Text(
                                    "لا يوجد مندوبين",
                                    style: TextStyle(color: Colors.black),
                                  );
                                }

                                final reps = snapshot.data!.docs;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: reps.map((doc) {
                                    final repData =
                                        doc.data() as Map<String, dynamic>;
                                    final repName =
                                        repData['username'] ?? "بدون اسم";

                                    return InkWell(
                                      onTap: () {
                                        Navigator.pop(context);
                                        updateUserResponse(userDoc.id, repName);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6),
                                        child: Text(
                                          repName,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),
                        ],
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
