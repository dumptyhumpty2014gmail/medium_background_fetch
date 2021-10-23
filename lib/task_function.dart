import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vector_math/vector_math.dart' as math;

import 'log_functions.dart';

final DateFormat formater = DateFormat("yy.MM.dd.HH.mm.ss");
const taskIdDivider = '_';

//префикс для taskId по страницам
abstract class TaskIds {
  static const firstPageKey = 'dh1';
  static const secondPageKey = 'dh2';
}

//основная фукнция, выполняющаяся в фоне
void backgroundFetchFunction(HeadlessTask task) {
  final taskId = task.taskId;
  final timeout = task.timeout;
  //final _myTaskConfig = MyTaskConfig.getTaskConfig(taskId);

  final timestamp = DateTime.now();
  //print('111111');

  LogManager.writeEventInLog("$taskId@$timestamp [ФОНОВАЯ]");

  //завершаем любую задачу
  BackgroundFetch.finish(taskId);
  //Если задача периодическая, значит это 15минутная к нам залетела, которая при конфигурировании возникает
  if (timeout || taskId == 'flutter_background_fetch') {
    return;
  }
  //TOD определяем время окончания. Если меньше, то запускаем новую задачу
  //TOD определяем периодичность для запуска
  checkIdAndStart(taskId);
}

//запускаем задачу с одинаковыми параметрами
void startNewTask(String taskId, int taskDelay) {
  BackgroundFetch.scheduleTask(TaskConfig(
    taskId: taskId,
    delay: taskDelay,
    periodic: false,
    forceAlarmManager: true,
    stopOnTerminate: false,
    enableHeadless: true,
    requiresNetworkConnectivity: true,
    requiresCharging: false,
  ));
}

void checkIdAndStart(String taskId) {
  final _myTaskConfig = MyTaskConfig.getTaskConfig(taskId);
  if (_myTaskConfig.period <= 0) {
    return;
  }
  if (DateTime.now().difference(_myTaskConfig.endDateTime).inSeconds >= 0) {
    //не запускаем новую задачу
    return;
  }

  startNewTask(taskId, _myTaskConfig.period * 100);
}

//диалог запроса периода и времени окончания и возвращает сформированный taskId
Future<String?> cupertinoGetTaskIdDialog(
    BuildContext context, String taskPagePrefix) async {
  String _periodTask = '10';
  String _allTimeTask = '20';
  void showSnackBar(String meassage) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(meassage),
    ));
  }

  final String? taskId = await showGeneralDialog<String?>(
      context: context,
      pageBuilder: (context, anim1, anim2) {
        return Container();
      },
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.4),
      barrierLabel: '',
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.rotate(
          angle: math.radians(anim1.value * 360),
          child: Opacity(
            opacity: anim1.value,
            child: CupertinoAlertDialog(
              title: const Text('Запустить фоновую задачу?'),
              content: Center(
                child: Card(
                  color: Colors.transparent,
                  elevation: 0.0,
                  child: Column(
                    children: [
                      const Text(
                        'Период выполнения функции, секунд',
                        style: TextStyle(fontSize: 10),
                      ),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp('[0-9]'))
                        ],
                        initialValue: _periodTask,
                        onChanged: (value) {
                          _periodTask = value;
                        },
                        decoration: const InputDecoration(
                          icon: Icon(Icons.access_alarm),
                          suffix: Text('сек'),
                        ),
                      ),
                      const Text(
                        'Закончить через, мин',
                        style: TextStyle(fontSize: 10),
                      ),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp('[0-9]'))
                        ],
                        initialValue: _allTimeTask,
                        onChanged: (value) {
                          _allTimeTask = value;
                        },
                        decoration: const InputDecoration(
                          icon: Icon(
                            Icons.access_time,
                          ),
                          suffix: Text('мин'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Да'),
                  onPressed: () {
                    final intPeriod = int.tryParse(_periodTask);
                    if (intPeriod != null) {
                      if (intPeriod < 10) {
                        showSnackBar('Период не может быть меньше 10 секунд!');
                        return;
                      }
                      if (intPeriod > 300) {
                        showSnackBar('Период не может быть больше 300 секунд!');
                        return;
                      }
                    } else {
                      showSnackBar('Ошибка в определении периода функции!');
                      return;
                    }
                    final intAllTime = int.tryParse(_allTimeTask);
                    if (intAllTime != null) {
                      if (intAllTime < 1 || intAllTime * 60 < intPeriod) {
                        showSnackBar(
                            'Время работы не может быть меньше 1 мин и меньше периода!');
                        return;
                      }
                      if (intAllTime > 60) {
                        showSnackBar(
                            'Время работы не может быть больше 60 минкт!');
                        return;
                      }
                    } else {
                      showSnackBar(
                          'Ошибка в определении времени окочания функции!');
                      return;
                    }
                    final taskId1 = MyTaskConfig.getTaskConfigString(
                        taskPrefix: taskPagePrefix,
                        period: _periodTask,
                        endTime: formater.format(
                            DateTime.now().add(Duration(minutes: intAllTime))));

                    Navigator.of(context).pop(taskId1);
                  },
                  isDestructiveAction: true,
                ),
                CupertinoDialogAction(
                    child: const Text('Нет'),
                    onPressed: () {
                      Navigator.of(context).pop(null);
                    }),
              ],
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 500));
  return taskId; //.then((value) => return value);
}

//набор параметров задачи с какой страницы запущено, период перезапуска, время окончания
class MyTaskConfig {
  final String pagePrefix;
  final int period;
  final DateTime endDateTime;

  MyTaskConfig(this.pagePrefix, this.period, this.endDateTime);
  //Формируем набор параметров из строки
  factory MyTaskConfig.getTaskConfig(String taskId) {
    final _configList = taskId.split(taskIdDivider);

    final _prefix = _configList.isNotEmpty ? _configList[0] : 'err';
    final _configPeriod =
        _configList.length > 1 ? int.tryParse(_configList[1]) ?? 0 : 0;
    DateTime _endDateTime;
    try {
      _endDateTime = _configList.length > 2
          ? formater.parse(_configList[2])
          : DateTime.now().add(
              const Duration(minutes: 30),
            );
    } catch (e) {
      _endDateTime = DateTime.now().add(
        const Duration(minutes: 30),
      );
    }
    return MyTaskConfig(_prefix, _configPeriod, _endDateTime);
  }
//Формируем строку из параметров задачи: с какой страницы запущено, период перезапуска, время окончания
  static String getTaskConfigString(
      {required String taskPrefix,
      required String period,
      required String endTime}) {
    return '$taskPrefix$taskIdDivider$period$taskIdDivider$endTime';
  }
}
