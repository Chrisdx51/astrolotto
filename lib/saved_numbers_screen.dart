import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🎨 Aurora color palette
const _cTurquoise = Color(0xFF12D1C0);
const _cMagenta = Color(0xFFFF4D9A);
const _cSunshine = Color(0xFFFFD166);
const _cDeepBlue = Color(0xFF0A003D);

class SavedNumbersScreen extends StatefulWidget {
  const SavedNumbersScreen({super.key});

  @override
  State<SavedNumbersScreen> createState() => _SavedNumbersScreenState();
}

class _SavedNumbersScreenState extends State<SavedNumbersScreen> {
  List<String> _savedNumbers = [];

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedNumbers = prefs.getStringList('savedSets') ?? [];
    });
  }

  Future<void> _deleteItem(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedNumbers.removeAt(index);
      prefs.setStringList('savedSets', _savedNumbers);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cDeepBlue,
      appBar: AppBar(
        title: const Text("💫 Saved Numbers"),
        backgroundColor: _cDeepBlue,
        centerTitle: true,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _savedNumbers.isEmpty
          ? const Center(
        child: Text(
          "No saved numbers yet 🌙",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _savedNumbers.length,
        itemBuilder: (context, index) {
          final entry = _savedNumbers[index];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white30),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry,
                    style: GoogleFonts.quicksand(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.white70),
                  onPressed: () => _deleteItem(index),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
