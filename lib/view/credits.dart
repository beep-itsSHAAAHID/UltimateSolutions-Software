import 'package:flutter/material.dart';

class Credits extends StatefulWidget {
  Credits({Key? key}) : super(key: key);

  @override
  _CreditsState createState() => _CreditsState();
}

class _CreditsState extends State<Credits> {
  // Sample data for the credit table
  List<Map<String, dynamic>> creditData = [
    {'customerName': 'Customer A', 'deliveryDate': '2023-12-20', 'daysDue': 15},
    {'customerName': 'Customer B', 'deliveryDate': '2023-12-15', 'daysDue': 5},
    {'customerName': 'Customer C', 'deliveryDate': '2023-12-10', 'daysDue': 25},
    // Add more demo data as needed
  ];

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
                  DataColumn(label: Text('Delivery Date')),
                  DataColumn(label: Text('Days Due')),
                ],
                rows: creditData.map<DataRow>((data) {
                  return DataRow(
                    cells: [
                      DataCell(Text(data['customerName'].toString())),
                      DataCell(Text(data['deliveryDate'].toString())),
                      DataCell(Text(data['daysDue'].toString())),
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
