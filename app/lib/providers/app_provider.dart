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
  String userName = 'User'; // User name for greeting

  AppProvider({Map<String, String>? initialGroups}) {
    selectedGroups = initialGroups ?? {};
  }

  Future<void> checkServer() async {
    serverReady = await _api.checkStatus();
    notifyListeners();
  }

  Future<void> getUserName() async {
    String? name;
    for (int i = 0; i < 5; i++) {
      name = await _api.getConnectedUserName();
      if (name != null) break;
      await Future.delayed(const Duration(seconds: 2));
    }
    if (name != null) {
      userName = name;
      notifyListeners();
    }
  }

  // Add logout:
  Future<void> logout() async {
    await _api.logout();
    cards = [];
    selectedGroups = {};
    userName = 'User';
    serverReady = false;
    status = AppStatus.idle;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_groups');
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
      print('📊 Loaded ${cards.length} total cards');
      for (var card in cards) {
        print('  - ${card.type}: ${card.subject} on ${card.date}');
      }
      status = AppStatus.idle;
    } catch (e) {
      print('❌ Error loading cards: $e');
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
    final threeDaysAgo = today.subtract(const Duration(days: 3));
    final weekLater = today.add(const Duration(days: 7));

    final filtered = cards.where((c) {
      // Include cards with null dates (show recent events with unknown dates)
      if (c.date == null) return true;

      final d = DateTime.parse(c.date!);
      final eventDate = DateTime(d.year, d.month, d.day);
      return !eventDate.isBefore(threeDaysAgo) && eventDate.isBefore(weekLater);
    }).toList();

    // Sort by generatedAt descending (newest first)
    filtered.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));

    return filtered;
  }

  List<EventCard> get historyCards {
    return [...cards]
      ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
  }
}