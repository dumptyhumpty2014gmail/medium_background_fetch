import 'package:background_fetch/background_fetch.dart';
import '/first_page.dart';
import '/log_functions.dart';
import 'package:flutter/material.dart';

void backgroundFetchFunction(HeadlessTask task) {
  final taskId = task.taskId;
  final timeout = task.timeout;

  final timestamp = DateTime.now();
  print('111111');

  LogManager.writeEventInLog("$taskId@$timestamp [ФОНОВАЯ]");

  //завершаем любую задачу
  BackgroundFetch.finish(taskId);
  //Если задача периодическая, значит это 15минутная к нам залетела, которая при конфигурировании возникает
  if (timeout || taskId == 'flutter_background_fetch') {
    return;
  }

  BackgroundFetch.scheduleTask(TaskConfig(
      taskId: taskId,
      delay: taskDelay, //const для экспериментов
      periodic: false,
      forceAlarmManager: true,
      stopOnTerminate: false,
      enableHeadless: true,
      requiresNetworkConnectivity: true,
      requiresCharging: true));
}

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
