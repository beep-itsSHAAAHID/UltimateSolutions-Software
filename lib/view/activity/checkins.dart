import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckInViewer extends StatefulWidget {
  const CheckInViewer({super.key});

  @override
  State<CheckInViewer> createState() => _CheckInViewerState();
}

class _CheckInViewerState extends State<CheckInViewer> {
  Map<String, List<Map<String, dynamic>>> groupedData = {};
  String? selectedUid;

  // UID to display name mapping
  final Map<String, String> uidToName = {
    "D8ZtJ4HvNYP9jr8bipI0LY3CBu73": "Jaseem",
    "ZVMdDBs8lONGrPONztFtOzvrd742": "Mazid",
    // Add more mappings if needed
  };

  @override
  void initState() {
    super.initState();
    fetchGroupedCheckIns();
  }

  Future<void> fetchGroupedCheckIns() async {
    final querySnapshot =
    await FirebaseFirestore.instance.collection('checkInWithChecks').get();

    final Map<String, List<Map<String, dynamic>>> tempMap = {};

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final uid = data['uid'] ?? 'unknown';

      if (!tempMap.containsKey(uid)) {
        tempMap[uid] = [];
      }

      tempMap[uid]!.add(data);
    }

    // Sort by timestamp descending
    tempMap.forEach((uid, entries) {
      entries.sort((a, b) {
        final tA = a['timestamp'];
        final tB = b['timestamp'];
        if (tA is Timestamp && tB is Timestamp) {
          return tB.compareTo(tA);
        }
        return 0;
      });
    });

    setState(() {
      groupedData = tempMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Center(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: groupedData.keys.map((uid) {
              final displayName = uidToName[uid] ?? uid.substring(0, 6) + "...";
              return ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedUid = uid;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedUid == uid ? Colors.green : Colors.grey[200],
                  foregroundColor: selectedUid == uid ? Colors.white : Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(displayName),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        if (selectedUid != null)
          Expanded(
            child: ListView.builder(
              itemCount: groupedData[selectedUid]!.length,
              itemBuilder: (context, index) {
                final entry = groupedData[selectedUid]![index];
                final timestamp = entry['timestamp'];
                final formattedTime = timestamp is Timestamp
                    ? timestamp.toDate().toLocal().toString()
                    : 'N/A';

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text("Date: ${entry['date'] ?? 'N/A'}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Odometer: ${entry['odometer'] ?? 'N/A'}"),
                        Text("Time: ${entry['time'] ?? 'N/A'}"),
                        Text("Remarks: ${entry['remarks'] ?? 'N/A'}"),
                        Text("Logged At: $formattedTime"),
                        Text("Check in Location: ${entry['location'] ?? 'N/A'}"),

                        const SizedBox(height: 6),
                        if (entry['checks'] != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: (entry['checks'] as Map<String, dynamic>)
                                .entries
                                .map((e) =>
                                Text("• ${e.key}: ${e.value.toString()}"))
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Text("👆 Select a user to view their check-ins",
                style: TextStyle(fontSize: 16)),
          ),
      ],
    );
  }
}
