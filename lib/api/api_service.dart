import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Dynamically determine the correct base URL
  static String get baseUrl {
    if (Platform.isAndroid) {
      return "http://${getLocalIp()}:5001"; // Use local network IP for real devices
    } else {
      return "http://10.0.2.2:5001"; //Android Emulator (Maps 127.0.0.1)  Use local network IP for real devices
    }
  }

  // Function to get your local network IP (Manually update if needed)
  static String getLocalIp() {
    return "192.168.52.131"; // Change this to your actual PC's IP address
  }

  // Register User
  static Future<bool> registerUser(
    String name,
    String username,
    String email,
    String password,
  ) async {
    final url = Uri.parse("$baseUrl/api/auth/register");

    try {
      final response = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({
              "name": name,
              "username": username,
              "email": email,
              "password": password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return true;
      } else {
        print("❌ Registration failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ Error during registration: $e");
      return false;
    }
  }

  // Login User
  static Future<String?> loginUser(String email, String password) async {
    final url = Uri.parse("$baseUrl/api/auth/login");

    try {
      final response = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({"email": email, "password": password}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['userId'] != null && data['userId'].length == 24) {
            return data['userId']; // Ensure it's a valid ObjectId
          } else {
            print("⚠️ Invalid userId received: ${data['userId']}");
            return null;
          }
        } catch (jsonError) {
          print("⚠️ JSON Decoding Error: $jsonError");
          return null;
        }
      } else {
        print("❌ Login failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("⚠️ Error during login: $e");
      return null;
    }
  }

  // Fetch User Details
  static Future<Map<String, dynamic>?> fetchUserDetails(String token) async {
    final url = Uri.parse("$baseUrl/api/user/profile");

    try {
      final response = await http
          .get(
            url,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body);
        } catch (jsonError) {
          print("⚠️ JSON Parsing Error: $jsonError");
          return null;
        }
      } else {
        print("❌ Fetching user details failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("⚠️ Error fetching user details: $e");
      return null;
    }
  }
}
