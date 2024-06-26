import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerSelectionPage extends StatefulWidget {
  @override
  _CustomerSelectionPageState createState() => _CustomerSelectionPageState();
}

class _CustomerSelectionPageState extends State<CustomerSelectionPage> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Customer'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Customer Code or Name',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('customers')
                  .orderBy('customerCode')
                  .get(),
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

                var filteredCustomerDocs = customerDocs.where((doc) {
                  var customerData = doc.data() as Map<String, dynamic>;
                  String customerCode = customerData['customerCode'].toLowerCase();
                  String customerName = customerData['customerName'].toLowerCase();

                  return customerCode.contains(_searchQuery) || customerName.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: filteredCustomerDocs.length,
                  itemBuilder: (context, index) {
                    var customerData = filteredCustomerDocs[index].data() as Map<String, dynamic>;
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
                          'customerId': filteredCustomerDocs[index].id, // Add document ID
                          'customerCode': customerCode,
                          'customerName': customerData['customerName'],
                          'arabicName': customerData['arabicName'],
                          'address': customerData['address'],
                          'mobileNumber': customerData['mobileNumber'],
                          'vtNumber': customerData['vtNumber'],
                          'email': customerData['email'],
                          'contactPerson': customerData['contactPerson'],
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
