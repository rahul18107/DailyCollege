import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event_card.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  Future<bool> checkStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/status'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['whatsapp'] == 'ready';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchGroups() async {
    final response = await http
        .get(Uri.parse('$baseUrl/groups'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to fetch groups');
  }

  Future<List<EventCard>> fetchCards(String groupId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/cards/$groupId'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => EventCard.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch cards');
  }

  Future<List<EventCard>> processMessages(String groupId) async {
    final response = await http
        .post(
      Uri.parse('$baseUrl/process'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'groupId': groupId}),
    )
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List cards = data['cards'];
      return cards.map((e) => EventCard.fromJson(e)).toList();
    }
    throw Exception('Failed to process messages');
  }
}