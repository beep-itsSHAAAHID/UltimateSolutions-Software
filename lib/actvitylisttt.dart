import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ActivityDetailPage extends StatelessWidget {
  final String userEmail;
  const ActivityDetailPage({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    final activityQuery = FirebaseFirestore.instance
        .collection('dailyActivities')
        .where('user_email', isEqualTo: userEmail)
        .where('created_at', isNotEqualTo: null)
        .orderBy('created_at', descending: true)
        .snapshots()
        .handleError((error) {
      debugPrint("Firestore stream error: $error");
    });

    return Scaffold(
      appBar: AppBar(title: Text(userEmail)),
      body: StreamBuilder<QuerySnapshot>(
        stream: activityQuery,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading activities"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(); // Remove spinner
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text("No activities found for this user"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final activityType = (data['activityType'] ?? '').toString().toUpperCase();
              final customer = data['customer'] ?? 'N/A';
              final location = data['location'] ?? 'N/A';
              final visitType = data['visitType'] ?? 'N/A';
              final createdAt = data['created_at']?.toDate();
              final formattedDate = createdAt != null
                  ? DateFormat('MMM d, yyyy • hh:mm a').format(createdAt)
                  : 'Unknown Date';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activityType,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("🧍 Customer: $customer"),
                      Text("📍 Location: $location"),
                      Text("🚗 Visit Type: $visitType"),
                      Text("📅 $formattedDate"),
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
