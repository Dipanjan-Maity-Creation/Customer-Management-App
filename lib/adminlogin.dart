import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminLogin extends StatefulWidget {
  @override
  _AdminLoginState createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange[200],
        title: const Text('Admin Login'),
      ),
      backgroundColor: Colors.green[100],
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double screenWidth = constraints.maxWidth;
            double screenHeight = constraints.maxHeight;
            double formWidth = screenWidth > 600 ? 400 : screenWidth * 0.8;
            double fontSize = screenWidth > 600 ? 20 : 16;
            double padding = screenWidth > 600 ? 40 : 20;
            double buttonHeight = 50;

            return Padding(
              padding: EdgeInsets.all(padding),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/4_X_2.png',
                      width: 100,
                      height: 100,
                    ),
                    SizedBox(
                      width: formWidth,
                      child: TextFormField(
                        controller: userIdController,
                        decoration: const InputDecoration(
                          labelText: 'User ID',
                          suffixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your user ID';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                        style: TextStyle(fontSize: fontSize),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: formWidth,
                      child: TextFormField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                        style: TextStyle(fontSize: fontSize),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _isLoading
                        ? CircularProgressIndicator()
                        : SizedBox(
                      width: formWidth,
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            setState(() {
                              _isLoading = true;
                            });

                            try {
                              UserCredential userCredential = await FirebaseAuth.instance
                                  .signInWithEmailAndPassword(
                                email: userIdController.text.trim(),
                                password: passwordController.text.trim(),
                              );

                              // Check if email is verified
                              if (userCredential.user?.emailVerified ?? false) {
                                Navigator.pushNamed(context, '/home_page');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please verify your email before login.')),
                                );
                              }
                            } on FirebaseAuthException catch (e) {
                              String message;
                              if (e.code == 'user-not-found') {
                                message = 'No user found for that email.';
                              } else if (e.code == 'wrong-password') {
                                message = 'Wrong password provided.';
                              } else {
                                message = 'Failed to login: ${e.message}';
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(message)),
                              );
                            } finally {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                        child: const Text('Login'),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgot_password');
                      },
                      child: const Text('Forgot Password?'),
                      style: TextButton.styleFrom(
                        textStyle: TextStyle(fontSize: fontSize * 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
