import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import 'ngo_map_screen.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  _DonationScreenState createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  bool _isLoading = true;
  String _error = '';
  String? _userId;

  // Stats
  String _lifetimeCarbon = "0";
  int _treesNeeded = 0;
  int _treesPlanted = 0;
  List<dynamic> _donationHistory = [];

  // Form
  final _amountController = TextEditingController();
  final _transactionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');

    if (_userId == null) {
      setState(() {
        _error = "User not logged in";
        _isLoading = false;
      });
      return;
    }

    try {
      final carbonRes = await http.get(
        Uri.parse(
          '${ApiService.baseUrl}/api/donations/lifetime-carbon/$_userId',
        ),
      );
      final treesRes = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/donations/trees-needed/$_userId'),
      );
      final historyRes = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/donations/history/$_userId'),
      );

      int calculatedTrees = 0;
      List<dynamic> history = [];

      if (historyRes.statusCode == 200) {
        history = jsonDecode(historyRes.body)['donations'] ?? [];
        for (var d in history) {
          calculatedTrees += (d['treesSponsored'] as num?)?.toInt() ?? 0;
        }
        // Sort history newest first
        history.sort(
          (a, b) =>
              DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])),
        );
      }

      setState(() {
        _lifetimeCarbon =
            jsonDecode(carbonRes.body)['lifetimeCarbon']?.toString() ?? "0";
        _treesNeeded = jsonDecode(treesRes.body)['treesNeeded'] ?? 0;
        _donationHistory = history;
        _treesPlanted = calculatedTrees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load data";
        _isLoading = false;
      });
    }
  }

  Future<void> _submitTransaction() async {
    double? amount = double.tryParse(_amountController.text);
    String txId = _transactionController.text.trim();

    if (amount == null || amount < 100 || txId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter valid amount (Min ₹100) and Transaction ID",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/donations/submit-transaction'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": _userId,
          "amount": amount,
          "transactionId": txId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🎉 Transaction submitted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        _amountController.clear();
        _transactionController.clear();
        _fetchData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              jsonDecode(response.body)['error'] ?? "Failed to submit",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Network error."),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }
    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 16),
              Text(
                _error,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                ),
                child: const Text(
                  "Retry",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        appBar: AppBar(
          title: const Text(
            "Restoration Hub",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green[800],
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: "Overview"),
              Tab(icon: Icon(Icons.qr_code_scanner), text: "Donate"),
              Tab(icon: Icon(Icons.history), text: "History"),
              Tab(icon: Icon(Icons.map), text: "NGO Map"),
            ],
          ),
        ),
        body: TabBarView(
          physics:
              const NeverScrollableScrollPhysics(), // Prevents map swiping conflict
          children: [
            _buildOverviewTab(),
            _buildDonateTab(),
            _buildHistoryTab(),
            const NgoMapScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    double progress = _treesNeeded > 0 ? (_treesPlanted / _treesNeeded) : 0;
    if (progress > 1.0) progress = 1.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 2,
            shadowColor: Colors.grey.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    "Your Offset Progress",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statCol(
                        Icons.co2,
                        "Footprint",
                        "$_lifetimeCarbon kg",
                        Colors.red[600]!,
                      ),
                      Container(height: 40, width: 1, color: Colors.grey[300]),
                      _statCol(
                        Icons.flag,
                        "Goal",
                        "$_treesNeeded Trees",
                        Colors.orange[600]!,
                      ),
                      Container(height: 40, width: 1, color: Colors.grey[300]),
                      _statCol(
                        Icons.park,
                        "Planted",
                        "$_treesPlanted Trees",
                        Colors.green[600]!,
                      ),
                    ],
                  ),
                  const SizedBox(height: 35),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: Colors.grey[200],
                      color: Colors.green[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${(progress * 100).toInt()}% of your lifetime footprint offset",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            color: Colors.green[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.green.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calculate, color: Colors.green[700]),
                      const SizedBox(width: 10),
                      Text(
                        "The Math Behind The Offset",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "On average, a mature tree absorbs roughly 21 kg of CO₂ per year. We calculate your required offset by dividing your total footprint by this absorption rate.",
                    style: TextStyle(height: 1.5, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCol(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildDonateTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.nature_people, color: Colors.green[700], size: 28),
                  const SizedBox(width: 10),
                  const Text(
                    "Plant a Tree",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Donation Amount (₹)",
                  hintText: "Minimum ₹100",
                  prefixIcon: const Icon(Icons.currency_rupee),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() {}),
              ),
              const SizedBox(height: 24),

              if (_amountController.text.isNotEmpty &&
                  (double.tryParse(_amountController.text) ?? 0) >= 100)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Scan to Fund",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 15),
                      QrImageView(
                        data:
                            "upi://pay?pa=lakshay9718@okhdfcbank&pn=Lakshay&am=${_amountController.text}&cu=INR",
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "UPI: lakshay9718@okhdfcbank",
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              TextField(
                controller: _transactionController,
                decoration: InputDecoration(
                  labelText: "Transaction ID / UTR",
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(Icons.receipt_long),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isSubmitting ? null : _submitTransaction,
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            "Verify Transaction",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_donationHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volunteer_activism, size: 60, color: Colors.green[200]),
            const SizedBox(height: 16),
            const Text(
              "No donations found.\nStart your restoration journey!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _donationHistory.length,
      itemBuilder: (context, index) {
        final d = _donationHistory[index];
        final date = DateTime.parse(d['date']).toLocal();
        final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(date);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shadowColor: Colors.grey.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.park, color: Colors.green[700]),
              ),
              title: Text(
                "Sponsored ${d['treesSponsored'] ?? 0} Trees",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Txn: ${d['transactionId'] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              trailing: Text(
                "₹${d['amount']}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green[800],
                ),
              ),
              isThreeLine: true,
            ),
          ),
        );
      },
    );
  }
}
