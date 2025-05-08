import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/activity_model.dart';
import '../api/api_service.dart'; // Import ApiService

class ActivityService {
  final String baseUrl =
      "${ApiService.baseUrl}/api/activities"; // Use dynamic base URL

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
