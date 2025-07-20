import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bcbs/HOME.dart';
import 'package:bcbs/update.dart';

import 'dart:typed_data'; // For Uint8List used in Web
import 'package:flutter/foundation.dart'; // To use kIsWeb
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';

class CustForumPage extends StatefulWidget {
  @override
  _CustForumPageState createState() => _CustForumPageState();
}

class _CustForumPageState extends State<CustForumPage> {
  final _formKey = GlobalKey<FormState>();
  String custId = '';
  String custName = '';
  String custPhoneNumber = '';
  String selectedAddressType = '';
  String villageName = '';
  String townName = '';
  String wardNo = '';
  String aadhaarNo = '';
  String imageUrl = ''; // Added imageUrl to store the uploaded photo URL
  bool isSaved = false;
  String message = '';
  bool isLoading = false;
  File? _imageFile;
  bool isImageSelected = false;
  bool isImageContainerVisible = false;
  final ImagePicker _picker = ImagePicker();

  User? user;
  DocumentSnapshot? currentCustomerDocument;

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp().then((_) {
      user = FirebaseAuth.instance.currentUser;
      setState(() {});
    });
  }

  Future<bool> isSTBNoUsed(String stbNo) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('customers')
        .where('custId', isEqualTo: stbNo)
        .where('userId', isEqualTo: user?.uid)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  Future<String> uploadImage(String filePath) async {
    try {
      final randomString = generateRandomString(10);
      final firebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child('customer_images/$randomString.jpg');
      await firebaseStorageRef.putFile(File(filePath));
      final imageUrl = await firebaseStorageRef.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return '';
    }
  }

  String generateRandomString(int length) {
    final characters = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    String result = '';
    for (int i = 0; i < length; i++) {
      result += characters[random.nextInt(characters.length)];
    }
    return result;
  }

  Future<void> fetchCustomerInformation(String stbNo) async {
    setState(() {
      isLoading = true;
    });

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('customers')
        .where('custId', isEqualTo: stbNo)
        .where('userId', isEqualTo: user?.uid)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        currentCustomerDocument = querySnapshot.docs.first;
        custName = currentCustomerDocument!['custName'];
        custPhoneNumber = currentCustomerDocument!['custPhoneNumber'];
        selectedAddressType = currentCustomerDocument!['selectedAddressType'];
        villageName = currentCustomerDocument!['villageName'];
        townName = currentCustomerDocument!['townName'];
        wardNo = currentCustomerDocument!['wardNo'];
        aadhaarNo = currentCustomerDocument!['aadhaarNo'];
        imageUrl = currentCustomerDocument!['imageUrl'];
        isImageContainerVisible = imageUrl.isNotEmpty;
      });
    } else {
      setState(() {
        currentCustomerDocument = null;
        custName = '';
        custPhoneNumber = '';
        selectedAddressType = '';
        villageName = '';
        townName = '';
        wardNo = '';
        aadhaarNo = '';
        imageUrl = '';
        isImageContainerVisible = false;
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> saveCustomerInformation() async {
    if (user == null) {
      setState(() {
        isSaved = false;
        message = 'User is not authenticated!';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      setState(() {
        isSaved = false;
        message = 'Please fill all the required fields correctly!';
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // If an image is selected, upload it and get the download URL
      if (_imageFile != null && _imageFile!.path.isNotEmpty) {
        imageUrl = await uploadImage(_imageFile!.path);
        if (imageUrl.isEmpty) {
          setState(() {
            isSaved = false;
            message = 'Failed to upload image!';
          });
          return;
        }
      }

      CollectionReference customers =
      FirebaseFirestore.instance.collection('customers');

      Map<String, dynamic> customerData = {
        'custId': custId,
        'custName': custName,
        'custPhoneNumber': custPhoneNumber,
        'selectedAddressType': selectedAddressType,
        'villageName': villageName,
        'townName': townName,
        'wardNo': wardNo,
        'aadhaarNo': aadhaarNo,
        'imageUrl': imageUrl, // Assign imageUrl to customerData
        'userId': user!.uid,
      };

      if (currentCustomerDocument != null) {
        await currentCustomerDocument!.reference.update(customerData);
        setState(() {
          isSaved = true;
          message = 'Customer information updated successfully!';
        });
      } else if (await isSTBNoUsed(custId)) {
        setState(() {
          isSaved = false;
          message = 'This STB NO. is already used!';
        });
      } else {
        await customers.add(customerData);
        setState(() {
          isSaved = true;
          message = 'Customer information saved successfully!';
        });
      }
    } catch (e) {
      print("Error saving customer information: $e");
      setState(() {
        isSaved = false;
        message = 'Failed to save data!';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteCustomer(String custId) async {
    try {
      final customerRef = FirebaseFirestore.instance
          .collection('customers')
          .where('custId', isEqualTo: custId)
          .where('userId', isEqualTo: user?.uid);

      final querySnapshot = await customerRef.get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          await doc.reference.delete();
        }
        setState(() {
          message = 'Customer information deleted successfully!';
          isSaved = false;
          currentCustomerDocument = null;
          custId = '';
          custName = '';
          custPhoneNumber = '';
          selectedAddressType = '';
          villageName = '';
          townName = '';
          wardNo = '';
          aadhaarNo = '';
          imageUrl = '';
          isImageContainerVisible = false;
        });
      } else {
        setState(() {
          message = 'Customer not found!';
          isSaved = false;
        });
      }
    } catch (e) {
      print("Error deleting customer information: $e");
      setState(() {
        message = 'Failed to delete customer data!';
        isSaved = false;
      });
    }
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to dismiss dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this customer? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                await deleteCustomer(custId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  Future<void> pickAndUploadImage(BuildContext context) async {
    if (kIsWeb) {
      // Web platform
      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        // Read the file as bytes
        Uint8List? imageBytes = await pickedImage.readAsBytes();
        if (imageBytes != null) {
          // Upload image bytes to Firebase
          await uploadImageToFirebaseWeb(imageBytes);
        }
      }
    } else {
      // Mobile/desktop platforms
      final XFile? pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        File imageFile = File(pickedImage.path);
        await uploadImageToFirebaseMobile(imageFile);
      }
    }
  }


  Future<void> uploadImageToFirebaseWeb(Uint8List imageBytes) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString(); // Unique file name
      Reference storageRef = FirebaseStorage.instance.ref().child('uploads/$fileName.jpg');

      // Upload the image bytes to Firebase Storage
      UploadTask uploadTask = storageRef.putData(imageBytes);
      TaskSnapshot snapshot = await uploadTask;

      // Get the download URL of the uploaded image
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print("Image uploaded successfully (Web). Download URL: $downloadUrl");
    } catch (e) {
      print("Error uploading image (Web): $e");
    }
  }

  Future<void> uploadImageToFirebaseMobile(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString(); // Unique file name
      Reference storageRef = FirebaseStorage.instance.ref().child('uploads/$fileName.jpg');

      // Upload the file to Firebase Storage
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // Get the download URL of the uploaded image
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print("Image uploaded successfully (Mobile). Download URL: $downloadUrl");
    } catch (e) {
      print("Error uploading image (Mobile): $e");
    }
  }


  bool validateAadhaarNo(String aadhaarNo) {
    return aadhaarNo.isEmpty ||
        (aadhaarNo.length == 12 && RegExp(r'^[0-9]+$').hasMatch(aadhaarNo));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:Colors.purple[200],
        title: Text('Customer Forum'),
      ),
      backgroundColor: Colors.brown[50],
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(54.0),
            child: user == null
                ? Center(child: Text('User not authenticated'))
                : isLoading
                ? Center(child: CircularProgressIndicator())
                : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'STB NO.'),
                      onChanged: (value) {
                        setState(() {
                          custId = value;
                        });
                      },
                      onFieldSubmitted: (value) {
                        fetchCustomerInformation(value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter STB NO.';
                        }
                        return null;
                      },
                      initialValue: custId,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      autofocus: true, // Ensure the field is focused automatically
                    ),

                    SizedBox(height: 10),
                    TextFormField(
                      decoration:
                      InputDecoration(labelText: 'Customer  Name'),
                      onChanged: (value) {
                        setState(() {
                          custName = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter customer name';
                        }
                        return null;
                      },
                      initialValue: custName,
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(
                          labelText: 'Cust Ph. No.'),
                      onChanged: (value) {
                        setState(() {
                          custPhoneNumber = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        return null;
                      },
                      initialValue: custPhoneNumber,
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      decoration:
                      InputDecoration(labelText: 'Aadhaar No.'),
                      validator: (value) =>
                      validateAadhaarNo(value!)
                          ? null
                          : 'Invalid Aadhaar number format',
                      onChanged: (value) {
                        setState(() {
                          aadhaarNo = value;
                        });
                      },
                      initialValue: aadhaarNo,
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedAddressType = 'Village';
                            });
                          },
                          child: Text('Village'),
                        ),
                        SizedBox(width: 30),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedAddressType = 'Town';
                            });
                          },
                          child: Text('Town'),
                        ),
                      ],
                    ),
                    if (selectedAddressType == 'Village')
                      TextFormField(
                        decoration: InputDecoration(
                            labelText: 'Village Name'),
                        onChanged: (value) {
                          setState(() {
                            villageName = value;
                          });
                        },
                        initialValue: villageName,
                      ),
                    if (selectedAddressType == 'Town') ...[
                      TextFormField(
                        decoration:
                        InputDecoration(labelText: 'Town Name'),
                        onChanged: (value) {
                          setState(() {
                            townName = value;
                          });
                        },
                        initialValue: townName,
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        decoration:
                        InputDecoration(labelText: 'Ward No'),
                        onChanged: (value) {
                          setState(() {
                            wardNo = value;
                          });
                        },
                        initialValue: wardNo,
                      ),
                    ],
                    SizedBox(height: 20),
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(100, 40),
                        ),

                        onPressed: () {
                          _imageFile != null ? Image.file(_imageFile!) : Placeholder(fallbackHeight: 200.0);

                          pickAndUploadImage(context);
                        },
                        child: Text('Upload Photo'),
                      ),
                    ),

                    SizedBox(height: 20),
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(100, 40),
                        ),
                        onPressed: () async {
                          await saveCustomerInformation();
                        },
                        child: Text('Save'),
                      ),

                    ),
                    SizedBox(height: 20),
                    if (currentCustomerDocument != null)
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteConfirmationDialog(context);
                        },
                      ),
                    if (message.isNotEmpty)
                      Center(
                        child: Text(
                          message,
                          style: TextStyle(
                            color: isSaved
                                ? Colors.green
                                : Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (isImageContainerVisible)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.file(
                    _imageFile!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
                    : imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
                    : SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    home: CustForumPage(),
  ));
}