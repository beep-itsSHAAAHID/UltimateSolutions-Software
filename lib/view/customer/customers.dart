import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../api/google_sheets_api.dart';
import 'addcustomer.dart';

class ViewCustomers extends StatefulWidget {
  final String userEmail;
  final bool isAdmin;

  const ViewCustomers({Key? key, required this.userEmail, required this.isAdmin}) : super(key: key);

  @override
  State<ViewCustomers> createState() => _ViewCustomersState();
}

class Customers {
  final String customerName;
  final String arabicName;
  final String customerCode;
  final String address;
  final String customerType;
  final String deliveryLocation;
  final String mobileNumber;
  final String telephoneNumber;
  final String vtNumber;
  final Timestamp createdAt;
  final String email;
  final int invoiceCount; // Add invoiceCount directly to the model

  Customers({
    required this.customerName,
    required this.customerCode,
    required this.address,
    required this.customerType,
    required this.deliveryLocation,
    required this.mobileNumber,
    required this.telephoneNumber,
    required this.vtNumber,
    required this.createdAt,
    required this.email,
    required this.arabicName,
    required this.invoiceCount,
  });
}

class _ViewCustomersState extends State<ViewCustomers> {
  late Future<List<Customers>> customers;

  late List<Customers> customersList = [];
  late List<Customers> filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    customers = fetchCustomers();
  }

  Future<List<Customers>> fetchCustomers() async {
    QuerySnapshot<Map<String, dynamic>> snapshot;

    if (widget.isAdmin) {
      // Fetch all customers for admin
      snapshot = await FirebaseFirestore.instance.collection('customers').get();
    } else {
      // Fetch customers added by the logged-in user for salesman
      snapshot = await FirebaseFirestore.instance
          .collection('customers')
          .where('addedBy', isEqualTo: widget.userEmail)
          .get();
    }

    // Convert the snapshot data to a list of Customer objects
    customersList = await Future.wait(snapshot.docs.map((doc) async {
      Map<String, dynamic> data = doc.data();

      // Fetch the invoice count for the current customer
      QuerySnapshot<Map<String, dynamic>> invoiceSnapshot = await FirebaseFirestore.instance
          .collection('invoices')
          .where('customerCode', isEqualTo: data['customerCode'])
          .get();

      return Customers(
        customerName: data['customerName'] ?? '',
        arabicName: data['arabicName'] ?? '',
        customerCode: data['customerCode'] ?? '',
        address: data['address'] ?? '',
        customerType: data['customerType'] ?? '',
        deliveryLocation: data['deliveryLocation'] ?? '',
        mobileNumber: data['mobileNumber'] ?? '0',
        telephoneNumber: data['telephoneNumber'] ?? '',
        vtNumber: data['vtNumber'] ?? '',
        email: data['email'] ?? '',
        createdAt: data['createdAt'] ?? Timestamp.now(),
        invoiceCount: invoiceSnapshot.size, // Store the invoice count
      );
    }).toList());

    return customersList;
  }

  Future<void> _refresh() async {
    setState(() {
      customers = fetchCustomers();
    });
  }

  void _searchCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        // If the query is empty, show all customers
        filteredCustomers = List.from(customersList);
      } else {
        // Filter customers based on the query
        filteredCustomers = customersList
            .where((customer) =>
            customer.customerName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> printCustomersToSheet() async {
    try {
      final List<Customers> customersToPrint = await customers;
      for (var customer in customersToPrint) {
        await appendCustomerToSheet('CustomerData', [
          customer.customerName,
          customer.customerCode,
          customer.address,
          customer.customerType,
          customer.deliveryLocation,
          customer.mobileNumber,
          customer.telephoneNumber,
          customer.vtNumber,
          customer.createdAt.toDate().toIso8601String(),
          customer.email,
        ]);
      }
      // Provide user feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer data successfully printed to Google Sheets.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to print customer data.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteCustomer(String customerCode) async {
    try {
      // Find the document with the matching customerCode
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .where('customerCode', isEqualTo: customerCode)
          .get();

      // Check if the document exists
      if (querySnapshot.docs.isNotEmpty) {
        // Get the document ID
        String documentId = querySnapshot.docs.first.id;

        // Delete the document using the document ID
        await FirebaseFirestore.instance
            .collection('customers')
            .doc(documentId)
            .delete();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the customer list after deletion
        _refresh();
      } else {
        // If the customer is not found, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Show error message if something goes wrong
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete customer'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'ULTIMATE SOLUTIONS....!',
            style: TextStyle(
              color: Colors.white,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          IconButton(
            icon: Icon(Icons.print),
            onPressed: printCustomersToSheet,
          ),
        ],
        backgroundColor: Colors.lightBlueAccent,
        toolbarHeight: 100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(50),
            bottomRight: Radius.circular(50),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildSearchBar(),
              SizedBox(height: 30),
              FutureBuilder<List<Customers>>(
                future: customers,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error.toString()}'));
                  } else {
                    List<Customers> displayCustomers =
                    filteredCustomers.isNotEmpty ? filteredCustomers : customersList;
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: displayCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = displayCustomers[index];
                        return Card(
                          color: Colors.lightBlue,
                          elevation: 10,
                          margin: EdgeInsets.all(10),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                // Square Icon Container
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.account_box, size: 30, color: Colors.blue),
                                ),
                                SizedBox(width: 10),

                                // Customer Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customer.customerName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        'Customer Code: ${customer.customerCode}',
                                        style: TextStyle(fontSize: 16, color: Colors.white),
                                      ),
                                      Text(
                                        'Arabic Name: ${customer.arabicName}',
                                        style: TextStyle(fontSize: 16, color: Colors.white),
                                      ),
                                      Text(
                                        'Vat Number: ${customer.vtNumber}',
                                        style: TextStyle(fontSize: 16, color: Colors.white),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            'Invoices: ${customer.invoiceCount}',
                                            style: TextStyle(fontSize: 16, color: Colors.black),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Edit and Delete Icons
                                Column(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.white),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AddCustomer(
                                              userEmail: widget.userEmail,
                                              customer: customer, // Pass the selected customer
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.white),
                                      onPressed: () {
                                        _deleteCustomer(customer.customerCode); // Use customerCode as ID
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        onChanged: _searchCustomers,
        decoration: InputDecoration(
          hintText: 'Search customers...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }
}
