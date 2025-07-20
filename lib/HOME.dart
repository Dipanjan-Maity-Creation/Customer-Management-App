import 'dart:io';
import 'dart:async';


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
//import 'dart:typed_data';
import 'package:flutter/services.dart'; // For ByteData
import 'package:flutter/foundation.dart';  // For kIsWeb
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:flutter/foundation.dart' show kIsWeb;


import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart' as pdfWidgets;
import 'package:http/http.dart' as http;
import 'package:pdf_image_renderer/pdf_image_renderer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;


import 'package:bcbs/update.dart';
import 'package:bcbs/forum.dart';
import 'package:bcbs/Revenue.dart';
import 'package:bcbs/Data.dart';
import 'package:bcbs/change email.dart';
//import 'package:bcbs/subadmin.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? searchValue;
  String? selectedYear;
  Map<String, dynamic>? customerData;
  List<Map<String, dynamic>> paymentData = [];
  String? errorMessage;
  User? user;
  String? userName; // Variable to hold user name
  Image? customerPhoto; // Variable to hold customer photo widget
  String? customerPhotoUrl; // Define customer photo URL here
  double totalAdvancePaymentAcrossYears =0;
  double totalDueAmountAcrossYears =0;
  double finalAdvancePaymentAmount = 0;
  double finalDueAmountAmount = 0;
  double finalDueAmount =0;
  double finalAdvanceAmount =0;
  double finalAdvancePayment=0;




  Color _selectedThemeColor = Colors.white; // Default theme color

  final Map<String, int> monthOrder = {
    'January': 1,
    'February': 2,
    'March': 3,
    'April': 4,
    'May': 5,
    'June': 6,
    'July': 7,
    'August': 8,
    'September': 9,
    'October': 10,
    'November': 11,
    'December': 12,
  };

  final List<Color> themeColors = [
    Colors.white,
    Colors.lightBlue[100]!,
    Colors.lightGreen[100]!,
    Colors.lime[100]!,
    Colors.teal[300]!,
  ];

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp().then((value) {
      setState(() {
        user = FirebaseAuth.instance.currentUser;
        fetchUserName();
      });
    });
  }

  Future<void> fetchUserName() async {
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection(
          'admins').doc(user!.uid).get();
      setState(() {
        userName = userDoc['username']; // Fetching the 'username' field
      });
    }
  }

  Future<void> getCustomerInfo() async {
    if (user == null) {
      setState(() {
        errorMessage = 'User not authenticated';
      });
      return;
    }

    if (searchValue == null || searchValue!.isEmpty) {
      setState(() {
        errorMessage = 'Please enter STB NO./Cust Ph. No.';
      });
      return;
    }

    QuerySnapshot customerSnapshot;
    customerSnapshot = await FirebaseFirestore.instance
        .collection('customers')
        .where('userId', isEqualTo: user!.uid)
        .where('custId', isEqualTo: searchValue)
        .get();

    if (customerSnapshot.docs.isEmpty) {
      customerSnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .where('userId', isEqualTo: user!.uid)
          .where('custPhoneNumber', isEqualTo: searchValue)
          .get();
    }

    if (customerSnapshot.docs.isNotEmpty) {
      setState(() {
        customerData =
        customerSnapshot.docs.first.data() as Map<String, dynamic>;
        errorMessage = null;
      });
      await getPaymentInfo(); // Fetch payment info after customer info is fetched

      // Fetch customer photo if available
      if (customerData != null && customerData!['imageUrl'] != null &&
          customerData!['imageUrl'].isNotEmpty) {
        fetchCustomerPhoto(customerData!['imageUrl']);
      }
    } else {
      setState(() {
        customerData = null;
        errorMessage = 'No customer found with the entered details.';
        paymentData = []; // Reset payment data if no customer found
        customerPhoto = null; // Reset customer photo
      });
    }
  }

  Future<void> getPaymentInfo() async {
    if (user == null) {
      setState(() {
        errorMessage = 'User not authenticated';
      });
      return;
    }

    if (customerData == null) {
      return; // Do not proceed if customerData is null
    }

    // Fetch payment data for the given customer
    QuerySnapshot paymentSnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('userId', isEqualTo: user!.uid)
        .where('custId', isEqualTo: customerData!['custId']) // Assuming custId exists in customerData
        .get();

    double totalAdvancePayment = 0;
    double totalDueAmount = 0;

    List<Map<String, dynamic>> allPaymentData = paymentSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    // Aggregate totals across all years
    allPaymentData.forEach((data) {
      totalAdvancePayment += (data['advancePayment'] ?? 0).toDouble();
      totalDueAmount += (data['dueAmount'] ?? 0).toDouble();
    });

    double finalAdvancePayment;
    double finalDueAmount;

    if (totalAdvancePayment > totalDueAmount) {
      finalAdvancePayment = totalAdvancePayment - totalDueAmount;
      finalDueAmount = 0; // No due amount if advance payment exceeds
    } else {
      finalDueAmount = totalDueAmount - totalAdvancePayment;
      finalAdvancePayment = 0; // No advance payment if due amount exceeds
    }

    setState(() {
      paymentData = allPaymentData;

      paymentData.sort((a, b) {
        String monthA = a['selectedMonth'] ?? '';
        String monthB = b['selectedMonth'] ?? '';
        return (monthOrder[monthA] ?? 0).compareTo(monthOrder[monthB] ?? 0);
      });

      // Store the aggregated totals across all years
      totalDueAmountAcrossYears = totalDueAmount;
      totalAdvancePaymentAcrossYears = totalAdvancePayment;

      // Store the final amounts to show
      finalAdvancePaymentAmount = finalAdvancePayment;
      finalDueAmountAmount = finalDueAmount;
    });
  }








  void fetchCustomerPhoto(String imageUrl) {
    setState(() {
      customerPhoto = Image.network(
        imageUrl,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    });
  }

  Widget buildCustomerPhoto() {
    return customerPhoto ?? SizedBox.shrink();
  }

  Widget buildCustomerInfo() {
    if (customerData == null) {
      return SizedBox.shrink();
    }

    final staticTextStyle = TextStyle(
      color: Colors.blue,
      fontWeight: FontWeight.bold,
    );

    final dynamicTextStyle = TextStyle(
      color: Colors.black,
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('STB NO.:', style: staticTextStyle),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('${customerData!['custId']}',
                                style: dynamicTextStyle),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Cust Name:', style: staticTextStyle),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('${customerData!['custName']}',
                                style: dynamicTextStyle),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Cust Ph. No.:', style: staticTextStyle),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('${customerData!['custPhoneNumber']}',
                                style: dynamicTextStyle),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Address Type:', style: staticTextStyle),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('${customerData!['selectedAddressType']}',
                                style: dynamicTextStyle),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      if (customerData!['selectedAddressType'] == 'Village')
                        Row(
                          children: [
                            Text('Village Name:', style: staticTextStyle),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('${customerData!['villageName']}',
                                  style: dynamicTextStyle),
                            ),
                          ],
                        ),
                      if (customerData!['selectedAddressType'] == 'Town') ...[
                        Row(
                          children: [
                            Text('Town Name:', style: staticTextStyle),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('${customerData!['townName']}',
                                  style: dynamicTextStyle),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Text('Ward No:', style: staticTextStyle),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('${customerData!['wardNo']}',
                                  style: dynamicTextStyle),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Aadhaar No.:', style: staticTextStyle),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('${customerData!['aadhaarNo']}',
                                style: dynamicTextStyle),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Text('Total Advance Payment:', style: staticTextStyle),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              totalAdvancePaymentAcrossYears.toString(),
                              style: dynamicTextStyle,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Total Due Amount:', style: staticTextStyle),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              totalDueAmountAcrossYears.toString(),
                              style: dynamicTextStyle,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Text('Final Due Amount:', style: staticTextStyle),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              finalDueAmountAmount.toString(),
                              style: dynamicTextStyle,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Final Advance Payment:', style: staticTextStyle),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              finalAdvancePaymentAmount .toString(),
                              style: dynamicTextStyle,
                            ),
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
                buildCustomerPhoto(),
              ],
            ),
            SizedBox(height: 10),
            SizedBox(
              width: 250, // Adjust the width as needed
              child: DropdownButtonFormField<String>(
                value: selectedYear,
                onChanged: (value) {
                  setState(() {
                    selectedYear = value;
                    getPaymentInfo(); // Update payment info when year changes
                  });
                },
                items: List.generate(60, (index) {
                  int year = DateTime.now().year - index;
                  return DropdownMenuItem<String>(
                    value: year.toString(),
                    child: Text(year.toString()),
                  );
                }),
                decoration: InputDecoration(
                  labelText: 'Select Year',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: getPaymentInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Button background color
                foregroundColor: Colors.white, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Rounded corners
                ),
                padding: EdgeInsets.symmetric(vertical: 3, horizontal: 15), // Padding
              ),
              child: Text('Generate Bill'),
            ),
            SizedBox(height: 10),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }





  Widget buildPaymentTable() {
    if (paymentData.isEmpty) {
      return SizedBox.shrink();
    }

    // Filter paymentData based on the selected year
    final filteredPaymentData = paymentData.where((data) => data['selectedYear'] == selectedYear).toList();

    double totalRechargeAmount = filteredPaymentData.fold(
        0, (sum, data) => sum + (data['rechargeAmount'] ?? 0).toDouble());
    double totalPaymentAmount = filteredPaymentData.fold(
        0, (sum, data) => sum + (data['paymentAmount'] ?? 0).toDouble());
    double totalDueAmount = filteredPaymentData.fold(
        0, (sum, data) => sum + (data['dueAmount'] ?? 0).toDouble());
    double totalAdvancePayment = filteredPaymentData.fold(
        0, (sum, data) => sum + (data['advancePayment'] ?? 0).toDouble());

    String totalToShow;
    if (totalDueAmount > totalAdvancePayment) {
      totalToShow = 'Total Due Amount: ${totalDueAmount - totalAdvancePayment}';
    } else if (totalAdvancePayment > totalDueAmount) {
      totalToShow = 'Total Advance Payment: ${totalAdvancePayment - totalDueAmount}';
    } else {
      totalToShow = 'Total Due Amount: $totalDueAmount';
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: screenWidth > 600 ? screenWidth * 0.7 : screenWidth,
                  maxWidth: screenWidth > 800 ? screenWidth * 0.8 : screenWidth,
                ),
                child: DataTable(
                  columnSpacing: 12.0, // Adjust column spacing
                  columns: [
                    DataColumn(label: Expanded(child: Text('Month'))),
                    DataColumn(label: Expanded(child: Text('Recharge'))),
                    DataColumn(label: Expanded(child: Text('Payment'))),
                    DataColumn(label: Expanded(child: Text('Due'))),
                    DataColumn(label: Expanded(child: Text('Advance'))),
                  ],
                  rows: [
                    ...filteredPaymentData.map((data) {
                      return DataRow(cells: [
                        DataCell(Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 4.0,
                            horizontal: 4.0,
                          ), // Adjust padding
                          child: Text(data['selectedMonth'] ?? ''),
                        )),
                        DataCell(Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 4.0,
                            horizontal: 4.0,
                          ), // Adjust padding
                          child: Text(data['rechargeAmount'].toString()),
                        )),
                        DataCell(Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 4.0,
                            horizontal: 4.0,
                          ), // Adjust padding
                          child: Text(data['paymentAmount'].toString()),
                        )),
                        DataCell(Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 4.0,
                            horizontal: 4.0,
                          ), // Adjust padding
                          child: Text(data['dueAmount'].toString()),
                        )),
                        DataCell(Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 4.0,
                            horizontal: 4.0,
                          ), // Adjust padding
                          child: Text(data['advancePayment'].toString()),
                        )),
                      ]);
                    }).toList(),
                    DataRow(cells: [
                      DataCell(
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 4.0,
                            horizontal: 4.0,
                          ), // Adjust padding
                          child: Text(
                            'Total',
                            style: TextStyle(
                              fontWeight: FontWeight.bold, // Make text bold
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 4.0,
                            horizontal: 4.0,
                          ), // Adjust padding
                          child: Text(
                            totalRechargeAmount.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold, // Make text bold
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 4.0,
                            horizontal: 4.0,
                          ), // Adjust padding
                          child: Text(
                            totalPaymentAmount.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold, // Make text bold
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 4.0,
                            horizontal: 4.0,
                          ), // Adjust padding
                          child: Text(
                            totalDueAmount.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold, // Make text bold
                            ),
                          ),
                        ),
                      ),
                      DataCell(Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 4.0,
                        ), // Adjust padding
                        child: Text(totalAdvancePayment.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )),
                    ]),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(10.0),
              color: Colors.blueAccent, // Change this to the desired background color
              child: Text(
                totalToShow,
                style: TextStyle(
                  color: Colors.white, // Change this to the desired text color
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }





  Future<pw.ImageProvider> loadPlaceholderImage() async {
    final ByteData data = await rootBundle.load(
        'assets/images/placeholder.png'); // Add a placeholder image to your assets
    return pw.MemoryImage(data.buffer.asUint8List());
  }


  Future<pw.ImageProvider> fetchImageForPdf(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      return await loadPlaceholderImage(); // Return a placeholder image
    }

    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (e) {
      print('Error fetching image for PDF: $e');
    }

    return await loadPlaceholderImage(); // Return a placeholder image in case of error
  }

  Future<pw.ImageProvider> loadLogoImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/4_X_2.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      print('Error loading logo image: $e');
      return await loadPlaceholderImage(); // Return a placeholder image in case of error
    }
  }



  Future<void> downloadPdf(BuildContext context) async {
    // Use the STB number to create a dynamic file name
    final stbNumber = customerData?['custId'] ?? 'unknown';
    final fileName = 'BILL_NO_$stbNumber.pdf';

    final pdf = pw.Document();

    // Fetch images for the PDF
    final customerImageProvider = await fetchImageForPdf(customerData?['imageUrl']);
    final logoImageProvider = await loadLogoImage();



    // Filter payment data to include only entries for the selected year
    final filteredPaymentData = paymentData.where((payment) {
      final paymentYear = payment['selectedYear'];
      return paymentYear == selectedYear; // Assumes payment data includes a 'selectedYear' field
    }).toList();

    // Calculate totals for the selected year
    double totalRechargeAmount = 0;
    double totalPaymentAmount = 0;
    double totalDueAmount = 0;
    double totalAdvanceAmount = 0;

    for (final payment in filteredPaymentData) {
      totalRechargeAmount += payment['rechargeAmount'] ?? 0;
      totalPaymentAmount += payment['paymentAmount'] ?? 0;
      totalDueAmount += payment['dueAmount'] ?? 0;
      totalAdvanceAmount += payment['advancePayment'] ?? 0;
    }

    // Calculate all-year totals
    double totalAdvancePaymentAcrossYears = 0;
    double totalDueAmountAcrossYears = 0;

    for (final payment in paymentData) {
      totalAdvancePaymentAcrossYears += payment['advancePayment'] ?? 0;
      totalDueAmountAcrossYears += payment['dueAmount'] ?? 0;
    }

    double finalDueAmountAmount = (totalDueAmountAcrossYears - totalAdvancePaymentAcrossYears).clamp(0, double.infinity);
    double finalAdvancePaymentAmount = (totalAdvancePaymentAcrossYears - totalDueAmountAcrossYears).clamp(0, double.infinity);

    // Build PDF content
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Image(logoImageProvider, width: 100, height: 100),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 2),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      userName ?? 'User',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      '   Year: $selectedYear',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                '     Bill Invoice',
                style: pw.TextStyle(fontSize: 24, color: PdfColors.blue, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 12),
              // Add other content here...
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('STB NO.: ${customerData?['custId'] ?? 'N/A'}'),
                        pw.Text('Cust Name: ${customerData?['custName'] ?? 'N/A'}'),
                        pw.Text('Cust Ph. No.: ${customerData?['custPhoneNumber'] ?? 'N/A'}'),
                        pw.Text('Selected Address Type: ${customerData?['selectedAddressType'] ?? 'N/A'}'),
                        pw.Text('${customerData?['villageName'] ?? 'N/A'}'),
                        pw.Text('${customerData?['townName'] ?? 'N/A'}'),
                        pw.Text('${customerData?['wardNo'] ?? 'N/A'}'),
                        pw.Text('Aadhaar No.: ${customerData?['aadhaarNo'] ?? 'N/A'}'),
                      ],
                    ),
                  ),
                  pw.Container(
                    width: 100,
                    height: 100,
                    alignment: pw.Alignment.topRight,
                    child: pw.Image(customerImageProvider, fit: pw.BoxFit.cover),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue, // Set your desired header background color here
                    ),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(3),
                        child: pw.Text(
                          'Month',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(3),
                        child: pw.Text(
                          'Recharge Amount',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(3),
                        child: pw.Text(
                          'Payment Amount',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(3),
                        child: pw.Text(
                          'Due Amount',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(3),
                        child: pw.Text(
                          'Advance Amount',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...filteredPaymentData.map((payment) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(3),
                          child: pw.Text(payment['selectedMonth'] ?? 'N/A'),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(3),
                          child: pw.Text(payment['rechargeAmount']?.toString() ?? '0'),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(3),
                          child: pw.Text(payment['paymentAmount']?.toString() ?? '0'),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(3),
                          child: pw.Text(payment['dueAmount']?.toString() ?? '0'),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(3),
                          child: pw.Text(payment['advancePayment']?.toString() ?? '0'),
                        ),
                      ],
                    );
                  }).toList()
                    ..add(
                      pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey300, // Color for the footer row
                        ),
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(3),
                            child: pw.Text('Total'),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(3),
                            child: pw.Text(totalRechargeAmount.toStringAsFixed(2)),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(3),
                            child: pw.Text(totalPaymentAmount.toStringAsFixed(2)),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(3),
                            child: pw.Text(totalDueAmount.toStringAsFixed(2)),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(3),
                            child: pw.Text(totalAdvanceAmount.toStringAsFixed(2)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200, // Background color for totals
                  borderRadius: pw.BorderRadius.circular(5), // Rounded corners
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text('Total Advance Payment:', style: pw.TextStyle(fontSize: 16,color: PdfColors.orange)),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.Text(
                              finalAdvancePaymentAmount.toStringAsFixed(2),
                              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold,color: PdfColors.purple400,)
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Text('Total Due Amount:', style: pw.TextStyle(fontSize: 16,color: PdfColors.teal)),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.Text(
                            finalDueAmountAmount.toStringAsFixed(2),
                            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            ],
          );
        },
      ),
    );

    // Save PDF and download it
    try {
      final pdfData = await pdf.save();

      // Trigger download in web
      final blob = html.Blob([pdfData], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url); // Clean up

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF downloaded successfully!')),
      );
    } catch (e) {
      print('Error saving PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving PDF')),
      );
    }
  }




  void _showThemeSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Theme Color'),
          content: SingleChildScrollView(
            child: Column(
              children: themeColors.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedThemeColor = color;
                      Navigator.of(context).pop();
                    });
                  },
                  child: Container(
                    color: color,
                    height: 50,
                    width: 100,
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: _selectedThemeColor == color
                        ? Icon(Icons.check, color: Colors.black)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    // Determine the width of the text field based on screen size
    final textFieldWidth = screenWidth > 600 ? 400.0 : screenWidth * 0.8;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple[300],
        title: Text(''),
        actions: [
          if (userName != null)
            Row(
              children: [
                Text(
                  '$userName',
                  style: TextStyle(
                    fontSize: 16, // Increase the font size here
                  ),
                ),
                SizedBox(width: 10), // Adjust spacing if needed
              ],
            ),
          Image.asset(
            'assets/images/4_X_2.png',
            width: 80,
            height: 80,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: userName != null ? Text(userName!) : null,
              accountEmail: user != null ? Text(user!.email!) : null,
              currentAccountPicture: CircleAvatar(
                child: Icon(Icons.person),
              ),
            ),
            ListTile(
              title: Text('Change Theme Color'),
              onTap: _showThemeSelectionDialog,
            ),
            ListTile(
              title: Text('Customer Forum'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CustForumPage()),
                );
              },
            ),
            ListTile(
              title: Text('Customer Update'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CustUpdatePage()),
                );
              },
            ),
            ListTile(
              title: Text('Revenue Page'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RevenuePage()),
                );
              },
            ),
            ListTile(
              title: Text('Change Email'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangeEmailPage()),
                );
              },
            ),
            ListTile(
              title: Text('Data Page'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DataPage()),
                );
              },
            ),

          ],
        ),
      ),
      body: Container(
        color: _selectedThemeColor, // Apply the selected theme color
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CustForumPage()),
                            );
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Forum',
                              style: TextStyle(color: Colors.white)),
                        ),
                        SizedBox(width: 8.0),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CustUpdatePage()),
                            );
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Update',
                              style: TextStyle(color: Colors.white)),
                        ),
                        SizedBox(width: 8.0),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => RevenuePage()),
                            );
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Revenue',
                              style: TextStyle(color: Colors.white)),
                        ),
                        SizedBox(width: 8.0),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DataPage()),
                            );
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Data',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),
                    Center( // Center the TextField in the screen
                      child: SizedBox(
                        width: 350,
                        // Set the width of the text field
                        child: TextField(
                          onChanged: (value) {
                            searchValue = value;
                          },
                          decoration: InputDecoration(
                            labelText: 'Enter STB NO./Cust Ph. No.',
                            border: OutlineInputBorder(),
                            errorText: errorMessage,
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: getCustomerInfo,
                                  icon: Icon(Icons.search),
                                  // Search icon
                                  color: Colors.black,
                                  // Icon color
                                  iconSize: 24.0,
                                  // Icon size
                                  tooltip: 'Get Customer Info', // Tooltip on long press
                                ),
                                Text(
                                  'search', // Text to show next to the icon
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16.0,
                                  ),
                                ),
                                SizedBox(width: 15),
                                // Space between text and icon
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildCustomerInfo(),
                        SizedBox(height: 10),
                        buildPaymentTable(),
                        ElevatedButton(
                          onPressed: () async {
                            await downloadPdf(context);
                          },
                          child: Text('Download PDF'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}