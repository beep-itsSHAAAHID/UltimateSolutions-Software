import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class ViewExpensesPage extends StatefulWidget {
  @override
  _ViewExpensesPageState createState() => _ViewExpensesPageState();
}

class _ViewExpensesPageState extends State<ViewExpensesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _selectedPaymentMethod = 'All';
  String _selectedDateFilter = 'All Time';
  String _searchQuery = '';
  bool _sortAscending = false;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  List<String> _userEmails = ['All']; // This will be filled from Firestore
  String _selectedUserEmail = 'All';
  final List<String> _dateFilters = ['All Time', 'Last Week', 'Last Month', 'Last 3 Months', 'Custom Range'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserEmails();
  }

  void _loadUserEmails() async {
    final snapshot = await _firestore.collection('expenses').get();
    final emailsSet = snapshot.docs.map((doc) => doc['user_email']?.toString() ?? '').toSet();
    emailsSet.removeWhere((email) => email.isEmpty);

    setState(() {
      _userEmails = ['All', ...emailsSet.toList()..sort()];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(120),
        child: _buildAppBar(),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderSection(),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildExpensesTable(),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: Color(0xFF1E40AF),
      flexibleSpace: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            "Expense Management",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.file_download_outlined, color: Colors.white, size: 20),
          ),
          onPressed: _exportExpensesToPDF,
        ),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          _buildStatsSection(),
          SizedBox(height: 20),
          _buildSearchAndFilter(),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredExpensesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildStatsPlaceholder();
        }

        final expenses = _filterExpensesByDate(snapshot.data!.docs);
        final totalAmount = expenses.fold<double>(0, (sum, doc) {
          return sum + (double.tryParse(doc['amount'].toString()) ?? 0);
        });

        final thisMonth = DateTime.now();
        final thisMonthExpenses = expenses.where((doc) {
          final timestamp = doc['timestamp'];
          DateTime date;
          if (timestamp is Timestamp) {
            date = timestamp.toDate();
          } else if (timestamp is String) {
            date = DateTime.tryParse(timestamp) ?? DateTime.now();
          } else {
            date = DateTime.now();
          }
          return date.month == thisMonth.month && date.year == thisMonth.year;
        }).length;

        final thisMonthAmount = expenses.where((doc) {
          final timestamp = doc['timestamp'];
          DateTime date;
          if (timestamp is Timestamp) {
            date = timestamp.toDate();
          } else if (timestamp is String) {
            date = DateTime.tryParse(timestamp) ?? DateTime.now();
          } else {
            date = DateTime.now();
          }
          return date.month == thisMonth.month && date.year == thisMonth.year;
        }).fold<double>(0, (sum, doc) {
          return sum + (double.tryParse(doc['amount'].toString()) ?? 0);
        });

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Amount',
                '${NumberFormat.currency(locale: 'en_US', symbol: 'SAR ', decimalDigits: 2).format(totalAmount)}',
                Icons.account_balance_wallet,
                Color(0xFF10B981),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'This Month',
                '${NumberFormat.currency(locale: 'en_US', symbol: 'SAR ', decimalDigits: 2).format(thisMonthAmount)}',
                Icons.calendar_month,
                Color(0xFF8B5CF6),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Records',
                '${expenses.length}',
                Icons.receipt_long,
                Color(0xFFF59E0B),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsPlaceholder() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Amount', 'SAR 0.00', Icons.account_balance_wallet, Color(0xFF10B981))),
        SizedBox(width: 12),
        Expanded(child: _buildStatCard('This Month', 'SAR 0.00', Icons.calendar_month, Color(0xFF8B5CF6))),
        SizedBox(width: 12),
        Expanded(child: _buildStatCard('Total Records', '0', Icons.receipt_long, Color(0xFFF59E0B))),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search expenses...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Color(0xFF1E40AF)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[500]),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedUserEmail,
                    items: _userEmails.map((email) => DropdownMenuItem(
                      value: email,
                      child: Text(email, style: TextStyle(fontSize: 14)),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUserEmail = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'User Email',
                      labelStyle: TextStyle(color: Color(0xFF1E40AF), fontSize: 12),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedDateFilter,
                    items: _dateFilters.map((filter) => DropdownMenuItem(
                      value: filter,
                      child: Text(filter, style: TextStyle(fontSize: 14)),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDateFilter = value!;
                        if (value == 'Custom Range') {
                          _showDateRangePicker();
                        }
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Date Filter',
                      labelStyle: TextStyle(color: Color(0xFF1E40AF), fontSize: 12),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF1E40AF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                    });
                  },
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (_selectedDateFilter == 'Custom Range' && _customStartDate != null && _customEndDate != null)
            Container(
              margin: EdgeInsets.only(top: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF1E40AF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF1E40AF).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.date_range, color: Color(0xFF1E40AF), size: 16),
                  SizedBox(width: 8),
                  Text(
                    '${DateFormat('MMM dd, yyyy').format(_customStartDate!)} - ${DateFormat('MMM dd, yyyy').format(_customEndDate!)}',
                    style: TextStyle(
                      color: Color(0xFF1E40AF),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _customStartDate = null;
                        _customEndDate = null;
                        _selectedDateFilter = 'All Time';
                      });
                    },
                    child: Icon(Icons.close, color: Color(0xFF1E40AF), size: 16),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpensesTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredExpensesStream(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final allExpenses = _filterExpenses(snapshot.data!.docs);
        final filteredExpenses = _filterExpensesByDate(allExpenses);

        if (filteredExpenses.isEmpty) {
          return _buildNoResultsState();
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, color: Color(0xFF1E40AF), size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Expense Records (${filteredExpenses.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: _buildResponsiveTable(filteredExpenses),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResponsiveTable(List<QueryDocumentSnapshot> expenses) {
    return DataTable(
      headingRowColor: MaterialStateProperty.all(Color(0xFFF1F5F9)),
      dataRowColor: MaterialStateProperty.resolveWith((states) {
        return states.contains(MaterialState.hovered)
            ? Color(0xFFF8FAFC)
            : Colors.white;
      }),
      border: TableBorder(
        horizontalInside: BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      headingTextStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E293B),
        fontSize: 14,
      ),
      dataTextStyle: TextStyle(
        color: Color(0xFF475569),
        fontSize: 13,
      ),
      columnSpacing: 20,
      headingRowHeight: 56,
      dataRowHeight: 72,
      columns: [
        DataColumn(
          label: Expanded(
            child: Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Color(0xFFF59E0B)),
                SizedBox(width: 4),
                Text('Date & Time'),
              ],
            ),
          ),
        ),
        DataColumn(
          label: Expanded(
            child: Row(
              children: [
                Icon(Icons.person, size: 16, color: Color(0xFF06B6D)),
                SizedBox(width: 4),
                Text('User'),
              ],
            ),
          ),
        ),
        DataColumn(
          label: Expanded(
            child: Row(
              children: [
                Icon(Icons.category, size: 16, color: Color(0xFFEF4444)),
                SizedBox(width: 4),
                Text('Type'),
              ],
            ),
          ),
        ),
        DataColumn(
          label: Expanded(
            child: Row(
              children: [
                Icon(Icons.description, size: 16, color: Color(0xFF3B82F6)),
                SizedBox(width: 4),
                Text('Details'),
              ],
            ),
          ),
        ),
        DataColumn(
          label: Expanded(
            child: Row(
              children: [
                Icon(Icons.note, size: 16, color: Color(0xFF8B5CF6)),
                SizedBox(width: 4),
                Text('Remarks'),
              ],
            ),
          ),
        ),
        DataColumn(
          label: Expanded(
            child: Row(
              children: [
                Icon(Icons.payments, size: 16, color: Color(0xFF10B981)),
                SizedBox(width: 4),
                Text('Amount'),
              ],
            ),
          ),
        ),
      ],
      rows: expenses.map<DataRow>((expense) {
        final amount = double.tryParse(expense['amount'].toString()) ?? 0;
        final timestamp = expense['timestamp'] as Timestamp;
        final date = timestamp.toDate();

        return DataRow(
          cells: [
            DataCell(
              Container(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMM dd, yyyy').format(date),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      DateFormat('hh:mm a').format(date),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DataCell(
              Container(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense['user_name'] ?? 'Unknown',
                      style: TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      expense['user_email'] ?? 'Unknown',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            DataCell(
              Container(
                width: double.infinity,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTypeColor(expense['type'] ?? 'N/A').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    expense['type'] ?? 'N/A',
                    style: TextStyle(
                      color: _getTypeColor(expense['type'] ?? 'N/A'),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            DataCell(
              Container(
                width: double.infinity,
                child: Text(
                  expense['carChargeDetails'] ?? 'No details',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ),
            DataCell(
              Container(
                width: 200,
                child: Text(
                  expense['remarks'] ?? 'No remarks',
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
            DataCell(
              Container(
                width: double.infinity,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    NumberFormat.currency(locale: 'en_US', symbol: 'SAR ', decimalDigits: 2).format(amount),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Stream<QuerySnapshot> _getFilteredExpensesStream() {
    return _firestore
        .collection('expenses')
        .orderBy('user_email', descending: !_sortAscending)
        .snapshots();
  }

  List<QueryDocumentSnapshot> _filterExpensesByDate(List<QueryDocumentSnapshot> docs) {
    if (_selectedDateFilter == 'All Time') return docs;

    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate = now;

    switch (_selectedDateFilter) {
      case 'Last Week':
        startDate = now.subtract(Duration(days: 7));
        break;
      case 'Last Month':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'Last 3 Months':
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case 'Custom Range':
        if (_customStartDate != null && _customEndDate != null) {
          startDate = _customStartDate!;
          endDate = _customEndDate!.add(Duration(hours: 23, minutes: 59, seconds: 59));
        } else {
          return docs;
        }
        break;
      default:
        return docs;
    }

    return docs.where((doc) {
      final timestamp = doc['timestamp'];
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is String) {
        date = DateTime.tryParse(timestamp) ?? DateTime.now();
      } else {
        date = DateTime.now();
      }

      if (startDate != null && date.isBefore(startDate)) return false;
      if (endDate != null && date.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF1E40AF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    } else {
      setState(() {
        _selectedDateFilter = 'All Time';
      });
    }
  }

  Future<void> _exportExpensesToPDF() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating PDF...'),
            ],
          ),
        ),
      );

      final snapshot = await _firestore
          .collection('expenses')
          .orderBy('user_email', descending: !_sortAscending)
          .get();

      final allExpenses = _filterExpenses(snapshot.docs);
      final filteredExpenses = _filterExpensesByDate(allExpenses);

      final pdf = pw.Document();

      final totalAmount = filteredExpenses.fold<double>(0, (sum, doc) {
        return sum + (double.tryParse(doc['amount'].toString()) ?? 0);
      });

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Container(
                  padding: pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue900,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Expense Report',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Generated on: ${DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.now())}',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                        ),
                      ),
                      pw.Text(
                        'Filter: $_selectedDateFilter',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Total Records:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('${filteredExpenses.length}', style: pw.TextStyle(fontSize: 16)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Total Amount:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                          NumberFormat.currency(locale: 'en_US', symbol: 'SAR ', decimalDigits: 2).format(totalAmount),
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(2.5),
                  2: pw.FlexColumnWidth(1.5),
                  3: pw.FlexColumnWidth(2.5),
                  4: pw.FlexColumnWidth(2.5),
                  5: pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('User', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Details', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Remarks', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...filteredExpenses.map((expense) {
                    final amount = double.tryParse(expense['amount'].toString()) ?? 0;
                    final timestamp = expense['timestamp'] as Timestamp;
                    final date = timestamp.toDate();

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(DateFormat('MMM dd, yyyy\nhh:mm a').format(date)),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(expense['user_email'] ?? 'Unknown'),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(expense['type'] ?? 'N/A'),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(expense['carChargeDetails'] ?? 'No details'),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(expense['remarks'] ?? 'No remarks'),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            NumberFormat.currency(locale: 'en_US', symbol: 'SAR ', decimalDigits: 2).format(amount),
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ];
          },
        ),
      );

      Navigator.pop(context);

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'expense_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Error generating PDF: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return Color(0xFF10B981);
      case 'card':
        return Color(0xFF3B82F6);
      case 'upi':
        return Color(0xFF8B5CF6);
      case 'bank transfer':
        return Color(0xFF06B6D4);
      default:
        return Color(0xFF6B7280);
    }
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF1E40AF),
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Loading expenses...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No expenses found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add your first expense to get started',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 48,
                color: Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No expenses match your search',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedUserEmail = 'All';
                  _selectedDateFilter = 'All Time';
                  _customStartDate = null;
                  _customEndDate = null;
                });
              },
              icon: Icon(Icons.clear_all),
              label: Text('Clear All Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E40AF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1E40AF).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  List<QueryDocumentSnapshot> _filterExpenses(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      if (_searchQuery.isNotEmpty) {
        final docNo = doc.id.toLowerCase();
        final enteredBy = (doc['user_name'] ?? doc['user_email'] ?? '').toString().toLowerCase();
        final details = (doc['carChargeDetails'] ?? doc['remarks'] ?? '').toString().toLowerCase();

        if (!docNo.contains(_searchQuery) &&
            !enteredBy.contains(_searchQuery) &&
            !details.contains(_searchQuery)) {
          return false;
        }
      }

      if (_selectedUserEmail != 'All' && doc['user_email'] != _selectedUserEmail) {
        return false;
      }

      return true;
    }).toList();
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.add_circle, color: Color(0xFF1E40AF)),
            SizedBox(width: 8),
            Text('Add New Expense'),
          ],
        ),
        content: Text('Add expense form would be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Add Expense'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}