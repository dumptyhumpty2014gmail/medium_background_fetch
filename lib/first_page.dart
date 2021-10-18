import 'package:background_fetch/background_fetch.dart';
import '/log_functions.dart';
import '/second_page.dart';
import 'package:flutter/material.dart';

const setStopOnTerminate = false; //для экспериментов
const setEnableHeadless = true; //для экспериментов

class FirstPage extends StatefulWidget {
  const FirstPage({Key? key}) : super(key: key);

  @override
  _FirstPageState createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  List<String> _events = [];

  @override
  void initState() {
    LogManager.readLog().then((value) {
      setState(() {
        _events = value;
      });
    });
    super.initState();
    //используем конфигурирование для регистрации функции, работающей не в фоне
    try {
      BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 15,
          forceAlarmManager: false,
          stopOnTerminate:
              setStopOnTerminate, //если true, просто не должно работать в фоне (когда приложение выгружено). Проверено экспериментом
          startOnBoot: false,
          enableHeadless:
              setEnableHeadless, //если false то не запускается именно первая (фоновая) функция?
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
          requiredNetworkType: NetworkType.NONE,
        ),
        fetchFunctionFirst,
        //_onBackgroundFetchTimeout
      );
      // желательно эту функцию сразу завершать, вдруг пользователь не будет запускать фоновые задачи...
      //можно было бы это делать перед каждым запуском task, но функция не подменяется (проверим на второй странице)
    } catch (e) {
      //print("[BackgroundFetch] ошибка при КОНФИГУРИРОВАНИИ: $e");
    }
  }

  void fetchFunctionFirst(String taskId) {
    final timestamp = DateTime.now();
    if (mounted) {
      LogManager.writeEventInLog("$taskId@$timestamp [НА ЭКРАНЕ 1]");
      setState(() {
        _events.insert(0, "$taskId@${timestamp.toString()}  [НА ЭКРАНЕ 1 SET]");
      });
    } else {
      LogManager.writeEventInLog("$taskId@$timestamp [СТРАНИЦА 1]");
    }

    //завершаем задачу на всякий случай
    BackgroundFetch.finish(taskId);
    //Если задача периодическая, значит это 15минутная к нам залетела, которая при конфигурировании возникает
    if (taskId == 'flutter_background_fetch') {
      return;
    }

    BackgroundFetch.scheduleTask(TaskConfig(
        taskId: taskId,
        delay: taskDelay, //const для экспериментов
        periodic: false,
        forceAlarmManager: true,
        stopOnTerminate: setStopOnTerminate,
        enableHeadless: setEnableHeadless,
        requiresNetworkConnectivity: true,
        requiresCharging: true));
  }

  void _startSheduleTask1() {
    BackgroundFetch.scheduleTask(TaskConfig(
        taskId: '1111',
        delay: taskDelay, //const для экспериментов
        periodic: false, //обязательно не периодическую
        forceAlarmManager: true,
        stopOnTerminate: setStopOnTerminate,
        enableHeadless: setEnableHeadless,
        requiresNetworkConnectivity: true,
        requiresCharging: true));
  }

  void _stopTasks() {
    BackgroundFetch.stop();
  }

  void _toSecondPage() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const SecondPage()));
  }

  void _clearLog() async {
    LogManager.deleteLog();
    setState(() {
      _events = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    const emptyText = Center(child: Text('События отсутствуют'));
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
            onPressed: _startSheduleTask1,
            child: const Text('Запустить задачу'),
          ),
          ElevatedButton(
            onPressed: _stopTasks,
            child: const Text('Остановить задачи'),
          ),
          ElevatedButton(
            onPressed: _toSecondPage,
            child: const Text('На вторую страницу'),
          ),
          ElevatedButton(
            onPressed: _clearLog,
            child: const Text('Очистить лог'),
          ),
          Expanded(
            child: (_events.isEmpty)
                ? emptyText
                : ListView.builder(
                    itemCount: _events.length,
                    itemBuilder: (BuildContext context, int index) {
                      var event = _events[index].split("@");
                      return oneEvent(event);
                    }),
          ),
        ],
      ),
    );
  }

  InputDecorator oneEvent(List<String> event) {
    return InputDecorator(
      decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.only(left: 5.0, top: 5.0, bottom: 5.0),
          labelStyle: const TextStyle(color: Colors.blue, fontSize: 20.0),
          labelText: "[${event[0].toString()}]"),
      child: Text(event[1],
          style: const TextStyle(color: Colors.black, fontSize: 16.0)),
    );
  }
}
