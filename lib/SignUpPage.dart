import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final value = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'nationalId': _nationalIdController.text.trim(),
          'phone': _phoneController.text.trim(),
          'isAdmin': false,
          "isSemiAdmin": false,
          'isActive': false,
          'createdAt': FieldValue.serverTimestamp(),
          'loanAmount': 0.0,
          'installmentAmount': 0.0,
          'initialBalance': 0.0,
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'username': _usernameController.text.trim(),
          'response': 'unknown',
        });

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ أثناء التسجيل';
      if (e.code == 'email-already-in-use') {
        message = 'هذا البريد مستخدم بالفعل.';
      } else if (e.code == 'weak-password') {
        message = 'كلمة المرور ضعيفة جدًا.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ غير متوقع، حاول مرة أخرى')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[100],
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nationalIdController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'تسجيل حساب جديد',
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _usernameController,
                    decoration: _inputDecoration('اسم المستخدم', Icons.person),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'الرجاء إدخال اسم المستخدم'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration:
                        _inputDecoration('البريد الإلكتروني', Icons.email),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الرجاء إدخال البريد الإلكتروني';
                      }
                      if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value.trim())) {
                        return 'الرجاء إدخال بريد إلكتروني صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration:
                        _inputDecoration('كلمة المرور', Icons.lock_outline),
                    obscureText: true,
                    validator: (value) =>
                        value == null || value.trim().length < 6
                            ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'
                            : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nationalIdController,
                    decoration: _inputDecoration('الرقم القومي', Icons.badge),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الرجاء إدخال الرقم القومي';
                      }
                      if (value.trim().length != 14) {
                        return 'الرقم القومي يجب أن يتكون من 14 رقم';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration:
                        _inputDecoration('رقم الهاتف', Icons.phone_android),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الرجاء إدخال رقم الهاتف';
                      }
                      if (!RegExp(r'^\+?\d{10,15}$').hasMatch(value.trim())) {
                        return 'الرجاء إدخال رقم هاتف صالح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(
                                          () => _rememberMe = value ?? false);
                                    },
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      if (await canLaunchUrl(Uri.parse(
                                          'https://blush-rochell-66.tiiny.site/'))) {
                                        await launchUrl(
                                            Uri.parse(
                                                'https://blush-rochell-66.tiiny.site/'),
                                            mode: LaunchMode.platformDefault);
                                      } else {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content:
                                                    Text('لا يمكن فتح الرابط')),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text(
                                        'الموافقة على الشروط والأحكام'),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.person_add_alt_1),
                                onPressed: _registerUser,
                                label: const Text('تسجيل الحساب'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
