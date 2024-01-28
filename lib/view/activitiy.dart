import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Activities extends StatefulWidget {
  const Activities({Key? key}) : super(key: key);

  @override
  State<Activities> createState() => _ActivitiesState();
}

class Activity {
  final String username;
  final String activity;
  final String customerName;
  final String customerRemarks;
  final String productName;
  final String quantity;
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
}

class _ActivitiesState extends State<Activities> {
  late Future<List<Activity>> allActivities;
  late List<String> uniqueUsernames = [];
  late Future<List<Activity>> displayedActivities = Future.value([]);



  @override
  void initState() {
    super.initState();
    allActivities = fetchActivitiesOrderedByTimestamp();
  }

  Future<List<Activity>> fetchActivitiesOrderedByTimestamp() async {
    QuerySnapshot<Map<String, dynamic>> snapshot =
    await FirebaseFirestore.instance.collection('activities').orderBy('timestamp', descending: true).get();

    List<Activity> activityList = snapshot.docs
        .map((DocumentSnapshot<Map<String, dynamic>> doc) {
      Map<String, dynamic> data = doc.data()!;
      return Activity(
        username: data['username'] ?? '',
        activity: data['activity'] ?? '',
        customerName: data['customerName'] ?? '',
        customerRemarks: data['customerRemarks'] ?? '',
        productName: data['productName'] ?? '',
        quantity: data['quantity'] ?? '0',
        salesmanRemarks: data['salesmanRemarks'] ?? '',
        timestamp: data['timestamp'] ?? Timestamp.now(),
      );
    })
        .toList();

    // Extract unique usernames
    uniqueUsernames = Set<String>.from(activityList.map((activity) => activity.username)).toList();

    return activityList;
  }

  Future<void> _refresh() async {
    setState(() {
      allActivities = fetchActivitiesOrderedByTimestamp();
      displayedActivities = Future.value([]); // Reset displayed activities

    });
  }

  void _filterActivitiesByUsername(String username) {
    setState(() {
      displayedActivities = (allActivities as Future<List<Activity>>).then((List<Activity> list) {
        return list.where((activity) => activity.username == username).toList();
      }).catchError((error) {
        print("Error fetching and filtering activities: $error");
        return []; // Return an empty list in case of an error
      });
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
              // Display buttons for each unique username
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: uniqueUsernames.map((username) {
                    return ElevatedButton(
                      style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.lightBlueAccent)),
                      onPressed: () => _filterActivitiesByUsername(username),
                      child: Text(style: TextStyle(
                        color: Colors.white
                      ),
                          username),
                    );
                  }).toList(),
                ),
              ),
              FutureBuilder<List<Activity>>(
                future: displayedActivities,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error.toString()}'));
                  } else {
                    List<Activity> activityList = snapshot.data ?? [];
                    return Column(
                      children: [
                        for (int index = 0; index < activityList.length; index++)
                          Card(
                            color: Colors.lightBlue,
                            elevation: 5,
                            margin: EdgeInsets.all(10),
                            child: ListTile(
                              leading: Icon(Icons.person, size: 40, color: Colors.white),
                              title: Text(
                                activityList[index].username,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Activity: ${activityList[index].activity}'),
                                  Text('Customer Name: ${activityList[index].customerName}'),
                                  Text('Remarks: ${activityList[index].customerRemarks}'),
                                  Text('Product: ${activityList[index].productName}'),
                                  Text('Quantity: ${activityList[index].quantity}'),
                                  Text('Salesman Remarks: ${activityList[index].salesmanRemarks}'),
                                  Text('Timestamp: ${activityList[index].timestamp.toDate().toString()}'),
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
