import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  String? profilePic;
  bool isLoading = false;
  String? token;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    if (token != null) {
      _fetchUserProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Authentication token not found")),
      );
    }
  }

  Future<void> _fetchUserProfile() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:5000/api/profile"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        setState(() {
          usernameController.text = userData['username'];
          mobileController.text = userData['mobile'] ?? "";
          dobController.text = userData['dob'] ?? ""; // Server returns "YYYY-MM-DD"
          addressController.text = userData['address'] ?? "";
          profilePic = userData['profilePic'] != null
              ? "http://10.0.2.2:5000${userData['profilePic']}"
              : null;
        });
      } else {
        throw Exception("Failed to load profile");
      }
    } catch (e) {
      print("Error fetching profile: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    setState(() => isLoading = true);

    try {
      final response = await http.put(
        Uri.parse("http://10.0.2.2:5000/api/profile"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "username": usernameController.text,
          "mobile": mobileController.text,
          "dob": dobController.text, // Now formatted as "YYYY-MM-DD"
          "address": addressController.text,
        }),
      );

      print("Response Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile updated successfully")),
        );
      } else {
        throw Exception("Failed to update profile: ${response.body}");
      }
    } catch (e) {
      print("Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update profile")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _uploadProfilePic() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    var request = http.MultipartRequest(
      "POST",
      Uri.parse("http://10.0.2.2:5000/api/profile/upload"),
    );
    request.headers["Authorization"] = "Bearer $token";
    request.files.add(
      await http.MultipartFile.fromPath("profilePic", imageFile.path),
    );

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = jsonDecode(await response.stream.bytesToString());
        setState(() {
          profilePic = "http://10.0.2.2:5000${responseData['profilePic']}";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile picture updated")),
        );
      } else {
        throw Exception("Failed to upload profile picture");
      }
    } catch (e) {
      print("Error uploading profile picture: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload profile picture")),
      );
    }
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        dobController.text =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Profile"), backgroundColor: Colors.deepPurple),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _uploadProfilePic,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: profilePic != null
                          ? NetworkImage(profilePic!)
                          : AssetImage("assets/default-avatar.png") as ImageProvider,
                      child: profilePic == null
                          ? Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                          : null,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text("Tap to change profile picture", style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 20),

                  // Username
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(labelText: "Username", border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 10),

                  // Mobile
                  TextField(
                    controller: mobileController,
                    decoration: InputDecoration(labelText: "Mobile Number", border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 10),

                  // Date of Birth (with Date Picker)
                  TextField(
                    controller: dobController,
                    decoration: InputDecoration(
                      labelText: "Date of Birth",
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: _selectDate, // Open calendar on tap
                      ),
                    ),
                    readOnly: true, // Prevent manual typing
                  ),
                  SizedBox(height: 10),

                  // Address
                  TextField(
                    controller: addressController,
                    decoration: InputDecoration(labelText: "Address", border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                  SizedBox(height: 20),

                  // Update Profile Button
                  ElevatedButton(
                    onPressed: _updateProfile,
                    child: Text("Save Changes"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                  ),
                ],
              ),
            ),
    );
  }
}
