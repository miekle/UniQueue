import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

class QueueStatusScreen extends StatefulWidget {
  final Map<String, dynamic> entry;
  final Map<String, dynamic> office;

  const QueueStatusScreen({
    super.key,
    required this.entry,
    required this.office,
  });

  @override
  State<QueueStatusScreen> createState() => _QueueStatusScreenState();
}

class _QueueStatusScreenState extends State<QueueStatusScreen> {
  final supabase = Supabase.instance.client;

  int peopleAhead = 0;
  int estimatedMinutes = 0;
  bool _statsReady = false;
  DateTime? _lastUpdated;

  static const int _turnWindowMinutes = 10;

  @override
  void initState() {
    super.initState();
    calculateQueue();
  }

  Future<void> calculateQueue() async {
    final officeId = widget.office['id'];
    final myQueueNumber = widget.entry['queue_number'];

    final response = await supabase
        .from('queue_entries')
        .select()
        .eq('office_id', officeId)
        .lt('queue_number', myQueueNumber)
        .inFilter('status', ['waiting', 'serving']);

    final count = response.length;

    final avgTime =
        int.tryParse(widget.office['average_service_time'].toString()) ?? 5;

    if (!mounted) return;
    setState(() {
      peopleAhead = count;
      estimatedMinutes = count * avgTime;
      _lastUpdated = DateTime.now();
      _statsReady = true;
    });
  }

  /// Visual fill for ETA bar (higher = closer to being served).
  double get _etaProgress {
    if (!_statsReady) return 0;
    if (peopleAhead <= 0) return 1;
    return (1 - peopleAhead / (peopleAhead + 5)).clamp(0.12, 0.98);
  }

  String _formatAmPm(DateTime t) {
    var h = t.hour % 12;
    if (h == 0) h = 12;
    final m = t.minute.toString().padLeft(2, '0');
    final suffix = t.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final queueNumber = widget.entry['queue_number'];
    final officeName = widget.office['name']?.toString() ?? 'Office';
    final arrival =
        DateTime.now().add(Duration(minutes: estimatedMinutes));

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.scaffold,
        foregroundColor: AppColors.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Queue Tracker',
          style: GoogleFonts.lexendDeca(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: _statsReady
          ? SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _LocationCard(officeName: officeName),
                  const SizedBox(height: 28),
                  Text(
                    'You are now in line',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexendDeca(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      style: GoogleFonts.lexendDeca(
                        fontSize: 15,
                        height: 1.45,
                        color: const Color(0xFF424242),
                      ),
                      children: [
                        const TextSpan(text: 'You are in line for '),
                        TextSpan(
                          text: '#$queueNumber',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text:
                              '. When it is your turn, you will have $_turnWindowMinutes minutes to enter the designated area.',
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _EtaProgressBar(progress: _etaProgress),
                  const SizedBox(height: 28),
                  _InfoCard(
                    label: 'Expected Arrival Time:',
                    value: _formatAmPm(arrival),
                  ),
                  const SizedBox(height: 14),
                  _InfoCard(
                    label: 'Estimated Wait Time:',
                    value:
                        '$estimatedMinutes Minute${estimatedMinutes == 1 ? '' : 's'}',
                  ),
                  const SizedBox(height: 14),
                  _InfoCard(
                    label: 'Number of People in Line:',
                    value:
                        '$peopleAhead People',
                  ),
                  const SizedBox(height: 24),
                  _StatusFooter(
                    timeText: _lastUpdated != null
                        ? _formatAmPm(_lastUpdated!)
                        : '--',
                  ),
                ],
              ),
            )
          : Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.officeName});

  final String officeName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.work_outline_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              officeName,
              style: GoogleFonts.lexendDeca(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EtaProgressBar extends StatelessWidget {
  const _EtaProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ETA',
          style: GoogleFonts.lexendDeca(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
            color: const Color(0xFF757575),
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            const bubbleHalf = 28.0;
            final bubbleLeft = (progress * w - bubbleHalf).clamp(4.0, w - 56.0);

            return Column(
              children: [
                SizedBox(
                  height: 34,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: bubbleLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '$pct%',
                            style: GoogleFonts.lexendDeca(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE8E8E8),
                    color: AppColors.primary,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.lexendDeca(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.lexendDeca(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFooter extends StatelessWidget {
  const _StatusFooter({required this.timeText});

  final String timeText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Status Last Updated',
            style: GoogleFonts.lexendDeca(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeText,
            style: GoogleFonts.lexendDeca(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
