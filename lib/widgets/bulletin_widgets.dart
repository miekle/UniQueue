import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

const List<String> kBulletinAccents = [
  'blue',
  'peach',
  'mint',
  'lavender',
];

Color bulletinBackgroundColor(String accent) {
  switch (accent) {
    case 'peach':
      return const Color(0xFFFCEEE3);
    case 'mint':
      return const Color(0xFFE8F5E9);
    case 'lavender':
      return const Color(0xFFF0E8F8);
    case 'blue':
    default:
      return const Color(0xFFE3F2FD);
  }
}

class BulletinCard extends StatelessWidget {
  const BulletinCard({
    super.key,
    required this.category,
    required this.message,
    required this.accent,
    this.trailing,
  });

  final String category;
  final String message;
  final String accent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
      decoration: BoxDecoration(
        color: bulletinBackgroundColor(accent),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  category,
                  style: GoogleFonts.lexendDeca(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF757575),
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.work_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: GoogleFonts.lexendDeca(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only bulletin list (e.g. queue form).
class BulletinBoardSection extends StatelessWidget {
  const BulletinBoardSection({
    super.key,
    required this.items,
    this.title = 'Bulletin Board',
  });

  final List<Map<String, dynamic>> items;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.lexendDeca(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 16),
        ...items.map((row) {
          return BulletinCard(
            category: row['category']?.toString() ?? '',
            message: row['message']?.toString() ?? '',
            accent: row['accent']?.toString() ?? 'blue',
          );
        }),
      ],
    );
  }
}
