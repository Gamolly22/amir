import 'package:cloud_firestore/cloud_firestore.dart';

class LoanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Future<void> updateInstallments(String userId, String loanId) async {
    final loanRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('loans')
        .doc(loanId);

    final loanSnap = await loanRef.get();
    if (!loanSnap.exists) return;

    final data = loanSnap.data()!;
    int paidInstallments = (data['paidInstallments'] ?? 0) + 1;
    int months = data['months'] ?? 0;

    bool isEnd = paidInstallments >= months;

    await loanRef.update({
      'paidInstallments': paidInstallments,
      'isEnd': isEnd,
    });
  }

  Future<void> checkAllLoans(String userId) async {
    final loansRef =
        _firestore.collection('users').doc(userId).collection('loans');
    final loansSnap = await loansRef.get();

    for (var loan in loansSnap.docs) {
      final data = loan.data();
      int paidInstallments = data['paidInstallments'] ?? 0;
      int months = data['months'] ?? 0;

      bool isEnd = paidInstallments >= months;

      await loan.reference.update({'isEnd': isEnd});
    }
  }
}
