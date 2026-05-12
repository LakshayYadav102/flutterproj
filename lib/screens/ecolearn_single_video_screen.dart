import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ecolearn_feed_screen.dart'; // Imports your optimized FeedVideoPlayer

class EcoLearnSingleVideoScreen extends StatefulWidget {
  final Map<String, dynamic> videoData;

  const EcoLearnSingleVideoScreen({super.key, required this.videoData});

  @override
  State<EcoLearnSingleVideoScreen> createState() =>
      _EcoLearnSingleVideoScreenState();
}

class _EcoLearnSingleVideoScreenState extends State<EcoLearnSingleVideoScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FeedVideoPlayer(
        videoData: widget.videoData,
        currentUserId: _userId,
        isVisible: true, // Always true since it's the only video on screen
      ),
    );
  }
}
