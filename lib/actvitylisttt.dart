import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ActivityDetailPage extends StatefulWidget {
  final String userEmail;
  const ActivityDetailPage({super.key, required this.userEmail});

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  String _sortOrder = 'newest'; // 'newest', 'oldest', or 'last 7 days'

  Future<void> _exportToPdf(List<DocumentSnapshot> docs) async {
    final pdf = pw.Document();

    // Prepare data for PDF with same sorting as table
    final List<List<String>> tableData = [];
    tableData.add(['Activity Type', 'Customer', 'Location', 'Visit Type', 'Date & Time']);

    // The docs are already sorted according to _sortOrder from the Firestore query
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final activityType = (data['activityType'] ?? '').toString().toUpperCase();
      final customer = data['customer'] ?? 'N/A';
      final location = data['location'] ?? 'N/A';
      final visitType = data['visitType'] ?? 'N/A';
      final createdAt = data['created_at']?.toDate();
      final formattedDate = createdAt != null
          ? DateFormat('MMM d, yyyy hh:mm a').format(createdAt)
          : 'Unknown Date';

      tableData.add([activityType, customer, location, visitType, formattedDate]);
    }

    final ttfArabicFont =
    pw.Font.ttf(await rootBundle.load("lib/assets/fonts/HacenTunisia.ttf"));

    // Determine sort order text for PDF
    final sortOrderText = _sortOrder == 'newest' ? 'Newest First' : (_sortOrder == 'oldest' ? 'Oldest First' : 'Last 7 Days');

    // Split data into chunks to handle multiple pages
    const int rowsPerPage = 25;
    for (int i = 0; i < tableData.length; i += rowsPerPage) {
      final pageData = tableData.skip(i).take(rowsPerPage).toList();

      // Add header row to each page except the first chunk
      if (i > 0) {
        pageData.insert(0, ['Activity Type', 'Customer', 'Location', 'Visit Type', 'Date & Time']);
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header only on first page
                if (i == 0) ...[
                  pw.Text(
                    'Activity Report - ${widget.userEmail}',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Sort Order: $sortOrderText',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.normal),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Generated on: ${DateFormat('MMM d, yyyy hh:mm a').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 16),
                ],

                // Table
                pw.Expanded(
                  child: pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2),
                      1: const pw.FlexColumnWidth(2),
                      2: const pw.FlexColumnWidth(2),
                      3: const pw.FlexColumnWidth(2),
                      4: const pw.FlexColumnWidth(2.5),
                    },
                    children: pageData.map((row) {
                      final isHeader = row == pageData.first && (i == 0 || row[0] == 'Activity Type');
                      return pw.TableRow(
                        decoration: isHeader
                            ? const pw.BoxDecoration(color: PdfColors.grey200)
                            : null,
                        children: row.map((cell) {
                          return pw.Container(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              cell,
                              style: pw.TextStyle(
                                fontSize: 9,
                                font: ttfArabicFont,
                                fontWeight: isHeader
                                    ? pw.FontWeight.bold
                                    : pw.FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),

                // Page number
                pw.Positioned(
                  bottom: 0,
                  right: 0,
                  child: pw.Text(
                    'Page ${(i ~/ rowsPerPage) + 1}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Stream<QuerySnapshot> _getActivityQuery() {
    if (_sortOrder == 'last 7 days') {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(Duration(days: 7));
      return FirebaseFirestore.instance
          .collection('dailyActivities')
          .where('user_email', isEqualTo: widget.userEmail)
          .where('created_at', isGreaterThanOrEqualTo: sevenDaysAgo)
          .orderBy('created_at', descending: true)
          .snapshots()
          .handleError((error) {
        debugPrint("Firestore stream error: $error");
      });
    } else {
      return FirebaseFirestore.instance
          .collection('dailyActivities')
          .where('user_email', isEqualTo: widget.userEmail)
          .where('created_at', isNotEqualTo: null)
          .orderBy('created_at', descending: _sortOrder == 'newest')
          .snapshots()
          .handleError((error) {
        debugPrint("Firestore stream error: $error");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userEmail),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getActivityQuery(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading activities"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("No activities found for this user"));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Controls Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Sort Filter
                    Row(
                      children: [
                        const Text('Sort by: ', style: TextStyle(fontSize: 16)),
                        DropdownButton<String>(
                          value: _sortOrder,
                          onChanged: (String? newValue) {
                            setState(() {
                              _sortOrder = newValue!;
                            });
                          },
                          items: const [
                            DropdownMenuItem(
                              value: 'newest',
                              child: Text('Newest First'),
                            ),
                            DropdownMenuItem(
                              value: 'oldest',
                              child: Text('Oldest First'),
                            ),
                            DropdownMenuItem(
                              value: 'last 7 days',
                              child: Text('Last 7 Days'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Export Button
                    ElevatedButton.icon(
                      onPressed: () => _exportToPdf(docs),
                      icon: const Icon(Icons.file_download),
                      label: const Text('Export PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Table
                Expanded(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.indigo,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Activity Type',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Customer',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Location',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Visit Type',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Date & Time',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Table Body
                        Expanded(
                          child: ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data = docs[index].data() as Map<String, dynamic>;
                              final activityType = (data['activityType'] ?? '').toString().toUpperCase();
                              final customer = data['customer'] ?? 'N/A';
                              final location = data['location'] ?? 'N/A';
                              final visitType = data['visitType'] ?? 'N/A';
                              final createdAt = data['created_at']?.toDate();
                              final formattedDate = createdAt != null
                                  ? DateFormat('MMM d, yyyy\nhh:mm a').format(createdAt)
                                  : 'Unknown Date';

                              return Container(
                                decoration: BoxDecoration(
                                  color: index % 2 == 0 ? Colors.grey[50] : Colors.white,
                                  border: const Border(
                                    bottom: BorderSide(color: Colors.grey, width: 0.5),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          activityType,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.indigo,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          customer,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          location,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          visitType,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          formattedDate,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}