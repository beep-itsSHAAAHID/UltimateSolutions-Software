import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../admindetail.dart';

class DashboardPage extends StatefulWidget {
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double totalSales = 0;
  double totalPurchases = 0;
  int invoiceCount = 0;
  int customerCount = 0;
  int productCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    double sales = 0;
    double purchases = 0;

    final invoiceSnapshot = await FirebaseFirestore.instance.collection('invoices').get();
    invoiceCount = invoiceSnapshot.docs.length;

    for (var doc in invoiceSnapshot.docs) {
      final val = double.tryParse(doc.data()['netAmount']?.toString() ?? '0') ?? 0;
      sales += val;
    }

    final purchaseSnapshot = await FirebaseFirestore.instance.collection('purchase').get();
    for (var doc in purchaseSnapshot.docs) {
      final val = double.tryParse(doc.data()['priceAfterVAT']?.toString() ?? '0') ?? 0;
      purchases += val;
    }

    final customerSnapshot = await FirebaseFirestore.instance.collection('customers').get();
    customerCount = customerSnapshot.docs.length;

    final productSnapshot = await FirebaseFirestore.instance.collection('products').get();
    productCount = productSnapshot.docs.length;

    setState(() {
      totalSales = sales;
      totalPurchases = purchases;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildList("Invoice Requests", "invoices", Colors.orange),
              buildList("Delivery Note Requests","delivery", Colors.blue),
              buildList("Quotation Requests","rfq", Colors.purple),



              Center(
                child: Text(
                  'Dashboard',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 28 : 40,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Stats
              Center(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildStatCard('Total Sales', 'SAR ${totalSales.toStringAsFixed(2)}', Colors.blue, isMobile),
                    _buildStatCard('Total Purchases', 'SAR ${totalPurchases.toStringAsFixed(2)}', Colors.green, isMobile),
                    _buildStatCard('Total Invoices', invoiceCount.toString(), Colors.orange, isMobile),
                    _buildStatCard('Customers', customerCount.toString(), Colors.purple, isMobile),
                   // _buildStatCard('Products', productCount.toString(), Colors.red, isMobile),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Graphs
              isMobile
                  ? Column(
                children: [
                  _buildLineChart(),
                  const SizedBox(height: 16),
                  _buildBarChart(),
                ],
              )
                  : Row(
                children: [
                  Expanded(child: _buildLineChart()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildBarChart()),
                ],
              ),

              const SizedBox(height: 20),

              // Bottom Stats
              // Wrap(
              //   spacing: 16,
              //   runSpacing: 16,
              //   children: [
              //     _buildStatCard('Customers', customerCount.toString(), Colors.purple, isMobile),
              //     _buildStatCard('Products', productCount.toString(), Colors.red, isMobile),
              //   ],
              // ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      padding: const EdgeInsets.all(10),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(show: true),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.black12)),
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: 200,
          lineBarsData: [
            LineChartBarData(
              spots: [
                FlSpot(0, 30),
                FlSpot(1, 80),
                FlSpot(2, 60),
                FlSpot(3, 130),
                FlSpot(4, 100),
                FlSpot(5, 180),
              ],
              isCurved: true,
              color: Colors.blue,
              barWidth: 4,
              isStrokeCapRound: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      padding: const EdgeInsets.all(10),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(show: true),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.black12)),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: Colors.blue)]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 6, color: Colors.green)]),
            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 7, color: Colors.red)]),
            BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 10, color: Colors.orange)]),
            BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 5, color: Colors.purple)]),
          ],
        ),
      ),
    );
  }

  // Stream and Approval logic remains unchanged
  Stream<QuerySnapshot> getPending(String collection) {
    return FirebaseFirestore.instance.collection(collection).where('status', isEqualTo: 'pending').snapshots();
  }

  void approveDocument(String collection, String docId) async {
    await FirebaseFirestore.instance.collection(collection).doc(docId).update({'status': 'approved'});
  }

  void _confirmAndReject(String collection, String docId) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reject Document"),
        content: const Text("Are you sure you want to reject and delete this document?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, Delete")),
        ],
      ),
    );
    if (confirm) {
      await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Document deleted.")));
    }
  }

  String getSubtitle(DocumentSnapshot doc, String collection) {
    final data = doc.data() as Map<String, dynamic>;
    if (collection == 'invoices') return data['invoiceNo'] ?? 'No Invoice No';
    if (collection == 'delivery') return data['deliveryNoteNo'] ?? 'No Delivery Note No';
    if (collection == 'rfq') return data['quotationNo'] ?? 'No Enquiry Ref';
    return 'No Info';
  }

  Widget buildList(String title, String collection, Color color) {
    return StreamBuilder<QuerySnapshot>(
      stream: getPending(collection),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text('No new requests', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey)),
          );
        }

        final docs = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;

                return Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    title: Text(data['customerName'] ?? 'Unnamed Customer',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        getSubtitle(doc, collection),
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => approveDocument(collection, doc.id),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text("Approve"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _confirmAndReject(collection, doc.id),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text("Reject"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => AdminDetailScreen(collection: collection, data: data),
                    )),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        );
      },
    );
  }
}
