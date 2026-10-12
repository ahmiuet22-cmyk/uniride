import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _pushKey = 'uniride_setting_push';
  static const String _arrivalKey = 'uniride_setting_arrival';
  static const String _delayKey = 'uniride_setting_delay';
  static const String _locationKey = 'uniride_setting_location';
  static const String _languageKey = 'uniride_setting_language';

  bool _pushNotifications = true;
  bool _arrivalAlerts = true;
  bool _busDelayAlerts = true;
  bool _locationEnabled = true;
  String _language = 'English';
  final String _appearance = 'Light';

  SettingsProvider() {
    _loadSettings();
  }

  bool get pushNotifications => _pushNotifications;
  bool get arrivalAlerts => _arrivalAlerts;
  bool get busDelayAlerts => _busDelayAlerts;
  bool get locationEnabled => _locationEnabled;
  String get language => _language;
  String get appearance => _appearance;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _pushNotifications = prefs.getBool(_pushKey) ?? true;
    _arrivalAlerts = prefs.getBool(_arrivalKey) ?? true;
    _busDelayAlerts = prefs.getBool(_delayKey) ?? true;
    _locationEnabled = prefs.getBool(_locationKey) ?? true;
    _language = prefs.getString(_languageKey) ?? 'English';
    notifyListeners();
  }

  Future<void> togglePushNotifications(bool val) async {
    _pushNotifications = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushKey, val);
  }

  Future<void> toggleArrivalAlerts(bool val) async {
    _arrivalAlerts = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_arrivalKey, val);
  }

  Future<void> toggleDelayAlerts(bool val) async {
    _busDelayAlerts = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_delayKey, val);
  }

  Future<void> toggleLocation(bool val) async {
    _locationEnabled = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationKey, val);
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, lang);
  }
}
