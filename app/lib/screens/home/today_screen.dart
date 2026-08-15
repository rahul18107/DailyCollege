import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../widgets/event_card_widget.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final cards = provider.todayCards;

    return RefreshIndicator(
      color: const Color(0xFFF5C842),
      backgroundColor: const Color(0xFF1A1A1A),
      onRefresh: () => context.read<AppProvider>().refresh(),
      child: CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFF111111),
          floating: true,
          pinned: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This Week',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (provider.selectedGroups.isNotEmpty)
                Text(
                  provider.selectedGroups.values.join(', '),
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: Colors.white38,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
            ],
          ),
        ),

        if (provider.status == AppStatus.loading)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFF5C842),
              ),
            ),
          )
        else if (provider.status == AppStatus.error)
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Something went wrong',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.errorMessage ?? '',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => context.read<AppProvider>().loadCards(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5C842),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (cards.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'All clear this week',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No updates from your groups yet.\nPull down to refresh.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => EventCardWidget(card: cards[index]),
                childCount: cards.length,
              ),
            ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    ),
  );
  }
}