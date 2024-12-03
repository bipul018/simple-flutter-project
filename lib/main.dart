import 'package:flutter/material.dart';
import 'navigator.dart';
import 'data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  database = init_database();
  dogstore = DogStore(db: database);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      //home: const MyHomePage(title: 'Flutter Demo Home Page'),
      // routes:<String, WidgetBuilder>{
      //   "/" : (context) => const TheHomePage(title: "Flutter home page"),
      //   "/another" : (context) => const NotTheHomePage(title: "Flutter not home page"),
      // },
      routes:get_navigator(["Flutter App"]),
    );
  }
}

