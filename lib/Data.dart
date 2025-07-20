import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DataPage extends StatefulWidget {
  @override
  _DataPageState createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  String? selectedYear;
  bool isYearly = true;
  List<Map<String, dynamic>> customerData = [];
  int totalCustomers = 0; // To store the count of customers who recharged
  String? errorMessage;
  User? user;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  String? selectedMonth; // Define selectedMonth here


  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        this.user = user;
      });
    });
  }

  Future<void> getTodayData() async {
    if (user == null) {
      setState(() {
        errorMessage = 'User not authenticated';
      });
      return;
    }

    // Get today's date
    DateTime today = DateTime.now();
    String todayString = "${today.year}-${today.month.toString().padLeft(
        2, '0')}-${today.day.toString().padLeft(2, '0')}";

    QuerySnapshot customerSnapshot = await FirebaseFirestore.instance
        .collection('customers')
        .where('userId', isEqualTo: user!.uid)
        .get();


    List<Map<String, dynamic>> fetchedCustomerData = [];
    int count = 0;

    for (var doc in customerSnapshot.docs) {
      Map<String, dynamic> customer = doc.data() as Map<String, dynamic>;

      QuerySnapshot paymentSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('userId', isEqualTo: user!.uid)
          .where('custId', isEqualTo: customer['custId'])
          .where(
          'paymentDate', isEqualTo: todayString) // Filter by today's date
          .get();

      if (paymentSnapshot.docs.isNotEmpty) {
        count++; // Increment count if customer recharged today
      }

      double totalRechargeAmount = 0;
      double totalPaymentAmount = 0;
      double totalDueAmount = 0;
      double totalAdvancePayment = 0;

      List<Map<String, dynamic>> monthlyPayments = [];
      for (var paymentDoc in paymentSnapshot.docs) {
        Map<String, dynamic> payment = paymentDoc.data() as Map<String,
            dynamic>;
        totalRechargeAmount += payment['rechargeAmount'] ?? 0;
        totalPaymentAmount += payment['paymentAmount'] ?? 0;
        totalDueAmount += payment['dueAmount'] ?? 0;
        totalAdvancePayment += payment['advancePayment'] ?? 0;

        monthlyPayments.add({
          'selectedMonth': payment['selectedMonth'],
          'rechargeAmount': payment['rechargeAmount'] ?? 0,
          'paymentAmount': payment['paymentAmount'] ?? 0,
          'dueAmount': payment['dueAmount'] ?? 0,
          'advancePayment': payment['advancePayment'] ?? 0,
        });
      }

      fetchedCustomerData.add({
        'custId': customer['custId'],
        'custName': customer['custName'],
        'custPhoneNumber': customer['custPhoneNumber'],
        'totalRechargeAmount': totalRechargeAmount,
        'totalPaymentAmount': totalPaymentAmount,
        'totalDueAmount': totalDueAmount,
        'totalAdvancePayment': totalAdvancePayment,
        'monthlyPayments': monthlyPayments,
      });
    }

    setState(() {
      customerData = fetchedCustomerData;
      totalCustomers = count; // Set the total customer count
      errorMessage = null;
    });
  }


  Future<void> getCustomerData() async {
    if (user == null) {
      setState(() {
        errorMessage = 'User not authenticated';
      });
      return;
    }

    if (isYearly) {
      // Existing code for yearly data
      if (selectedYear == null) {
        setState(() {
          errorMessage = 'Please select a year';
        });
        return;
      }

      // Existing code to get yearly data
    } else if (selectedMonth == 'Today') {
      // Get today's data
      await getTodayData();
    } else {
      // Existing code for monthly data
      if (selectedMonth == null) {
        setState(() {
          errorMessage = 'Please select a month';
        });
        return;
      }
    }

    QuerySnapshot customerSnapshot = await FirebaseFirestore.instance
        .collection('customers')
        .where('userId', isEqualTo: user!.uid)
        .get();

    List<Map<String, dynamic>> fetchedCustomerData = [];
    int count = 0;

    for (var doc in customerSnapshot.docs) {
      Map<String, dynamic> customer = doc.data() as Map<String, dynamic>;

      QuerySnapshot paymentSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('userId', isEqualTo: user!.uid)
          .where('custId', isEqualTo: customer['custId'])
          .where('selectedYear', isEqualTo: selectedYear)
          .get();

      if (paymentSnapshot.docs.isNotEmpty) {
        count++; // Increment count if customer recharged in the selected period
      }

      double totalRechargeAmount = 0;
      double totalPaymentAmount = 0;
      double totalDueAmount = 0;
      double totalAdvancePayment = 0;

      List<Map<String, dynamic>> monthlyPayments = [];
      for (var paymentDoc in paymentSnapshot.docs) {
        Map<String, dynamic> payment = paymentDoc.data() as Map<String, dynamic>;
        totalRechargeAmount += payment['rechargeAmount'] ?? 0;
        totalPaymentAmount += payment['paymentAmount'] ?? 0;
        totalDueAmount += payment['dueAmount'] ?? 0;
        totalAdvancePayment += payment['advancePayment'] ?? 0;

        monthlyPayments.add({
          'selectedMonth': payment['selectedMonth'],
          'rechargeAmount': payment['rechargeAmount'] ?? 0,
          'paymentAmount': payment['paymentAmount'] ?? 0,
          'dueAmount': payment['dueAmount'] ?? 0,
          'advancePayment': payment['advancePayment'] ?? 0,
        });
      }

      fetchedCustomerData.add({
        'custId': customer['custId'],
        'custName': customer['custName'],
        'custPhoneNumber': customer['custPhoneNumber'],
        'totalRechargeAmount': totalRechargeAmount,
        'totalPaymentAmount': totalPaymentAmount,
        'totalDueAmount': totalDueAmount,
        'totalAdvancePayment': totalAdvancePayment,
        'monthlyPayments': monthlyPayments,
      });
    }

    setState(() {
      customerData = fetchedCustomerData;
      totalCustomers = count; // Set the total customer count
      errorMessage = null;
    });
  }

  void _sort<T>(Comparable<T> Function(Map<String, dynamic>) getField, int columnIndex, bool ascending) {
    customerData.sort((a, b) {
      final Comparable<T> aValue = getField(a);
      final Comparable<T> bValue = getField(b);
      return ascending ? Comparable.compare(aValue, bValue) : Comparable.compare(bValue, aValue);
    });
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  Widget buildYearDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedYear,
      onChanged: (value) {
        setState(() {
          selectedYear = value;
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
    );
  }

  Widget buildCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: isYearly,
          onChanged: (value) {
            setState(() {
              isYearly = value!;
            });
          },
        ),
        Text('Yearly'),
        Checkbox(
          value: !isYearly,
          onChanged: (value) {
            setState(() {
              isYearly = !value!;
            });
          },
        ),
        Text('Monthly'),
        Checkbox(
          value: selectedMonth == 'Today',
          onChanged: (value) {
            setState(() {
              if (value!) {
                selectedMonth = 'Today';
              } else {
                selectedMonth = null;
              }
            });
          },
        ),
        Text('Today'),
      ],
    );
  }


  Widget buildYearlyTable() {
    double totalRechargeAmount = customerData.fold<double>(0, (sum, data) => sum + data['totalRechargeAmount']);
    double totalPaymentAmount = customerData.fold<double>(0, (sum, data) => sum + data['totalPaymentAmount']);
    double totalDueAmount = customerData.fold<double>(0, (sum, data) => sum + data['totalDueAmount']);
    double totalAdvancePayment = customerData.fold<double>(0, (sum, data) => sum + data['totalAdvancePayment']);

    return DataTable(
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      columns: [
        DataColumn(label: Text('Sl No.')),
        DataColumn(label: Text('STB NO.'), onSort: (columnIndex, ascending) => _sort<String>((data) => data['custId'], columnIndex, ascending)),
        DataColumn(label: Text('Customer Name'), onSort: (columnIndex, ascending) => _sort<String>((data) => data['custName'], columnIndex, ascending)),
        DataColumn(label: Text('Cust Ph No.'), onSort: (columnIndex, ascending) => _sort<String>((data) => data['custPhoneNumber'], columnIndex, ascending)),
        DataColumn(label: Text('Total Recharge amount'), onSort: (columnIndex, ascending) => _sort<double>((data) => data['totalRechargeAmount'], columnIndex, ascending)),
        DataColumn(label: Text('Total Payment amount'), onSort: (columnIndex, ascending) => _sort<double>((data) => data['totalPaymentAmount'], columnIndex, ascending)),
        DataColumn(label: Text('Total Due amount'), onSort: (columnIndex, ascending) => _sort<double>((data) => data['totalDueAmount'], columnIndex, ascending)),
        DataColumn(label: Text('Total Advance amount'), onSort: (columnIndex, ascending) => _sort<double>((data) => data['totalAdvancePayment'], columnIndex, ascending)),
      ],
      rows: [
        ...customerData.asMap().entries.map((entry) {
          int index = entry.key + 1;
          var data = entry.value;
          return DataRow(cells: [
            DataCell(Text(index.toString())),
            DataCell(Text(data['custId'])),
            DataCell(Text(data['custName'])),
            DataCell(Text(data['custPhoneNumber'])),
            DataCell(Text(data['totalRechargeAmount'].toString())),
            DataCell(Text(data['totalPaymentAmount'].toString())),
            DataCell(Text(data['totalDueAmount'].toString())),
            DataCell(Text(data['totalAdvancePayment'].toString())),
          ]);
        }).toList(),
        DataRow(cells: [
          DataCell(Text('Total')),
          DataCell(Text('')),
          DataCell(Text('')),
          DataCell(Text('')),
          DataCell(Text(totalRechargeAmount.toString())),
          DataCell(Text(totalPaymentAmount.toString())),
          DataCell(Text(totalDueAmount.toString())),
          DataCell(Text(totalAdvancePayment.toString())),
        ]),
      ],
    );
  }

  Widget buildMonthlyDataGrid() {
    // List of months in order
    final List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    // Grouping customer data by months
    Map<String, List<Map<String, dynamic>>> groupedData = {};

    customerData.forEach((data) {
      data['monthlyPayments'].forEach((payment) {
        String month = payment['selectedMonth'];
        if (!groupedData.containsKey(month)) {
          groupedData[month] = [];
        }
        groupedData[month]!.add({
          'custId': data['custId'],
          'custName': data['custName'],
          'custPhoneNumber': data['custPhoneNumber'],
          'selectedMonth': payment['selectedMonth'],
          'rechargeAmount': payment['rechargeAmount'],
          'paymentAmount': payment['paymentAmount'],
          'dueAmount': payment['dueAmount'],
          'advancePayment': payment['advancePayment'],
        });
      });
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        DropdownButton<String>(
          value: selectedMonth,
          onChanged: (value) {
            setState(() {
              selectedMonth = value;
            });
          },
          items: months.map((month) {
            return DropdownMenuItem<String>(
              value: month,
              child: Text(month),
            );
          }).toList(),
        ),
        SizedBox(height: 10),
        if (selectedMonth != null && groupedData[selectedMonth] != null)
          DataTable(
            sortColumnIndex: _sortColumnIndex,
            sortAscending: _sortAscending,
            columns: [
              DataColumn(label: Text('Sl No.')),
              DataColumn(label: Text('STB NO.'), onSort: (columnIndex, ascending) => _sort<String>((data) => data['custId'], columnIndex, ascending)),
              DataColumn(label: Text('Customer Name'), onSort: (columnIndex, ascending) => _sort<String>((data) => data['custName'], columnIndex, ascending)),
              DataColumn(label: Text('Cust Ph No.'), onSort: (columnIndex, ascending) => _sort<String>((data) => data['custPhoneNumber'], columnIndex, ascending)),
              DataColumn(label: Text('Recharge amount'), onSort: (columnIndex, ascending) => _sort<double>((data) => data['rechargeAmount'], columnIndex, ascending)),
              DataColumn(label: Text('Payment amount'), onSort: (columnIndex, ascending) => _sort<double>((data) => data['paymentAmount'], columnIndex, ascending)),
              DataColumn(label: Text('Due amount'), onSort: (columnIndex, ascending) => _sort<double>((data) => data['dueAmount'], columnIndex, ascending)),
              DataColumn(label: Text('Advance amount'), onSort: (columnIndex, ascending) => _sort<double>((data) => data['advancePayment'], columnIndex, ascending)),
            ],
            rows: [
              ...groupedData[selectedMonth]!.asMap().entries.map((entry) {
                int index = entry.key + 1;
                var data = entry.value;
                return DataRow(cells: [
                  DataCell(Text(index.toString())),
                  DataCell(Text(data['custId'])),
                  DataCell(Text(data['custName'])),
                  DataCell(Text(data['custPhoneNumber'])),
                  DataCell(Text(data['rechargeAmount'].toString())),
                  DataCell(Text(data['paymentAmount'].toString())),
                  DataCell(Text(data['dueAmount'].toString())),
                  DataCell(Text(data['advancePayment'].toString())),
                ]);
              }).toList(),
            ],
          ),
      ],
    );
  }




  Widget buildDataTable() {
    return isYearly || selectedMonth == 'Today' ? buildYearlyTable() : buildMonthlyDataGrid();


  }
//6
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:Colors.teal[300],
        title: Text('Data Page'),
      ),
      backgroundColor: Colors.red[100],
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildYearDropdown(),
              buildCheckbox(),
              ElevatedButton(
                onPressed: getCustomerData,
                child: Text('Fetch Data'),
              ),
              SizedBox(height: 20),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              if (customerData.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Customers Recharged: $totalCustomers',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: buildDataTable(),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
