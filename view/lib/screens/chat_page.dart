import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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

  Future<void> _sendRequest(String question) async {
    setState(() {
      _isLoading = true;
      messages.add({'question': question, 'response': ''});
    });

    final url = Uri.parse('http://127.0.0.1:8000/predict/');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'question': question});

    final response = await http.post(url, headers: headers, body: body);

    setState(() {
      _isLoading = false;
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        messages[messages.length - 1]['response'] = jsonResponse['response'];
      } else {
        messages[messages.length - 1]['response'] =
            'Error: ${response.statusCode}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OMÜ Chatbot'),
        centerTitle: true,
        backgroundColor: const Color(0xFF002D72), // OMÜ mavi rengi
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          width: 600,
          child: Stack(
            children: [
              Center(
                child: Container(
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: 0.05,
                    child: Image.asset(
                      'assets/omu.jpg', // OMÜ logosunun yolu
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: messages.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          return const Center(
                            child: SpinKitThreeBounce(
                              color: Color(0xFF002D72), // OMÜ mavi rengi
                              size: 30.0,
                            ),
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMessageBubble(
                                  messages[index]['question'], true),
                              const SizedBox(height: 8),
                              _buildMessageBubble(
                                  messages[index]['response'], false),
                              const SizedBox(height: 16),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                  _buildInputArea(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String? message, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(14.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF002D72)
              : Colors.grey[300], // OMÜ mavi rengi
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12.0),
            topRight: const Radius.circular(12.0),
            bottomLeft: Radius.circular(isUser ? 12.0 : 0.0),
            bottomRight: Radius.circular(isUser ? 0.0 : 12.0),
          ),
        ),
        child: Text(
          message ?? '',
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Mesajınızı giriniz...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 10.0, horizontal: 20.0),
              ),
              onSubmitted: (value) {
                final question = _controller.text;
                _controller.clear();
                _sendRequest(question);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            color: const Color(0xFF002D72), // OMÜ mavi rengi
            onPressed: () {
              final question = _controller.text;
              _controller.clear();
              _sendRequest(question);
            },
          ),
        ],
      ),
    );
  }
}
