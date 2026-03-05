import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/Homescreen.dart';
import 'package:flutter_application_1/RepresentativePaymentsPage.dart';
import 'package:flutter_application_1/myLoans.dart';
import 'package:flutter_application_1/setting.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool isAdmin = false;
  bool loading = true;
  bool isSemiAdmin = false;

  final List<Widget> _screens = [
    MyInstallmentsPage(),
    HomeScreen(),
    SettingsPage(),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'الأقساط'),
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
  ];

  @override
  void initState() {
    super.initState();
    checkIfAdmin();
    checkIfSemiAdmin();
  }

  Future<void> checkIfAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      setState(() {
        isAdmin = doc.data()?['isAdmin'] == true;
        loading = false;
      });
    }
  }

  Future<void> checkIfSemiAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      setState(() {
        isSemiAdmin = doc.data()?['isSemiAdmin'] == true;
        loading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF00796B),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'الرئيسية',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            if (isAdmin) 
              IconButton(
                icon: const Icon(Icons.payment),
                tooltip: 'مدفوعات المندوبين',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RepresentativePaymentsPage(),
                    ),
                  );
                },
              ),
          ],
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'لوحة الأدمن',
              onPressed: () {
                Navigator.pushNamed(context, '/admin');
              },
            ),
          if (!isAdmin && isSemiAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'لوحة المشرف',
              onPressed: () {
                Navigator.pushNamed(context, '/semiadmin');
              },
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _bottomNavItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}
