import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';

class EventDonationFormScreen extends StatefulWidget {
  const EventDonationFormScreen({super.key});

  @override
  _EventDonationFormScreenState createState() =>
      _EventDonationFormScreenState();
}

class _EventDonationFormScreenState extends State<EventDonationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMsg = "";

  // Logic State - UNTOUCHED
  String _eventType = "marriage";
  final _eventNameCtrl = TextEditingController();
  String _foodType = "veg";
  final _qtyCtrl = TextEditingController();
  String _unit = "plates";

  DateTime? _windowStart;
  DateTime? _windowEnd;

  final _locationCtrl = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  final _contactNumberCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  Future<void> _pickDateTime(bool isStart) async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.orange[800]!),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;

    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.orange[800]!),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return;

    setState(() {
      DateTime finalDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (isStart) {
        _windowStart = finalDateTime;
      } else {
        _windowEnd = finalDateTime;
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_windowStart == null || _windowEnd == null) {
      setState(() => _errorMsg = "Please select both start and end times.");
      return;
    }
    if (_windowStart!.isAfter(_windowEnd!) ||
        _windowStart!.isAtSameMomentAs(_windowEnd!)) {
      setState(() => _errorMsg = "End time must be after start time.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = "";
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final payload = {
        "donationSource": "EVENT",
        "eventType": _eventType,
        "eventName": _eventNameCtrl.text.trim(),
        "foodCategory": "cooked",
        "foodType": _foodType,
        "quantity": int.tryParse(_qtyCtrl.text) ?? 0,
        "unit": _unit,
        "expiryTime": _windowEnd!.toIso8601String(),
        "location": _locationCtrl.text.trim(),
        "notes": _notesCtrl.text.trim(),
        "contactPerson": _contactPersonCtrl.text.trim(),
        "contactNumber": _contactNumberCtrl.text.trim(),
      };

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/food-donations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🎉 Donation created successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // Go back to dashboard
      } else {
        setState(
          () =>
              _errorMsg =
                  jsonDecode(response.body)['message'] ??
                  "Failed to submit donation",
        );
      }
    } catch (e) {
      setState(() => _errorMsg = "Network error. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- UI HELPERS ---
  Widget _buildLabel(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _customInputDecoration({String? hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: Colors.orange[700]) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.orange[800]!, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6), // Premium off-white background
      appBar: AppBar(
        title: const Text(
          "Event Donation",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange[800],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- HEADER SECTION ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.orange[800],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: const Column(
                children: [
                  Text(
                    "Large Scale Rescue",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Donate Event Surplus",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Have extra food from a wedding, party, or corporate event? Let NGOs know so they can pick it up in bulk.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMsg.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.red),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMsg,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // --- SECTION 1: EVENT DETAILS ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "🎉 Event Details",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Divider(height: 30),

                          _buildLabel("🏷️", "Event Type"),
                          DropdownButtonFormField<String>(
                            value: _eventType,
                            isExpanded: true,
                            decoration: _customInputDecoration(),
                            items: const [
                              DropdownMenuItem(
                                value: "marriage",
                                child: Text("Marriage / Wedding"),
                              ),
                              DropdownMenuItem(
                                value: "party",
                                child: Text("Birthday / Party"),
                              ),
                              DropdownMenuItem(
                                value: "religious",
                                child: Text("Religious Function"),
                              ),
                              DropdownMenuItem(
                                value: "corporate",
                                child: Text("Corporate / Office Event"),
                              ),
                              DropdownMenuItem(
                                value: "other",
                                child: Text("Other"),
                              ),
                            ],
                            onChanged: (v) => setState(() => _eventType = v!),
                          ),
                          const SizedBox(height: 16),

                          _buildLabel("🏢", "Event Name (Optional)"),
                          TextFormField(
                            controller: _eventNameCtrl,
                            decoration: _customInputDecoration(
                              hint: "e.g., Sharma Wedding",
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- SECTION 2: FOOD & TIMING ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "🍲 Food & Timing",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Divider(height: 30),

                          _buildLabel("🥗", "Food Type"),
                          DropdownButtonFormField<String>(
                            value: _foodType,
                            isExpanded: true,
                            decoration: _customInputDecoration(),
                            items: const [
                              DropdownMenuItem(
                                value: "veg",
                                child: Text("Pure Vegetarian"),
                              ),
                              DropdownMenuItem(
                                value: "non-veg",
                                child: Text("Non-Vegetarian"),
                              ),
                              DropdownMenuItem(
                                value: "mixed",
                                child: Text("Mixed (Veg + Non-Veg)"),
                              ),
                            ],
                            onChanged: (v) => setState(() => _foodType = v!),
                          ),
                          const SizedBox(height: 16),

                          _buildLabel("⚖️", "Estimated Quantity"),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _qtyCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: _customInputDecoration(
                                    hint: "e.g., 50",
                                  ),
                                  validator:
                                      (val) => val!.isEmpty ? "Required" : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: DropdownButtonFormField<String>(
                                  value: _unit,
                                  isExpanded:
                                      true, // ✅ FIX: Prevents the 1.3px overflow
                                  decoration: _customInputDecoration(),
                                  items: const [
                                    DropdownMenuItem(
                                      value: "plates",
                                      child: Text("Plates"),
                                    ),
                                    DropdownMenuItem(
                                      value: "kg",
                                      child: Text("Kg"),
                                    ),
                                  ],
                                  onChanged: (v) => setState(() => _unit = v!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildLabel("⏳", "Pickup Window"),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _pickDateTime(true),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          _windowStart == null
                                              ? Colors.red[50]
                                              : Colors.green[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            _windowStart == null
                                                ? Colors.red[200]!
                                                : Colors.green[300]!,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Start Time",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _windowStart != null
                                              ? DateFormat(
                                                'MMM dd, hh:mm a',
                                              ).format(_windowStart!)
                                              : "Select Start",
                                          style: TextStyle(
                                            color:
                                                _windowStart != null
                                                    ? Colors.black87
                                                    : Colors.red,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _pickDateTime(false),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          _windowEnd == null
                                              ? Colors.red[50]
                                              : Colors.orange[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            _windowEnd == null
                                                ? Colors.red[200]!
                                                : Colors.orange[300]!,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "End Time (Expiry)",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _windowEnd != null
                                              ? DateFormat(
                                                'MMM dd, hh:mm a',
                                              ).format(_windowEnd!)
                                              : "Select End",
                                          style: TextStyle(
                                            color:
                                                _windowEnd != null
                                                    ? Colors.black87
                                                    : Colors.red,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- SECTION 3: LOGISTICS & CONTACT ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "📍 Logistics & Contact",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Divider(height: 30),

                          _buildLabel("📍", "Event Location"),
                          TextFormField(
                            controller: _locationCtrl,
                            decoration: _customInputDecoration(
                              hint: "Enter full address",
                            ),
                            validator:
                                (val) => val!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel("👤", "Contact Person"),
                          TextFormField(
                            controller: _contactPersonCtrl,
                            decoration: _customInputDecoration(
                              hint: "Name of coordinator",
                            ),
                            validator:
                                (val) => val!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel("📞", "Contact Number"),
                          TextFormField(
                            controller: _contactNumberCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: _customInputDecoration(
                              hint: "Phone number for pickup",
                            ),
                            validator:
                                (val) => val!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel("📝", "Additional Notes (Optional)"),
                          TextFormField(
                            controller: _notesCtrl,
                            maxLines: 3,
                            decoration: _customInputDecoration(
                              hint:
                                  "Any special instructions for entry, parking, or packaging...",
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- ACTION BUTTONS ---
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.orange[800]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "← Back",
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[800],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _isLoading ? null : _handleSubmit,
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text(
                                      "Submit Event Donation →",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
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
