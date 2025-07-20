import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangeEmailPage extends StatefulWidget {
  @override
  _ChangeEmailPageState createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newEmailController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  bool isLoading = false;

  Future<void> changeEmail(BuildContext context) async {
    setState(() {
      isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;

      // Re-authenticate the user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: currentPasswordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);

      // Update the email
      await user.updateEmail(newEmailController.text.trim());

      // Set new password
      await user.updatePassword(newPasswordController.text.trim());

      // Send verification email
      await user.sendEmailVerification();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email updated successfully! A verification email has been sent.'),
          backgroundColor: Colors.green,
        ),
      );

      // Optionally sign out the user or navigate back
      // FirebaseAuth.instance.signOut();
      // Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'requires-recent-login') {
        message = 'Please re-login to update your email.';
      } else {
        message = 'Failed to update email: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
        title: const Text('Change Email'),
        backgroundColor: Colors.cyan,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: newEmailController,
              decoration: const InputDecoration(labelText: 'New Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : () => changeEmail(context),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Update Email', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
