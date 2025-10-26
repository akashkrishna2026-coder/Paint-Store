import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'auth/login_page.dart';
import 'widgets/loading_screen.dart';
import 'widgets/onboarding_screen.dart';
import 'pages/core/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://smart-paint-shop-default-rtdb.firebaseio.com/',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? _isFirstTime;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

    setState(() {
      _isFirstTime = isFirstTime;
    });

    if (isFirstTime) {
      prefs.setBool('isFirstTime', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstTime == null) {
      // While we check first time status, show loading
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const LoadingScreen(nextPage: SizedBox()),
      );
    }

    return MaterialApp(
      title: 'Smart Paint Shop',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: LoadingScreen(
        nextPage: _isFirstTime! ? const OnboardingScreen() : _getNextPage(),
      ),
    );
  }

  Widget _getNextPage() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return const HomePage(); // Logged-in user
    } else {
      return const LoginPage(); // Not logged in
    }
  }
}
