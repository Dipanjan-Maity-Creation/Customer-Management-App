import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SubAdminPage extends StatefulWidget {
  @override
  _SubAdminPageState createState() => _SubAdminPageState();
}

class _SubAdminPageState extends State<SubAdminPage> {
  String? _photoUrl;

  // Upload image to Firebase Storage
  Future<void> _pickAndUploadPhoto() async {
    // Create an HTML file input element
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*'; // Accept only image files
    uploadInput.click(); // Trigger the file picker

    // Wait for the user to select a file
    uploadInput.onChange.listen((event) async {
      final file = uploadInput.files!.first;
      final reader = html.FileReader();

      // Read the file
      reader.readAsDataUrl(file);

      // When file reading is complete
      reader.onLoadEnd.listen((event) async {
        try {
          // Create a reference to Firebase Storage
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('subadmin_photos/${DateTime.now().millisecondsSinceEpoch}.png');

          // Upload the file as a blob
          final uploadTask = storageRef.putBlob(file);

          // Get the download URL after the upload completes
          final downloadUrl = await (await uploadTask).ref.getDownloadURL();

          // Update the UI with the uploaded image URL
          setState(() {
            _photoUrl = downloadUrl;
          });
        } catch (e) {
          print('Error uploading image: $e');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sub Admin Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _pickAndUploadPhoto,
              child: Text('Pick and Upload Sub Admin Photo'),
            ),
            SizedBox(height: 20),
            _photoUrl != null
                ? Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: Image.network(_photoUrl!),
            )
                : Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: Center(child: Text('No photo uploaded')),
            ),
          ],
        ),
      ),
    );
  }
}
