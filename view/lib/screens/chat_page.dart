import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool('isLoggedIn');

    if (isLoggedIn == null || !isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  String cleanResponse(String response) {
    return response.replaceAll('<Pad>', '').replaceAll('<EOS>', '').trim();
  }

  Future<void> _sendRequest(String question) async {
    setState(() {
      _isLoading = true;
      messages.add({'question': question, 'response': 'loading'}); // Add loading state
    });

    final url = Uri.parse('http://localhost:8000/ask/');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': '*/*',
    };
    final body = jsonEncode({'text': question});

    final response = await http.post(url, headers: headers, body: body);

    setState(() {
      _isLoading = false;
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        String cleanedResponse = cleanResponse(jsonResponse['answer']);
        messages[messages.length - 1]['response'] = cleanedResponse;
      } else {
        messages[messages.length - 1]['response'] = 'Error: ${response.statusCode}';
      }
    });
  }

  Widget _buildMessageBubble(String message, bool isUserMessage) {
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: isUserMessage ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isUserMessage
                ? Text(
              message,
              style: TextStyle(color: Colors.white),
            )
                : message == 'loading'
                ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
              ),
            ) // Show spinner
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(color: Colors.black),
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    Text('Bu değerlendirme faydalı oldu mu?'),
                    IconButton(
                      icon: Icon(Icons.thumb_up, color: Colors.green),
                      onPressed: () {
                        // Like button action
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.thumb_down, color: Colors.red),
                      onPressed: () {
                        // Dislike button action
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot'),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          width: 600,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/omu.jpg'), // OMÜ logosu yolu
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.1),
                BlendMode.dstATop,
              ),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMessageBubble(
                              'You: ${messages[index]['question']}', true),
                          _buildMessageBubble(
                              '${messages[index]['response']}', false),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Enter your message...',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            _sendRequest(value);
                            _controller.clear();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        if (_controller.text.isNotEmpty) {
                          _sendRequest(_controller.text);
                          _controller.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
