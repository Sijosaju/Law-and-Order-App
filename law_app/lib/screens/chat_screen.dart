import 'package:flutter/material.dart';
import 'package:law_app/widgets/chat_bubble.dart';
import 'package:law_app/widgets/typing_indicator.dart';
import 'package:law_app/models/chat_message.dart'; // Added import
import 'dart:convert';
import 'package:http/http.dart' as http;


class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _typingController;
  List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text: "Hello! I'm Dharma,your AI legal assistant. How can I help you with your legal questions today?",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

void _sendMessage() {
  if (_messageController.text.trim().isEmpty) return;

  final userMessage = _messageController.text.trim();

  setState(() {
    _messages.add(ChatMessage(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _isTyping = true;
  });

  _messageController.clear();
  _typingController.repeat();
  _scrollToBottom();

  _getAIResponseFromBackend(userMessage).then((aiReply) {
    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(
        text: aiReply,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _typingController.stop();
    _scrollToBottom();
  });
}


Future<String> _getAIResponseFromBackend(String userMessage) async {
  final url = Uri.parse("https://law-and-order-app.onrender.com/chat");

  try {
    print("Sending request to: $url"); // Debug log
    print("Message: $userMessage"); // Debug log
    
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"message": userMessage}),
    );

    print("Response status: ${response.statusCode}"); // Debug log
    print("Response body: ${response.body}"); // Debug log

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["reply"] ?? "Sorry, I couldn't understand your question.";
    } else if (response.statusCode == 404) {
      return "⚠️ Chat endpoint not found. Backend might be sleeping or misconfigured.";
    } else {
      return "⚠️ Server error: ${response.statusCode}\nDetails: ${response.body}";
    }
  } catch (e) {
    print("Network error: $e"); // Debug log
    return "⚠️ Failed to connect: $e\nPlease check your internet connection.";
  }
}


  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF5B73FF)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dharma AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF00D4FF),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              Color(0xFF1A1D3A),
              Color(0xFF0A0E27),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return TypingIndicator(animation: _typingController);
                  }
                  return ChatBubble(message: _messages[index]);
                },
              ),
            ),
            // Chat Input Section (positioned above navigation bar)
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 90, // Increased to 90 to fully clear the navigation bar (60px height + 10px margin + shadow buffer)
              ),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1D3A).withOpacity(0.9),
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Ask your legal question...',
                            hintStyle: TextStyle(color: Colors.white60),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF00D4FF), Color(0xFF5B73FF)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF00D4FF).withOpacity(0.3),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}