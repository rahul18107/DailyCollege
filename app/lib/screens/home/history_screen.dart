import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../widgets/event_card_widget.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final cards = provider.historyCards;

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
                'History',
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
        else if (cards.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Nothing yet',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Parsed events will show up here.',
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
                  (context, index) {
                final card = cards[index];
                final showDateHeader = index == 0 ||
                    !_sameDay(
                      cards[index - 1].generatedAt,
                      card.generatedAt,
                    );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDateHeader)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                        child: Text(
                          DateFormat('EEEE, d MMM').format(card.generatedAt),
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white24,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    EventCardWidget(card: card),
                  ],
                );
              },
              childCount: cards.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}