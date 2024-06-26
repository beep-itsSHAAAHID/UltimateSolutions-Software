import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../api/google_sheets_api.dart';

class ViewCustomers extends StatefulWidget {
  final String userEmail;
  final bool isAdmin;

  const ViewCustomers({Key? key, required this.userEmail, required this.isAdmin}) : super(key: key);

  @override
  State<ViewCustomers> createState() => _ViewCustomersState();
}

class Customers {
  final String customerName;
  final String customerCode;
  final String address;
  final String customerType;
  final String deliveryLocation;
  final String mobileNumber;
  final String telephoneNumber;
  final String vtNumber;
  final Timestamp createdAt;
  final String email;

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
    customersList = snapshot.docs
        .map((DocumentSnapshot<Map<String, dynamic>> doc) {
      Map<String, dynamic> data = doc.data()!;
      return Customers(
        customerName: data['customerName'] ?? '',
        customerCode: data['customerCode'] ?? '',
        address: data['address'] ?? '',
        customerType: data['customerType'] ?? '',
        deliveryLocation: data['deliveryLocation'] ?? '',
        mobileNumber: data['mobileNumber'] ?? '0',
        telephoneNumber: data['telephoneNumber'] ?? '',
        vtNumber: data['vtNumber'] ?? '',
        email: data['email'] ?? '',
        createdAt: data['createdAt'] ?? Timestamp.now(),
      );
    }).toList();

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
                    return Column(
                      children: [
                        for (int index = 0; index < displayCustomers.length; index++)
                          Card(
                            color: Colors.lightBlue,
                            elevation: 10,
                            margin: EdgeInsets.all(10),
                            child: ListTile(
                              leading: Icon(Icons.apartment, size: 40, color: Colors.white),
                              title: Text(
                                displayCustomers[index].customerName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(Icons.numbers, size: 20, color: Colors.white),
                                      SizedBox(width: 5),
                                      Text(
                                        'Customer Code: ${displayCustomers[index].customerCode}',
                                        style: TextStyle(fontSize: 16, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, size: 20, color: Colors.white),
                                      SizedBox(width: 5),
                                      Text(
                                        'Address: ${displayCustomers[index].address}',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.credit_card_rounded, size: 20, color: Colors.white),
                                      SizedBox(width: 5),
                                      Text(
                                        'Customer Type: ${displayCustomers[index].customerType}',
                                        style: TextStyle(fontSize: 16, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 20, color: Colors.white),
                                      SizedBox(width: 5),
                                      Text(
                                        'Delivery Location: ${displayCustomers[index].deliveryLocation}',
                                        style: TextStyle(fontSize: 16, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.phone_android, size: 20, color: Colors.white),
                                      SizedBox(width: 5),
                                      Text(
                                        'Mobile Number: ${displayCustomers[index].mobileNumber}',
                                        style: TextStyle(fontSize: 16, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.phone, size: 20, color: Colors.white),
                                      SizedBox(width: 5),
                                      Text(
                                        'Telephone Number: ${displayCustomers[index].telephoneNumber}',
                                        style: TextStyle(fontSize: 16, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.percent, size: 20, color: Colors.white),
                                      SizedBox(width: 5),
                                      Text(
                                        'Vat Number: ${displayCustomers[index].vtNumber}',
                                        style: TextStyle(fontSize: 16, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 20, color: Colors.white),
                                      SizedBox(width: 5),
                                      Text(
                                        'Created At: ${displayCustomers[index].createdAt.toDate().toString()}',
                                        style: TextStyle(fontSize: 14, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.email, size: 20, color: Colors.white),
                                      SizedBox(width: 5),
                                      Text(
                                        'Email: ${displayCustomers[index].email}',
                                        style: TextStyle(fontSize: 14, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                ],
                              ),
                            ),
                          ),
                      ],
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
