import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/event_card.dart';

class EventCardWidget extends StatelessWidget {
  final EventCard card;

  const EventCardWidget({super.key, required this.card});

  Color get cardColor {
    switch (card.type) {
      case 'cancellation':
        return const Color(0xFFFF6B6B);
      case 'exam':
        return const Color(0xFFF5C842);
      case 'holiday':
        return const Color(0xFFA8D672);
      case 'reschedule':
        return const Color(0xFF74B9FF);
      case 'cir':
        return const Color(0xFFC39BD3);
      default:
        return const Color(0xFFE0E0E0);
    }
  }

  String get typeLabel {
    switch (card.type) {
      case 'cancellation':
        return 'Cancelled';
      case 'exam':
        return 'Exam';
      case 'holiday':
        return 'Holiday';
      case 'reschedule':
        return 'Rescheduled';
      case 'cir':
        return 'CIR';
      default:
        return card.type;
    }
  }

  String get formattedDate {
    if (card.date == null) return '';
    final d = DateTime.parse(card.date!);
    return DateFormat('EEE, d MMM').format(d);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row — type chip + tentative tag
          Row(
            children: [
              _Chip(label: typeLabel),
              if (card.isTentative) ...[
                const SizedBox(width: 8),
                _Chip(label: '⚠️ Tentative'),
              ],
              if (card.confidence == 'low') ...[
                const SizedBox(width: 8),
                _Chip(label: '~ Unconfirmed'),
              ],
              const Spacer(),
              if (card.date != null)
                Text(
                  formattedDate,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Subject
          if (card.subject != null)
            Text(
              card.subject!,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),

          const SizedBox(height: 6),

          // Description
          Text(
            card.description,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              color: Colors.black87,
              height: 1.4,
            ),
          ),

          // Reschedule new time
          if (card.newTime != null) ...[
            const SizedBox(height: 10),
            Text(
              'New time: ${card.newTime}',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],

          // Exam syllabus
          if (card.syllabus != null) ...[
            const SizedBox(height: 10),
            Text(
              'Syllabus: ${card.syllabus}',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],

          // Sent by
          if (card.sentBy != null) ...[
            const SizedBox(height: 14),
            Text(
              'via ${card.sentBy}',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: Colors.black45,
              ),
            ),
          ],

          // Group name
          if (card.groupName != null) ...[
            const SizedBox(height: 4),
            Text(
              card.groupName!,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black38,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }
}