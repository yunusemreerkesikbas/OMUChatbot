import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

class QAPage extends StatefulWidget {
  @override
  _QAPageState createState() => _QAPageState();
}

class _QAPageState extends State<QAPage> {
  List<Map<String, String>> qaPairs = [
    {
      "question": "En iyi balık restoranı hangisi?",
      "answer": "Samsun Balık Hali'ndeki restoranlar harika."
    },
    {
      "question": "Sabah yürüyüşü için en güzel park neresidir?",
      "answer": "Doğu Park"
    },
    {
      "question": "Yerel bir festivale katılmak istesem ne zaman gitmeliyim?",
      "answer": "Samsun Uluslararası Opera ve Bale Festivali zamanı."
    },
    {
      "question": "Ailece gidilecek en iyi mekan neresi?",
      "answer": "Piazza AVM ve oyun alanları."
    },
    {
      "question":
          "Tarihi ve kültürel gezi yapmak istesem nereyi ziyaret etmeliyim?",
      "answer": "Gazi Müzesi."
    },
    {
      "question": "Kahvaltı için en sevdiğin yer neresi?",
      "answer": "Simisso Cafe."
    }
  ];

  TextEditingController questionController = TextEditingController();
  TextEditingController answerController = TextEditingController();

  void addQAPair() {
    setState(() {
      qaPairs.add({
        'question': questionController.text,
        'answer': answerController.text,
      });
      questionController.clear();
      answerController.clear();
    });
  }

  void updateQAPair(int index) {
    setState(() {
      qaPairs[index] = {
        'question': questionController.text,
        'answer': answerController.text,
      };
      questionController.clear();
      answerController.clear();
    });
  }

  void deleteQAPair(int index) {
    setState(() {
      qaPairs.removeAt(index);
    });
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Q&A Manager'),
        ),
        body: Column(
          children: <Widget>[
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Expanded(
                child: ListView.builder(
                  itemCount: qaPairs.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(qaPairs[index]['question'] ?? ''),
                      subtitle: Text(qaPairs[index]['answer'] ?? ''),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          deleteQAPair(index);
                        },
                      ),
                      onTap: () {
                        questionController.text =
                            qaPairs[index]['question'] ?? '';
                        answerController.text = qaPairs[index]['answer'] ?? '';
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Edit Q&A Pair'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  TextField(
                                    controller: questionController,
                                    decoration: InputDecoration(
                                      labelText: 'Question',
                                    ),
                                  ),
                                  TextField(
                                    controller: answerController,
                                    decoration: InputDecoration(
                                      labelText: 'Answer',
                                    ),
                                  ),
                                ],
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: Text('Save'),
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
                child: Icon(Icons.file_upload),
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
                      title: Text('Add Q&A Pair'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          TextField(
                            controller: questionController,
                            decoration: InputDecoration(
                              labelText: 'Question',
                            ),
                          ),
                          TextField(
                            controller: answerController,
                            decoration: InputDecoration(
                              labelText: 'Answer',
                            ),
                          ),
                        ],
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text('Add'),
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
              child: Icon(Icons.add),
            ),
          ],
        ));
  }
}
