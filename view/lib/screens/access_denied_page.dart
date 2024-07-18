import 'package:flutter/material.dart';

class AccessDeniedPage extends StatelessWidget {
  const AccessDeniedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
      ),
      body: Center(
        child: Text(
          'Bu sayfaya erişiminiz yoktur',
          style: TextStyle(fontSize: 24, color: Colors.red),
        ),
      ),
    );
  }
}
