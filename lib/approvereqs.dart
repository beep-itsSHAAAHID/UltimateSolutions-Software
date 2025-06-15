import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:translator/translator.dart';

import 'admindetail.dart';

class AdminPendingScreen extends StatefulWidget {
  const AdminPendingScreen({super.key});

  @override
  State<AdminPendingScreen> createState() => _AdminPendingScreenState();
}

class _AdminPendingScreenState extends State<AdminPendingScreen> {

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

  void approveDocument(String collection, String docId) async {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(docId)
        .update({'status': 'approved'});
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
            child: Text('$title (None)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey)),
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

  Widget buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }





  // Future<void> updateCustomersWithInvoiceData() async {
  //   // Get all the invoices
  //   try {
  //     print("Fetching all invoices...");
  //     QuerySnapshot invoicesSnapshot = await FirebaseFirestore.instance
  //         .collection('invoices')
  //         .get();
  //
  //     print("Invoices fetched. Total invoices: ${invoicesSnapshot.docs.length}");
  //
  //     for (var invoiceDoc in invoicesSnapshot.docs) {
  //       print("Processing invoice ID: ${invoiceDoc.id}");
  //
  //       // Get invoice data
  //       var invoiceData = invoiceDoc.data() as Map<String, dynamic>;
  //       var customerName = invoiceData['customerName'];  // Use customerName instead of customerCode
  //
  //       // Fetch the customer using the customerName field
  //       print("Fetching customer with customerName: $customerName");
  //       QuerySnapshot customerSnapshot = await FirebaseFirestore.instance
  //           .collection('customers')
  //           .where('customerName', isEqualTo: customerName) // Query by customerName
  //           .get();
  //
  //       // If customer exists, check for missing data and update
  //       if (customerSnapshot.docs.isNotEmpty) {
  //         var customerDoc = customerSnapshot.docs.first;
  //         print("Customer found: ${customerDoc.id}");
  //
  //         var customerData = customerDoc.data() as Map<String, dynamic>;
  //
  //         // Check if the arabicName is missing and update it
  //         if (customerData['arabicName'] == null && invoiceData['arabicName'] != null) {
  //           print("arabicName missing in customer. Updating with value: ${invoiceData['arabicName']}");
  //           await customerDoc.reference.update({
  //             'arabicName': invoiceData['arabicName'],
  //           });
  //         } else {
  //           print("arabicName is already present in customer.");
  //         }
  //
  //         // Check if vatNo is missing and update it
  //         if (customerData['vtNumber'] == null && invoiceData['vatNo'] != null) {
  //           print("vatNo missing in customer. Updating with value: ${invoiceData['vatNo']}");
  //           await customerDoc.reference.update({
  //             'vtNumber': invoiceData['vatNo'],
  //           });
  //         } else {
  //           print("vatNo is already present in customer.");
  //         }
  //
  //         // You can add more fields to check and update here, as needed
  //         // Example for email field (optional):
  //         // if (customerData['email'] == null && invoiceData['email'] != null) {
  //         //   print("email missing in customer. Updating with value: ${invoiceData['email']}");
  //         //   await customerDoc.reference.update({'email': invoiceData['email']});
  //         // }
  //
  //       } else {
  //         print("Customer not found for customerName: $customerName");
  //       }
  //     }
  //
  //     print("Customer data update process completed.");
  //
  //   } catch (e) {
  //     print("Error occurred while updating customer data: $e");
  //   }
  // }


  @override
  void initState() {
    // TODO: implement initState

   // updateCustomersWithInvoiceData();

    // final translator = GoogleTranslator();
    //
    // final input = "how r u";
    //
    // translator.translate(input, from: 'en', to: 'ar').then(print);
    // prints Hello. Are you okay?

   // var translation =  translator.translate("Dart is very cool!", to: 'pl');
   // print(translation);
    // prints Dart jest bardzo fajny!


    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Pending Approvals",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        //backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSectionHeader("Pending Invoices", Colors.orange),
            const SizedBox(height: 8),
            buildList("Invoices","invoices", Colors.orange),
            const SizedBox(height: 24),
            buildSectionHeader("Pending Deliveries", Colors.blue),
            const SizedBox(height: 8),
            buildList("Delivery Notes","delivery", Colors.blue),
            const SizedBox(height: 24),
            buildSectionHeader("Pending RFQs", Colors.purple),
            const SizedBox(height: 8),
            buildList("Quotation Requests","rfq", Colors.purple),
          ],
        ),
      ),
    );
  }
}
