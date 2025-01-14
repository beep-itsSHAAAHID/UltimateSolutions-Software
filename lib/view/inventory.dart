import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Inventory extends StatefulWidget {
  const Inventory({Key? key}) : super(key: key);

  @override
  State<Inventory> createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> with SingleTickerProviderStateMixin {
  late Future<Map<String, Map<String, dynamic>>> inventory;
  late Future<List<Map<String, dynamic>>> salesHistory;
  late TabController _tabController;
  List<Map<String, dynamic>> _filteredSalesHistory = [];
  Map<String, Map<String, dynamic>> _filteredInventory = {};
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    inventory = fetchInventory();
    salesHistory = fetchSalesHistory();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_filterResults);
  }

  Future<Map<String, Map<String, dynamic>>> fetchInventory() async {
    Map<String, Map<String, dynamic>> inventory = {};

    // Fetch purchase data
    QuerySnapshot purchaseSnapshot = await FirebaseFirestore.instance.collection('purchase').get();
    for (var doc in purchaseSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String productCode = data['productCode'] ?? '';
      String productName = data['productName'] ?? '';
      int quantity = int.tryParse(data['quantity']?.toString() ?? '0') ?? 0;

      if (inventory.containsKey(productCode)) {
        inventory[productCode]!['quantity'] = inventory[productCode]!['quantity'] + quantity;
      } else {
        inventory[productCode] = {'productName': productName, 'quantity': quantity};
      }
    }

    // Fetch sales (invoice) data
    QuerySnapshot invoiceSnapshot = await FirebaseFirestore.instance.collection('invoices').get();
    for (var doc in invoiceSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> products = data['products'] ?? [];

      for (var product in products) {
        String productCode = product['code'] ?? '';
        int quantity = int.tryParse(product['quantity']?.toString() ?? '0') ?? 0;

        if (inventory.containsKey(productCode)) {
          inventory[productCode]!['quantity'] = inventory[productCode]!['quantity'] - quantity;
        }
      }
    }

    return inventory;
  }

  Future<List<Map<String, dynamic>>> fetchSalesHistory() async {
    List<Map<String, dynamic>> salesHistory = [];

    // Fetch sales (invoice) data
    QuerySnapshot invoiceSnapshot = await FirebaseFirestore.instance.collection('invoices').get();
    for (var doc in invoiceSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String customerName = data['customerName'] ?? '';
      String invoiceDate = data['invoiceDate'] ?? '';
      List<dynamic> products = data['products'] ?? [];

      for (var product in products) {
        salesHistory.add({
          'customerName': customerName,
          'invoiceDate': invoiceDate,
          'productName': product['name'] ?? '',
          'quantity': product['quantity'] ?? 0,
        });
      }
    }

    return salesHistory;
  }

  void _filterResults() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      // Filter inventory
      _filteredInventory = {};
      inventory.then((inventory) {
        inventory.forEach((productCode, data) {
          if (data['productName'].toLowerCase().contains(query) || productCode.toLowerCase().contains(query)) {
            _filteredInventory[productCode] = data;
          }
        });
      });

      // Filter sales history
      _filteredSalesHistory = [];
      salesHistory.then((history) {
        _filteredSalesHistory = history.where((item) {
          return item['customerName'].toLowerCase().contains(query) ||
              item['productName'].toLowerCase().contains(query) ||
              item['invoiceDate'].toLowerCase().contains(query);
        }).toList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Inventory Management",
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 30),
        ),
        centerTitle: true,
        backgroundColor: Color(0xff0C88BD),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(40),
          ),
        ),
        bottom: TabBar(
          labelColor: Colors.white, // Set the color for the selected tab
          unselectedLabelColor: Colors.white, // Set the color for the unselected tabs

          controller: _tabController,
          tabs: [
            Tab(text: 'Inventory'),
            Tab(text: 'Sales History'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                FutureBuilder<Map<String, Map<String, dynamic>>>(
                  future: inventory,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No inventory data found.'));
                    }

                    Map<String, Map<String, dynamic>> inventoryData = _searchController.text.isEmpty ? snapshot.data! : _filteredInventory;

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: inventoryData.length,
                        itemBuilder: (context, index) {
                          String productCode = inventoryData.keys.elementAt(index);
                          String productName = inventoryData[productCode]!['productName'];
                          int quantity = inventoryData[productCode]!['quantity'];

                          return Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Product Name: $productName',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Product Code: $productCode',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Spacer(),
                                  Text(
                                    'Available Quantity: $quantity',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: quantity > 0 ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: salesHistory,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No sales history found.'));
                    }

                    List<Map<String, dynamic>> salesHistoryData = _searchController.text.isEmpty ? snapshot.data! : _filteredSalesHistory;

                    return ListView.builder(
                      padding: EdgeInsets.all(16.0),
                      itemCount: salesHistoryData.length,
                      itemBuilder: (context, index) {
                        String customerName = salesHistoryData[index]['customerName'];
                        String invoiceDate = salesHistoryData[index]['invoiceDate'];
                        String productName = salesHistoryData[index]['productName'];
                        int quantity = salesHistoryData[index]['quantity'];

                        return Card(
                          elevation: 5,
                          margin: EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Customer Name: $customerName',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Invoice Date: $invoiceDate',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  'Product Name: $productName',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  'Quantity Sold: $quantity',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
