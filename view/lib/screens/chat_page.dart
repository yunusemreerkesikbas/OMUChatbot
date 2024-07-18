import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:view/const/project_utilities.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];
  bool _isLoading = false;
  String role = 'user';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool('isLoggedIn');
    role = prefs.getString('role') ?? 'user';

    if (isLoggedIn == null || !isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  String cleanResponse(String response) {
    return response.replaceAll('<Pad>', '').replaceAll('<EOS>', '').trim();
  }

  Future<void> _sendRequest(String question) async {
    setState(() {
      _isLoading = true;
      messages.add({'question': question, 'response': 'loading'}); // Add loading state
    });

    final url = Uri.parse('${ProjectUtilities.portName}/ask');
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
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
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(vertical: 5),
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
                    style: const TextStyle(color: Colors.white),
                  )
                : message == 'loading'
                    ? const SizedBox(
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
                            style: const TextStyle(color: Colors.black),
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
            ),
            if (role == 'admin')
              IconButton(
                icon: const Icon(Icons.admin_panel_settings),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, role == 'admin' ? '/admin' : '/chat');
                },
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          width: 600,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('assets/omu.jpg'), // OMÜ logosu yolu
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
                          _buildMessageBubble('You: ${messages[index]['question']}', true),
                          _buildMessageBubble('${messages[index]['response']}', false),
                        ],
                      );
                    },
                  ),
                ),
              ),
              messages.isNotEmpty ? CustomRow(message: messages[messages.length - 1]) : const SizedBox.shrink(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Enter your message...',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            _sendRequest(value.toString());
                            _controller.clear();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
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

class CustomRow extends StatefulWidget {
  const CustomRow({
    super.key,
    required this.message,
  });

  final Map<String, String> message;

  @override
  State<CustomRow> createState() => _CustomRowState();
}

class _CustomRowState extends State<CustomRow> {
  bool isThumbsUpClicked = false;
  bool isThumbsDownClicked = false;
  String _text = 'Bu değerlendirme faydalı oldu mu?';

  Future<void> _addUnsuccessfulQuestion(String question) async {
    final url = Uri.parse('${ProjectUtilities.portName}/qa/');
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };
    final body = jsonEncode({'question': question, 'answer': '---'});

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (!(response.statusCode == 200)) {
        _showSnackBar("Lütfen Tekrar Deneyiniz");
      } else {
        _showSnackBar('Şikayetiniz tarafımıza iletilmiştir.');
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return Container(
      height: height * 0.05,
      width: width * 0.97,
      decoration: ShapeDecoration(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(Radius.circular(15)),
              side: BorderSide(color: Colors.grey.shade600, width: 1.5, strokeAlign: BorderSide.strokeAlignCenter))),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            _text,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          IconButton(
            icon: const Icon(Icons.thumb_up, color: Colors.green),
            onPressed: () {
              _showSnackBar('Bizi tercih ettiğiniz için teşekkür ederiz');
            },
          ),
          IconButton(
            icon: const Icon(Icons.thumb_down, color: Colors.red),
            onPressed: () {
              _addUnsuccessfulQuestion(widget.message.values.first.toString());
            },
          ),
        ],
      ),
    );
  }
}
