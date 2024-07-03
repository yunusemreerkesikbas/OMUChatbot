import "package:flutter/material.dart";
import "package:view/screens/chat_page.dart";
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class GeneralButtonConfig {
  TextButton signUpPageNavigateButton(context) {
    return TextButton(
      onPressed: () {
        Navigator.pushNamed(context, '/signup');
      },
      child: Text('Don\'t have an account? Sign up'),
    );
  }

  ElevatedButton loginNavigationButton(void login()) {
    return ElevatedButton(
      onPressed: login,
      child: Text('Login'),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  IconButton sendMessageButton(TextEditingController controller,
      Future<void> sendRequest(String question)) {
    return IconButton(
      icon: const Icon(Icons.send),
      color: const Color(0xFF002D72), // OMÜ mavi rengi
      onPressed: () {
        final question = controller.text;
        controller.clear();
        sendRequest(question);
      },
    );
  }
}

class MessagingConfig {
  Widget buildMessageBubble(context, String? message, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12.0),
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

  ListView chatBotmessageList(
      List<Map<String, String>> messages, bool _isLoading) {
    return ListView.builder(
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
              MessagingConfig().buildMessageBubble(
                  context, messages[index]['question'], true),
              const SizedBox(height: 8),
              MessagingConfig().buildMessageBubble(
                  context, messages[index]['response'], false),
              const SizedBox(height: 16),
            ],
          );
        }
      },
    );
  }
}

class GeneralMediaConfig {
  Container omuLogo = Container(
    alignment: Alignment.center,
    child: Opacity(
      opacity: 0.1,
      child: Image.asset(
        'assets/omu.jpg', // OMÜ logosunun yolu
      ),
    ),
  );
}

class GeneralTextfieldConfig {
  TextField chatTextField(TextEditingController controller,
      Future<void> sendRequest(String question)) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Enter your message',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      ),
      onSubmitted: (value) {
        final question = controller.text;
        controller.clear();
        sendRequest(question);
      },
    );
  }

  TextFormField emailTextFormField(TextEditingController emailController) {
    return TextFormField(
      controller: emailController,
      decoration: InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  TextFormField passwordtextFormField(
      TextEditingController passwordController) {
    return TextFormField(
      controller: passwordController,
      decoration: InputDecoration(
        labelText: 'Password',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        } else if (value.length < 6) {
          return 'Password must be at least 6 characters long';
        }
        return null;
      },
    );
  }
}

class TextConfig {
  Widget loginAndSignUpText(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
