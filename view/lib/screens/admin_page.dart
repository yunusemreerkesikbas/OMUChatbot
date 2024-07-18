import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:view/const/project_utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Map<String, String>> qaPairs = [];

  TextEditingController questionController = TextEditingController();
  TextEditingController answerController = TextEditingController();
  var dio = Dio();
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    getQAPairs();
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

  Future<void> getQAPairs() async {
    try {
      var response = await dio.get('${ProjectUtilities.portName}/qa/');
      List<dynamic> contents = response.data;
      setState(() {
        qaPairs = contents.map((item) {
          return {
            'id': item['id'].toString(),
            'question': item['question'] as String,
            'answer': item['answer'] as String,
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

  Future<void> addQAPair() async {
    try {
      var response = await dio.post(
        '${ProjectUtilities.portName}/qa/',
        data: {
          'question': questionController.text,
          'answer': answerController.text,
        },
      );
      print(response.data);
      getQAPairs(); // Refresh list
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
      questionController.clear();
      answerController.clear();
    });
  }

  Future<void> updateQAPair(int index) async {
    try {
      var response = await dio.put(
        '${ProjectUtilities.portName}/qa/${qaPairs[index]['id']}',
        data: {
          'question': questionController.text,
          'answer': answerController.text,
        },
      );
      print(response.data);
      getQAPairs(); // Refresh list
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

  Future<void> deleteQAPair(int index) async {
    try {
      var response = await dio.delete('${ProjectUtilities.portName}/qa/del/${qaPairs[index]['id']}');
      print(response.data);
      getQAPairs(); // Refresh list
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

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );
    if (result != null) {
      // Do something with the file
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
                itemCount: qaPairs.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(qaPairs[index]['question'] ?? ''),
                    subtitle: Text(qaPairs[index]['answer'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        deleteQAPair(index);
                      },
                    ),
                    onTap: () {
                      questionController.text = qaPairs[index]['question'] ?? '';
                      answerController.text = qaPairs[index]['answer'] ?? '';
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Edit Q&A Pair'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                TextField(
                                  controller: questionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Question',
                                  ),
                                ),
                                TextField(
                                  controller: answerController,
                                  decoration: const InputDecoration(
                                    labelText: 'Answer',
                                  ),
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
                                child: const Text('Save'),
                                onPressed: () {
                                  if (index < qaPairs.length) {
                                    updateQAPair(index);
                                  } else {
                                    addQAPair();
                                  }
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: FloatingActionButton(
                onPressed: pickFile,
                child: const Icon(Icons.file_upload),
              ),
            ),
            FloatingActionButton(
              onPressed: () {
                questionController.clear();
                answerController.clear();
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Add Q&A Pair'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          TextField(
                            controller: questionController,
                            decoration: const InputDecoration(
                              labelText: 'Question',
                            ),
                          ),
                          TextField(
                            controller: answerController,
                            decoration: const InputDecoration(
                              labelText: 'Answer',
                            ),
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
                            addQAPair();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              tooltip: 'Add Q&A Pair',
              child: const Icon(Icons.add),
            ),
          ],
        ));
  }
}
