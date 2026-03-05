import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:flutter_application_1/Admin_Panel.dart';
import 'package:flutter_application_1/HomePage.dart';
import 'package:flutter_application_1/LoginPage.dart';
import 'package:flutter_application_1/SemiAdminPanelPage.dart';
import 'package:flutter_application_1/SignUpPage.dart';
import 'package:flutter_application_1/setting.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Alamir',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const InitialScreen(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/admin': (context) => const AdminPanelPage(),
        '/semiadmin': (context) => const Semiadminpanelpage(),
        '/signup': (context) => const SignUpPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}

class InitialScreen extends StatelessWidget {
  const InitialScreen({super.key});

  Future<Widget> _getInitialPage() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return const HomePage();
      } else {
        return const LoginPage();
      }
    } catch (e) {
      debugPrint('Error determining initial page: $e');

      return const LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getInitialPage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return const LoginPage();
        } else {
          return snapshot.data!;
        }
      },
    );
  }
}
