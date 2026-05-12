import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../widgets/ride_card.dart';
import '../widgets/carpool_bottom_nav.dart';

class FindRideScreen extends StatefulWidget {
  const FindRideScreen({super.key});

  @override
  _FindRideScreenState createState() => _FindRideScreenState();
}

class _FindRideScreenState extends State<FindRideScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  List<dynamic> _rides = [];
  List<dynamic> _myRequests = [];
  List<dynamic> _openRequests = [];

  bool _loadingRides = false;
  bool _loadingRequests = false;
  bool _loadingOpen = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');
    if (_userId != null) {
      _fetchRides();
      _fetchMyRequests();
      _fetchOpenRequests();
    }
  }

  String _getRequesterId(dynamic req) {
    if (req['requester'] is Map) {
      return req['requester']['_id']?.toString() ??
          req['requester']['id']?.toString() ??
          '';
    }
    return req['requester']?.toString() ?? '';
  }

  String _getRequesterName(dynamic req) {
    if (req['requester'] is Map) {
      return req['requester']['username'] ??
          req['requester']['name'] ??
          'Member';
    }
    return 'Member';
  }

  Future<void> _fetchRides() async {
    setState(() => _loadingRides = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      Map<String, String> qParams = {};
      if (_fromController.text.isNotEmpty)
        qParams['from'] = _fromController.text;
      if (_toController.text.isNotEmpty) qParams['to'] = _toController.text;
      if (_dateController.text.isNotEmpty)
        qParams['date'] = _dateController.text;

      final uri = Uri.parse(
        '${ApiService.baseUrl}/api/rides/find',
      ).replace(queryParameters: qParams);
      final res = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        setState(() => _rides = jsonDecode(res.body));
      }
    } catch (e) {
      print("Error fetching rides: $e");
    } finally {
      setState(() => _loadingRides = false);
    }
  }

  Future<void> _fetchMyRequests() async {
    setState(() => _loadingRequests = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/rides/requests?myRequests=true'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        setState(() => _myRequests = jsonDecode(res.body));
      }
    } catch (e) {
      print("Error fetching my requests: $e");
    } finally {
      setState(() => _loadingRequests = false);
    }
  }

  Future<void> _fetchOpenRequests() async {
    setState(() => _loadingOpen = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/rides/requests'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        List<dynamic> allRequests = jsonDecode(res.body);

        setState(() {
          _openRequests =
              allRequests.where((req) {
                return _getRequesterId(req) != _userId;
              }).toList();
        });
      }
    } catch (e) {
      print("Error fetching open requests: $e");
    } finally {
      setState(() => _loadingOpen = false);
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // ✅ FIX: Changed to POST and singular 'request' to match backend exactly
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/rides/request/$requestId/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request cancelled successfully"),
            backgroundColor: Colors.green,
          ),
        );
        _fetchMyRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to cancel request"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error cancelling request: $e");
    }
  }

  InputDecoration _customInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.teal[700]),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.teal[700]!, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        appBar: AppBar(
          title: const Text(
            "Find Your Perfect Ride",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.teal[800],
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.search), text: "Search Rides"),
              Tab(icon: Icon(Icons.list_alt), text: "My Requests"),
              Tab(icon: Icon(Icons.public), text: "Community Requests"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSearchTab(),
            _buildMyRequestsTab(),
            _buildCommunityRequestsTab(),
          ],
        ),
        bottomNavigationBar: const CarpoolBottomNav(currentIndex: 1),
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fromController,
                      decoration: _customInputDecoration(
                        label: "From",
                        icon: Icons.my_location,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _toController,
                      decoration: _customInputDecoration(
                        label: "To",
                        icon: Icons.location_on,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _dateController,
                      decoration: _customInputDecoration(
                        label: "Date (YYYY-MM-DD)",
                        icon: Icons.calendar_today,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _fetchRides,
                        child: const Icon(Icons.search, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _loadingRides
                  ? const Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  )
                  : _rides.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_car_filled_outlined,
                          size: 60,
                          color: Colors.teal[200],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No rides found.",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Try adjusting your search filters.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.only(top: 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _rides.length,
                    itemBuilder: (ctx, i) => RideCard(ride: _rides[i]),
                  ),
        ),
      ],
    );
  }

  Widget _buildMyRequestsTab() {
    if (_loadingRequests)
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    if (_myRequests.isEmpty)
      return const Center(
        child: Text(
          "You haven't made any requests yet.",
          style: TextStyle(color: Colors.grey),
        ),
      );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: _myRequests.length,
      itemBuilder: (ctx, i) {
        final req = _myRequests[i];
        bool isOpen = req['status'] == 'open' || req['status'] == 'pending';
        String reqId = req['_id'] ?? req['id'] ?? '';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.waving_hand, color: Colors.teal[700]),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${req['from']} → ${req['to']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Date: ${req['date'] != null ? req['date'].split('T')[0] : 'N/A'}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isOpen ? Colors.green[50] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (req['status'] ?? 'Unknown').toString().toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color:
                                isOpen ? Colors.green[800] : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOpen && reqId.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.redAccent),
                    onPressed: () => _cancelRequest(reqId),
                    tooltip: "Cancel Request",
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommunityRequestsTab() {
    if (_loadingOpen)
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    if (_openRequests.isEmpty)
      return const Center(
        child: Text(
          "No open community requests.",
          style: TextStyle(color: Colors.grey),
        ),
      );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: _openRequests.length,
      itemBuilder: (ctx, i) {
        final req = _openRequests[i];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.teal[100],
                      child: const Icon(Icons.person, color: Colors.teal),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${req['from']} → ${req['to']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Requested by: ${_getRequesterName(req)}",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/ride/offer',
                        arguments: req,
                      );
                    },
                    icon: const Icon(
                      Icons.local_taxi,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      "Offer Ride",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
