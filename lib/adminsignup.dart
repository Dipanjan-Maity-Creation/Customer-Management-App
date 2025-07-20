import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twilio_flutter/twilio_flutter.dart';

class AdminSignup extends StatefulWidget {
  @override
  _AdminSignupState createState() => _AdminSignupState();
}

class _AdminSignupState extends State<AdminSignup> {
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController gstController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  TwilioFlutter? twilioFlutter;

  @override
  void initState() {
    super.initState();

    // Initialize TwilioFlutter with your account credentials
    twilioFlutter = TwilioFlutter(
      accountSid: 'YOUR_ACCOUNT_SID', // replace with your Twilio Account SID
      authToken: 'YOUR_AUTH_TOKEN', // replace with your Twilio Auth Token
      twilioNumber: 'YOUR_TWILIO_NUMBER', // replace with your Twilio Phone Number
    );
  }

  Future<void> createUserWithEmailAndPassword(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: userIdController.text,
        password: passwordController.text,
      );

      await FirebaseFirestore.instance
          .collection('admins')
          .doc(userCredential.user?.uid)
          .set({
        'userId': userIdController.text,
        'username': usernameController.text,
        'phoneNumber': '+91${phoneNumberController.text}', // Ensure the phone number is stored with the country code
      });

      await FirebaseAuth.instance.currentUser?.sendEmailVerification();

      // Send SMS
      await twilioFlutter!.sendSMS(
        toNumber: '+91${phoneNumberController.text}', // Include the country code when sending SMS
        messageBody: 'You have successfully signed up for BCBS!',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signup successful. Verification email sent.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      String errorMessage = 'Failed to sign up';

      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          errorMessage = 'This email is already registered.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'The email address is not valid.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'The password is too weak.';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink[100],
        title: const Text('Admin Signup'),
      ),
      backgroundColor: Colors.yellow[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;
          double formWidth = width > 600 ? 400 : width * 0.9; // 400 for desktop, 90% of screen width for mobile

          return Center(
            child: Container(
              width: formWidth,
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/4_X_2.png',
                        width: 100,
                        height: 100,
                      ),
                      TextFormField(
                        controller: userIdController,
                        decoration: const InputDecoration(
                          labelText: 'User ID (Email)',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Invalid email format';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.perm_identity_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: phoneNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.contact_phone),
                          prefixText: '+91 ', // Add the country code as a prefix text
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (!RegExp(r'^\d{10}$').hasMatch(value)) { // Check for a 10-digit phone number
                            return 'Invalid phone number';
                          }
                          return null;
                        },
                      ),

                      TextFormField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                          labelText: 'G.S.T NO.',
                          prefixIcon: Icon(Icons.perm_identity_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your G.S.T NO.';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: 'Create Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible ? Icons.visibility : Icons.visibility_off_sharp,
                            ),
                            onPressed: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        obscureText: !isPasswordVisible,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password should be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                isConfirmPasswordVisible = !isConfirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                        obscureText: !isConfirmPasswordVisible,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: isLoading ? null : () => createUserWithEmailAndPassword(context),
                        child: isLoading ? const CircularProgressIndicator() : const Text('Signup'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
