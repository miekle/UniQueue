import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../widgets/bulletin_widgets.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> queue = [];
  List<Map<String, dynamic>> offices = [];
  List<Map<String, dynamic>> bulletins = [];

  Map<String, dynamic>? selectedOffice;

  RealtimeChannel? channel;

  @override
  void initState() {
    super.initState();
    fetchOffices();
    fetchBulletins();
  }

  @override
  void dispose() {
    channel?.unsubscribe();
    super.dispose();
  }

  Future<void> fetchOffices() async {
    final data = await supabase.from('offices').select();

    setState(() {
      offices = List<Map<String, dynamic>>.from(data);
    });
  }

  Future<void> fetchBulletins() async {
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

  Future<void> fetchQueue() async {
    if (selectedOffice == null) return;

    final data = await supabase
        .from('queue_entries')
        .select()
        .eq('office_id', selectedOffice!['id'])
        .order('queue_number');

    setState(() {
      queue = List<Map<String, dynamic>>.from(data);
    });
  }

  void subscribeRealtime() {
    channel?.unsubscribe();

    channel = supabase.channel('admin_${selectedOffice!['id']}');

    channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'queue_entries',
          callback: (_) {
            fetchQueue();
          },
        )
        .subscribe();
  }

  Future<void> callNext() async {
    final current =
        queue.where((q) => q['status'] == 'serving').toList();

    if (current.isNotEmpty) {
      await supabase
          .from('queue_entries')
          .update({'status': 'completed'})
          .eq('id', current.first['id']);
    }

    final next =
        queue.where((q) => q['status'] == 'waiting').toList();

    if (next.isNotEmpty) {
      await supabase
          .from('queue_entries')
          .update({
            'status': 'serving',
            'started_at': DateTime.now().toIso8601String(),
          })
          .eq('id', next.first['id']);
    }

    await fetchQueue();
  }

  Future<void> skipUser(String id) async {
    await supabase
        .from('queue_entries')
        .update({'status': 'skipped'})
        .eq('id', id);

    await fetchQueue();
  }

  Future<int> _nextBulletinSortOrder() async {
    final r = await supabase
        .from('bulletin_posts')
        .select('sort_order')
        .order('sort_order', ascending: false)
        .limit(1);
    if (r.isEmpty) return 0;
    final v = r[0]['sort_order'];
    final n = v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0;
    return n + 1;
  }

  Future<void> _saveBulletin({
    String? id,
    required String category,
    required String message,
    required String accent,
  }) async {
    if (category.trim().isEmpty || message.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category and message are required')),
        );
      }
      return;
    }

    try {
      if (id == null) {
        final order = await _nextBulletinSortOrder();
        await supabase.from('bulletin_posts').insert({
          'category': category.trim(),
          'message': message.trim(),
          'accent': accent,
          'sort_order': order,
        });
      } else {
        await supabase.from('bulletin_posts').update({
          'category': category.trim(),
          'message': message.trim(),
          'accent': accent,
        }).eq('id', id);
      }
      if (mounted) Navigator.of(context).pop();
      await fetchBulletins();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    }
  }

  Future<void> _deleteBulletin(String id) async {
    try {
      await supabase.from('bulletin_posts').delete().eq('id', id);
      await fetchBulletins();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete: $e')),
        );
      }
    }
  }

  void _openBulletinEditor({Map<String, dynamic>? existing}) {
    final categoryCtrl = TextEditingController(
      text: existing?['category']?.toString() ?? '',
    );
    final messageCtrl = TextEditingController(
      text: existing?['message']?.toString() ?? '',
    );
    String accent = existing?['accent']?.toString() ?? 'blue';
    if (!kBulletinAccents.contains(accent)) accent = 'blue';
    final id = existing?['id']?.toString();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.scaffold,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      id == null ? 'New announcement' : 'Edit announcement',
                      style: GoogleFonts.lexendDeca(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Category / department',
                        hintText: 'e.g. OSA',
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: messageCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        alignLabelWithHint: true,
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey(accent),
                      initialValue: accent,
                      decoration: const InputDecoration(
                        labelText: 'Card color',
                        filled: true,
                      ),
                      items: kBulletinAccents
                          .map(
                            (a) => DropdownMenuItem(
                              value: a,
                              child: Text(
                                a[0].toUpperCase() + a.substring(1),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => accent = v);
                      },
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => _saveBulletin(
                        id: id,
                        category: categoryCtrl.text,
                        message: messageCtrl.text,
                        accent: accent,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(id == null ? 'Add' : 'Save'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete announcement?'),
        content: Text(row['message']?.toString() ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _deleteBulletin(row['id'].toString());
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'waiting':
        return Colors.orange;
      case 'serving':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'skipped':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Queue'),
              Tab(text: 'Bulletins'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildQueueTab(),
            _buildBulletinsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueTab() {
    final serving =
        queue.where((q) => q['status'] == 'serving').toList();
    final waiting =
        queue.where((q) => q['status'] == 'waiting').toList();

    return Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: DropdownButtonFormField<String>(
            key: ValueKey(selectedOffice?['id']),
            hint: const Text('Select Office'),
            initialValue: selectedOffice?['name'] as String?,
            items: offices.map<DropdownMenuItem<String>>((office) {
              return DropdownMenuItem<String>(
                value: office['name'] as String,
                child: Text(office['name'] as String),
              );
            }).toList(),
            onChanged: (val) {
              if (val == null) return;
              final office =
                  offices.firstWhere((o) => o['name'] == val);

              setState(() {
                selectedOffice = office;
              });

              fetchQueue();
              subscribeRealtime();
            },
          ),
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: ElevatedButton(
            onPressed: callNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Call Next'),
          ),
        ),
        const SizedBox(height: 15),
        Expanded(
          child: ListView(
            children: [
              if (serving.isNotEmpty) sectionTitle('Now Serving'),
              ...serving.map((item) => buildCard(item)),
              if (waiting.isNotEmpty) sectionTitle('Waiting'),
              ...waiting.map((item) => buildCard(item)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBulletinsTab() {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 88),
          children: [
            Text(
              'Bulletin Board',
              style: GoogleFonts.lexendDeca(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add. Use the menu on a card to edit or delete.',
              style: GoogleFonts.lexendDeca(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 20),
            if (bulletins.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Center(
                  child: Text(
                    'No announcements yet.\nCreate the bulletin_posts table in Supabase if you see errors.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexendDeca(
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ),
              )
            else
              ...bulletins.map((row) {
                return BulletinCard(
                  category: row['category']?.toString() ?? '',
                  message: row['message']?.toString() ?? '',
                  accent: row['accent']?.toString() ?? 'blue',
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Color(0xFF424242)),
                    onSelected: (action) {
                      if (action == 'edit') {
                        _openBulletinEditor(existing: row);
                      } else if (action == 'delete') {
                        _confirmDelete(row);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                );
              }),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 24,
          child: FloatingActionButton(
            onPressed: () => _openBulletinEditor(),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget buildCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "#${item['queue_number']} - ${item['name']}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  item['purpose'] ?? '',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item['status'],
                style: TextStyle(
                  color: statusColor(item['status']),
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: () => skipUser(item['id']),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
