import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Customer'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('customers').orderBy('customerCode').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          // Process the data and build the ListView
          var customerDocs = snapshot.data?.docs ?? [];
          Set<String> uniqueCustomerCodes = Set<String>();

          return ListView.builder(
            itemCount: customerDocs.length,
            itemBuilder: (context, index) {
              var customerData = customerDocs[index].data() as Map<String, dynamic>;
              String customerCode = customerData['customerCode'];

              // Skip if customer code is already added
              if (!uniqueCustomerCodes.add(customerCode)) {
                return SizedBox.shrink();
              }

              return ListTile(
                title: Text(customerData['customerName']),
                subtitle: Text('Customer Code: $customerCode'),

                onTap: () {
                  // Pass selected customer data back to the previous page
                  Navigator.pop(context, {
                    'customerCode': customerCode,
                    'customerName': customerData['customerName'],
                    'address': customerData['address'],
                    'mobileNumber': customerData['mobileNumber'],
                    'vtNumber': customerData['vtNumber'],
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}
