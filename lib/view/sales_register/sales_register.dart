import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gsheets/gsheets.dart';
import 'package:intl/intl.dart';

class SalesRegisterPage extends StatefulWidget {
  @override
  _SalesRegisterPageState createState() => _SalesRegisterPageState();
}

class _SalesRegisterPageState extends State<SalesRegisterPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  GSheets? gsheets;
  Spreadsheet? _spreadsheet;

  final _credentials = {
    "type": "service_account",
    "project_id": "ultimate-ba724",
    "private_key_id": "4bb7f7d640d344f25ce95cadfe53cd87e536d320",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDrURUC3PNtisGd\n3i89SRr19FSyaJE3PqJv4DURiecdxB15LmcU4o5dtszmpQbC7lnEQA1uyFSRMBbo\nYqjK4XyPf/fjwWoS/r9MGy3WXF06lcajO+BpsvNIpkXoLPFBM7jlwGvN99I6+X6t\nmL93Isa6tWjEVVOyiQBQvhxL9IMMozDhPTDe9dExU31crBzHSPyxluGujfI4trH8\nh/yb7cO7wFMCkNUUqLGf7yrZDi5sLCp+BWTCPd0cbChfuFKnIJ5fMMVKtPMTWqmU\naQ9EGZBw+g+DoWoAto58mvDPr0kKAkmWhDWjnbuH771HAXgA7w+irXBfKf7ngVv2\nFbwFTzmTAgMBAAECggEAFwzn5aeRF3+KZxVsQ9uVDtddMztiUNVg11v7YXlvBeUV\nDK7KnYAdI/mTvrAW+8yZ8csNxcv32gpU5B9DRi7/ouridGaY0RLagvD9SiHdZq9k\njXmAX7o4xzq1CauFV7a3pkHKuEVN9vBDmWunWFs0DkwA3uKLgqdAPFMzCw8A20wy\nQUGUFXvWbJOdTv3p3iv6G2BUVMYwKE4Xckfa1N1R0mTEUMzg+uLYnaNv+ckPy+4K\nKTG8I67hVUkH41gDBqRSfHSET/dkiHncdWsQ1KvI5uLoFTTVwmb0bY+D5vfmgtFW\nh2wTXBOpMMJtpwhNkIK+dxkec405n0GWxEFGoyXUuQKBgQD5YI36rvgZi6nYpx7/\n45x7UJ4jbsV8m0lJ10lZMnho8NJEaUEZygyyiEjXrtFAHiErZmBTxQ2IsW1uysaf\n2DLK3HXn2HoOjLfD4nnqHX6pv/sZY5WbmJo4iQytKSyscXg+xqcIp/+m1J8584Qy\n8W8uHtat9iFernPqw70XqK/OxwKBgQDxkO86X0Mlz+DJA2xMnohTTmXfcxx4fjhQ\nMN0UjjTEA6AfGUwLiMWfLlnlKSjqb+RkNldfLAtFCC1thUNTgG+wTshki4mT2+sh\nl9jAKjxomUNhC6HTnwUiQ1AaekRzQRFAvGExLV7WfPajrMo/1KsAsTI3ZbXOhyn+\nV67jUyBi1QKBgQDJsuXDH2e9ya+7cxhooaE8QC1XvU1wBm1VkxJZWa/4OOfouzUT\ndc+lSwOXp2bJtFThtHEu8A+NQuyfEtVqDcSvPXcD6Zx3TiuH/RLcX7TF+WhP1bL4\n4YnDNl4RZF8krrYyGBybrL3jItASYDrJtWtWY00B8TR2TyWkeWLk0uQ3mwKBgCC7\nMq8GGWMWN68E97eqA27GQKd2QXVSJO84r7wJSL0GgLu2AcfOUHixHx0d5p1da+To\nOA59OUmxQfaFCApYbMnG4wA8p/eQ5Ns4Z/Yhwu2pVqffm53A/kEWPdRYnM3BE0Vi\nQQkYzLDjXcfvsbfUaRc+6z72WRwS1G3SE7BZoxnBAoGBAONJvjZOkcmU0585uaFc\n9Vlod9WVHkwvmBPprjDLmlqI0frihvo0RxSo7vQqLhh6mFog6y5yImsY0VrDLWJu\npuoPdcinXFANxRLO2DBAj3SrDPMHFwYBldFqZOQm4qgDO7hODIop/H1NqE50XOPS\n40szid7VjYmNmSqo8BMYD9Lc\n-----END PRIVATE KEY-----\n",
    "client_email": "shahidsservices-913@ultimate-ba724.iam.gserviceaccount.com",
    "client_id": "101185272529500843022",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/shahidsservices-913%40ultimate-ba724.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com"
  };

  @override
  void initState() {
    super.initState();
    gsheets = GSheets(_credentials);
    init();
  }

  Future<void> init() async {
    const spreadsheetId = '1jdkTt_u6ECcEGs_yydRWnCNEKP6NY-UKVJTO2Mn7cNE';
    _spreadsheet = await gsheets!.spreadsheet(spreadsheetId);
    print('Spreadsheet initialized successfully');
  }

  Future<Worksheet> getOrCreateWorksheet() async {
    if (_spreadsheet == null) {
      await init();
    }

    var worksheet = _spreadsheet!.worksheetByTitle('SalesRegister');
    if (worksheet == null) {
      worksheet = await _spreadsheet!.addWorksheet('SalesRegister');
      await worksheet.values.insertRow(1, [
        'Date',
        'Invoice No',
        'Payment Type',
        'VAT No',
        'Customer Name',
        'Gross Amount'
        'VAT Total',
        'Net Amount'
      ]);
    }
    return worksheet;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sales Register'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDateTile('Start Date', _startDate, (pickedDate) {
                      setState(() {
                        _startDate = pickedDate;
                      });
                    }),
                    SizedBox(height: 10),
                    _buildDateTile('End Date', _endDate, (pickedDate) {
                      setState(() {
                        _endDate = pickedDate;
                      });
                    }),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (_startDate != null && _endDate != null) {
                  _generateSalesReport(_startDate!, _endDate!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select both start and end dates')),
                  );
                }
              },
              child: Text('Generate Report'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTile(String title, DateTime? date, ValueChanged<DateTime> onDatePicked) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 10),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        date == null ? 'Select Date' : DateFormat('yyyy-MM-dd').format(date),
        style: TextStyle(fontSize: 16, color: Colors.black54),
      ),
      trailing: Icon(Icons.calendar_today, color: Colors.blueAccent),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        if (pickedDate != null) {
          onDatePicked(pickedDate);
        }
      },
    );
  }

  Future<void> _generateSalesReport(DateTime startDate, DateTime endDate) async {
    QuerySnapshot salesSnapshot = await FirebaseFirestore.instance
        .collection('invoices')
        .where('invoiceDate', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(startDate))
        .where('invoiceDate', isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(endDate))
        .get();

    List<List<dynamic>> salesData = [];

    for (var doc in salesSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      salesData.add([
        data['invoiceDate'] ?? '',
        data['invoiceNo'] ?? '',
        data['modeOfPayment'] ?? '',
        data['vatNo'] ?? '',
        data['customerName'] ?? '',
        data['totalWithoutVat'] ?? '',
        (double.tryParse(data['totalWithoutVat']?.toString() ?? '0')! * 0.15).toStringAsFixed(2),
        data['netAmount']?.toString() ?? ''
      ]);
    }

    await _appendSalesDataToSheet(salesData);
  }

  Future<void> _appendSalesDataToSheet(List<List<dynamic>> salesData) async {
    final worksheet = await getOrCreateWorksheet();
    for (var row in salesData) {
      await worksheet.values.appendRow(row);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sales data added to Google Sheet successfully')),
    );
  }
}
