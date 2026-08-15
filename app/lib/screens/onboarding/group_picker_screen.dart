import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/api_service.dart';

class GroupPickerScreen extends StatefulWidget {
  final Set<String> initialSelection;

  const GroupPickerScreen({super.key, this.initialSelection = const {}});

  @override
  State<GroupPickerScreen> createState() => _GroupPickerScreenState();
}

class _GroupPickerScreenState extends State<GroupPickerScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _groups = [];
  late Set<String> _selectedIds;
  bool _loading = true;
  bool _serverOffline = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.initialSelection);
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _loading = true;
      _serverOffline = false;
    });
    try {
      final serverReady = await _api.checkStatus();
      if (!serverReady) {
        setState(() {
          _serverOffline = true;
          _loading = false;
        });
        return;
      }
      final groups = await _api.fetchGroups();
      setState(() {
        _groups = groups;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _serverOffline = true;
        _loading = false;
      });
    }
  }

  void _toggleGroup(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _confirm() {
    if (_selectedIds.isEmpty) return;
    final selected = {
      for (final g in _groups.where((g) => _selectedIds.contains(g['id'])))
        g['id'] as String: g['name'] as String,
    };
    context.read<AppProvider>().selectGroups(selected);
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              Text(
                'DailyCollege',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pick one or more college WhatsApp groups to get started.',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  color: Colors.white54,
                ),
              ),

              const SizedBox(height: 48),

              if (_loading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFF5C842),
                    ),
                  ),
                )
              else if (_serverOffline)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Server offline',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Make sure your backend is running,\nthen try again.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _PillButton(
                          label: 'Retry',
                          onTap: _loadGroups,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Expanded(
                  child: ListView.separated(
                    itemCount: _groups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final group = _groups[index];
                      final id = group['id'] as String;
                      final isSelected = _selectedIds.contains(id);
                      return _GroupTile(
                        name: group['name'],
                        participantCount: group['participantCount'],
                        isSelected: isSelected,
                        onTap: () => _toggleGroup(id),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedOpacity(
                  opacity: _selectedIds.isNotEmpty ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 200),
                  child: _PillButton(
                    label: _selectedIds.isEmpty
                        ? 'Select a group'
                        : 'Continue with ${_selectedIds.length} group${_selectedIds.length == 1 ? '' : 's'}',
                    onTap: _confirm,
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

class _GroupTile extends StatelessWidget {
  final String name;
  final int participantCount;
  final bool isSelected;
  final VoidCallback onTap;

  const _GroupTile({
    required this.name,
    required this.participantCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A2A1A) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFF5C842) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$participantCount members',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: isSelected
                  ? const Icon(Icons.check_circle,
                      key: ValueKey(true),
                      size: 22,
                      color: Color(0xFFF5C842))
                  : const Icon(Icons.circle_outlined,
                      key: ValueKey(false), size: 22, color: Colors.white24),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5C842),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}