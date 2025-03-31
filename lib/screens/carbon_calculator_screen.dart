import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CarbonCalculatorScreen extends StatefulWidget {
  @override
  _CarbonCalculatorScreenState createState() => _CarbonCalculatorScreenState();
}

class _CarbonCalculatorScreenState extends State<CarbonCalculatorScreen> {
  final TextEditingController _transportController = TextEditingController();
  final TextEditingController _electricityController = TextEditingController();
  final TextEditingController _lpgController = TextEditingController();
  final TextEditingController _clothingController = TextEditingController();
  final TextEditingController _screenTimeController = TextEditingController();

  String _selectedDiet = "Vegetarian";
  String? _carbonFootprint;
  String _errorMessage = "";
  bool _isLoading = false;
  DateTime? _fromDate;
  DateTime? _toDate;

  /// Select Date Function
  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  /// Carbon Emission Calculation
  double _calculateTotalEmission() {
    double transportEmission = (_transportController.text.isNotEmpty)
        ? double.parse(_transportController.text) * 0.12
        : 0;

    double electricityEmission = (_electricityController.text.isNotEmpty)
        ? double.parse(_electricityController.text) * 0.5
        : 0;

    double lpgEmission = (_lpgController.text.isNotEmpty)
        ? double.parse(_lpgController.text) * 2.5
        : 0;

    double clothingEmission = (_clothingController.text.isNotEmpty)
        ? double.parse(_clothingController.text) * 1.2
        : 0;

    double screenTimeEmission = (_screenTimeController.text.isNotEmpty)
        ? double.parse(_screenTimeController.text) * 0.05
        : 0;

    return transportEmission +
        electricityEmission +
        lpgEmission +
        clothingEmission +
        screenTimeEmission;
  }

  /// API Call to Calculate Carbon Footprint
 Future<void> _calculateCarbon() async {
   setState(() {
     _isLoading = true;
     _carbonFootprint = null;
     _errorMessage = "";
   });

   final url = Uri.parse("http://10.0.2.2:5000/api/activities/save");

   try {
     // Retrieve userId from SharedPreferences
     SharedPreferences prefs = await SharedPreferences.getInstance();
     String? userId = prefs.getString("userId");

     if (userId == null) {
       setState(() {
         _errorMessage = "User not logged in!";
         _isLoading = false;
       });
       return;
     }

     if (_fromDate == null || _toDate == null) {
       setState(() {
         _errorMessage = "Please select From and To dates.";
         _isLoading = false;
       });
       return;
     }

     double totalEmission = _calculateTotalEmission();

     final response = await http.post(
       url,
       headers: {
         "Content-Type": "application/json",
         "Accept": "application/json",
       },
       body: jsonEncode({
         "userId": userId,
         "fromDate": _fromDate!.toIso8601String(),
         "toDate": _toDate!.toIso8601String(),
         "transportData": {
           "distance": double.tryParse(_transportController.text) ?? 0
         },
         "houseData": {
           "electricityUsage": double.tryParse(_electricityController.text) ?? 0,
           "lpgUsage": double.tryParse(_lpgController.text) ?? 0
         },
         "lifestyleData": {
           "diet": _selectedDiet,
           "clothing": int.tryParse(_clothingController.text) ?? 0,
           "screen_time": double.tryParse(_screenTimeController.text) ?? 0
         },
         "carbonFootprint": totalEmission // ✅ Fixed Calculation
       }),
     );

     print("Response Code: ${response.statusCode}");
     print("Response Body: ${response.body}");

     if (response.statusCode == 201) {
       final data = jsonDecode(response.body);
       print("Parsed Response: $data"); // Debugging Log

       // ✅ Check if 'carbonFootprint' exists and is valid
       if (data.containsKey('carbonFootprint') && data['carbonFootprint'] != null) {
         setState(() {
           _carbonFootprint =
               "Carbon Footprint: ${data['carbonFootprint'].toString()} kg CO₂";
         });
       } else {
         setState(() {
           _carbonFootprint = "Carbon Footprint: Data not available";
         });
       }
     } else {
       setState(() {
         _errorMessage = "Error: ${response.statusCode} - ${response.body}";
       });
     }
   } catch (e) {
     setState(() {
       _errorMessage = "Error: ${e.toString()}";
     });
   } finally {
     setState(() {
       _isLoading = false;
     });
   }
 }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Carbon Calculator")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// Date Pickers
              TextButton(
                onPressed: () => _selectDate(context, true),
                child: Text(_fromDate != null
                    ? "From Date: ${_fromDate!.toLocal()}".split(' ')[0]
                    : "Select From Date"),
              ),
              TextButton(
                onPressed: () => _selectDate(context, false),
                child: Text(_toDate != null
                    ? "To Date: ${_toDate!.toLocal()}".split(' ')[0]
                    : "Select To Date"),
              ),

              /// Input Fields
              TextField(
                controller: _transportController,
                decoration: InputDecoration(labelText: "Transport Distance (km)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _electricityController,
                decoration: InputDecoration(labelText: "Electricity Usage (kWh)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _lpgController,
                decoration: InputDecoration(labelText: "LPG Usage (kg)"),
                keyboardType: TextInputType.number,
              ),

              /// Diet Dropdown
              DropdownButton<String>(
                value: _selectedDiet,
                items: ["Vegetarian", "Non-Vegetarian", "Vegan"]
                    .map((diet) => DropdownMenuItem(value: diet, child: Text(diet)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDiet = value!;
                  });
                },
              ),

              TextField(
                controller: _clothingController,
                decoration: InputDecoration(labelText: "Clothing Purchased (items)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _screenTimeController,
                decoration: InputDecoration(labelText: "Screen Time (hours/day)"),
                keyboardType: TextInputType.number,
              ),

              SizedBox(height: 20),

              /// Calculate Button
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _calculateCarbon,
                      child: Text("Calculate Carbon Footprint"),
                    ),

              /// Results Display
              if (_carbonFootprint != null)
                Text(_carbonFootprint!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (_errorMessage.isNotEmpty)
                Text(_errorMessage, style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}
