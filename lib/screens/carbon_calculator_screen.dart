import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Added for nice date formatting
import '../api/api_service.dart';

class CarbonCalculatorScreen extends StatefulWidget {
  const CarbonCalculatorScreen({super.key});

  @override
  _CarbonCalculatorScreenState createState() => _CarbonCalculatorScreenState();
}

class _CarbonCalculatorScreenState extends State<CarbonCalculatorScreen> {
  bool _isLoading = false;
  double? _carbonFootprint;

  // Date Range State
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  // Controllers & State (Removed default '0' for better UX)
  final _distanceController = TextEditingController();
  String _transportType = 'petrol';

  final _electricityController = TextEditingController();
  final _lpgController = TextEditingController();
  String _renewableEnergy = 'none';

  String _diet = 'vegetarian';
  final _clothingController = TextEditingController();
  final _screenTimeController = TextEditingController();

  @override
  void dispose() {
    _distanceController.dispose();
    _electricityController.dispose();
    _lpgController.dispose();
    _clothingController.dispose();
    _screenTimeController.dispose();
    super.dispose();
  }

  // Date Picker Function
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green[700]!,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _calculateAndSave() async {
    setState(() => _isLoading = true);

    try {
      // Parse inputs safely, defaulting to 0 if empty
      double distance = double.tryParse(_distanceController.text) ?? 0;
      double electricity = double.tryParse(_electricityController.text) ?? 0;
      double lpg = double.tryParse(_lpgController.text) ?? 0;
      double clothing = double.tryParse(_clothingController.text) ?? 0;
      double screenTime = double.tryParse(_screenTimeController.text) ?? 0;

      if (distance < 0 || electricity < 0 || lpg < 0) {
        _showSnackBar("Values cannot be negative.");
        setState(() => _isLoading = false);
        return;
      }

      // 1. Transport Calculation
      Map<String, double> emissionFactors = {
        'petrol': 0.21,
        'diesel': 0.24,
        'cng': 0.07,
        'two_wheeler': 0.09, // ✅ Added Two-Wheeler
        'bus': 0.03,
        'train': 0.01,
        'flight_short': 0.15,
        'flight_long': 0.20,
        'bicycle': 0,
        'walking': 0,
      };
      double transportCarbon =
          distance > 0 ? distance * (emissionFactors[_transportType] ?? 0) : 0;

      // 2. House Calculation
      double electricityCarbon = electricity * 0.85;
      double lpgCarbon = lpg * 2.98;
      Map<String, double> renewableReduction = {
        'solar': 0.5,
        'wind': 0.7,
        'hydro': 0.6,
        'none': 1.0,
      };
      double renewableFactor = renewableReduction[_renewableEnergy] ?? 1.0;
      double houseCarbon = (electricityCarbon + lpgCarbon) * renewableFactor;

      // 3. Lifestyle Calculation
      Map<String, double> dietFactors = {
        'vegetarian': 1.0,
        'non_vegetarian': 2.5,
        'vegan': 0.8,
        'pescatarian': 1.5,
      };
      double foodCarbon = dietFactors[_diet] ?? 1.0;
      double clothingCarbon = clothing * 5;
      double techCarbon = screenTime * 0.1;
      double lifestyleCarbon = foodCarbon + clothingCarbon + techCarbon;

      double totalFootprint = transportCarbon + houseCarbon + lifestyleCarbon;

      setState(() {
        _carbonFootprint = totalFootprint;
      });

      // Save to Backend
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId != null) {
        final activityData = {
          "fromDate":
              _startDate.toIso8601String(), // ✅ Uses selected start date
          "toDate": _endDate.toIso8601String(), // ✅ Uses selected end date
          "transportData": {
            "distance": distance,
            "transportType": _transportType,
          },
          "houseData": {
            "electricityUsage": electricity,
            "lpgUsage": lpg,
            "renewableEnergy": _renewableEnergy,
          },
          "lifestyleData": {
            "diet": _diet,
            "clothingPurchases": clothing,
            "screenTime": screenTime,
          },
          "carbonFootprint": totalFootprint,
          "userId": userId,
        };

        await http.post(
          Uri.parse('${ApiService.baseUrl}/api/activities/save'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(activityData),
        );
      }
    } catch (e) {
      _showSnackBar("Error saving data");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Carbon Calculator",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ Added Date Range Selector
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: const Icon(Icons.calendar_month, color: Colors.green),
                title: const Text(
                  "Select Activity Period",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}",
                  style: TextStyle(color: Colors.grey[700]),
                ),
                trailing: const Icon(Icons.edit, size: 20),
                onTap: () => _selectDateRange(context),
              ),
            ),
            const SizedBox(height: 10),

            // Transport Section
            Card(
              child: ExpansionTile(
                initiallyExpanded: true,
                leading: const Icon(Icons.directions_car, color: Colors.blue),
                title: const Text(
                  "Transportation",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _distanceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Distance traveled (km)",
                            hintText: "e.g., 50",
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _transportType,
                          decoration: const InputDecoration(
                            labelText: "Vehicle Type",
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'two_wheeler',
                              child: Text("Two-Wheeler (Bike/Scooter)"),
                            ), // ✅ Added
                            DropdownMenuItem(
                              value: 'petrol',
                              child: Text("Petrol Car"),
                            ),
                            DropdownMenuItem(
                              value: 'diesel',
                              child: Text("Diesel Car"),
                            ),
                            DropdownMenuItem(
                              value: 'cng',
                              child: Text("CNG Car"),
                            ),
                            DropdownMenuItem(value: 'bus', child: Text("Bus")),
                            DropdownMenuItem(
                              value: 'train',
                              child: Text("Train"),
                            ),
                            DropdownMenuItem(
                              value: 'flight_short',
                              child: Text("Flight (Short)"),
                            ),
                            DropdownMenuItem(
                              value: 'flight_long',
                              child: Text("Flight (Long)"),
                            ),
                            DropdownMenuItem(
                              value: 'bicycle',
                              child: Text("Bicycle"),
                            ),
                            DropdownMenuItem(
                              value: 'walking',
                              child: Text("Walking"),
                            ),
                          ],
                          onChanged:
                              (val) => setState(() => _transportType = val!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Household Section
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.home, color: Colors.orange),
                title: const Text(
                  "Household",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _electricityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Electricity Usage (kWh)",
                            hintText: "e.g., 150",
                          ),
                        ),
                        TextField(
                          controller: _lpgController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "LPG Usage (kg)",
                            hintText: "e.g., 14.2",
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _renewableEnergy,
                          decoration: const InputDecoration(
                            labelText: "Renewable Energy Source",
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'none',
                              child: Text("None"),
                            ),
                            DropdownMenuItem(
                              value: 'solar',
                              child: Text("Solar"),
                            ),
                            DropdownMenuItem(
                              value: 'wind',
                              child: Text("Wind"),
                            ),
                          ],
                          onChanged:
                              (val) => setState(() => _renewableEnergy = val!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Lifestyle Section
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.eco, color: Colors.green),
                title: const Text(
                  "Lifestyle",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _diet,
                          decoration: const InputDecoration(
                            labelText: "Diet Type",
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'vegetarian',
                              child: Text("Vegetarian"),
                            ),
                            DropdownMenuItem(
                              value: 'non_vegetarian',
                              child: Text("Non-Vegetarian"),
                            ),
                            DropdownMenuItem(
                              value: 'vegan',
                              child: Text("Vegan"),
                            ),
                            DropdownMenuItem(
                              value: 'pescatarian',
                              child: Text("Pescatarian"),
                            ),
                          ],
                          onChanged: (val) => setState(() => _diet = val!),
                        ),
                        TextField(
                          controller: _clothingController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "New Clothing Items Bought",
                            hintText: "e.g., 2",
                          ),
                        ),
                        TextField(
                          controller: _screenTimeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Daily Screen Time (hours)",
                            hintText: "e.g., 4",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _isLoading ? null : _calculateAndSave,
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        "Calculate My Footprint",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),

            if (_carbonFootprint != null) ...[
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Your Calculated Footprint",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${_carbonFootprint!.toStringAsFixed(2)} kg CO₂",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Data successfully saved to your profile!",
                      style: TextStyle(color: Colors.green[800], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
