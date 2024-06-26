import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Credits extends StatefulWidget {
  Credits({Key? key}) : super(key: key);

  @override
  _CreditsState createState() => _CreditsState();
}

class _CreditsState extends State<Credits> {
  // Sample data for the credit table
  List<Map<String, dynamic>> creditData = [];

  @override
  void initState() {
    super.initState();
    _fetchCreditInvoices();
  }

  Future<void> _fetchCreditInvoices() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('invoices')
          .where('modeOfPayment', isEqualTo: 'Credit')
          .get();

      setState(() {
        creditData = querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'customerName': data['customerName'],
            'deliveryDate': data['invoiceDate'],
            'daysDue': _calculateDaysDue(data['invoiceDate']),
            'modeOfPayment': data['modeOfPayment'],
            'invoiceDate' : data['invoiceDate'],
            'invoiceNo' : data['invoiceNo'],
            'netAmount' : data['netAmount'],
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching credit invoices: $e');
    }
  }

  int _calculateDaysDue(String deliveryDate) {
    DateTime date = DateTime.parse(deliveryDate);
    return DateTime.now().difference(date).inDays;
  }

  Future<void> _updatePaymentStatus(String id) async {
    try {
      await FirebaseFirestore.instance.collection('invoices').doc(id).update({
        'modeOfPayment': 'Paid',
      });
      // Refresh the list after updating
      _fetchCreditInvoices();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment status updated to Paid'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating payment status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update payment status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: AppBar(
          title: Text(
            "Credits",
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 30),
          ),
          centerTitle: true,
          backgroundColor: Color(0xff0C88BD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(40),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Credit Table',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Customer Name')),
                  DataColumn(label: Text('Invoice Date')),
                  DataColumn(label: Text('Invoice N0.')),
                  DataColumn(label: Text('Invoice Amount.')),
                  DataColumn(label: Text('Days Due')),
                  DataColumn(label: Text('Action')),
                ],
                rows: creditData.map<DataRow>((data) {
                  return DataRow(
                    cells: [
                      DataCell(Text(data['customerName'].toString())),
                      DataCell(Text(data['invoiceDate'].toString())),
                      DataCell(Text(data['invoiceNo'].toString())),
                      DataCell(Text(data['netAmount'].toString())),
                      DataCell(Text(data['daysDue'].toString())),
                      DataCell(
                        ElevatedButton(
                          onPressed: () => _updatePaymentStatus(data['id']),
                          child: Text('Mark as Paid'),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
