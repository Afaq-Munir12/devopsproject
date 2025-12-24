import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';

import 'login_page.dart';
import 'signup_page.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Safe Firebase initialization for tests and CI
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Realtime Database URL
    FirebaseDatabase.instance.databaseURL =
    "https://lab10-80335-default-rtdb.asia-southeast1.firebasedatabase.app";
  } catch (e) {
    // Ignore Firebase errors in tests/CI
    debugPrint("Firebase initialization skipped: $e");
  }

  runApp(const MyApp()); // ✅ const constructor
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // ✅ const constructor

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
