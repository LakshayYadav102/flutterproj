import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import 'ngo_map_screen.dart'; // Ensure this import is correct

class DonationScreen extends StatefulWidget {
  final String userId;

  const DonationScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _DonationScreenState createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  double lifetimeCarbon = 0;
  int treesNeeded = 0;
  int treesPlanted = 0;
  String amount = '';
  String transactionId = '';
  String message = '';
  List<dynamic> donationHistory = [];
  bool isLoading = true;
  String error = '';
  String activeSection = 'overview';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      error = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        setState(() {
          error = 'User not logged in';
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to continue')),
        );
        return;
      }

      final headers = {'Authorization': 'Bearer $token'};
      final baseUrl = ApiService.baseUrl;

      final responses = await Future.wait([
        http.get(
          Uri.parse('$baseUrl/api/donations/lifetime-carbon/${widget.userId}'),
          headers: headers,
        ),
        http.get(
          Uri.parse('$baseUrl/api/donations/trees-needed/${widget.userId}'),
          headers: headers,
        ),
        http.get(
          Uri.parse('$baseUrl/api/donations/history/${widget.userId}'),
          headers: headers,
        ),
      ]);

      setState(() {
        lifetimeCarbon =
            jsonDecode(responses[0].body)['lifetimeCarbon']?.toDouble() ?? 0;
        treesNeeded = jsonDecode(responses[1].body)['treesNeeded'] ?? 0;
        donationHistory = jsonDecode(responses[2].body)['donations'] ?? [];
        treesPlanted = donationHistory.fold(
          0,
          (sum, d) => sum + (d['treesSponsored'] as int? ?? 0),
        );
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load data. Please try again later.';
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load data')));
    }
  }

  Future<void> submitTransaction() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null ||
        amount.isEmpty ||
        double.tryParse(amount) == null ||
        double.parse(amount) < 100 ||
        transactionId.isEmpty) {
      setState(() {
        message =
            'Please enter a valid amount (minimum ₹100) and transaction ID';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid input')));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/donations/submit-transaction'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': widget.userId,
          'amount': double.parse(amount),
          'transactionId': transactionId,
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          message =
              jsonDecode(response.body)['message'] ??
              '🎉 Transaction submitted successfully!';
          amount = '';
          transactionId = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction submitted successfully')),
        );
        await fetchData(); // Refresh data
      } else {
        setState(() {
          message =
              jsonDecode(response.body)['error'] ??
              '❌ Transaction submission failed.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction submission failed')),
        );
      }
    } catch (e) {
      setState(() {
        message = '❌ Transaction submission failed.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction submission failed')),
      );
    }
  }

  int calculateTreesFromAmount() {
    return double.tryParse(amount) != null
        ? (double.parse(amount) / 100).floor()
        : 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Dashboard'),
        backgroundColor:
            isDarkMode ? Colors.deepPurple[800] : Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Row(
                children: [
                  // Sidebar
                  Container(
                    width:
                        MediaQuery.of(context).size.width *
                        0.3, // Responsive width
                    color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                    child: ListView(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.dashboard),
                          title: const Text('Overview'),
                          selected: activeSection == 'overview',
                          onTap:
                              () => setState(() => activeSection = 'overview'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.monetization_on),
                          title: const Text('Donate'),
                          selected: activeSection == 'donate',
                          onTap: () => setState(() => activeSection = 'donate'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.history),
                          title: const Text('History'),
                          selected: activeSection == 'history',
                          onTap:
                              () => setState(() => activeSection = 'history'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.map),
                          title: const Text('NGO Map'),
                          selected: activeSection == 'map',
                          onTap: () => setState(() => activeSection = 'map'),
                        ),
                      ],
                    ),
                  ),
                  // Main Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (activeSection == 'overview') ...[
                            _buildOverviewCard(),
                          ],
                          if (activeSection == 'donate') ...[
                            _buildDonationCard(),
                            const SizedBox(height: 16),
                            _buildWhyDonateCard(),
                          ],
                          if (activeSection == 'history') ...[
                            _buildHistoryCard(),
                          ],
                          if (activeSection == 'map') ...[
                            Card(
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Explore Our NGO Partners',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed:
                                          () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      const NgoMapScreen(),
                                            ),
                                          ),
                                      child: const Text('View NGO Map'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          _buildCalculationCard(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildOverviewCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Offset Your Carbon Footprint',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Lifetime Carbon Footprint: ${lifetimeCarbon.toStringAsFixed(2)} kg CO₂',
            ),
            Text('Trees Needed to Offset: $treesNeeded'),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: treesNeeded > 0 ? treesPlanted / treesNeeded : 0,
              backgroundColor: Colors.grey[300],
              color: Colors.green,
            ),
            Text(
              '${treesNeeded > 0 ? ((treesPlanted / treesNeeded) * 100).round() : 0}% Offset',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => activeSection = 'donate'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Make a Donation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Donate to Offset',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Donation Amount (₹)',
                hintText: 'Enter amount (minimum ₹100)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() => amount = value),
            ),
            if (double.tryParse(amount) != null &&
                double.parse(amount) >= 100) ...[
              const SizedBox(height: 16),
              const Text('Scan to Pay', style: TextStyle(fontSize: 16)),
              QrImageView(
                data:
                    'upi://pay?pa=lakshay9718@okhdfcbank&pn=Lakshay&am=$amount&cu=INR',
                size: 200,
              ),
              const Text('UPI ID: lakshay9718@okhdfcbank'),
            ],
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Transaction ID',
                hintText: 'Enter transaction ID',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => transactionId = value),
            ),
            const SizedBox(height: 16),
            Text(
              'Your ₹${amount.isEmpty ? '0' : amount} donation will plant approximately ${calculateTreesFromAmount()} trees!',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  double.tryParse(amount) != null &&
                          double.parse(amount) >= 100 &&
                          transactionId.isNotEmpty
                      ? submitTransaction
                      : null,
              child: const Text('Submit Transaction'),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  color:
                      message.contains('successfully')
                          ? Colors.green
                          : Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWhyDonateCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Why Donate?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your donations fund initiatives to combat climate change and promote sustainability:',
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.park),
              title: const Text('Tree Planting (70%)'),
              subtitle: const Text(
                'Funds planting in deforested areas and urban spaces.',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.forest),
              title: const Text('Reforestation (20%)'),
              subtitle: const Text('Restores ecosystems with verified NGOs.'),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Operational Costs (10%)'),
              subtitle: const Text('Ensures transparency and monitoring.'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Your Donation History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            donationHistory.isEmpty
                ? const Text('No donations yet. Start your eco journey today!')
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: donationHistory.length,
                  itemBuilder: (context, index) {
                    final donation = donationHistory[index];
                    return ListTile(
                      leading: const Icon(Icons.monetization_on),
                      title: Text(
                        '₹${donation['amount']} on ${DateTime.parse(donation['date']).toLocal().toString().split(' ')[0]}',
                      ),
                      subtitle: Text(
                        'Transaction ID: ${donation['transactionId'] ?? 'N/A'}',
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'How We Calculate Trees Needed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Lifetime Carbon Footprint: ${lifetimeCarbon.toStringAsFixed(2)} kg CO₂',
            ),
            Text(
              'We estimate trees needed using: Trees = Carbon Footprint ÷ 21 kg CO₂/tree',
            ),
            Text(
              'For you: ${lifetimeCarbon.toStringAsFixed(2)} kg ÷ 21 ≈ $treesNeeded trees',
            ),
          ],
        ),
      ),
    );
  }
}
