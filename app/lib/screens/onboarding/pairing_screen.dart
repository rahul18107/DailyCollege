import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import 'package:flutter/services.dart';

class PairingScreen extends StatefulWidget {
  final VoidCallback? onPaired;
  const PairingScreen({super.key, this.onPaired});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _phoneController = TextEditingController();
  final _apiService = ApiService();

  String? _pairingCode;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollTimer;

  @override
  void dispose() {
    _phoneController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final phone = '91${_phoneController.text.trim()}';
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Please enter your phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/request-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phone}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _pairingCode = data['code'];
          _isLoading = false;
        });
        _startPolling();
      } else {
        setState(() {
          _errorMessage = 'Failed to get pairing code. Try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Is the server running?';
        _isLoading = false;
      });
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      // Check for updated pairing code
      try {
        final codeResponse = await http.get(
          Uri.parse('${ApiService.baseUrl}/current-code'),
        ).timeout(const Duration(seconds: 5));

        if (codeResponse.statusCode == 200 && mounted) {
          final codeData = jsonDecode(codeResponse.body);
          final newCode = codeData['code'];
          if (newCode != null && newCode != _pairingCode) {
            setState(() {
              _pairingCode = newCode;
            });
          }
        }
      } catch (e) {
        // Ignore code check errors
      }

      // Check connection status
      final status = await _apiService.fetchWhatsAppStatus();
      if (status == 'ready' && mounted) {
        timer.cancel();
        widget.onPaired?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(

            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'DailyCollege',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4F3D3D),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _pairingCode == null
                    ? 'Enter your WhatsApp number to connect'
                    : 'Enter this code in WhatsApp  ',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                    fontWeight: FontWeight.bold,
                  color: const Color(0xFF4F3D3D)

                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),



              if (_pairingCode == null) ...<Widget>[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4F3D3D),
                  ),
                  decoration: InputDecoration(
                    prefixText: '+91 ',
                    prefixStyle: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4F3D3D),
                    ),
                    hintText: 'XXXXXXXXXX',
                    hintStyle: GoogleFonts.dmSans(
                      fontSize: 18,
                      color: const Color(0xFFC5C5C3),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF4F4F2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: const Color(0xFFFF6B6B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const Spacer(),



                GestureDetector(
                  onTap: _isLoading ? null : _requestCode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _isLoading
                          ? const Color(0xFFFDEFDB).withOpacity(0.5)
                          : const Color(0xFFFDEFDB),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: _isLoading
                        ? const Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: const Color(0xFF4F3D3D),
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                        : Text(
                      'Get Code',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4F3D3D),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F2),
                    borderRadius: BorderRadius.circular(20),

                  ),
                  child: Text(
                    _pairingCode!,
                    style: GoogleFonts.dmMono(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4F3D3D),
                      letterSpacing: 5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height:250 ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: const Color(0xFF4F3D3D),
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Waiting for pairing...',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        color: const Color(0xFF4F3D3D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _pairingCode = null;
                      _pollTimer?.cancel();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _isLoading
                          ? const Color(0xFFFDEFDB).withOpacity(0.5)  // lighter/faded while loading
                          : const Color(0xFFFDEFDB),                   // full color when idle
                      borderRadius: BorderRadius.circular(30),

                    ),
                    child: Text(
                      'Request New Code',

                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4F3D3D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}