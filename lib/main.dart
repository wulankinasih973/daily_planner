import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import "package:http/http.dart" as http; // fetchdata dari webservice

import 'package:firebase_core/firebase_core.dart'; // inisialisasi Firebase
import 'package:firebase_auth/firebase_auth.dart'; // autentikasi Firebase
import 'firebase_options.dart'; // file ini digenerate saat setup firebase
import 'auth_page.dart'; // halaman login/register

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // diperlukan sebelum inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // inisialisasi Firebase dengan opsi platform saat ini
  );
  runApp(DailyPlannerApp());
}

// Widget Stateless: tidak dapat berubah walaupun ada interaksi dari user
class DailyPlannerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'What Will You Do Today?',
      theme: ThemeData( // menambahkan dekorasi (material design, thema warna)
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
        cardTheme: CardTheme(
          color: Colors.indigo[50],
          elevation: 3,
          margin: EdgeInsets.symmetric(vertical: 6),
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 16),
        ),
      ),
      home: AuthWrapper(), // autentikasi: menampilkan halaman berdasarkan status login
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
  List<String> _motivations = []; // fetchdata dari webservice (rest-api)

  @override
  void initState() {
    super.initState();
    _loadTasks(); // memuat data saat pertama kali aplikasi dibuka
    _fetchMotivations(); // fetchdata dari webservice (rest-api)
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

  // fetchdata dari webservice (rest-api) menggunakan ZenQuotes API
  Future<void> _fetchMotivations() async {
    try {
      List<String> quotes = [];
      for (int i = 0; i < 3; i++) {
        final response = await http.get(Uri.parse('https://zenquotes.io/api/random'));
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          final String quote = "${data[0]['q']} — ${data[0]['a']}";
          quotes.add(quote);
        }
      }

      setState(() {
        _motivations = quotes;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
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
        actions: [ // autentikasi: tombol logout
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut(); // keluar dari akun
            },
          ),
        ],
      ),
      body: OrientationBuilder( // Layout: Responsive dengan Orientation (Row & Column)
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
                Row( // widget layout: Row untuk form input dan tombol
                  children: [
                    Expanded(
                      child: TextField( // widget basic: edittext (TextField)
                        controller: _controller,
                        decoration: InputDecoration(
                          labelText: 'Add task',
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton( // widget basic: button
                      onPressed: addTask,
                      child: Text('Add'), // widget basic: text pada button
                    )
                  ],
                ),
                SizedBox(height: 16),
                Expanded(
                  child: ListView( // widget flutter (list)
                    children: [
                      Text("Your Tasks", style: TextStyle(fontWeight: FontWeight.bold)),
                      Divider(),

                      // widget flutter (list)
                      ..._tasks.map((task) => Card(
                        child: ListTile(
                          title: Text(task), // widget basic: text
                          trailing: IconButton( // icon delete task
                            icon: Icon(Icons.delete),
                            onPressed: () => _removeTask(_tasks.indexOf(task)),
                          ),
                        ),
                      )),

                      SizedBox(height: 20),
                      Text("Motivation for Today", style: TextStyle(fontWeight: FontWeight.bold)),
                      Divider(),

                      // menampilkan data dari sumber di luar perangkat: fetchdata dari webservice (rest-api)
                      ...(_motivations.isEmpty
                          ? [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(child: Text("Motivasi belum tersedia. Periksa koneksi Anda.")),
                        )
                      ]
                          : _motivations.map((quote) => Card(
                        child: ListTile(
                          leading: Icon(Icons.format_quote),
                          title: Text(quote),
                        ),
                      )).toList()),
                    ],
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

// autentikasi: menentukan apakah user sudah login atau belum
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // memantau status login user
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          return DailyPlannerHomePage(); // jika sudah login
        } else {
          return AuthPage(); // jika belum login
        }
      },
    );
  }
}
