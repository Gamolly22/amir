import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _changePasswordDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تغيير كلمة المرور"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'كلمة المرور القديمة'),
            ),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'كلمة المرور الجديدة'),
            ),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("إلغاء"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("تحديث"),
            onPressed: () async {
              final oldPassword = oldPasswordController.text.trim();
              final newPassword = newPasswordController.text.trim();
              final confirmPassword = confirmPasswordController.text.trim();

              if (newPassword != confirmPassword) {
                _showMessage("كلمتا المرور غير متطابقتين");
                return;
              }

              if (newPassword.length < 6) {
                _showMessage("كلمة المرور يجب أن تكون 6 أحرف على الأقل");
                return;
              }

              try {
                User user = _auth.currentUser!;
                String email = user.email!;
                AuthCredential credential = EmailAuthProvider.credential(
                    email: email, password: oldPassword);
                await user.reauthenticateWithCredential(credential);
                await user.updatePassword(newPassword);
                _showMessage("تم تغيير كلمة المرور بنجاح");

                oldPasswordController.clear();
                newPasswordController.clear();
                confirmPasswordController.clear();

                Navigator.pop(context);
              } catch (e) {
                _showMessage("فشل تغيير كلمة المرور: ${e.toString()}");
              }
            },
          ),
        ],
      ),
    );
  }

  void openWhatsAppChat() async {
    final phoneNumber = "201554194749";
    final message = Uri.encodeComponent("مرحبًا، لدي شكوى أود إرسالها.");
    final url = "https://wa.me/$phoneNumber?text=$message";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      _showMessage("تعذر فتح واتساب");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false, title: const Text("الإعدادات")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock, color: Colors.blue),
                    title: const Text("تغيير كلمة المرور"),
                    onTap: _changePasswordDialog,
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.warning_rounded, color: Colors.blue),
                    title: const Text("سياسة الخصوصية"),
                    onTap: () async {
                      await launchUrl(
                          Uri.parse('https://blush-rochell-66.tiiny.site/'));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text("تسجيل الخروج"),
                    onTap: _logout,
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "الدعم عبر واتساب",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.chat),
                      label: const Text("إرسال شكوى عبر واتساب"),
                      onPressed: openWhatsAppChat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                "اصدار 1.0.0+3",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
