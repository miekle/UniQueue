import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../widgets/bulletin_widgets.dart';
import 'queue_status_screen.dart';

class QueueFormScreen extends StatefulWidget {
  final String userType;
  final Map<String, dynamic> office;

  const QueueFormScreen({
    super.key,
    required this.userType,
    required this.office,
  });

  @override
  State<QueueFormScreen> createState() => _QueueFormScreenState();
}

class _QueueFormScreenState extends State<QueueFormScreen> {
  final supabase = Supabase.instance.client;

  final nameController = TextEditingController();
  final purposeController = TextEditingController();

  bool isLoading = false;
  List<Map<String, dynamic>> bulletins = [];

  @override
  void initState() {
    super.initState();
    _fetchBulletins();
  }

  Future<void> _fetchBulletins() async {
    try {
      final data = await supabase
          .from('bulletin_posts')
          .select()
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);

      if (!mounted) return;
      setState(() {
        bulletins = List<Map<String, dynamic>>.from(data);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => bulletins = []);
    }
  }

  Future<void> joinQueue() async {
    if (nameController.text.isEmpty || purposeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final officeId = widget.office['id'];

      final lastEntry = await supabase
          .from('queue_entries')
          .select('queue_number')
          .eq('office_id', officeId)
          .order('queue_number', ascending: false)
          .limit(1);

      int nextQueueNumber = 1;

      if (lastEntry.isNotEmpty) {
        nextQueueNumber = lastEntry[0]['queue_number'] + 1;
      }

      final inserted = await supabase.from('queue_entries').insert({
        'office_id': officeId,
        'name': nameController.text,
        'purpose': purposeController.text,
        'user_type': widget.userType,
        'queue_number': nextQueueNumber,
        'status': 'waiting',
      }).select().single();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QueueStatusScreen(
            entry: inserted,
            office: widget.office,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  void dispose() {
    nameController.dispose();
    purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Queue Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildInput(nameController, 'Name / ID'),
              const SizedBox(height: 20),
              buildInput(purposeController, 'Purpose'),
              if (bulletins.isNotEmpty) ...[
                const SizedBox(height: 28),
                BulletinBoardSection(items: bulletins),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: isLoading ? null : joinQueue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  minimumSize: const Size(double.infinity, 55),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Join Queue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInput(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
