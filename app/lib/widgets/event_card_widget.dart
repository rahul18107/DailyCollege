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
        return const Color(0xFFB6534E);
      case 'exam':
        return const Color(0xFF5E80AE);
      case 'holiday':
        return const Color(0xFF6A9B5E);
      case 'reschedule':
        return const Color(0xFF5A7BA8);
      case 'cie':
        return const Color(0xFF7878AA);
      default:
        return const Color(0xFFA84B45);
    }
  }

  String get typeLabel {
    switch (card.type) {
      case 'cancellation': return 'Cancelled';
      case 'exam': return 'Exam';
      case 'holiday': return 'Holiday';
      case 'reschedule': return 'Rescheduled';
      case 'cie': return 'CIE';
      default: return card.type;
    }
  }

  String get formattedTime {
    if (card.date == null) return '';
    final d = DateTime.parse(card.date!);
    return DateFormat('HH.mm').format(d);
  }

  @override
  Widget build(BuildContext context) {
    return Container(

      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  card.description,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  typeLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (card.subject != null)
            Row(
              children: [
                const Icon(Icons.subject_outlined, size: 15, color: Colors.white60),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    card.subject!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white60,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          else
            const SizedBox(height: 18),
          if (card.quotedMsg != null) ...[
            const SizedBox(height: 12),
            Text(
              'Referenced',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white60,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              card.quotedMsg!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (card.sentBy != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Colors.white60),
                    const SizedBox(width: 5),
                    Text(
                      card.sentBy!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              if (card.groupName != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.group_outlined, size: 14, color: Colors.white60),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        card.groupName!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              if (card.date != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white60),
                    const SizedBox(width: 5),
                    Text(
                      DateFormat('EEE, MMM d, y').format(DateTime.parse(card.date!)),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (card.isTentative || card.confidence == 'low') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                card.isTentative ? 'Tentative' : 'Unconfirmed',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final String label;
  const _AvatarStack({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 3; i++)
          Transform.translate(
            offset: Offset(-i * 8.0, 0),
            child: CircleAvatar(
              radius: 11,
              backgroundColor: Colors.white.withValues(alpha: 0.3 + i * 0.1),
              child: const Icon(Icons.person, size: 12, color: Colors.white70),
            ),
          ),
      ],
    );
  }
}

// ── Cancellation card ──────────────────────────────────────────────────────

class CancellationCardWidget extends StatelessWidget {
  final EventCard card;
  const CancellationCardWidget({super.key, required this.card});

  String get formattedTime {
    if (card.date == null) return '';
    final d = DateTime.parse(card.date!);
    return DateFormat('HH.mm').format(d);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFA84B45),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  card.description,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Cancelled',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (card.subject != null)
            Row(
              children: [
                const Icon(Icons.cancel_outlined, size: 15, color: Colors.white60),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    card.subject!,
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white60),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          else
            const SizedBox(height: 18),
          if (card.quotedMsg != null) ...[
            const SizedBox(height: 12),
            Text(
              'Referenced',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white60,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              card.quotedMsg!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (card.sentBy != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Colors.white60),
                    const SizedBox(width: 5),
                    Text(
                      card.sentBy!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              if (card.groupName != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.group_outlined, size: 14, color: Colors.white60),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        card.groupName!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              if (card.date != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white60),
                    const SizedBox(width: 5),
                    Text(
                      DateFormat('EEE, MMM d, y').format(DateTime.parse(card.date!)),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Exam card ──────────────────────────────────────────────────────────────

class ExamCardWidget extends StatelessWidget {
  final EventCard card;
  const ExamCardWidget({super.key, required this.card});

  String get formattedTime {
    if (card.date == null) return '';
    final d = DateTime.parse(card.date!);
    return DateFormat('HH.mm').format(d);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFCF5A3C),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  card.description,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Exam',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (card.subject != null || card.syllabus != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (card.subject != null)
                  Row(
                    children: [
                      const Icon(Icons.subject_outlined, size: 15, color: Colors.white60),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          card.subject!,
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.white60),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                if (card.syllabus != null) ...[
                  if (card.subject != null) const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, size: 15, color: Colors.white60),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          card.syllabus!,
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.white60),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            )
          else
            const SizedBox(height: 18),
          if (card.quotedMsg != null) ...[
            const SizedBox(height: 12),
            Text(
              'Referenced',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white60,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              card.quotedMsg!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (card.sentBy != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Colors.white60),
                    const SizedBox(width: 5),
                    Text(
                      card.sentBy!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              if (card.groupName != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.group_outlined, size: 14, color: Colors.white60),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        card.groupName!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              if (card.date != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white60),
                    const SizedBox(width: 5),
                    Text(
                      DateFormat('EEE, MMM d, y').format(DateTime.parse(card.date!)),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
