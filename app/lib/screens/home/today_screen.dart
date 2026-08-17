import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/event_card.dart';
import '../../widgets/event_card_widget.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  Widget _cardWidget(EventCard card) {
    if (card.type == 'cancellation') return CancellationCardWidget(card: card);
    if (card.type == 'exam') return ExamCardWidget(card: card);
    return EventCardWidget(card: card);
  }

  List<Widget> _buildCardRows(List<EventCard> cards) {
    return cards.map((card) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _cardWidget(card),
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final cards = provider.todayCards;
    final now = DateTime.now();

    return RefreshIndicator(
      color: const Color(0xFFA84B45),
      backgroundColor:const Color(0xFFF2EDE3),
      onRefresh: () => context.read<AppProvider>().refresh(),
      child: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: const Color(0xFFF2EDE3),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Hello, ',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black87,
                                  ),
                                ),
                                TextSpan(
                                  text: provider.userName,
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Have a great day!',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFF2EDE3),
                      child: Icon(Icons.person, color: Colors.grey.shade600, size: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Date display
                Text(
                  DateFormat('EEEE').format(now),
                  style: GoogleFonts.inter(
                    fontSize: 25,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('d').format(now),
                          style: GoogleFonts.inter(
                            fontSize: 64,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          DateFormat('MMMM').format(now).toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 40,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 80),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            DateFormat('HH.mm').format(now),
                            style: GoogleFonts.inter(
                              fontSize: 35,
                              fontWeight: FontWeight.w300,
                              color: Colors.black,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            'India',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        if (provider.status == AppStatus.loading)
          SliverFillRemaining(
            child: Container(
              color: const Color(0xFFF2EDE3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFA84B45),
                ),
              ),
            ),
          )
        else if (provider.status == AppStatus.error)
          SliverFillRemaining(
            child: Container(
              color: const Color(0xFFF2EDE3),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Something went wrong',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.errorMessage ?? '',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => context.read<AppProvider>().loadCards(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'Retry',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else if (cards.isEmpty)
            SliverFillRemaining(
              child: Container(
                color: const Color(0xFFF2EDE3),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'All clear this week',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No updates from your groups yet.\nPull down to refresh.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _cardWidget(cards[index]),
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
}
