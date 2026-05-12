import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../widgets/carpool_bottom_nav.dart';

class OfferRideScreen extends StatefulWidget {
  final Map<String, dynamic>? requestData;

  const OfferRideScreen({super.key, this.requestData});

  @override
  _OfferRideScreenState createState() => _OfferRideScreenState();
}

class _OfferRideScreenState extends State<OfferRideScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Vehicle
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();

  // Replaced TextEditingController with an integer state for dropdown
  int _totalSeats = 4;
  String _carType = "Sedan";
  String _fuelType = "Petrol";

  // Step 2: Trip
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _distanceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  int _seatsAvailable = 1;

  // Step 3: Prefs
  String _luggage = "None";
  bool _smoking = false;
  bool _pets = false;
  bool _carbonOffset = false;
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.requestData != null) {
      _fromCtrl.text = widget.requestData!['from'] ?? '';
      _toCtrl.text = widget.requestData!['to'] ?? '';
      _dateCtrl.text =
          widget.requestData!['date'] != null
              ? widget.requestData!['date'].split('T')[0]
              : '';
      _timeCtrl.text = widget.requestData!['time'] ?? '';
      if (widget.requestData!['seatsNeeded'] != null) {
        _seatsAvailable = widget.requestData!['seatsNeeded'];
      }
    }
  }

  // --- NEW: Native Date Picker ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal[800]!, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateCtrl.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // --- NEW: Native Time Picker ---
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.teal[800]!),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _timeCtrl.text =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _submitOffer() async {
    if (_makeCtrl.text.isEmpty ||
        _modelCtrl.text.isEmpty ||
        _plateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all Vehicle fields"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _currentStep = 0);
      return;
    }
    if (_fromCtrl.text.isEmpty ||
        _toCtrl.text.isEmpty ||
        _dateCtrl.text.isEmpty ||
        _timeCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all Trip fields"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _currentStep = 1);
      return;
    }

    setState(() => _isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      Map<String, dynamic> payload = {
        "vehicle": {
          "make": _makeCtrl.text,
          "model": _modelCtrl.text,
          "licensePlate": _plateCtrl.text,
          "carType": _carType,
          "totalSeats": _totalSeats, // Updated to use the integer state
          "fuelType": _fuelType,
        },
        "from": _fromCtrl.text,
        "to": _toCtrl.text,
        "date": _dateCtrl.text,
        "time": _timeCtrl.text,
        "seatsAvailable": _seatsAvailable,
        "pricePerSeat": double.tryParse(_priceCtrl.text) ?? 0,
        "distance": double.tryParse(_distanceCtrl.text) ?? 0,
        "estimatedDuration": _durationCtrl.text,
        "stops": [],
        "luggageSpace": _luggage,
        "smokingAllowed": _smoking,
        "petsAllowed": _pets,
        "additionalNotes": _notesCtrl.text,
        "carbonOffset": _carbonOffset,
      };

      if (widget.requestData != null) {
        payload["matchedRequest"] =
            widget.requestData!['_id'] ?? widget.requestData!['id'];
      }

      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/rides/offer'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🎉 Ride offered successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              jsonDecode(res.body)['error'] ?? 'Error offering ride',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Network Error"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.teal[700]),
      filled: true,
      fillColor: Colors.white, // Cleaned up background
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.teal[700]!, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text(
          "Offer a Ride",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal[800],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Theme(
        data: ThemeData(
          colorScheme: ColorScheme.light(primary: Colors.teal[700]!),
          canvasColor: Colors.transparent,
        ),
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          physics: const BouncingScrollPhysics(),
          controlsBuilder: (BuildContext context, ControlsDetails details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: details.onStepContinue,
                      child: Text(
                        _currentStep == 2 ? "Publish Ride" : "Continue",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 15),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: BorderSide(color: Colors.teal[700]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: details.onStepCancel,
                        child: Text(
                          "Back",
                          style: TextStyle(
                            color: Colors.teal[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() => _currentStep += 1);
            } else {
              _submitOffer();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep -= 1);
          },
          steps: [
            Step(
              title: const Text(
                "Vehicle Information",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Card(
                elevation: 2,
                shadowColor: Colors.grey.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _makeCtrl,
                        decoration: _inputDeco(
                          "Make (e.g. Toyota)",
                          Icons.directions_car,
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _modelCtrl,
                        decoration: _inputDeco(
                          "Model (e.g. Corolla)",
                          Icons.car_repair,
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _plateCtrl,
                        decoration: _inputDeco("License Plate", Icons.pin),
                      ),
                      const SizedBox(height: 15),

                      // ✅ UPDATED: Dropdown for Total Seats
                      DropdownButtonFormField<int>(
                        value: _totalSeats,
                        isExpanded: true,
                        decoration: _inputDeco(
                          "Total Seats",
                          Icons.airline_seat_recline_normal,
                        ),
                        items:
                            List.generate(8, (index) => index + 1).map((
                              int value,
                            ) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(value.toString()),
                              );
                            }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _totalSeats = newValue!;
                            // Prevent offering more seats than the car has
                            if (_seatsAvailable > _totalSeats) {
                              _seatsAvailable = _totalSeats;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 15),

                      // ✅ ADDED isExpanded to prevent UI breaking
                      DropdownButtonFormField<String>(
                        value: _carType,
                        isExpanded: true,
                        decoration: _inputDeco("Car Type", Icons.category),
                        items:
                            [
                                  "Sedan",
                                  "SUV",
                                  "Hatchback",
                                  "Van",
                                  "Electric",
                                  "Other",
                                ]
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _carType = v!),
                      ),
                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        value: _fuelType,
                        isExpanded: true,
                        decoration: _inputDeco(
                          "Fuel Type",
                          Icons.local_gas_station,
                        ),
                        items:
                            ["Petrol", "Diesel", "Electric", "Hybrid"]
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _fuelType = v!),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Step(
              title: const Text(
                "Trip Details",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Card(
                elevation: 2,
                shadowColor: Colors.grey.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      if (widget.requestData != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Trip pre-filled from community request.",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      TextFormField(
                        controller: _fromCtrl,
                        decoration: _inputDeco(
                          "From (City)",
                          Icons.my_location,
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _toCtrl,
                        decoration: _inputDeco("To (City)", Icons.location_on),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          // ✅ UPDATED: Native Date Picker
                          Expanded(
                            child: TextFormField(
                              controller: _dateCtrl,
                              readOnly: true,
                              onTap: () => _selectDate(context),
                              decoration: _inputDeco(
                                "Date",
                                Icons.calendar_today,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // ✅ UPDATED: Native Time Picker
                          Expanded(
                            child: TextFormField(
                              controller: _timeCtrl,
                              readOnly: true,
                              onTap: () => _selectTime(context),
                              decoration: _inputDeco("Time", Icons.access_time),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      // ✅ UPDATED: Changed label from $ to ₹
                      TextFormField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _inputDeco(
                          "Price per Seat (₹)",
                          Icons.currency_rupee,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ✅ FIXED OVERFLOW: Used Flexible and MainAxisSize.min
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Flexible(
                              child: Text(
                                "Seats Available:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.teal,
                                  ),
                                  onPressed:
                                      () => setState(
                                        () =>
                                            _seatsAvailable > 1
                                                ? _seatsAvailable--
                                                : null,
                                      ),
                                ),
                                Text(
                                  "$_seatsAvailable",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.teal,
                                  ),
                                  // Can't offer more seats than the car holds!
                                  onPressed:
                                      () => setState(
                                        () =>
                                            _seatsAvailable < _totalSeats
                                                ? _seatsAvailable++
                                                : null,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Step(
              title: const Text(
                "Preferences & Review",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              isActive: _currentStep >= 2,
              content: Card(
                elevation: 2,
                shadowColor: Colors.grey.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _luggage,
                        isExpanded: true,
                        decoration: _inputDeco("Luggage Space", Icons.work),
                        items:
                            ["None", "Small", "Medium", "Large"]
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _luggage = v!),
                      ),
                      const SizedBox(height: 15),
                      SwitchListTile(
                        title: const Text("Smoking Allowed"),
                        secondary: const Icon(
                          Icons.smoking_rooms,
                          color: Colors.grey,
                        ),
                        activeColor: Colors.teal,
                        value: _smoking,
                        onChanged: (v) => setState(() => _smoking = v),
                      ),
                      SwitchListTile(
                        title: const Text("Pets Allowed"),
                        secondary: const Icon(Icons.pets, color: Colors.grey),
                        activeColor: Colors.teal,
                        value: _pets,
                        onChanged: (v) => setState(() => _pets = v),
                      ),
                      SwitchListTile(
                        title: const Text(
                          "Carbon Offset Committed 🌱",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        secondary: const Icon(Icons.eco, color: Colors.green),
                        activeColor: Colors.green,
                        value: _carbonOffset,
                        onChanged: (v) => setState(() => _carbonOffset = v),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        decoration: _inputDeco("Additional Notes", Icons.note),
                      ),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(color: Colors.teal),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CarpoolBottomNav(currentIndex: 2),
    );
  }
}
