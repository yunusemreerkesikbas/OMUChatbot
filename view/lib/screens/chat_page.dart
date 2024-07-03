import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:view/config/general_config.dart';

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
        leading: BackButton(
          onPressed: () {
            Navigator.pushNamed(context, "/login");
          },
        ),
        title: const Text('Chatbot'),
        centerTitle: true,
        backgroundColor: const Color(0xFF002D72), // OMÜ mavi rengi
      ),
      body: Center(
        child: Container(
          width: 600,
          child: Stack(
            children: [
              Center(
                child: GeneralMediaConfig().omuLogo,
              ),
              Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: MessagingConfig()
                          .chatBotmessageList(messages, _isLoading),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: GeneralTextfieldConfig()
                              .chatTextField(_controller, _sendRequest),
                        ),
                        const SizedBox(width: 8),
                        GeneralButtonConfig()
                            .sendMessageButton(_controller, _sendRequest),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
