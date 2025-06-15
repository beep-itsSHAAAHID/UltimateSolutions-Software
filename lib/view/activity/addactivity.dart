import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../actvitylisttt.dart';

class UserListPage extends StatelessWidget {
  const UserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Users")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('dailyActivities').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allDocs = snapshot.data!.docs;

            if (allDocs.isEmpty) {
              return const Center(child: Text('No data found.'));
            }

            // Safely extract emails
            final Set<String> emails = {};
            for (var doc in allDocs) {
              final data = doc.data() as Map<String, dynamic>;
              if (data.containsKey('user_email') && data['user_email'] != null) {
                emails.add(data['user_email'].toString());
              }
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: emails.map((email) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActivityDetailPage(userEmail: email),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 6,
                    margin: const EdgeInsets.only(bottom: 16),
                    color: Colors.indigo.shade100,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        email,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }

      ),
    );
  }
}
