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
      color: const Color(0xFFA84B45),
      backgroundColor: const Color(0xFFF2EDE3),
      onRefresh: () => context.read<AppProvider>().refresh(),
      child: CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFFF2EDE3),
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
                  color: Colors.black,
                ),
              ),
              if (provider.selectedGroups.isNotEmpty)
                Text(
                  provider.selectedGroups.values.join(', '),
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: Colors.black38,
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
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
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
                          padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
                          child: Text(
                            DateFormat('EEEE, d MMM').format(card.generatedAt).toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: EventCardWidget(card: card),
                      ),
                    ],
                  );
                },
                childCount: cards.length,
              ),
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