import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../api/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;

  Map<String, dynamic>? _user;
  String? _profilePic;
  String? _token;

  final _usernameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/profile'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _user = data;
          _usernameController.text = data['username'] ?? '';
          _mobileController.text = data['mobile'] ?? '';
          _dobController.text =
              data['dob'] != null ? data['dob'].toString().split('T')[0] : '';
          _addressController.text = data['address'] ?? '';

          if (data['profilePic'] != null) {
            String picUrl = data['profilePic'];
            _profilePic =
                picUrl.startsWith('http')
                    ? picUrl
                    : '${ApiService.baseUrl}$picUrl';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar("Failed to load profile", isError: true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isSaving = true);
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/api/profile'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': _usernameController.text,
          'mobile': _mobileController.text,
          'dob': _dobController.text,
          'address': _addressController.text,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar("Profile updated successfully!");
        _fetchProfile();
      } else {
        _showSnackBar("Failed to update profile", isError: true);
      }
    } catch (e) {
      _showSnackBar("Network error.", isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _uploadProfilePic() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null || _token == null) return;

    setState(() => _isUploading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/api/profile/upload'),
      );
      request.headers.addAll({'Authorization': 'Bearer $_token'});
      request.files.add(
        await http.MultipartFile.fromPath('profilePic', image.path),
      );

      var response = await request.send();
      if (response.statusCode == 200) {
        final resData = await response.stream.bytesToString();
        final data = jsonDecode(resData);
        setState(() {
          String picUrl = data['profilePic'];
          _profilePic =
              picUrl.startsWith('http')
                  ? picUrl
                  : '${ApiService.baseUrl}$picUrl';
        });
        _showSnackBar("Profile picture updated!");
      } else {
        _showSnackBar("Failed to upload image", isError: true);
      }
    } catch (e) {
      _showSnackBar("Network error during upload", isError: true);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Profile"),
          backgroundColor: Colors.green[700],
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Your Profile"),
        backgroundColor: Colors.green[700],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // GreenCoin Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.green[300]!, width: 2),
              ),
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      "🪙 ${_user?['greenCoins'] ?? 0} GreenCoins",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Your universal GreenVerse currency. Earn more by offsetting carbon, sharing rides, and rescuing food!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Main Profile Form Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Avatar Upload
                    GestureDetector(
                      onTap: _uploadProfilePic,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[300],
                            backgroundImage:
                                _profilePic != null
                                    ? NetworkImage(_profilePic!)
                                    : null,
                            child:
                                _profilePic == null
                                    ? const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.white,
                                    )
                                    : null,
                          ),
                          if (_isUploading)
                            const CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Tap to update photo",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 30),

                    // Form Fields
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: "Username",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Mobile Number",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _dobController,
                      decoration: const InputDecoration(
                        labelText: "Date of Birth (YYYY-MM-DD)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: "Address",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                        ),
                        onPressed: _isSaving ? null : _updateProfile,
                        child:
                            _isSaving
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  "Save Changes",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
