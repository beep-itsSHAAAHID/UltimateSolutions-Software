import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../admindetail.dart'; // Package for the graph

class DashboardPage extends StatefulWidget {
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  void _confirmAndReject(String collection, String docId) async {
    final bool confirmReject = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Reject Document"),
          content: const Text("Are you sure you want to reject and delete this document?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Yes, Delete"),
            ),
          ],
        );
      },
    );

    if (confirmReject == true) {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Document rejected and deleted.")),
      );
    }
  }



  Stream<QuerySnapshot> getPending(String collection) {
    return FirebaseFirestore.instance
        .collection(collection)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  String getSubtitle(DocumentSnapshot doc, String collection) {
    final data = doc.data() as Map<String, dynamic>;

    if (collection == 'invoices') {
      return data['invoiceNo'] ?? 'No Invoice No';
    } else if (collection == 'delivery') {
      return data['deliveryNoteNo'] ?? 'No Delivery Note No';
    } else if (collection == 'rfq') {
      return data['quotationNo'] ?? 'No Enquiry Ref';
    } else {
      return 'No Info';
    }
  }


  void approveDocument(String collection, String docId) async {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(docId)
        .update({'status': 'approved'});
  }


  Widget buildList(String title, String collection, Color color) {
    return StreamBuilder<QuerySnapshot>(
      stream: getPending(collection),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

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
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
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
                    title: Text(
                      data['customerName'] ?? 'Unnamed Customer',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminDetailScreen(
                            collection: collection,
                            data: data,
                          ),
                        ),
                      );
                    },
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


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          buildList("Invoices","invoices", Colors.orange),


          Center(child: Text('Dashboard',
            style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600,fontSize: 40),
          )),
          SizedBox(height: 20,),

          // Header with stats (3 containers spanning full width)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard('Total Sales', '\$120,000', Colors.blue),
                _buildStatCard('Total Purchases', '\$80,000', Colors.green),
                _buildStatCard('Total Invoices', '1500', Colors.orange),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Two Graphs in the middle (side by side)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // First Graph (Line Chart)
              Expanded(
                child: Container(
                  height: 250,
                  margin: EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  padding: EdgeInsets.all(10),
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
                ),
              ),
              // Second Graph (Bar Chart)
              Expanded(
                child: Container(
                  height: 250,
                  margin: EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  padding: EdgeInsets.all(10),
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
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Bottom row with 3 containers for additional stats
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard('Customers', '2500', Colors.purple),
                _buildStatCard('Products', '320', Colors.red),
                _buildStatCard('Orders', '4300', Colors.teal),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Optional widget for more stats
         // _buildAdditionalStats(),
        ],
      ),
    );
  }

  // Build the individual stat cards
  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      width: 200,
      padding: EdgeInsets.all(16),
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
          SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
