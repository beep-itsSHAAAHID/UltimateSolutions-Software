import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewCustomers extends StatefulWidget {
  const ViewCustomers({Key? key}) : super(key: key);

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
  });
}

class _ViewCustomersState extends State<ViewCustomers> {
  late Future<List<Customers>> customers;

  @override
  void initState() {
    super.initState();
    customers = fetchCustomers();
  }

  Future<List<Customers>> fetchCustomers() async {
    // Fetch customers from Firebase Firestore collection
    QuerySnapshot<Map<String, dynamic>> snapshot =
    await FirebaseFirestore.instance.collection('customers').get();

    // Convert the snapshot data to a list of Customer objects
    List<Customers> customersList = snapshot.docs
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
        createdAt: data['createdAt'] ?? '',
      );
    }).toList();

    return customersList;
  }

  Future<void> _refresh() async {
    setState(() {
      customers = fetchCustomers();
    });
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
              FutureBuilder<List<Customers>>(
                future: customers,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error.toString()}'));
                  } else {
                    List<Customers> customersList = snapshot.data ?? [];
                    return Column(
                      children: [
                        for (int index = 0; index < customersList.length; index++)
                          Card(
                            color: Colors.lightBlue,
                            elevation: 5,
                            margin: EdgeInsets.all(10),
                            child: ListTile(
                              leading: Icon(Icons.apartment, size: 40, color: Colors.white),
                              title: Text(
                                customersList[index].customerName,
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
                                        'Customer Code: ${customersList[index].customerCode}',
                                        style: TextStyle(fontSize: 16, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, size: 20, color: Colors.white),
                                      SizedBox(width: 5),
                                      Text(
                                        'Address: ${customersList[index].address}',
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
                                        'Customer Type: ${customersList[index].customerType}',
                                        style: TextStyle(fontSize: 16, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 20, color: Colors.white),
                                      SizedBox(width: 5),
                                      Text(
                                        'Delivery Location: ${customersList[index].deliveryLocation}',
                                        style: TextStyle(fontSize: 16, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.phone_android, size: 20, color: Colors.white),
                                      SizedBox(width: 5),
                                      Text(
                                        'Mobile Number: ${customersList[index].mobileNumber}',
                                        style: TextStyle(fontSize: 16, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.phone, size: 20, color: Colors.white),
                                      SizedBox(width: 5),
                                      Text(
                                        'Telephone Number: ${customersList[index].telephoneNumber}',
                                        style: TextStyle(fontSize: 16, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.percent, size: 20, color: Colors.white),
                                      SizedBox(width: 5),
                                      Text(
                                        'Vat Number: ${customersList[index].vtNumber}',
                                        style: TextStyle(fontSize: 16, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 20, color: Colors.white),
                                      SizedBox(width: 5),
                                      Text(
                                        'Created At: ${customersList[index].createdAt.toDate().toString()}',
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
}
