import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'providers/app_provider.dart';
import 'screens/onboarding/group_picker_screen.dart';
import 'screens/onboarding/pairing_screen.dart';
import 'screens/home/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final prefs = await SharedPreferences.getInstance();
  Map<String, String> initialGroups = {};

  final savedGroupsJson = prefs.getString('selected_groups');
  if (savedGroupsJson != null) {
    final decoded = jsonDecode(savedGroupsJson) as Map<String, dynamic>;
    initialGroups = decoded.map((k, v) => MapEntry(k, v as String));
  } else {
    // backward-compat: migrate old single-group prefs
    final oldId = prefs.getString('selected_group_id');
    final oldName = prefs.getString('selected_group_name');
    if (oldId != null && oldName != null) {
      initialGroups = {oldId: oldName};
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(initialGroups: initialGroups),
      child: const DailyCollegeApp(),
    ),
  );
}

class DailyCollegeApp extends StatelessWidget {
  const DailyCollegeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DailyCollege',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const AppGate(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      scaffoldBackgroundColor: const Color(0xFF111111),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFF5C842),
        surface: Color(0xFF1A1A1A),
      ),
      useMaterial3: true,
    );
  }
}

class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  String _whatsappStatus = 'checking';

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final api = ApiService();
    final status = await api.fetchWhatsAppStatus();
    setState(() => _whatsappStatus = status);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    if (_whatsappStatus == 'checking') {
      return const Scaffold(
        backgroundColor: Color(0xFF111111),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF5C842)),
        ),
      );
    }

    if (_whatsappStatus != 'ready') {
      return PairingScreen(onPaired: () {
        setState(() => _whatsappStatus = 'ready');
      });
    }

    if (provider.selectedGroups.isEmpty) {
      return const GroupPickerScreen();
    }

    return const HomeShell();
  }
}