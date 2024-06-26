import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/google_sheets_api.dart';
import '../../models/activity_model.dart';

class Activities extends StatefulWidget {
  const Activities({Key? key}) : super(key: key);

  @override
  State<Activities> createState() => _ActivitiesState();
}



class _ActivitiesState extends State<Activities> {
  late Future<List<Activity>> allActivities;
  late List<String> uniqueUsernames = [];
  late Future<List<Activity>> displayedActivities = Future.value([]);
  Set<Activity> selectedActivities = Set<Activity>();




  @override
  void initState() {
    super.initState();
    allActivities = fetchActivitiesOrderedByTimestamp();
  }

  Future<List<Activity>> fetchActivitiesOrderedByTimestamp() async {
    QuerySnapshot<Map<String, dynamic>> snapshot =
    await FirebaseFirestore.instance.collection('activities').orderBy('timestamp', descending: true).get();

    List<Activity> activityList = snapshot.docs.map((DocumentSnapshot<Map<String, dynamic>> doc) {
      Map<String, dynamic> data = doc.data()!;
      return Activity(
        username: data['username'] ?? '',
        activity: data['activity'] ?? '',
        customerName: data['customerName'] ?? '',
        customerRemarks: data['customerRemarks'] ?? '',
        productName: data['productName'] ?? '',
        quantity: int.tryParse(data['quantity'] ?? '0') ?? 0,  // Ensure quantity is an int
        salesmanRemarks: data['salesmanRemarks'] ?? '',
        timestamp: (data['timestamp'] as Timestamp?) ?? Timestamp.now(),
      );
    }).toList();

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

  void _selectAll() async {
    List<Activity> activities = await displayedActivities;
    setState(() {
      selectedActivities.addAll(activities);
    });
  }

  void _deleteSelected() async {
    for (Activity activity in selectedActivities) {
      await FirebaseFirestore.instance.collection('activities').where('timestamp', isEqualTo: activity.timestamp).get().then((querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          doc.reference.delete();
        });
      });
    }
    // After deletion, clear the selected activities and refresh the activities list
    selectedActivities.clear();
    _refresh();
  }

  Future<bool> printActivitiesToSheet() async {
    bool newDataPrinted = false; // Flag to track if data is printed

    try {
      final List<Activity> activitiesToPrint = await displayedActivities; // Get all displayed activities
      if (activitiesToPrint.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No activities available to print.'),
            backgroundColor: Colors.orange,
          ),
        );
        return false; // No activities to print
      }

      for (var activity in activitiesToPrint) {
        String formattedTimestamp = activity.timestamp.toDate().toIso8601String();
        // Print each activity to the Google Sheets
        await appendActivityToEmployeeSheet(activity.username, [
          activity.username,
          activity.customerName,
          activity.activity,
          activity.customerRemarks,
          activity.salesmanRemarks,
          formattedTimestamp,
        ]);
        newDataPrinted = true; // Data has been printed
      }

      if (newDataPrinted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All data successfully printed to Google Sheets.'),
            backgroundColor: Colors.green,
          ),
        );
        return true; // Successfully printed
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No new data to print.'),
            backgroundColor: Colors.orange,
          ),
        );
        return false; // No new data was printed
      }
    } catch (e) {
      print("Error printing activities to sheet: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to print data.'),
          backgroundColor: Colors.red,
        ),
      );
      return false; // Failure in printing
    }
  }




  Future<DateTime?> getLastPrintedTimestamp(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final lastPrintedString = prefs.getString('lastPrinted_$username');
    if (lastPrintedString != null) {
      return DateTime.parse(lastPrintedString);
    }
    return null; // Indicates no previous print for this username
  }

  Future<void> updateLastPrintedTimestamp(String username, DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastPrinted_$username', timestamp.toIso8601String());
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
            icon: Icon(Icons.print),
            onPressed: () async {
              ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide any existing snackbar
              final bool success = await printActivitiesToSheet();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Data successfully printed to Google Sheets.' : 'Failed to print data.'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
          ),

          Center(
            child: IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _refresh,
            ),
          ),
          // IconButton(
          //   icon: Icon(Icons.check_box_outlined),
          //   onPressed: _selectAll,
          // ),
          // IconButton(
          //   icon: Icon(Icons.delete),
          //   onPressed: selectedActivities.isEmpty ? null : _deleteSelected,
          // ),
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

      body: Center(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Display buttons for each unique username
                SizedBox(height: 10),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: uniqueUsernames.map((username) {
                      return ElevatedButton(
                        style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.black)),
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
                              color: Colors.blue.shade900,
                              elevation: 5,
                              margin: EdgeInsets.all(10),
                              child: ListTile(
                                leading: Icon(Icons.person, size: 40, color: Colors.white),
                                title: Text(
                                  activityList[index].username,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.yellow
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Activity: ${activityList[index].activity}',style: TextStyle(color: Colors.white),),
                                    Text('Customer Name: ${activityList[index].customerName}',style: TextStyle(color: Colors.white),),
                                    Text('Remarks: ${activityList[index].customerRemarks}',style: TextStyle(color: Colors.white),),
                                    Text('Salesman Remarks: ${activityList[index].salesmanRemarks}',style: TextStyle(color: Colors.white),),
                                    Text('Timestamp: ${activityList[index].timestamp.toDate().toString()}',style: TextStyle(color: Colors.white),),
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
      ),
    );
  }
}

