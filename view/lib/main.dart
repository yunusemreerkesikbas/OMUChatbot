import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/admin_page.dart';
import 'screens/chat_page.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/access_denied_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  String role = prefs.getString('role') ?? 'user';
  runApp(MyApp(isLoggedIn: isLoggedIn, role: role));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String role;

  const MyApp({Key? key, required this.isLoggedIn, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatbot',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: isLoggedIn
          ? (role == 'admin' ? '/admin' : '/chat')
          : '/',
      routes: {
        '/': (context) => LoginPage(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/chat': (context) => ChatPage(),
        '/admin': (context) => AdminPage(),
        '/access-denied': (context) => AccessDeniedPage(),
      },
    );
  }
}
