import 'package:flutter/material.dart';

import 'package:bcbs/HOME.dart';
import 'package:bcbs/forum.dart';
import 'package:bcbs/main.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustUpdatePage extends StatefulWidget {
  @override
  _CustUpdatePageState createState() => _CustUpdatePageState();
}

class _CustUpdatePageState extends State<CustUpdatePage> {
  String? custId;
  String? custName;
  String? custPhoneNumber;
  String? selectedAddressType;
  String? villageName;
  String? townName;
  String? wardNo;
  String? aadhaarNo; // Added Aadhaar number field
  String? errorMessage;
  String? selectedYear;
  String? selectedMonth;
  double? rechargeAmount;
  double? paymentAmount;
  double? dueAmount;
  double? advancePayment;
  double totalDueAmount = 0;
  double totalAdvancePayment = 0;
  bool enablePaymentFields = false;
  bool showFunctions = false;

  User? user;
  String? editingPaymentId;
  String? imageUrl; // Added imageUrl to store the customer's photo URL

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp();
    user = FirebaseAuth.instance.currentUser;
  }

  Future<void> getSavedCustomerInformation(String searchValue) async {
    if (user == null) {
      setState(() {
        errorMessage = 'User not authenticated';
        showFunctions = false;
      });
      return;
    }

    QuerySnapshot customerSnapshot = await FirebaseFirestore.instance
        .collection('customers')
        .where('userId', isEqualTo: user!.uid)
        .where('custId', isEqualTo: searchValue) // Search by STB number
        .get();

    if (customerSnapshot.docs.isEmpty) {
      // If no customer found by STB number, search by customer phone number
      customerSnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .where('userId', isEqualTo: user!.uid)
          .where('custPhoneNumber', isEqualTo: searchValue)
          .get();
    }

    if (customerSnapshot.docs.isNotEmpty) {
      Map<String, dynamic> customerData =
      customerSnapshot.docs.first.data() as Map<String, dynamic>;
      setState(() {
        custId = customerData['custId'];
        custName = customerData['custName'];
        custPhoneNumber = customerData['custPhoneNumber'];
        selectedAddressType = customerData['selectedAddressType'];
        villageName = customerData['villageName'];
        townName = customerData['townName'];
        wardNo = customerData['wardNo'];
        errorMessage = null;
        showFunctions = true;
        imageUrl = customerData['imageUrl']; // Set imageUrl to the retrieved photo URL
        aadhaarNo = customerData['aadhaarNo']; // Set Aadhaar number to the retrieved value
      });

      QuerySnapshot paymentSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('userId', isEqualTo: user!.uid)
          .where('custId', isEqualTo: custId) // Use custId for payment query
          .get();

      double totalDueAmount = 0;
      double totalAdvancePayment = 0;
      paymentSnapshot.docs.forEach((doc) {
        totalDueAmount += doc['dueAmount'] ?? 0;
        totalAdvancePayment += doc['advancePayment'] ?? 0;
      });

      setState(() {
        this.totalDueAmount = totalDueAmount;
        this.totalAdvancePayment = totalAdvancePayment;
      });
    } else {
      setState(() {
        custId = null;
        custName = null;
        custPhoneNumber = null;
        selectedAddressType = null;
        villageName = null;
        townName = null;
        wardNo = null;
        errorMessage = 'Please enter a valid STB NO./cust Ph no.';
        showFunctions = false;
      });
    }
  }



  Future<void> savePaymentInformation() async {
    if (user == null) {
      setState(() {
        errorMessage = 'User not authenticated';
      });
      return;
    }

    if (rechargeAmount == null || paymentAmount == null) {
      setState(() {
        errorMessage = 'Please fill the amount values';
      });
      return;
    }

    if (selectedYear == null || selectedMonth == null) {
      setState(() {
        errorMessage = 'Please select year and month';
      });
      return;
    }

    // Create payment data
    Map<String, dynamic> paymentData = {
      'selectedYear': selectedYear,
      'selectedMonth': selectedMonth,
      'rechargeAmount': rechargeAmount,
      'paymentAmount': paymentAmount,
      'dueAmount': dueAmount,
      'advancePayment': advancePayment,
      'custId': custId,
      'userId': user!.uid,
      'timestamp': Timestamp.now(),
    };

    // Check for existing data
    QuerySnapshot existingDataSnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('userId', isEqualTo: user!.uid)
        .where('custId', isEqualTo: custId)
        .where('selectedYear', isEqualTo: selectedYear)
        .where('selectedMonth', isEqualTo: selectedMonth)
        .get();

    if (existingDataSnapshot.docs.isNotEmpty) {
      // Data already exists, show confirmation dialog
      bool? shouldUpdate = await showUpdateConfirmationDialog();
      if (shouldUpdate == true) {
        // User chose to update the existing record
        String existingDocumentId = existingDataSnapshot.docs.first.id;
        await FirebaseFirestore.instance
            .collection('payments')
            .doc(existingDocumentId)
            .update(paymentData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment data updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // No existing data, add new record
      await FirebaseFirestore.instance.collection('payments').add(paymentData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved Data'),
          backgroundColor: Colors.green,
        ),
      );
    }

    // Clear fields and error messages
    setState(() {
      rechargeAmount = null;
      paymentAmount = null;
      dueAmount = null;
      advancePayment = null;
      errorMessage = null;
    });
  }

  Future<bool?> showUpdateConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Data already exists'),
          content: Text('Payment data already exists for this year and month. Do you want to update it?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User chose to update
              },
              child: Text('Update'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User chose to cancel
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }



  void showConfirmationSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment data already exists. Are you sure you want to change it?',
          style: TextStyle(color: Colors.white), // Custom text color
        ),
        action: SnackBarAction(
          label: 'Yes',
          onPressed: () async {
            // Handle 'Yes' action here
            // Implement the logic to change the payment data
            // Update the existing data with new values
            await updatePaymentData();
          },
        ),
        behavior: SnackBarBehavior.floating, // Centered vertically
        backgroundColor: Colors.red, // Custom background color
      ),
    );
  }

  Future<void> updatePaymentData() async {
    // Retrieve the existing document to get its ID
    QuerySnapshot existingDataSnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('userId', isEqualTo: user!.uid)
        .where('custId', isEqualTo: custId)
        .where('selectedYear', isEqualTo: selectedYear)
        .where('selectedMonth', isEqualTo: selectedMonth)
        .get();

    // Check if there's exactly one document found
    if (existingDataSnapshot.docs.isNotEmpty) {
      String existingDocumentId = existingDataSnapshot.docs.first.id;

      // Construct new payment data
      Map<String, dynamic> newPaymentData = {
        'selectedYear': selectedYear,
        'selectedMonth': selectedMonth,
        'rechargeAmount': rechargeAmount,
        'paymentAmount': paymentAmount,
        'dueAmount': dueAmount,
        'advancePayment': advancePayment,
        'custId': custId,
        'userId': user!.uid,
        'timestamp': Timestamp.now(),
      };

      // Update the existing document with new values
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(existingDocumentId)
          .update(newPaymentData);

      // Show success message with green text color and centered vertically
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment data updated',
            style: TextStyle(color: Colors.white), // Custom text color
          ),
          behavior: SnackBarBehavior.floating, // Centered vertically
          backgroundColor: Colors.green, // Custom background color
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    double adjustedTotalDueAmount = totalDueAmount > totalAdvancePayment
        ? totalDueAmount - totalAdvancePayment
        : 0;
    double adjustedTotalAdvancePayment = totalAdvancePayment > totalDueAmount
        ? totalAdvancePayment - totalDueAmount
        : 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor:Colors.indigo[300],
        title: Text('Customer Update'),
      ),
      backgroundColor: Colors.brown[50],
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(50.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (imageUrl != null) // Display the customer's photo if available
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    width: 100, // Fixed width for the image
                    height: 100, // Fixed height for the image
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle, // Shape of the image container
                      border: Border.all(
                        color: Colors.grey,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 20), // Add some space below the image
              DropdownButtonFormField<String>(
                value: selectedYear,
                onChanged: (value) {
                  setState(() {
                    selectedYear = value;
                    if (selectedMonth != null) {
                      enablePaymentFields = true;
                    }
                  });
                },
                items: List.generate(60, (index) {
                  int year = DateTime.now().year - index;
                  return DropdownMenuItem<String>(
                    value: year.toString(),
                    child: Text(year.toString()),
                  );
                }),
                decoration: InputDecoration(labelText: 'Select Year'),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedMonth,
                onChanged: (value) {
                  setState(() {
                    selectedMonth = value;
                    if (selectedYear != null) {
                      enablePaymentFields = true;
                    }
                  });
                },
                items: [
                  'January',
                  'February',
                  'March',
                  'April',
                  'May',
                  'June',
                  'July',
                  'August',
                  'September',
                  'October',
                  'November',
                  'December',
                ].map((month) {
                  return DropdownMenuItem<String>(
                    value: month,
                    child: Text(month),
                  );
                }).toList(),
                decoration: InputDecoration(labelText: 'Select Month'),
              ),
              SizedBox(
                width: 500, // Adjust this width as needed
                child: TextFormField(
                  decoration: InputDecoration(labelText: 'STB NO.'),
                  onChanged: (value) {
                    setState(() {
                      custId = value;
                    });
                  },
                ),
              ),
              Container(
                width: double.infinity, // Allow the container to take full width of its parent
                padding: EdgeInsets.symmetric(horizontal: 20.0), // Add padding for spacing
                child: Center(
                  child: SizedBox( // Limit button width with SizedBox
                    width: 100.0, // Set a specific width for the button
                    child: ElevatedButton(
                      onPressed: () async {
                        if (custId != null) {
                          await getSavedCustomerInformation(custId!);
                        } else {
                          setState(() {
                            errorMessage = 'Please enter a valid STB NO./cust Ph no.';
                            showFunctions = false;
                          });
                        }
                      },
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                          EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                        ),
                        alignment: Alignment.center,
                      ),
                      child: Text(
                        'Get Data',
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              if (showFunctions) ...[
                Text('STB NO.: $custId', style: TextStyle(fontSize: 16.0)),
                Text('Cust Name: $custName', style: TextStyle(fontSize: 16.0)),
                Text('Cust Ph. No.: $custPhoneNumber', style: TextStyle(fontSize: 16.0)),
                Text('Selected Address Type: $selectedAddressType', style: TextStyle(fontSize: 16.0)),
                if (selectedAddressType == 'Village')
                  Text('Village Name: $villageName', style: TextStyle(fontSize: 16.0)),
                if (selectedAddressType == 'Town') ...[
                  Text('Town Name: $townName', style: TextStyle(fontSize: 16.0)),
                  Text('Ward No: $wardNo', style: TextStyle(fontSize: 16.0)),
                ],
                Text('Aadhaar No.: $aadhaarNo', style: TextStyle(fontSize: 16.0)), // Display Aadhaar number
                SizedBox(height: 20),
                Text('Payment Information',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                if (enablePaymentFields) ...[
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Recharge Amount'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        rechargeAmount = double.tryParse(value);
                        calculateDueAmountAndAdvancePayment();
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Payment Amount'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        paymentAmount = double.tryParse(value);
                        calculateDueAmountAndAdvancePayment();
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  if (dueAmount != null) Text('Due Amount: $dueAmount'),
                  if (advancePayment != null)
                    Text('Advance Payment: $advancePayment'),
                ],
                SizedBox(height: 10),
                Text('Total Due Amount: $adjustedTotalDueAmount'),
                Text('Total Advance Payment: $adjustedTotalAdvancePayment'),
                SizedBox(height: 10),


                Container(
                  width: double.infinity, // This allows the container to take full width of its parent
                  padding: EdgeInsets.symmetric(horizontal: 20.0), // Add padding to container for spacing
                  child: Center(
                    child: SizedBox( // Limit button width with SizedBox
                      width: 100.0, // Set a specific width for the button
                      child: ElevatedButton(
                        onPressed: () async {
                          await savePaymentInformation();
                        },
                        style: ButtonStyle(
                          padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                            EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                          ),
                          alignment: Alignment.center,
                        ),
                        child: Text(
                          'Save',
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                  ),
                ),



                SizedBox(height: 5),
                Container(
                  width: double.infinity, // Allow the container to take full width of its parent
                  padding: EdgeInsets.symmetric(horizontal: 20.0), // Add padding for spacing
                  child: Center(
                    child: SizedBox( // Limit button width with SizedBox
                      width: 140.0, // Set a specific width for the button
                      child: ElevatedButton(
                        onPressed: () {
                          showSavedData();
                        },
                        style: ButtonStyle(
                          padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                            EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                          ),
                          alignment: Alignment.center,
                        ),
                        child: Text(
                          'View Status',
                          style: TextStyle(fontSize: 13.0),
                        ),
                      ),
                    ),
                  ),
                ),

              ],
            ],
          ),
        ),
      ),
    );
  }


  // Function to calculate due amount and advance payment
  void calculateDueAmountAndAdvancePayment() {
    if (rechargeAmount != null && paymentAmount != null) {
      double totalAmount = rechargeAmount! - paymentAmount!;
      setState(() {
        if (totalAmount >= 0) {
          dueAmount = totalAmount;
          advancePayment = 0;
        } else {
          dueAmount = 0;
          advancePayment = totalAmount.abs();
        }
      });
    }
  }

  // Function to show all saved data based on criteria
  void showSavedData() async {
    try {
      // Fetch all payment data from Firestore
      QuerySnapshot paymentSnapshot = await FirebaseFirestore.instance.collection('payments').get();

      // Map the document data into a list of maps
      List<Map<String, dynamic>> allData = paymentSnapshot.docs
          .map((doc) => {
        ...doc.data() as Map<String, dynamic>,
        'documentId': doc.id, // Add document ID for reference
      })
          .toList();

      // Filter data based on criteria: custId (STB number) and selectedYear
      List<Map<String, dynamic>> filteredData = allData.where((data) {
        bool matchesCustId = custId != null && data['custId'] == custId;
        bool matchesYear = selectedYear != null && data['selectedYear'] == selectedYear;
        return matchesCustId && matchesYear;
      }).toList();

      // Sort the filtered data in descending order based on timestamp
      filteredData.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      // Check if there's any filtered data
      if (filteredData.isEmpty) {
        // Show a message if no payment history is found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No payment history found for the selected criteria.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show filtered data with delete option
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Filtered Data'),
            content: Container(
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: filteredData.length,
                itemBuilder: (BuildContext context, int index) {
                  Map<String, dynamic> data = filteredData[index];
                  return ListTile(
                    title: Text('Year: ${data['selectedYear']}, Month: ${data['selectedMonth']}, '
                        'Recharge: ${data['rechargeAmount']}, Payment: ${data['paymentAmount']}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _showDeleteConfirmationDialog(data['custId'], data['selectedYear'], data['selectedMonth']);
                      },
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                child: Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch payment data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Function to show delete confirmation dialog
  Future<void> _showDeleteConfirmationDialog(String custId, String selectedYear, String selectedMonth) async {
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Confirmation'),
          content: Text('Are you sure you want to delete this payment data?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User confirmed delete
              },
              child: Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User canceled
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deletePaymentData(custId, selectedYear, selectedMonth);
    }
  }

// Function to delete payment data
  Future<void> _deletePaymentData(String custId, String selectedYear, String selectedMonth) async {
    try {
      QuerySnapshot paymentSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('custId', isEqualTo: custId)
          .where('selectedYear', isEqualTo: selectedYear)
          .where('selectedMonth', isEqualTo: selectedMonth)
          .get();

      for (var doc in paymentSnapshot.docs) {
        await FirebaseFirestore.instance.collection('payments').doc(doc.id).delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment data deleted'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the displayed data
      showSavedData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    runApp(MaterialApp(
      home: CustUpdatePage(),
    ));
  }
}