import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RevenuePage extends StatefulWidget {
  @override
  _RevenuePageState createState() => _RevenuePageState();
}

class _RevenuePageState extends State<RevenuePage> {
  String? selectedYear;
  String? errorMessage;
  User? currentUser;

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

  Map<String, Map<String, double>> monthlyData = {};

  double totalRechargeAmount = 0.0;
  double totalPaymentAmount = 0.0;
  double totalDueAmount = 0.0;
  double totalAdvanceAmount = 0.0;

  @override
  void initState() {
    super.initState();
    monthlyData = {
      for (String month in monthOrder.keys)
        month: {
          'rechargeAmount': 0.0,
          'paymentAmount': 0.0,
          'dueAmount': 0.0,
          'advanceAmount': 0.0,
        }
    };
    currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> calculateYearlyAmounts() async {
    if (selectedYear == null) {
      setState(() {
        errorMessage = 'Please select a year.';
      });
      return;
    }

    if (currentUser == null) {
      setState(() {
        errorMessage = 'User not logged in.';
      });
      return;
    }

    try {
      for (String month in monthOrder.keys) {
        QuerySnapshot paymentSnapshot = await FirebaseFirestore.instance
            .collection('payments')
            .where('selectedYear', isEqualTo: selectedYear)
            .where('selectedMonth', isEqualTo: month)
            .where('userId', isEqualTo: currentUser!.uid) // Filter by userId
            .get();

        double rechargeAmount = 0.0;
        double paymentAmount = 0.0;
        double dueAmount = 0.0;
        double advanceAmount = 0.0;

        for (var doc in paymentSnapshot.docs) {
          rechargeAmount += (doc['rechargeAmount'] ?? 0).toDouble();
          paymentAmount += (doc['paymentAmount'] ?? 0).toDouble();
          dueAmount += (doc['dueAmount'] ?? 0).toDouble();
          advanceAmount += (doc['advancePayment'] ?? 0).toDouble();
        }

        print('Month: $month, Recharge Amount: $rechargeAmount, Payment Amount: $paymentAmount, Due Amount: $dueAmount, Advance Amount: $advanceAmount');

        setState(() {
          monthlyData[month] = {
            'rechargeAmount': rechargeAmount,
            'paymentAmount': paymentAmount,
            'dueAmount': dueAmount,
            'advanceAmount': advanceAmount,
          };
        });
      }

      setState(() {
        totalRechargeAmount = monthlyData.values.fold(0, (sum, data) => sum + (data['rechargeAmount'] ?? 0));
        totalPaymentAmount = monthlyData.values.fold(0, (sum, data) => sum + (data['paymentAmount'] ?? 0));
        totalDueAmount = monthlyData.values.fold(0, (sum, data) => sum + (data['dueAmount'] ?? 0));
        totalAdvanceAmount = monthlyData.values.fold(0, (sum, data) => sum + (data['advanceAmount'] ?? 0));
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred while calculating the amounts.';
      });
    }
  }

  Widget buildMonthlyTable() {
    String adjustedTotalAmountText;
    String adjustedTotalTextBox;

    if (totalDueAmount > totalAdvanceAmount) {
      adjustedTotalAmountText = totalDueAmount.toStringAsFixed(2);
      adjustedTotalTextBox = '(${(totalDueAmount - totalAdvanceAmount).toStringAsFixed(2)})';
    } else {
      adjustedTotalAmountText = totalAdvanceAmount.toStringAsFixed(2);
      adjustedTotalTextBox = '(${(totalAdvanceAmount - totalDueAmount).toStringAsFixed(2)})';
    }

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text('Month')),
              DataColumn(label: Text('Recharge Amount')),
              DataColumn(label: Text('Payment Amount')),
              DataColumn(label: Text('Due Amount')),
              DataColumn(label: Text('Advance Amount')),
            ],
            rows: [
              ...monthOrder.keys.map((month) {
                return DataRow(cells: [
                  DataCell(Text(month)),
                  DataCell(Text(monthlyData[month]!['rechargeAmount']?.toStringAsFixed(2) ?? '0.00')),
                  DataCell(Text(monthlyData[month]!['paymentAmount']?.toStringAsFixed(2) ?? '0.00')),
                  DataCell(Text(monthlyData[month]!['dueAmount']?.toStringAsFixed(2) ?? '0.00')),
                  DataCell(Text(monthlyData[month]!['advanceAmount']?.toStringAsFixed(2) ?? '0.00')),
                ]);
              }).toList(),
              DataRow(cells: [
                DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(totalRechargeAmount.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(totalPaymentAmount.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(
                  adjustedTotalAmountText,
                  style: TextStyle(fontWeight: FontWeight.bold),
                )),
                DataCell(Text(totalAdvanceAmount.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold))),
              ]),
            ],
          ),
        ),
        SizedBox(height: 10),
        Text(
          totalDueAmount > totalAdvanceAmount
              ? 'Total Due Amount: $adjustedTotalTextBox'
              : 'Total Advance Amount: $adjustedTotalTextBox',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:Colors.lime[200],
        title: Text('Revenue Page'),
      ),
      backgroundColor: Colors.orange[100],
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
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
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: calculateYearlyAmounts,
              child: Text('Calculate Yearly Amounts'),
            ),
            SizedBox(height: 20),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            Expanded(
              child: SingleChildScrollView(
                child: buildMonthlyTable(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
