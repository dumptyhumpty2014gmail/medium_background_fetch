import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const String logKey = 'log_key';
const int taskDelay = 15000;
const int taskDelay2 = 20000;

abstract class LogManager {
  static void writeEventInLog(String event) async {
    final prefs = await SharedPreferences.getInstance();

    // Читаем лог событий из SharedPreferences
    var events = <String>[];
    var json = prefs.getString(logKey);
    if (json != null) {
      events = jsonDecode(json).cast<String>();
    }
    // Записываем событие
    events.insert(0, event);
    // Записываем обновленный лог
    try {
      prefs.setString(logKey, jsonEncode(events));
    } catch (e) {
      //на случай, если лог "переполнится"
    }
  }

  static Future<List<String>> readLog() async {
    var prefs = await SharedPreferences.getInstance();
    var json = prefs.getString(logKey);
    if (json != null) {
      try {
        return jsonDecode(json).cast<String>();
      } catch (e) {
        return [];
      }
    }

    return [];
  }

  static deleteLog() async {
    var prefs = await SharedPreferences.getInstance();
    prefs.remove(logKey);
  }
}
