import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api/api_service.dart';
import '../widgets/ecolearn_bottom_nav.dart';
import 'ecolearn_single_video_screen.dart'; // ✅ Added import

class EcoLearnExploreScreen extends StatefulWidget {
  const EcoLearnExploreScreen({super.key});

  @override
  _EcoLearnExploreScreenState createState() => _EcoLearnExploreScreenState();
}

class _EcoLearnExploreScreenState extends State<EcoLearnExploreScreen> {
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _videos = [];

  String _selectedCategory = "All";
  String _sortType = "latest";
  final List<String> _categories = [
    "All",
    "Waste",
    "Energy",
    "Climate",
    "Food",
    "DIY",
    "Travel",
  ];

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      Map<String, String> qParams = {};
      if (_selectedCategory != "All") qParams['category'] = _selectedCategory;
      if (_sortType == "trending") qParams['sort'] = "trending";

      final uri = Uri.parse(
        '${ApiService.baseUrl}/api/ecolearn/explore',
      ).replace(queryParameters: qParams);
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        setState(() {
          _videos = jsonDecode(res.body) ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load videos";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Network error";
        _isLoading = false;
      });
    }
  }

  // Format high numbers like 1200 to 1.2k
  String _formatViews(dynamic views) {
    if (views == null) return "0 views";
    int v = views is int ? views : int.tryParse(views.toString()) ?? 0;
    if (v >= 1000) return "${(v / 1000).toStringAsFixed(1)}k views";
    return "$v views";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Explore",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Sort Toggle
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSortButton("Latest", "latest"),
                const SizedBox(width: 10),
                _buildSortButton("Trending", "trending"),
              ],
            ),
          ),

          // Categories Horizontal List
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Colors.green,
                    backgroundColor: Colors.grey[800],
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat);
                        _fetchVideos();
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // Video Grid
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    )
                    : _error.isNotEmpty
                    ? Center(
                      child: Text(
                        _error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                    : _videos.isEmpty
                    ? const Center(
                      child: Text(
                        "No videos found.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.7,
                          ),
                      itemCount: _videos.length,
                      itemBuilder: (context, index) {
                        final video = _videos[index];
                        return GestureDetector(
                          // ✅ FIXED: Navigation added
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => EcoLearnSingleVideoScreen(
                                      videoData: video,
                                    ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(10),
                              image: const DecorationImage(
                                image: AssetImage(
                                  'assets/images/home.jpg',
                                ), // Fallback thumbnail
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.8),
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "@${video['user']?['username'] ?? 'user'}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatViews(video['views']),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10,
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
                      },
                    ),
          ),
        ],
      ),
      bottomNavigationBar: const EcoLearnBottomNav(currentIndex: 1),
    );
  }

  Widget _buildSortButton(String label, String type) {
    bool isActive = _sortType == type;
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.green : Colors.grey[800],
          foregroundColor: isActive ? Colors.white : Colors.grey[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: isActive ? 2 : 0,
        ),
        onPressed: () {
          if (!isActive) {
            setState(() => _sortType = type);
            _fetchVideos();
          }
        },
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
