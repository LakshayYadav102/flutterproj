import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';

class MyReceivedFoodScreen extends StatefulWidget {
  const MyReceivedFoodScreen({super.key});

  @override
  _MyReceivedFoodScreenState createState() => _MyReceivedFoodScreenState();
}

class _MyReceivedFoodScreenState extends State<MyReceivedFoodScreen> {
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _received = [];
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _fetchReceivedFood();
  }

  Future<void> _fetchReceivedFood() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      setState(() {
        _error = "Not authenticated";
        _isLoading = false;
      });
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/food-donations/received'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _received = data['received'] ?? [];
          _summary = data['summary'];
          _error = '';
        });
      } else {
        setState(() => _error = "Failed to load received food.");
      }
    } catch (e) {
      setState(() => _error = "Network error.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _calculateCarbon(num quantity, String unit) {
    double kg = quantity.toDouble();
    if (unit == "grams") kg /= 1000;
    if (unit == "plates") kg *= 0.4;
    return kg * 2.5;
  }

  String _getFoodIcon(String? type) {
    String t = type?.toLowerCase() ?? "";
    if (t.contains("veg") && !t.contains("non")) return "🥗";
    if (t.contains("non-veg") || t.contains("meat")) return "🍗";
    if (t.contains("mixed")) return "🥘";
    return "🍱";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text(
          "My Received Food",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.pink[800],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.pink),
              )
              : _error.isNotEmpty
              ? Center(
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.pink[800],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: const Column(
              children: [
                Text(
                  "Retrieval History",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "My Received Food",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Track the donations you've accepted and your impact.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_summary != null)
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          "Retrievals",
                          "${_summary!['totalReceived']}",
                          Icons.handshake,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSummaryCard(
                          "Food Rescued",
                          "${_summary!['totalFoodReceivedKg']} kg",
                          Icons.scale,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSummaryCard(
                          "Waste Prevented",
                          "${_summary!['totalCarbonImpact']} kg",
                          Icons.public,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),

                if (_received.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.restaurant,
                          size: 60,
                          color: Colors.pink[200],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No received food yet.",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Browse available food to start making an impact.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                else
                  ..._received.map((d) {
                    double carbon =
                        (d['carbonSaved'] != null && d['carbonSaved'] > 0)
                            ? d['carbonSaved'].toDouble()
                            : _calculateCarbon(d['quantity'], d['unit']);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _getFoodIcon(d['foodType']),
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      d['foodCategory']
                                          .toString()
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                if (d['donationSource'] == 'EVENT')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purple[50],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      "🎊 EVENT",
                                      style: TextStyle(
                                        color: Colors.purple[800],
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const Divider(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${d['quantity']} ${d['unit']}",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.pink[700],
                                      ),
                                    ),
                                    Text(
                                      "Quantity • ${d['foodType']}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${carbon.toStringAsFixed(2)} kg",
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const Text(
                                      "CO₂ Saved",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "Donated by: ${d['donor']?['username'] ?? 'Anonymous'}",
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(
                                  Icons.timer,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "Received: ${DateTime.tryParse(d['updatedAt'] ?? '')?.toLocal() != null ? DateFormat('MMM dd, hh:mm a').format(DateTime.parse(d['updatedAt']).toLocal()) : 'N/A'}",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),

                            // ✅ FIXED ROUTING & ARGUMENTS HERE
                            if (d['status'] == 'ACCEPTED' &&
                                d['_id'] != null) ...[
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pink[700],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/food-waste/chat', // Correct Route
                                      arguments:
                                          d['_id']
                                              .toString(), // Correct Argument Type
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.chat_bubble,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "Message Donor",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String val,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            val,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
