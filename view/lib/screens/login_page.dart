import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:view/config/general_config.dart";

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _login() async {
    if(Platform.isIOS){
      
    }

    if (_formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? storedEmail = prefs.getString('email');
      String? storedPassword = prefs.getString('password');

      if (_emailController.text == storedEmail &&
          _passwordController.text == storedPassword) {
        await prefs.setBool('isLoggedIn', true);
        Navigator.pushReplacementNamed(context, '/chat');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid email or password')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(child: GeneralMediaConfig().omuLogo),
          Center(
            child: Container(
              width: 400,
              height: 400,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextConfig().loginAndSignUpText('OMU Chatbot Login'),
                    const SizedBox(height: 24),
                    GeneralTextfieldConfig()
                        .emailTextFormField(_emailController),
                    const SizedBox(height: 16),
                    GeneralTextfieldConfig()
                        .passwordtextFormField(_passwordController),
                    SizedBox(height: 16),
                    GeneralButtonConfig().loginNavigationButton(_login),
                    GeneralButtonConfig().signUpPageNavigateButton(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
