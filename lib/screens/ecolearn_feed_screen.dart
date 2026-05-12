import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../api/api_service.dart';
import '../widgets/comment_bottom_sheet.dart';
import '../widgets/ecolearn_bottom_nav.dart';

class EcoLearnFeedScreen extends StatefulWidget {
  const EcoLearnFeedScreen({super.key});

  @override
  _EcoLearnFeedScreenState createState() => _EcoLearnFeedScreenState();
}

class _EcoLearnFeedScreenState extends State<EcoLearnFeedScreen> {
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _videos = [];
  String? _userId;
  int _currentIndex = 0; // Tracks which video is currently on screen

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');
    String? token = prefs.getString('token');

    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/ecolearn/feed'),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (res.statusCode == 200) {
        setState(() {
          _videos = jsonDecode(res.body);
          _error = '';
          _isLoading = false;
        });
      } else {
        setState(() => _error = "Failed to load feed");
      }
    } catch (e) {
      setState(() => _error = "Network error");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    if (_isLoading) {
      bodyContent = const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    } else if (_error.isNotEmpty) {
      bodyContent = Center(
        child: Text(_error, style: const TextStyle(color: Colors.red)),
      );
    } else if (_videos.isEmpty) {
      bodyContent = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("🌱", style: TextStyle(fontSize: 60)),
            SizedBox(height: 20),
            Text(
              "No eco videos yet",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Be the first to share!",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    } else {
      bodyContent = PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: _videos.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index; // Updates the active video
          });
        },
        itemBuilder: (context, index) {
          return FeedVideoPlayer(
            videoData: _videos[index],
            currentUserId: _userId,
            isVisible: _currentIndex == index, // ✅ CRITICAL FOR PERFORMANCE
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "EcoLearn",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/ecolearn/explore'),
          ),
          IconButton(
            icon: const Icon(Icons.add_box, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/ecolearn/upload'),
          ),
        ],
      ),
      body: bodyContent,
      bottomNavigationBar: const EcoLearnBottomNav(currentIndex: 0),
    );
  }
}

class FeedVideoPlayer extends StatefulWidget {
  final Map<String, dynamic> videoData;
  final String? currentUserId;
  final bool isVisible; // Tells the player if it is currently on screen

  const FeedVideoPlayer({
    super.key,
    required this.videoData,
    this.currentUserId,
    required this.isVisible,
  });

  @override
  _FeedVideoPlayerState createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isLiked = false;
  int _likesCount = 0;
  bool _isMuted = false;

  // Animation Triggers
  bool _showMuteIcon = false;
  bool _showHeartIcon = false;
  bool _hasCountedView =
      false; // Ensures we only count the view once per session

  @override
  void initState() {
    super.initState();
    _isLiked = widget.videoData['userLiked'] ?? false;
    _likesCount = widget.videoData['likesCount'] ?? 0;

    String url = widget.videoData['videoUrl'];
    if (!url.startsWith('http')) {
      url = '${ApiService.baseUrl}$url';
    }

    _controller = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        if (widget.isVisible) {
          _controller.play();
          _incrementView();
        }
      });
  }

  // ✅ PERFORMANCE FIX: Play/Pause based on scroll visibility
  @override
  void didUpdateWidget(FeedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.play();
      _incrementView();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _controller.pause();
      _controller.seekTo(Duration.zero);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ✅ VIEWS FIX: Trigger backend to count views
  Future<void> _incrementView() async {
    if (_hasCountedView) return;
    _hasCountedView = true;
    try {
      await http.post(
        Uri.parse(
          '${ApiService.baseUrl}/api/ecolearn/view/${widget.videoData['_id']}',
        ),
      );
    } catch (e) {
      // Ignore silently
    }
  }

  // --- GESTURE CONTROLS ---

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
      _showMuteIcon = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showMuteIcon = false);
    });
  }

  void _onDoubleTap() {
    if (!_isLiked) {
      _handleLike();
    }
    setState(() => _showHeartIcon = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showHeartIcon = false);
    });
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _controller.pause();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (widget.isVisible) {
      _controller.play();
    }
  }

  Future<void> _handleLike() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to like videos")),
      );
      return;
    }

    setState(() {
      _isLiked = !_isLiked;
      _isLiked ? _likesCount++ : _likesCount--;
    });

    try {
      final res = await http.post(
        Uri.parse(
          '${ApiService.baseUrl}/api/ecolearn/like/${widget.videoData['_id']}',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _isLiked = data['liked'];
          _likesCount = data['totalLikes'];
        });
      }
    } catch (e) {
      // Revert on failure
      setState(() {
        _isLiked = !_isLiked;
        _isLiked ? _likesCount++ : _likesCount--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleMute, // Single tap to mute
      onDoubleTap: _onDoubleTap, // Double tap to like
      onLongPressStart: _onLongPressStart, // Hold to pause
      onLongPressEnd: _onLongPressEnd, // Release to play
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Layer
          if (_controller.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.green)),

          // Dark Gradient for readable text
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 250,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
            ),
          ),

          // Pop-up Animations
          if (_showMuteIcon)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),
          if (_showHeartIcon)
            Center(
              child: Icon(
                Icons.favorite,
                color: Colors.redAccent.withOpacity(0.9),
                size: 120,
              ),
            ),

          // Bottom Left User Info
          Positioned(
            bottom: 20,
            left: 15,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        '/ecolearn/creator',
                        arguments: widget.videoData['user']?['_id'],
                      ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey,
                        backgroundImage:
                            widget.videoData['user']?['profilePic'] != null
                                ? NetworkImage(
                                  widget.videoData['user']['profilePic']
                                          .startsWith('http')
                                      ? widget.videoData['user']['profilePic']
                                      : '${ApiService.baseUrl}${widget.videoData['user']['profilePic']}',
                                )
                                : null,
                        child:
                            widget.videoData['user']?['profilePic'] == null
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "@${widget.videoData['user']?['username'] ?? 'user'}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.videoData['caption'] ?? "",
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "#${widget.videoData['category']}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right Sidebar Actions
          Positioned(
            bottom: 20,
            right: 10,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Like Button
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : Colors.white,
                        size: 35,
                      ),
                      onPressed: _handleLike,
                    ),
                    Text(
                      "$_likesCount",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Comment Button
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: 35,
                      ),
                      onPressed:
                          () => CommentBottomSheet.show(
                            context,
                            widget.videoData['_id'],
                          ),
                    ),
                    Text(
                      "${widget.videoData['comments']?.length ?? 0}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
