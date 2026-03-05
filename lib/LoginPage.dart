import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRememberedLogin();
    });
  }

  Future<void> _checkRememberedLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool('rememberMe') ?? false;
      final currentUser = FirebaseAuth.instance.currentUser;

      if (rememberMe && currentUser != null) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      // أي خطأ هنا لن يغلق التطبيق
      debugPrint('Error checking remembered login: $e');
    }
  }

  Future<void> _resetPassword() async {
    final email = _inputController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال البريد الإلكتروني أولاً')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📩 تم إرسال رابط إعادة تعيين كلمة المرور')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إرسال البريد: $e')),
      );
    }
  }

  Future<void> _login() async {
    final input = _inputController.text.trim();
    final password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ أدخل البريد/الموبايل وكلمة المرور')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String emailToUse = input;

      final phoneRegExp = RegExp(r'^01[0-2,5]\d{8}$');

      if (phoneRegExp.hasMatch(input)) {
        // تحقق من Firestore بطريقة آمنة
        try {
          final querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('phone', isEqualTo: input)
              .limit(1)
              .get();

          if (querySnapshot.docs.isEmpty) {
            throw FirebaseAuthException(
              code: 'user-not-found',
              message: 'لم يتم العثور على حساب بهذا الرقم.',
            );
          }

          emailToUse = querySnapshot.docs.first.data()['email'] ?? '';
          if (emailToUse.isEmpty) {
            throw FirebaseAuthException(
              code: 'invalid-email',
              message: 'لا يوجد بريد مرتبط بهذا الرقم.',
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ أثناء التحقق من الرقم: $e')),
          );
          return;
        }
      }

      // تسجيل الدخول
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', _rememberMe);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ أثناء تسجيل الدخول';
      if (e.code == 'user-not-found') {
        message = 'لم يتم العثور على حساب بهذا البريد أو الرقم.';
      } else if (e.code == 'wrong-password') {
        message = 'كلمة المرور غير صحيحة.';
      } else if (e.code == 'invalid-email') {
        message = 'البريد الإلكتروني غير صالح.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ غير متوقع: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'تسجيل الدخول',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _inputController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني أو رقم الموبايل',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _resetPassword,
                    child: const Text('نسيت كلمة المرور؟', style: TextStyle(color: Colors.red)),
                  ),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) => setState(() => _rememberMe = value ?? false),
                    ),
                    const Text('تذكرني'),
                  ],
                ),
                const SizedBox(height: 12),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('دخول', style: TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                      ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text('إنشاء حساب جديد', style: TextStyle(fontSize: 16, color: Colors.blue)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}