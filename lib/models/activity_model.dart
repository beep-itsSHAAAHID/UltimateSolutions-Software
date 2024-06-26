import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String username;
  final String activity;
  final String customerName;
  final String customerRemarks;
  final String productName;
  final int quantity;
  final String salesmanRemarks;
  final Timestamp timestamp;

  Activity({
    required this.username,
    required this.activity,
    required this.customerName,
    required this.customerRemarks,
    required this.productName,
    required this.quantity,
    required this.salesmanRemarks,
    required this.timestamp,
  });

  factory Activity.fromMap(Map<String, dynamic> data) {
    return Activity(
      username: data['username'] ?? '',
      activity: data['activity'] ?? '',
      customerName: data['customerName'] ?? '',
      customerRemarks: data['customerRemarks'] ?? '',
      productName: data['productName'] ?? '',
      quantity: data['quantity'] != null ? int.tryParse(data['quantity'].toString()) ?? 0 : 0,
      salesmanRemarks: data['salesmanRemarks'] ?? '',
      timestamp: data['timestamp'] as Timestamp, // assuming 'timestamp' is always provided
    );
  }
}
