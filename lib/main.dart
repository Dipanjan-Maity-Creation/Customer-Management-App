import 'package:flutter/material.dart';
import 'package:bcbs/HOME.dart';
import 'package:bcbs/adminsignup.dart';
import 'package:bcbs/adminlogin.dart';
import 'package:bcbs/forgot password.dart';
//import 'package:bcbs/sub admin login.dart';

import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyByg-oRZnI037Y6CzM6VxZHha6zvIDHVng",
      appId: "1:508106177470:android:bb34fbf9cbbafc1e52d7ef",
      messagingSenderId: "508106177470",
      projectId: "customer1-40fa0",
      storageBucket: "customer1-40fa0.appspot.com",
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/admin_signup': (context) => AdminSignup(),
        '/admin_login': (context) => AdminLogin(),
        '/forgot_password': (context) => ForgotPassword(),
        '/home_page': (context) => HomePage(),

        //'/sub_admin_login': (context) => SubAdminLoginPage(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple[900],
      ),
      backgroundColor: Colors.purple[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/4_X_2.png',
              width: 200,
              height: 100,
            ),
            SizedBox(height: 4),
            SizedBox(width:10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin_signup');
                  },
                  child: Text('Admin Signup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    minimumSize: Size(80, 20),
                  ),
                ),

              ],
            ),
            SizedBox(height: 4),
            SizedBox(width:10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin_login');
                  },
                  child: Text('Admin Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    minimumSize: Size(75, 20),
                  ),
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }
}