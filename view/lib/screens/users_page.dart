import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:view/const/project_utilities.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<Map<String, String>> users = [];
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  var dio = Dio();
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    getUsers();
  }

  Future<void> _checkAdminAccess() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('role');
    if (role == 'admin') {
      setState(() {
        isAdmin = true;
      });
    } else {
      Navigator.pushReplacementNamed(context, '/access-denied');
    }
  }

  Future<void> getUsers() async {
    try {
      var response = await dio.get('${ProjectUtilities.portName}/users/');
      List<dynamic> contents = response.data;
      setState(() {
        users = contents.map((item) {
          return {
            'id': item['id'].toString(),
            'email': item['email'] as String,
            'role': item['role'] as String,
          };
        }).toList();
      });
    } on DioException catch (e) {
      if (e.response != null) {
        print(e.response!.data);
        print(e.response!.headers);
        print(e.response!.requestOptions);
      } else {
        print(e.message);
      }
    }
  }

  Future<void> addUser() async {
    try {
      var response = await dio.post(
        '${ProjectUtilities.portName}/users/',
        data: {
          'email': emailController.text,
          'password': passwordController.text,
        },
      );
      print(response.data);
      getUsers(); // Refresh list
    } on DioException catch (e) {
      if (e.response != null) {
        print(e.response!.data);
        print(e.response!.headers);
        print(e.response!.requestOptions);
      } else {
        print(e.message);
      }
    }
    setState(() {
      emailController.clear();
      passwordController.clear();
    });
  }

  Future<void> deleteUser(int index) async {
    try {
      var response = await dio.delete('${ProjectUtilities.portName}/users/del/${users[index]['id']}');
      print(response.data);
      getUsers(); // Refresh list
    } on DioException catch (e) {
      if (e.response != null) {
        print(e.response!.data);
        print(e.response!.headers);
        print(e.response!.requestOptions);
      } else {
        print(e.message);
      }
    }
  }

  Future<void> _signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
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
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/admin');
              },
            ),
            IconButton(
              icon: const Icon(Icons.people),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/users');
              },
            ),
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/chat');
              },
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(users[index]['email'] ?? ''),
                  subtitle: Text(users[index]['role'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      deleteUser(index);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          emailController.clear();
          passwordController.clear();
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Add User'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                      ),
                    ),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                      ),
                      obscureText: true,
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text('Add'),
                    onPressed: () {
                      addUser();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        },
        tooltip: 'Add User',
        child: const Icon(Icons.add),
      ),
    );
  }
}
