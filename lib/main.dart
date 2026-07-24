import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/auth_gate.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const GateHub360App());
}

class GateHub360App extends StatelessWidget {
  const GateHub360App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GateHub360',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AuthGate(),
    );
  }
}
