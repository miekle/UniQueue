import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'queue_form_screen.dart';
import 'admin_login_screen.dart'; // ✅ UPDATED (PIN screen)

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;

  String? selectedUserType;
  Map<String, dynamic>? selectedOffice;

  List<Map<String, dynamic>> offices = [];

  @override
  void initState() {
    super.initState();
    fetchOffices();
  }

  Future<void> fetchOffices() async {
    final data = await supabase.from('offices').select();

    setState(() {
      offices = List<Map<String, dynamic>>.from(data);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                "UniQueue",
                textAlign: TextAlign.center,
                style: GoogleFonts.lexendDeca(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 40),
              buildDropdown(
                hint: "Select User Type",
                value: selectedUserType,
                items: ["Student", "Parent", "Visitor"],
                onChanged: (val) {
                  setState(() => selectedUserType = val);
                },
              ),
              const SizedBox(height: 20),
              buildDropdown(
                hint: "Select Office",
                value: selectedOffice?['name'],
                items: offices.map((e) => e['name'] as String).toList(),
                onChanged: (val) {
                  final office =
                      offices.firstWhere((e) => e['name'] == val);
                  setState(() => selectedOffice = office);
                },
              ),
              const Expanded(child: SizedBox.shrink()),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  if (selectedUserType == null || selectedOffice == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please complete selections")),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QueueFormScreen(
                        userType: selectedUserType!,
                        office: selectedOffice!,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Proceed",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminLoginScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Admin Access",
                  style: TextStyle(decoration: TextDecoration.underline )),
              ),
              const SizedBox(height: 12),
              Center(
               child: Image.asset(
                'assets/images/usls_logo.png',
                height: MediaQuery.of(context).size.height * 0.08,
                fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
          )
        ],
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(hint),
        isExpanded: true,
        underline: const SizedBox(),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}