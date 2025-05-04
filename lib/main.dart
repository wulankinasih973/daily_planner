import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(DailyPlannerApp());
}

// Widget Stateless: tidak dapat berubah walaupun ada interaksi dari user
class DailyPlannerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'What Will You Do Today?',
      home: DailyPlannerHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Widget Stateful: dapat berubah sesuai interaksi user
class DailyPlannerHomePage extends StatefulWidget {
  @override
  DailyPlannerHomePageState createState() => DailyPlannerHomePageState(); // dalam widget stateful tidak menggunakan build, melainkan createState
}

class DailyPlannerHomePageState extends State<DailyPlannerHomePage> {
  List<String> _tasks = []; // menyimpan daftar tugas
  final TextEditingController _controller = TextEditingController(); // mengambil teks yang diketik di dalam textfield

  @override
  void initState() {
    super.initState();
    _loadTasks(); // memuat data saat pertama kali aplikasi dibuka
  }

  // memuat data dari SharedPreferences
  void _loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _tasks = prefs.getStringList('tasks') ?? [];
    });
  }

  // menyimpan data ke SharedPreferences
  void _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('tasks', _tasks);
  }

  // menambahkan tugas ke list
  void addTask() {
    String text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _tasks.add(text); // menambah tugas baru
        _controller.clear(); // mengosongkan text field setelah tugas ditambahkan
        _saveTasks(); // menyimpan perubahan ke SharedPreferences
      });
    }
  }

  // menghapus tugas dari list
  void _removeTask(int index) {
    setState(() {
      _tasks.removeAt(index); // menghapus tugas
      _saveTasks(); // menyimpan perubahan ke SharedPreferences
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // dengan AppBar & Container (Image)
      appBar: AppBar(
        title: Text('What Will You Do Today?'),
        centerTitle: true,
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container( // Container untuk logo
                  height: 100,
                  margin: EdgeInsets.only(bottom: 20),
                  child: Image.asset('assets/images/logo.jpg'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          labelText: 'Add task',
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: addTask,
                      child: Text('Add'),
                    )
                  ],
                ),
                SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          title: Text(_tasks[index]),
                          trailing: IconButton( // icon delete task
                            icon: Icon(Icons.delete),
                            onPressed: () => _removeTask(index),
                          ),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
