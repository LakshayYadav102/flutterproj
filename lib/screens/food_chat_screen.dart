import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:intl/intl.dart';
import '../api/api_service.dart';

class FoodChatScreen extends StatefulWidget {
  final String donationId;

  const FoodChatScreen({super.key, required this.donationId});

  @override
  _FoodChatScreenState createState() => _FoodChatScreenState();
}

class _FoodChatScreenState extends State<FoodChatScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _conversation;
  final TextEditingController _messageController = TextEditingController();
  late IO.Socket _socket;
  String? _userId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _startConversation();
  }

  Future<void> _startConversation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');
    String? token = prefs.getString('token');

    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/food-conversations/start'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"donationId": widget.donationId}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        setState(() {
          _conversation = data;
          _isLoading = false;
        });

        _initSocket(data['_id'], token);
        _scrollToBottom();
      } else {
        _showError("Failed to load chat.");
      }
    } catch (e) {
      _showError("Network error initializing chat.");
    }
  }

  void _initSocket(String conversationId, String? token) {
    _socket = IO.io(ApiService.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
    });

    _socket.connect();

    _socket.onConnect((_) {
      _socket.emit('joinFoodConversation', conversationId);
    });

    _socket.on('newFoodMessage', (data) {
      if (mounted) {
        setState(() {
          _conversation = data['conversation'];
        });
        _scrollToBottom();
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _conversation == null) return;

    _socket.emit('sendFoodMessage', {
      'conversationId': _conversation!['_id'],
      'senderId': _userId,
      'message': _messageController.text.trim(),
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String msg) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  @override
  void dispose() {
    if (_conversation != null) {
      _socket.disconnect();
      _socket.dispose();
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text(
          "Donation Chat",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange[800],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                )
                : _conversation == null
                ? const Center(child: Text("Could not load conversation."))
                : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        itemCount: (_conversation!['messages'] as List).length,
                        itemBuilder: (context, index) {
                          final msg = _conversation!['messages'][index];
                          final sender = msg['sender'];
                          final isMe = sender['_id'] == _userId;

                          return Align(
                            alignment:
                                isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.orange[800] : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(15),
                                  topRight: const Radius.circular(15),
                                  bottomLeft:
                                      isMe
                                          ? const Radius.circular(15)
                                          : const Radius.circular(0),
                                  bottomRight:
                                      isMe
                                          ? const Radius.circular(0)
                                          : const Radius.circular(15),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isMe
                                        ? "You"
                                        : (sender['username'] ?? "User"),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color:
                                          isMe
                                              ? Colors.white70
                                              : Colors.orange[800],
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    msg['message'] ?? "",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color:
                                          isMe ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    msg['timestamp'] != null
                                        ? DateFormat('hh:mm a').format(
                                          DateTime.parse(
                                            msg['timestamp'],
                                          ).toLocal(),
                                        )
                                        : '',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          isMe
                                              ? Colors.white54
                                              : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: "Type a message...",
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.orange[800],
                            radius: 24,
                            child: IconButton(
                              icon: const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _sendMessage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
