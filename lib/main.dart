import 'package:background_fetch/background_fetch.dart';
import '/first_page.dart';
import 'package:flutter/material.dart';

import 'task_function.dart';

void main() async {
  runApp(const MyApp());
  await BackgroundFetch.registerHeadlessTask(backgroundFetchFunction);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Background fetch Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FirstPage(),
    );
  }
}
