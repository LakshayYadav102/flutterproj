import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';

class HouseholdDonationFormScreen extends StatefulWidget {
  const HouseholdDonationFormScreen({super.key});

  @override
  _HouseholdDonationFormScreenState createState() =>
      _HouseholdDonationFormScreenState();
}

class _HouseholdDonationFormScreenState
    extends State<HouseholdDonationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMsg = "";

  // Form State
  String _foodCategory = "";
  String _foodType = "";
  final _qtyCtrl = TextEditingController();
  String _unit = "kg";
  DateTime? _expiryTime;
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // 🟢 THE FIX: State variable for the missing backend field
  String _expiredHandling =
      "COMPOST"; // Change to "compost" if your backend expects lowercase

  // Typing Effect States
  String _quoteText = "";
  int _quoteIndex = 0;
  bool _isDeleting = false;
  Timer? _typingTimer;

  final List<String> quotes = [
    "Small portions, massive impact.",
    "Every meal saved is a step toward zero-waste.",
    "Share your leftovers, nourish a neighbor.",
    "Don't let good food go bad.",
    "Your kitchen can be a source of hope.",
  ];

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _qtyCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _startTyping() {
    _typingTimer = Timer.periodic(
      Duration(milliseconds: _isDeleting ? 40 : 80),
      (timer) {
        if (!mounted) return;

        final fullQuote = quotes[_quoteIndex];

        setState(() {
          if (!_isDeleting) {
            if (_quoteText.length < fullQuote.length) {
              _quoteText = fullQuote.substring(0, _quoteText.length + 1);
            } else {
              _isDeleting = true;
              timer.cancel();
              Future.delayed(const Duration(seconds: 2), _startTyping);
            }
          } else {
            if (_quoteText.isNotEmpty) {
              _quoteText = fullQuote.substring(0, _quoteText.length - 1);
            } else {
              _isDeleting = false;
              _quoteIndex = (_quoteIndex + 1) % quotes.length;
              timer.cancel();
              Future.delayed(const Duration(milliseconds: 500), _startTyping);
            }
          }
        });
      },
    );
  }

  Future<void> _pickExpiryTime() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.amber[800]!),
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
            colorScheme: ColorScheme.light(primary: Colors.amber[800]!),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return;

    setState(() {
      _expiryTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_foodCategory.isEmpty || _foodType.isEmpty) {
      setState(() => _errorMsg = "Please select food category and type.");
      return;
    }

    if (_expiryTime == null) {
      setState(() => _errorMsg = "Please select an expiry time.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = "";
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // 🟢 THE FIX: Explicitly passing 'expiredHandling' in the JSON payload
      final payload = {
        "donationSource": "HOUSEHOLD",
        "foodCategory": _foodCategory,
        "foodType": _foodType,
        "quantity": double.tryParse(_qtyCtrl.text) ?? 0.0,
        "unit": _unit,
        "expiryTime": _expiryTime!.toIso8601String(),
        "location": _locationCtrl.text.trim(),
        "notes": _notesCtrl.text.trim(),
        "expiredHandling": _expiredHandling, // <-- Mongoose needs this!
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
            content: Text("Donation submitted successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _errorMsg =
              jsonDecode(response.body)['message'] ??
              "Failed to submit donation.";
        });
      }
    } catch (e) {
      setState(() => _errorMsg = "Network error. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

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

  InputDecoration _glassInputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withOpacity(0.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.amber.withOpacity(0.3), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.amber.withOpacity(0.3), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.amber[800]!, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber[50],
      appBar: AppBar(
        title: const Text(
          "FoodRescue",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.amber[800],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.amber[800],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Household Contribution",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Donate From Home",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$_quoteText|",
                      style: const TextStyle(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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

                          // Section 1: Food Details
                          const Text(
                            "🍲 Food Details",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Divider(height: 30),

                          _buildLabel("📂", "Food Category"),
                          DropdownButtonFormField<String>(
                            value: _foodCategory.isEmpty ? null : _foodCategory,
                            isExpanded: true,
                            decoration: _glassInputDecoration(
                              hint: "Select Category",
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: "cooked",
                                child: Text("Cooked Food"),
                              ),
                              DropdownMenuItem(
                                value: "raw",
                                child: Text("Raw Ingredients"),
                              ),
                              DropdownMenuItem(
                                value: "packaged",
                                child: Text("Packaged Food"),
                              ),
                            ],
                            onChanged:
                                (v) => setState(() => _foodCategory = v!),
                          ),
                          const SizedBox(height: 16),

                          _buildLabel("🥗", "Food Type"),
                          DropdownButtonFormField<String>(
                            value: _foodType.isEmpty ? null : _foodType,
                            isExpanded: true,
                            decoration: _glassInputDecoration(
                              hint: "Select Type",
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: "veg",
                                child: Text("Vegetarian"),
                              ),
                              DropdownMenuItem(
                                value: "non-veg",
                                child: Text("Non-Vegetarian"),
                              ),
                              DropdownMenuItem(
                                value: "mixed",
                                child: Text("Mixed"),
                              ),
                            ],
                            onChanged: (v) => setState(() => _foodType = v!),
                          ),
                          const SizedBox(height: 16),

                          _buildLabel("⚖️", "Quantity"),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _qtyCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: _glassInputDecoration(
                                    hint: "e.g., 2.5",
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
                                  isExpanded: true,
                                  decoration: _glassInputDecoration(),
                                  items: const [
                                    DropdownMenuItem(
                                      value: "kg",
                                      child: Text("Kg"),
                                    ),
                                    DropdownMenuItem(
                                      value: "grams",
                                      child: Text("Grams"),
                                    ),
                                    DropdownMenuItem(
                                      value: "plates",
                                      child: Text("Plates"),
                                    ),
                                  ],
                                  onChanged: (v) => setState(() => _unit = v!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildLabel("⏳", "Expiry Date & Time"),
                          InkWell(
                            onTap: _pickExpiryTime,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.amber.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _expiryTime != null
                                        ? DateFormat(
                                          'yyyy-MM-dd HH:mm',
                                        ).format(_expiryTime!)
                                        : "Select Expiry Time",
                                    style: TextStyle(
                                      color:
                                          _expiryTime != null
                                              ? Colors.black87
                                              : Colors.grey[600],
                                      fontSize: 15,
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.amber[800],
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Section 2: Logistics
                          const Text(
                            "📍 Logistics & Notes",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Divider(height: 30),

                          _buildLabel("📍", "Pickup Location"),
                          TextFormField(
                            controller: _locationCtrl,
                            decoration: _glassInputDecoration(
                              hint: "Enter full pickup address",
                            ),
                            validator:
                                (val) => val!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 16),

                          // 🟢 THE UI FOR THE FIX: Expired Handling Dropdown
                          _buildLabel("♻️", "If food expires before pickup?"),
                          DropdownButtonFormField<String>(
                            value: _expiredHandling,
                            isExpanded: true,
                            decoration: _glassInputDecoration(),
                            items: const [
                              DropdownMenuItem(
                                value: "COMPOST",
                                child: Text("Send to Compost"),
                              ),
                              DropdownMenuItem(
                                value: "ANIMAL_FEED",
                                child: Text("Use for Animal Feed"),
                              ),
                              DropdownMenuItem(
                                value: "DISCARD",
                                child: Text("Discard Safely"),
                              ),
                            ],
                            onChanged:
                                (v) => setState(() => _expiredHandling = v!),
                          ),
                          const SizedBox(height: 16),

                          _buildLabel("📝", "Additional Notes (Optional)"),
                          TextFormField(
                            controller: _notesCtrl,
                            maxLines: 4,
                            decoration: _glassInputDecoration(
                              hint: "Any special instructions...",
                            ),
                          ),
                          const SizedBox(height: 30),

                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    side: BorderSide(color: Colors.amber[800]!),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    "← Back",
                                    style: TextStyle(
                                      color: Colors.amber[800],
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
                                    backgroundColor: Colors.amber[800],
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
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
                                            "Submit Donation →",
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
