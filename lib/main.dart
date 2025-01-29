import 'package:flutter/material.dart';
import 'package:personal_pudget/pages/auth/profile.dart';
import 'package:personal_pudget/home_page.dart';
import 'package:personal_pudget/widgets/bottom_navigation_bar.dart';
import 'package:personal_pudget/transaction_page.dart';
import 'pages/auth/welcome_screen.dart';
import 'package:personal_pudget/Report.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
    return;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Budget Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
      ),
      home: const WelcomeScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/home': (context) => const MainScreen(initialIndex: 0),
        '/transactions': (context) => const MainScreen(initialIndex: 1),
        '/reports': (context) => const MainScreen(initialIndex: 2),
        '/profile': (context) => const MainScreen(initialIndex: 3),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, required this.initialIndex});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  late final List<Widget> _pages;

  void onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    print('MainScreen initState called');
    _currentIndex = widget.initialIndex;
    _pages = [
      const HomePage(),
      const TransactionPage(),
      const ReportsPage(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _pages[_currentIndex],
      bottomNavigationBar: MyBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: onPageChanged,
      ),
    );
  }
}
