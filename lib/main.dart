import 'package:equa/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const EquaApp());
}

class EquaApp extends StatelessWidget {
  const EquaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Equa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'MadeTommy'
      ),
      // Menggunakan StreamBuilder sebagai "Satpam" penjaga pintu masuk
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Jika aplikasi masih loading mengecek status user
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Jika Firebase mendeteksi sesi user masih ada (Ingat Saya)
          if (snapshot.hasData) {
            return const MainScreen();
          }
          // Jika tidak ada sesi (belum login / sudah logout)
          return const LoginScreen();
        },
      ),
    );
  }
}