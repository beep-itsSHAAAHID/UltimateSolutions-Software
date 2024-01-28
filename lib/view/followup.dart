import 'package:flutter/material.dart';

class FollowUp extends StatefulWidget {
  @override
  _FollowUpState createState() => _FollowUpState();
}

class _FollowUpState extends State<FollowUp> {
  List<Map<String, String>> followUpData = [
    {
      'name': 'John Doe',
      'date': '2023-01-15',
      'reason': 'Payment Follow-Up',
      'remarks': 'Awaiting payment confirmation.',
    },
    {
      'name': 'Alice Smith',
      'date': '2023-01-18',
      'reason': 'Order Follow-Up',
      'remarks': 'Checking the status of the pending order.',
    },
    {
      'name': 'Bob Johnson',
      'date': '2023-01-20',
      'reason': 'General Follow-Up',
      'remarks': 'Discussing upcoming events and updates.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Follow-Up',
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
      body: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Date of Follow-Up')),
              DataColumn(label: Text('Reason')),
              DataColumn(label: Text('Remarks')),
            ],
            rows: followUpData.map((data) {
              return DataRow(
                cells: [
                  DataCell(Text(data['name']!)),
                  DataCell(Text(data['date']!)),
                  DataCell(Text(data['reason']!)),
                  DataCell(Text(data['remarks']!)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

