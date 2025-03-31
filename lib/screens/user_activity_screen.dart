import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import 'activity_service.dart';

class UserActivityScreen extends StatefulWidget {
  final String userId;

  const UserActivityScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _UserActivityScreenState createState() => _UserActivityScreenState();
}

class _UserActivityScreenState extends State<UserActivityScreen> {
  late Future<List<Activity>> futureActivities;

  @override
  void initState() {
    super.initState();
    futureActivities = ActivityService().fetchUserActivities(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Activity History')),
      body: FutureBuilder<List<Activity>>(
        future: futureActivities,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No activities found.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                Activity activity = snapshot.data![index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: ListTile(
                    title: Text(
                      'Activity from ${activity.fromDate.toLocal()} to ${activity.toDate.toLocal()}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🚗 Transportation: ${activity.transportation} km'),
                        Text('🥗 Diet: ${activity.diet}'),
                        Text('⚡ Energy Usage: ${activity.energy} kWh'),
                        Text('🌍 Total Emission: ${activity.totalEmission} kg CO2'),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
