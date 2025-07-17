import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';



class PaymentCollections extends StatefulWidget {
  const PaymentCollections({super.key});

  @override
  State<PaymentCollections> createState() => _PaymentCollectionsState();
}

class _PaymentCollectionsState extends State<PaymentCollections> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allCollections = [];
  List<Map<String, dynamic>> _filteredCollections = [];
  List<Map<String, dynamic>> _selectedItems = [];
  String _selectedCategory = 'All';
  String _currentSortOrder = 'Latest First';
  bool _isLoading = true;
  bool _selectAll = false;
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _categoryOptions = ['All', 'Cash', 'Bank Transfer'];
  final List<String> _sortOptions = ['Latest First', 'Oldest First', 'Last Week', 'Last Month', 'Last 3 Months', 'Custom Date'];

  @override
  void initState() {
    super.initState();
    _loadCollections();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterCollections();
  }
  Future<void> _exportToCustomPDF() async {
    final pdf = pw.Document();

    final headers = [
      'Invoice No.',
      'Date',
      'Customer',
      'User',
      'Payment Mode',
      'Amount',
      'Receipt'
    ];

    final data = _filteredCollections.map((collection) {
      return [
        collection['invoiceNo']?.toString() ?? '-',
        _formatDate(collection['timestamp']),
        collection['customerName']?.toString() ?? '-',
        _getEmailPrefix(collection['userEmail']),
        collection['paymentMode']?.toString() ?? '-',
        'SAR ${collection['amount']?.toString() ?? '0'}',
        collection['receipt']?.toString() ?? 'Digital',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // Header
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Collection Report',
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  )),
              pw.SizedBox(height: 6),
              pw.Text(
                'Generated on: ${DateTime.now().toLocal().toString().split(" ").first}',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
            ],
          ),

          pw.SizedBox(height: 24),

          // Summary Section
          // pw.Text('Summary',
          //     style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          // pw.SizedBox(height: 8),
          // pw.Row(
          //   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          //   children: [
          //     pw.Text('Total Collection: SAR ${_calculateTotalAmount().toStringAsFixed(2)}'),
          //     pw.Text('Net Sales: SAR ${_calculateNetSales().toStringAsFixed(2)}'),
          //     pw.Text('Cash Received: SAR ${_calculateCashReceived().toStringAsFixed(2)}'),
          //   ],
          // ),

          pw.SizedBox(height: 32),

          // Table
          pw.Text('Detailed Records',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: headers,
            data: data,
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: PdfColors.indigo),
            border: pw.TableBorder.all(color: PdfColors.grey400),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 11),
            cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          ),

          pw.SizedBox(height: 24),
          pw.Divider(color: PdfColors.grey400),
          pw.Center(
            child: pw.Text('Report generated on ${DateTime.now().toLocal().toString().split(" ").first}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("PDF exported successfully")),
    );
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();

    final headers = [
      'Invoice No.',
      'Date',
      'Customer',
      'User',
      'Payment Mode',
      'Amount',
      'Receipt'
    ];

    final data = _filteredCollections.map((collection) {
      return [
        collection['invoiceNo']?.toString() ?? '-',
        _formatDate(collection['timestamp']),
        collection['customerName']?.toString() ?? '-',
        _getEmailPrefix(collection['userEmail']),
        collection['paymentMode']?.toString() ?? '-',
        'SAR ${collection['amount']?.toString() ?? '0'}',
        collection['receipt']?.toString() ?? 'Digital',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('Payment Collections Report',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              )),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: headers,
            data: data,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(8),
            border: pw.TableBorder.all(color: PdfColors.grey400),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Generated on ${DateTime.now()}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("PDF export completed")),
    );
  }


  Future<void> _loadCollections() async {
    try {
      setState(() => _isLoading = true);

      QuerySnapshot querySnapshot = await _firestore.collection('collections').get();

      List<Map<String, dynamic>> collections = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _allCollections = collections;
        _filteredCollections = collections;
        _isLoading = false;
      });

      _sortCollections();
    } catch (e) {
      print('Error fetching collections: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterCollections() {
    setState(() {
      _filteredCollections = _allCollections.where((collection) {
        String searchQuery = _searchController.text.toLowerCase();
        bool matchesSearch = searchQuery.isEmpty ||
            collection['customerName']?.toString().toLowerCase().contains(searchQuery) == true ||
            collection['invoiceNo']?.toString().toLowerCase().contains(searchQuery) == true ||
            collection['userEmail']?.toString().toLowerCase().contains(searchQuery) == true;

        bool matchesCategory = _selectedCategory == 'All' ||
            collection['paymentMode']?.toString() == _selectedCategory;

        bool matchesDateRange = _matchesDateRange(collection['timestamp']);

        return matchesSearch && matchesCategory && matchesDateRange;
      }).toList();
    });
    _sortCollections();
  }

  bool _matchesDateRange(dynamic timestamp) {
    DateTime collectionDate = _parseTimestamp(timestamp);

    if (_currentSortOrder == 'Custom Date' && _startDate != null && _endDate != null) {
      return collectionDate.isAfter(_startDate!) && collectionDate.isBefore(_endDate!);
    }

    if (_currentSortOrder == 'Last Week') {
      DateTime lastWeek = DateTime.now().subtract(Duration(days: 7));
      return collectionDate.isAfter(lastWeek);
    } else if (_currentSortOrder == 'Last Month') {
      DateTime lastMonth = DateTime.now().subtract(Duration(days: 30));
      return collectionDate.isAfter(lastMonth);
    } else if (_currentSortOrder == 'Last 3 Months') {
      DateTime lastThreeMonths = DateTime.now().subtract(Duration(days: 90));
      return collectionDate.isAfter(lastThreeMonths);
    }

    return true;
  }

  void _sortCollections() {
    setState(() {
      _filteredCollections.sort((a, b) {
        DateTime dateA = _parseTimestamp(a['timestamp']);
        DateTime dateB = _parseTimestamp(b['timestamp']);

        if (_currentSortOrder == 'Latest First') {
          return dateB.compareTo(dateA);
        } else if (_currentSortOrder == 'Oldest First') {
          return dateA.compareTo(dateB);
        }
        return 0;
      });

    });
  }


  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  double _calculateTotalAmount() {
    double total = 0.0;
    for (var collection in _filteredCollections) {
      if (collection['amount'] != null) {
        total += collection['amount'] as double;
      }
    }
    return total;
  }

  double _calculateNetSales() {
    // Assuming net sales is the same as total collection for now
    // You can modify this logic based on your business requirements
    return _calculateTotalAmount();
  }

  double _calculateCashReceived() {
    double cashTotal = 0.0;
    for (var collection in _filteredCollections) {
      if (collection['paymentMode'] == 'Cash' && collection['amount'] != null) {
        cashTotal += collection['amount'] as double;
      }
    }
    return cashTotal;
  }


  Map<String, double> _getPaymentModeBreakdown() {
    Map<String, double> breakdown = {};
    for (var collection in _filteredCollections) {
      String paymentMode = collection['paymentMode']?.toString() ?? 'Unknown';
      double amount = collection['amount'] as double? ?? 0.0;
      breakdown[paymentMode] = (breakdown[paymentMode] ?? 0.0) + amount;
    }
    return breakdown;
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked.start != null && picked.end != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _filterCollections();
    }
  }

  Widget _buildSummaryCard(String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWideScreen = screenWidth > 1200;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Export Button Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Collection List',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _exportToCustomPDF,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Export PDF"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

// Summary Cards - Three cards in a row
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Collection',
                    'SAR ${_calculateTotalAmount().toStringAsFixed(0)}',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Net Sales',
                    'SAR0',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Received by Cash',
                    'SAR 0',
                    Colors.orange,
                  ),
                ),
              ],
            ),



            const SizedBox(height: 32),

            // Filters Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search and Category Filter
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search for category, name, company, etc',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          items: _categoryOptions.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                            _filterCollections();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Sort Options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sort by Date: ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      DropdownButton<String>(
                        value: _currentSortOrder,
                        onChanged: (String? newValue) {
                          setState(() {
                            _currentSortOrder = newValue!;
                          });
                          if (_currentSortOrder == 'Custom Date') {
                            _selectDateRange();
                          } else {
                            _filterCollections();
                          }
                        },
                        items: _sortOptions.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),




            const SizedBox(height: 24),

            // Recent Collections Table
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Recent Collections',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 48, // Full width minus padding
                      child: DataTable(
                        headingRowHeight: 56,
                        dataRowHeight: 64,
                        headingRowColor: MaterialStateColor.resolveWith(
                              (states) => const Color(0xFFF8F9FA),
                        ),
                        headingTextStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                          letterSpacing: 0.3,
                        ),
                        dataTextStyle: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w400,
                        ),
                        columnSpacing: 24,
                        horizontalMargin: 20,
                        columns: const [
                          DataColumn(
                            label: Text('Invoice No.'),
                          ),
                          DataColumn(
                            label: Text('Date'),
                          ),
                          DataColumn(
                            label: Text('Customer'),
                          ),
                          DataColumn(
                            label: Text('User'),
                          ),
                          DataColumn(
                            label: Text('Payment mode'),
                          ),
                          DataColumn(
                            label: Text('Amount'),
                          ),
                          DataColumn(
                            label: Text('Receipt'),
                          ),
                        ],
                        rows: _filteredCollections.asMap().entries.map((entry) {
                          int index = entry.key;
                          Map<String, dynamic> collection = entry.value;

                          return DataRow(
                            color: MaterialStateColor.resolveWith(
                                  (states) => index % 2 == 0
                                  ? Colors.white
                                  : const Color(0xFFFAFAFA),
                            ),
                            cells: [
                              DataCell(
                                Text(
                                  collection['invoiceNo']?.toString() ?? '-',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  _formatDate(collection['timestamp']),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  collection['customerName']?.toString() ?? '-',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  _getEmailPrefix(collection['userEmail']),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  collection['paymentMode']?.toString() ?? '-',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  'SAR ${collection['amount']?.toString() ?? '0'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  collection['receipt']?.toString() ?? 'Digital',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    DateTime dateTime = _parseTimestamp(timestamp);
    return '${dateTime.day.toString().padLeft(2, '0')} ${_getMonthName(dateTime.month)} ${dateTime.year}';
  }

  String _getEmailPrefix(String? email) {
    if (email != null && email.contains('@')) {
      return email.split('@')[0];
    }
    return email ?? '-';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}