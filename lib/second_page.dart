import 'package:background_fetch/background_fetch.dart';

import '/log_functions.dart';

import '/first_page.dart';
import 'package:flutter/material.dart';

void fetchFunctionSecond(String taskId) {
  final timestamp = DateTime.now();

  LogManager.writeEventInLog("$taskId@$timestamp [СТРАНИЦА 2]");

  //завершаем задачу на всякий случай
  BackgroundFetch.finish(taskId);
  //Если задача периодическая, значит это 15минутная к нам залетела, которая при конфигурировании возникает
  if (taskId == 'flutter_background_fetch') {
    return;
  }

  BackgroundFetch.scheduleTask(TaskConfig(
      taskId: taskId,
      delay: taskDelay2, //const для экспериментов
      periodic: false,
      forceAlarmManager: true,
      stopOnTerminate: false,
      enableHeadless: true,
      requiresNetworkConnectivity: true,
      requiresCharging: true));
}

class SecondPage extends StatefulWidget {
  const SecondPage({Key? key}) : super(key: key);

  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  void _toFirstPage() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const FirstPage()));
  }

  void _startSheduleTask2() {
    try {
      BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 15,
          forceAlarmManager: false,
          stopOnTerminate: false,
          startOnBoot: false,
          enableHeadless: true,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
          requiredNetworkType: NetworkType.NONE,
        ),
        fetchFunctionSecond,
        //_onBackgroundFetchTimeout
      );
      // желательно эту функцию сразу завершать, вдруг пользователь не будет запускать фоновые задачи...
      //можно было бы это делать перед каждым запуском task, но функция не подменяется (проверим на второй странице)
    } catch (e) {
      //print("[BackgroundFetch] ошибка при КОНФИГУРИРОВАНИИ: $e");
    }
    BackgroundFetch.scheduleTask(TaskConfig(
        taskId: '2222',
        delay: taskDelay2, //const для экспериментов
        periodic: false, //обязательно не периодическую
        forceAlarmManager: true,
        stopOnTerminate: false,
        enableHeadless: true,
        requiresNetworkConnectivity: true,
        requiresCharging: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пример работы в фоне',
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.amberAccent,
        //brightness: Brightness.light,
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _startSheduleTask2,
            child: const Text('Запустить задачу 2'),
          ),
          // ElevatedButton(
          //   onPressed: _stopTasks,
          //   child: const Text('Остановить задачи'),
          // ),
          ElevatedButton(
            onPressed: _toFirstPage,
            child: const Text('На первую страницу'),
          ),
        ],
      ),
    );
  }
}
