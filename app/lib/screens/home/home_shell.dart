import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../screens/onboarding/group_picker_screen.dart';
import 'today_screen.dart';
import 'history_screen.dart';
import 'dart:ui';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TodayScreen(),
    HistoryScreen(),
    _GroupsTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF2EDE3),
      body: Stack(
        children: [
          Column(
            children: [
              // Server offline banner
              if (!provider.serverReady)
                Container(
                  width: double.infinity,
                  color: const Color(0xFFFF6B6B),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: SafeArea(
                    bottom: false,
                    child: Text(
                      'Server offline — showing cached cards',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              Expanded(child: _screens[_currentIndex]),
            ],
          ),

          // Floating nav bar
            Positioned(
            bottom: 60,
                  left: 100,
                  right: 100,
                  child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),

                  child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                  decoration: BoxDecoration(
                  color: Colors.black12.withValues(alpha: 0.01),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                  color: Colors.white.withValues(alpha: 0.11),
                  width: 0.8,
                  ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                  child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.today_outlined,
                      selectedIcon: Icons.today,
                      selected: _currentIndex == 0,
                      onTap: () => setState(() => _currentIndex = 0),
                    ),
                    _NavItem(
                      icon: Icons.history_outlined,
                      selectedIcon: Icons.history,
                      selected: _currentIndex == 1,
                      onTap: () => setState(() => _currentIndex = 1),
                    ),
                    _NavItem(
                      icon: Icons.group_outlined,
                      selectedIcon: Icons.group,
                      selected: _currentIndex == 2,
                      onTap: () => setState(() => _currentIndex = 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
            ),  // Positioned
        ],  // Stack children
      ),

      bottomNavigationBar: null,
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),

        decoration: BoxDecoration(
          color: selected ? Colors.black12.withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Icon(
          selected ? selectedIcon : icon,
          color: selected ? Colors.white : Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

class _GroupsTab extends StatelessWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFFF2EDE3),
          floating: true,
          pinned: false,
          title: Text(
            'Groups',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              ...provider.selectedGroups.entries.map(
                    (e) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2EDE3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFA84B45), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 18, color: Color(0xFFA84B45)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          e.value,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupPickerScreen(
                      initialSelection: provider.selectedGroups.keys.toSet(),
                    ),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'Change Groups',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}