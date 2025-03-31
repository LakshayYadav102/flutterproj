import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/activity_model.dart';

class ActivityService {
  final String baseUrl = 'http://10.0.2.2:5000/api/activities';

  Future<List<Activity>> fetchUserActivities(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/user/$userId'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Activity.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load user activities');
    }
  }
}
