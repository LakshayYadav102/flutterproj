import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api/api_service.dart';

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
  final TextEditingController _airTravelController = TextEditingController();
  final TextEditingController _wasteController = TextEditingController();
  final TextEditingController _waterController = TextEditingController();

  String _selectedDiet = "Vegetarian";
  String _selectedTransportType = "Petrol"; // Default transport type
  String _selectedRenewableEnergy = "None"; // Default renewable energy
  String? _carbonFootprint;
  String _errorMessage = "";
  bool _isLoading = false;
  DateTime? _fromDate;
  DateTime? _toDate;
  Map<String, double>? _emissionBreakdown;
  List<String>? _reductionTips;

  /// Emission Factors (kg CO₂ per unit)
  final Map<String, double> _emissionFactors = {
    "Petrol": 0.21, // kg CO₂ per km
    "Diesel": 0.24,
    "CNG": 0.07,
    "Bus": 0.03,
    "Train": 0.01,
    "Flight Short": 0.15, // Short-haul flight
    "Flight Long": 0.20, // Long-haul flight
    "Bicycle": 0.0,
    "Walking": 0.0,
  };

  final Map<String, double> _renewableReduction = {
    "Solar": 0.5, // 50% reduction
    "Wind": 0.7, // 30% reduction
    "Hydro": 0.6, // 40% reduction
    "None": 1.0, // No reduction
  };

  final Map<String, double> _dietFactors = {
    "Vegetarian": 1.0, // kg CO₂ per day
    "Non-Vegetarian": 2.5,
    "Vegan": 0.8,
    "Pescatarian": 1.5,
  };

  /// Select Date Function
  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green[700]!,
              onPrimary: Colors.white,
              surface: Colors.green[50]!,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.green[100],
          ),
          child: child!,
        );
      },
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

  /// Advanced Carbon Emission Calculation
  Map<String, double> _calculateTotalEmission() {
    double transportEmission =
        (_transportController.text.isNotEmpty)
            ? double.parse(_transportController.text) *
                (_emissionFactors[_selectedTransportType] ?? 0)
            : 0;

    double airTravelEmission =
        (_airTravelController.text.isNotEmpty)
            ? double.parse(_airTravelController.text) *
                (_selectedTransportType.contains("Flight")
                    ? _emissionFactors[_selectedTransportType] ?? 0
                    : 0)
            : 0;

    double electricityEmission =
        (_electricityController.text.isNotEmpty)
            ? double.parse(_electricityController.text) *
                0.85 // kg CO₂ per kWh (India avg)
            : 0;

    double lpgEmission =
        (_lpgController.text.isNotEmpty)
            ? double.parse(_lpgController.text) *
                2.98 // kg CO₂ per kg LPG
            : 0;

    double waterEmission =
        (_waterController.text.isNotEmpty)
            ? double.parse(_waterController.text) *
                0.001 // kg CO₂ per liter
            : 0;

    double renewableFactor =
        _renewableReduction[_selectedRenewableEnergy] ?? 1.0;
    double houseCarbon =
        (electricityEmission + lpgEmission + waterEmission) * renewableFactor;

    double wasteEmission =
        (_wasteController.text.isNotEmpty)
            ? double.parse(_wasteController.text) *
                0.7 // kg CO₂ per kg waste
            : 0;

    double dietEmission = _dietFactors[_selectedDiet] ?? 1.0;
    if (_fromDate != null && _toDate != null) {
      int days = _toDate!.difference(_fromDate!).inDays + 1;
      dietEmission *= days;
    }

    double clothingEmission =
        (_clothingController.text.isNotEmpty)
            ? double.parse(_clothingController.text) *
                5.0 // kg CO₂ per clothing item
            : 0;

    double screenTimeEmission =
        (_screenTimeController.text.isNotEmpty)
            ? double.parse(_screenTimeController.text) *
                0.1 // kg CO₂ per hour
            : 0;

    double lifestyleCarbon =
        dietEmission + clothingEmission + screenTimeEmission;

    return {
      "Transport": transportEmission + airTravelEmission,
      "Electricity": electricityEmission * renewableFactor,
      "LPG": lpgEmission * renewableFactor,
      "Water": waterEmission * renewableFactor,
      "Waste": wasteEmission,
      "Diet": dietEmission,
      "Clothing": clothingEmission,
      "Screen Time": screenTimeEmission,
      "Total":
          transportEmission +
          airTravelEmission +
          houseCarbon +
          wasteEmission +
          lifestyleCarbon,
    };
  }

  /// Generate Reduction Tips
  List<String> _generateReductionTips(double totalEmission) {
    List<String> tips = [];
    if (totalEmission > 50) {
      tips.add(
        "Consider switching to public transport or a bicycle for lower emissions.",
      );
    }
    if (_electricityController.text.isNotEmpty &&
        double.parse(_electricityController.text) > 100 &&
        _selectedRenewableEnergy == "None") {
      tips.add(
        "Adopt solar or wind energy to reduce your electricity footprint.",
      );
    }
    if (_selectedDiet == "Non-Vegetarian") {
      tips.add("Try more vegan or vegetarian meals to lower your food impact.");
    }
    if (_clothingController.text.isNotEmpty &&
        double.parse(_clothingController.text) > 5) {
      tips.add(
        "Buy second-hand clothing or reduce purchases to cut emissions.",
      );
    }
    return tips.isEmpty ? ["Your footprint is low—great job!"] : tips;
  }

  /// API Call to Calculate Carbon Footprint
  Future<void> _calculateCarbon() async {
    setState(() {
      _isLoading = true;
      _carbonFootprint = null;
      _errorMessage = "";
      _emissionBreakdown = null;
      _reductionTips = null;
    });

    final url = Uri.parse("${ApiService.baseUrl}/api/activities/save");

    try {
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

      Map<String, double> emissions = _calculateTotalEmission();
      double totalEmission = emissions["Total"]!;

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
            "distance": double.tryParse(_transportController.text) ?? 0,
            "transportType": _selectedTransportType,
            "airTravel": double.tryParse(_airTravelController.text) ?? 0,
          },
          "houseData": {
            "electricityUsage":
                double.tryParse(_electricityController.text) ?? 0,
            "lpgUsage": double.tryParse(_lpgController.text) ?? 0,
            "waterUsage": double.tryParse(_waterController.text) ?? 0,
            "renewableEnergy": _selectedRenewableEnergy,
          },
          "lifestyleData": {
            "diet": _selectedDiet,
            "clothing": int.tryParse(_clothingController.text) ?? 0,
            "screen_time": double.tryParse(_screenTimeController.text) ?? 0,
            "waste": double.tryParse(_wasteController.text) ?? 0,
          },
          "carbonFootprint": totalEmission,
        }),
      );

      print("Response Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _carbonFootprint =
              "Carbon Footprint: ${totalEmission.toStringAsFixed(2)} kg CO₂";
          _emissionBreakdown = emissions;
          _reductionTips = _generateReductionTips(totalEmission);
        });
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
      backgroundColor: Colors.green[50], // Light earthy background
      appBar: AppBar(
        title: Text(
          "Carbon Calculator",
          style: TextStyle(
            fontFamily: 'Roboto',
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green[800]!,
                Colors.green[600]!,
              ], // Forest gradient
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// Date Pickers
              _buildSectionCard(
                title: "Time Frame",
                children: [
                  _buildDateButton("From Date", _fromDate, true),
                  _buildDateButton("To Date", _toDate, false),
                ],
              ),

              /// Transport Section
              _buildSectionCard(
                title: "Transport",
                children: [
                  _buildDropdown(
                    "Transport Type",
                    _selectedTransportType,
                    _emissionFactors.keys.toList(),
                    Icons.directions_car,
                    (value) => setState(() => _selectedTransportType = value!),
                  ),
                  _buildTextField(
                    _transportController,
                    "Distance (km)",
                    Icons.directions,
                  ),
                  if (_selectedTransportType.contains("Flight"))
                    _buildTextField(
                      _airTravelController,
                      "Flight Distance (km)",
                      Icons.flight,
                    ),
                ],
              ),

              /// Household Section
              _buildSectionCard(
                title: "Household",
                children: [
                  _buildTextField(
                    _electricityController,
                    "Electricity (kWh)",
                    Icons.electrical_services,
                  ),
                  _buildDropdown(
                    "Renewable Energy",
                    _selectedRenewableEnergy,
                    _renewableReduction.keys.toList(),
                    Icons.eco,
                    (value) =>
                        setState(() => _selectedRenewableEnergy = value!),
                  ),
                  _buildTextField(
                    _lpgController,
                    "LPG (kg)",
                    Icons.local_gas_station,
                  ),
                  _buildTextField(
                    _waterController,
                    "Water (liters)",
                    Icons.water_drop,
                  ),
                  _buildTextField(_wasteController, "Waste (kg)", Icons.delete),
                ],
              ),

              /// Lifestyle Section
              _buildSectionCard(
                title: "Lifestyle",
                children: [
                  _buildDropdown(
                    "Diet",
                    _selectedDiet,
                    _dietFactors.keys.toList(),
                    Icons.fastfood,
                    (value) => setState(() => _selectedDiet = value!),
                  ),
                  _buildTextField(
                    _clothingController,
                    "Clothing (items)",
                    Icons.checkroom,
                  ),
                  _buildTextField(
                    _screenTimeController,
                    "Screen Time (hours/day)",
                    Icons.screen_lock_portrait,
                  ),
                ],
              ),

              SizedBox(height: 20),

              /// Calculate Button
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                child:
                    _isLoading
                        ? Center(
                          child: CircularProgressIndicator(
                            color: Colors.green[700],
                          ),
                        )
                        : ElevatedButton(
                          onPressed: _calculateCarbon,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 8,
                            shadowColor: Colors.green[400]!.withOpacity(0.5),
                          ),
                          child: Text(
                            "Calculate Carbon Footprint",
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'Roboto',
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
              ),

              SizedBox(height: 20),

              /// Results Display
              if (_carbonFootprint != null)
                _buildResultCard(
                  children: [
                    Text(
                      _carbonFootprint!,
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Roboto',
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Emission Breakdown",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.brown[900],
                        fontSize: 16,
                      ),
                    ),
                    if (_emissionBreakdown != null)
                      ..._emissionBreakdown!.entries
                          .where(
                            (entry) => entry.key != "Total" && entry.value > 0,
                          )
                          .map(
                            (entry) => Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                "${entry.key}: ${entry.value.toStringAsFixed(2)} kg CO₂",
                                style: TextStyle(color: Colors.brown[700]),
                              ),
                            ),
                          ),
                    SizedBox(height: 10),
                    Text(
                      "Reduction Tips",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.brown[900],
                        fontSize: 16,
                      ),
                    ),
                    if (_reductionTips != null)
                      ..._reductionTips!.map(
                        (tip) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            "- $tip",
                            style: TextStyle(color: Colors.brown[700]),
                          ),
                        ),
                      ),
                  ],
                ),
              if (_errorMessage.isNotEmpty)
                _buildResultCard(
                  children: [
                    Text(
                      _errorMessage,
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Roboto',
                        color: Colors.red[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Custom Widgets
  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'Roboto',
                color: Colors.green[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.green[700]),
          prefixIcon: Icon(icon, color: Colors.green[700]),
          filled: true,
          fillColor: Colors.green[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green[700]!, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green[300]!, width: 1),
          ),
        ),
        keyboardType: TextInputType.number,
        style: TextStyle(color: Colors.brown[900]),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    IconData icon,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        items:
            items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.green[700]),
          prefixIcon: Icon(icon, color: Colors.green[700]),
          filled: true,
          fillColor: Colors.green[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green[700]!, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green[300]!, width: 1),
          ),
        ),
        style: TextStyle(color: Colors.brown[900]),
        dropdownColor: Colors.green[100],
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, bool isFromDate) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: ElevatedButton(
        onPressed: () => _selectDate(context, isFromDate),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[100],
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: Colors.green[400]!.withOpacity(0.3),
        ),
        child: Text(
          date != null
              ? "$label: ${date.toLocal()}".split(' ')[0]
              : "Select $label",
          style: TextStyle(color: Colors.green[800], fontFamily: 'Roboto'),
        ),
      ),
    );
  }

  Widget _buildResultCard({required List<Widget> children}) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}
