import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewPurchase extends StatefulWidget {
  const ViewPurchase({Key? key}) : super(key: key);

  @override
  State<ViewPurchase> createState() => _ViewPurchaseState();
}

class _ViewPurchaseState extends State<ViewPurchase> {
  late Future<List<Map<String, dynamic>>> purchases;

  @override
  void initState() {
    super.initState();
    purchases = fetchPurchases();
  }

  Future<List<Map<String, dynamic>>> fetchPurchases() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('products').get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "View Purchases",
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 30),
        ),
        centerTitle: true,
        backgroundColor: Color(0xff0C88BD),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(40),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: purchases,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No purchases found.'));
          }

          List<Map<String, dynamic>> purchases = snapshot.data!;

          return ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: purchases.length,
            itemBuilder: (context, index) {
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
                        'Product Name: ${purchases[index]['productName']}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Product Code: ${purchases[index]['productCode']}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Purchase Amount: ${purchases[index]['purchaseAmount']}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Quantity: ${purchases[index]['quantity']}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Current Stock: ${purchases[index]['currentStock']}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Opening Stock: ${purchases[index]['openingStock']}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Average Cost: ${purchases[index]['averageCost']}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Retail Price: ${purchases[index]['retailPrice']}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Wholesale Rate: ${purchases[index]['wholesaleRate']}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'VAT Category: ${purchases[index]['vatCategory']}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Price After VAT: ${purchases[index]['priceAfterVAT']}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Added By: ${purchases[index]['addedBy']}',
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
    );
  }
}
