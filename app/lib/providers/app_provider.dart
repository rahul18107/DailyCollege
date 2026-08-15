import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_card.dart';
import '../services/api_service.dart';

enum AppStatus { idle, loading, refreshing, error }

class AppProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  Map<String, String> selectedGroups = {}; // id → name
  List<EventCard> cards = [];
  AppStatus status = AppStatus.idle;
  String? errorMessage;
  bool serverReady = false;

  AppProvider({Map<String, String>? initialGroups}) {
    selectedGroups = initialGroups ?? {};
  }

  Future<void> checkServer() async {
    serverReady = await _api.checkStatus();
    notifyListeners();
  }

  Future<void> selectGroups(Map<String, String> groups) async {
    selectedGroups = groups;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_groups', jsonEncode(groups));
    notifyListeners();
    await loadCards();
  }

  Future<void> loadCards() async {
    if (selectedGroups.isEmpty) return;
    status = AppStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final futures = selectedGroups.entries.map(
        (e) => _api
            .fetchCards(e.key)
            .then((list) => list.map((c) => c.withGroupName(e.value)).toList()),
      );
      final results = await Future.wait(futures);
      cards = results.expand((l) => l).toList();
      status = AppStatus.idle;
    } catch (e) {
      status = AppStatus.error;
      errorMessage = 'Could not load cards. Is the server running?';
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    if (selectedGroups.isEmpty) return;
    status = AppStatus.refreshing;
    errorMessage = null;
    notifyListeners();
    try {
      final futures = selectedGroups.entries.map(
        (e) => _api.processMessages(e.key).then(
              (list) => list.map((c) => c.withGroupName(e.value)).toList(),
            ),
      );
      final results = await Future.wait(futures);
      cards = results.expand((l) => l).toList();
      status = AppStatus.idle;
    } catch (e) {
      status = AppStatus.error;
      errorMessage = 'Refresh failed. Is the server running?';
    }
    notifyListeners();
  }

  List<EventCard> get todayCards {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekLater = today.add(const Duration(days: 7));
    return cards.where((c) {
      if (c.date == null) return false;
      final d = DateTime.parse(c.date!);
      return !d.isBefore(today) && !d.isAfter(weekLater);
    }).toList()
      ..sort((a, b) => a.date!.compareTo(b.date!));
  }

  List<EventCard> get historyCards {
    return [...cards]
      ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
  }
}