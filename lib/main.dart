// Kani waa file-ka ugu muhiimsan app-ka, wuxuu ku jiraa configuration-ka ugu horeeya
// iyo setup-ka Firebase iyo Provider state management

import 'package:flutter/material.dart';
import 'package:personal_pudget/pages/auth/profile.dart';
import 'package:personal_pudget/home_page.dart';
import 'package:personal_pudget/widgets/bottom_navigation_bar.dart';
import 'package:personal_pudget/transaction_page.dart';
import 'pages/auth/welcome_screen.dart';
import 'package:personal_pudget/Report.dart';
import 'package:provider/provider.dart';
import 'package:personal_pudget/services/currency_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Halkan waxaa ka bilaabmaya app-ka

void main() async {
  // Ka hor inta aanan la bilaabin app-ka, waa in la hubiyaa in Flutter initialization dhammaystiran yahay
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('Initializing Firebase...');
    // Bilowga Firebase-ka iyo xiriirinta app-ka
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
    return;
  }

  // Bilaabida app-ka
  runApp(const MyApp());
}

// Class-kan waa meesha laga maamulo app-ka oo dhan
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider wuxuu noo ogalaanayaa in lacagta loo bedelo si fudud
    return ChangeNotifierProvider(
      create: (_) => CurrencyService(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Budget Manager',
        // Halkan waxaa lagu qeexayaa theme-ka app-ka
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Inter',
        ),
        home: const WelcomeScreen(),
        // Dhamaan meelaha uu user-ku booqan karo
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/home': (context) => const MainScreen(initialIndex: 0),
          '/transactions': (context) => const MainScreen(initialIndex: 1),
          '/reports': (context) => const MainScreen(initialIndex: 2),
          '/profile': (context) => const MainScreen(initialIndex: 3),
        },
      ),
    );
  }
}

// Class-kan wuxuu maamulaa screen-ka ugu weyn ee app-ka
class MainScreen extends StatefulWidget {
  // initialIndex wuxuu sheegayaa screen-ka ugu horeeya ee la tusayo
  final int initialIndex;

  const MainScreen({super.key, required this.initialIndex});

  @override
  State<MainScreen> createState() => MainScreenState();
}

// State-ka MainScreen, halkan waxaa lagu maamulaa screen-nada kala duwan
class MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  // List-kan wuxuu hayaa dhamaan screen-nada app-ka
  late final List<Widget> _pages;

  // Marka screen cusub la doorto
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
    // Screen-nada ugu muhiimsan ee app-ka
    _pages = [
      const HomePage(), // Bogga guriga
      const TransactionPage(), // Bogga lacag-bixinta
      const ReportsPage(), // Bogga warbixinta
      const ProfileScreen(), // Bogga profile-ka
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // Tusida screen-ka hadda lagu jiro
      body: _pages[_currentIndex],
      // Navigation bar-ka hoose ee lagu dooranayo screen-nada
      bottomNavigationBar: MyBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: onPageChanged,
      ),
    );
  }
}
