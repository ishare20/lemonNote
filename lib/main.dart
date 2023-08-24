import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const App());
}

class Note {
  String content;

  Note({required this.content});

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
    };
  }
}

class App extends StatelessWidget {
  const App({super.key});


  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.blue, // 设置状态栏颜色
      statusBarBrightness: Brightness.dark, // 设置状态栏亮度
    ));
    return MaterialApp(
      title: '柠檬便签',
      home: const NoteList(),
      builder: EasyLoading.init(),
    );
  }
}

class NoteList extends StatefulWidget {
  const NoteList({super.key});

  @override
  createState() => _NoteListState();
}

class _NoteListState extends State<NoteList> {
  SharedPreferences? _prefs;
  List<Note> _noteList = <Note>[];
  final TextEditingController _textFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    // 从 SharedPreferences 中获取保存的 Note 数据
    List<String>? noteList = _prefs!.getStringList('notes');
    if (noteList != null) {
      setState(() {
        _noteList =
            noteList.map((note) => Note.fromJson(jsonDecode(note))).toList();
      });
    }
  }

  Future<void> _saveNotes() async {
    List<String> noteList =
        _noteList.map((note) => jsonEncode(note.toJson())).toList();
    await _prefs!.setStringList('notes', noteList);
  }

  void addNote(Note note) {
    setState(() {
      _noteList.add(note);
      _saveNotes();
    });
  }

  void editNote(Note note) {
    setState(() {
      _saveNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('柠檬便签'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == '0') {
                _launchURL("https://github.com/ishare20/lemonNote");
              } else if (value == '1') {
                _launchURL("https://sibtools.app/");
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: '0',
                child: Text('Github源码'),
              ),
              const PopupMenuItem(
                value: '1',
                child: Text('小而美的工具们'),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[300],
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemCount: _noteList.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () async {
                      // 处理点击事件的逻辑
                      await Clipboard.setData(
                          ClipboardData(text: _noteList[index].content));
                      EasyLoading.showSuccess('复制成功',
                          duration: const Duration(milliseconds: 400));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8), // 设置圆角半径
                        color: Colors.white, // 设置背景颜色
                      ),
                      padding: const EdgeInsets.all(6),
                      margin: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex:5,
                            child: Container(
                              padding: const EdgeInsets.only(left: 10),
                              child: Text(
                                _noteList[index].content,
                                maxLines: 1, // 最多显示两行
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Expanded(
                            flex:4,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.share),
                                  onPressed: () {
                                    Share.share(_noteList[index].content);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    _displayDialog(context,
                                        note: _noteList[index]);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    deleteTodo(index);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _displayDialog(context),
        tooltip: '新增便签',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addTodoItem(String title) {
    //Wrapping it inside a set state will notify
    // the app that the state has changed

    setState(() {
      _noteList.add(Note(content: title));
      _saveNotes();
    });
    _textFieldController.clear();
  }

  deleteTodo(index) {
    setState(() {
      _noteList.removeAt(index);
      _saveNotes();
    });
  }

  void _launchURL(url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $uri');
    }
  }

  //Generate list of item widgets
  Widget _buildTodoItem(Note note) {
    return Container(
        padding: const EdgeInsets.all(5),
        child: Row(
          children: [Text(note.content)],
        ));
  }

  //Generate a single item widget
  Future<Future> _displayDialog(BuildContext context, {Note? note}) async {
    _textFieldController.text = note != null ? note.content : "";
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(note != null ? '编辑便签' : '新增便签'),
            content: TextField(
              controller: _textFieldController,
              decoration: const InputDecoration(hintText: '输入内容'),
            ),
            actions: <Widget>[
              ElevatedButton(
                child: Text(note != null ? '保存' : '新增'),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (_textFieldController.text != '') {
                    if (note != null) {
                      note.content = _textFieldController.text;
                      editNote(note);
                    } else {
                      _addTodoItem(_textFieldController.text);
                    }
                  }
                },
              ),
              ElevatedButton(
                child: const Text('取消'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }
}
