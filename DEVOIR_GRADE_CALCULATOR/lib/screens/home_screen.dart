import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/etudiant.dart';
import '../services/pdf_service.dart';

// --- ORIENTATION OBJET : Design System ---
abstract class UI {
  static Widget card({required Widget child}) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
    ),
    child: child,
  );

  static TextStyle txt(double s, [Color? c, FontWeight? w]) =>
      GoogleFonts.lexend(
        fontSize: s,
        color: c ?? Colors.black,
        fontWeight: w ?? FontWeight.normal,
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Etudiant> etudiants = [];
  bool isLoading = false;

  // --- FONCTIONS RÉDUITES (Calculs via Getters) ---
  int get admis => etudiants.where((e) => e.moyenne >= 10).length;
  double get moyG => etudiants.isEmpty
      ? 0
      : etudiants.map((e) => e.moyenne).reduce((a, b) => a + b) /
            etudiants.length;

  Future<void> pickExcel() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (res == null) return;
    setState(() => isLoading = true);
    try {
      final bytes = kIsWeb
          ? res.files.first.bytes
          : await File(res.files.first.path!).readAsBytes();
      if (bytes != null) {
        final rows = SpreadsheetDecoder.decodeBytes(
          bytes,
        ).tables.values.first.rows;
        setState(
          () => etudiants =
              rows
                  .skip(1)
                  .where((r) => r.isNotEmpty && r[0] != null)
                  .map(
                    (r) => Etudiant(
                      r[0].toString().toUpperCase(),
                      r
                          .skip(1)
                          .map((v) => double.tryParse(v.toString()) ?? 0.0)
                          .toList(),
                    ),
                  )
                  .toList()
                ..sort((a, b) => b.moyenne.compareTo(a.moyenne)),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          _appBar(),
          if (etudiants.isNotEmpty) SliverToBoxAdapter(child: _stats()),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : etudiants.isEmpty
                ? const SliverFillRemaining(
                    child: Icon(
                      Icons.folder_open,
                      size: 50,
                      color: Colors.black12,
                    ),
                  )
                : _list(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: pickExcel,
        backgroundColor: const Color.fromARGB(255, 65, 16, 177),
        icon: const Icon(Icons.add_chart, color: Colors.white),
        label: Text(
          "IMPORTER",
          style: UI.txt(14, Colors.white, FontWeight.bold),
        ),
      ),
    );
  }

  Widget _appBar() => SliverAppBar(
    expandedHeight: 100,
    pinned: true,
    backgroundColor: Colors.indigo[900],
    title: Row(
      children: [
        const Icon(Icons.leaderboard, color: Colors.white),
        const SizedBox(width: 10),
        Text(
          "GradeMaster Pro",
          style: UI.txt(18, Colors.white, FontWeight.bold),
        ),
      ],
    ),
    actions: [
      if (etudiants.isNotEmpty)
        IconButton(
          onPressed: () => PdfService.exporter(
            etudiants,
            moyG,
            admis,
            etudiants.length - admis,
          ),
          icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 28),
        ),
    ],
  );

  Widget _stats() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
    child: Row(
      children: [
        _tile(
          "Moyenne",
          moyG.toStringAsFixed(2),
          Icons.insights,
          Colors.orange,
        ),
        const SizedBox(width: 12),
        _tile("Admis", "$admis", Icons.check_circle, Colors.teal),
      ],
    ),
  );

  Widget _tile(String l, String v, IconData i, Color c) => Expanded(
    child: UI.card(
      child: ListTile(
        leading: Icon(i, color: c),
        title: Text(v, style: UI.txt(18, null, FontWeight.bold)),
        subtitle: Text(l, style: UI.txt(11, Colors.grey)),
      ),
    ),
  );

  Widget _list() => SliverList(
    delegate: SliverChildBuilderDelegate((ctx, i) {
      final e = etudiants[i];
      return UI.card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: e.color.withValues(alpha: 0.1),
            child: Text(
              e.grade,
              style: TextStyle(color: e.color, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(e.nom, style: UI.txt(13, null, FontWeight.bold)),
          trailing: Text(
            e.moyenne.toStringAsFixed(2),
            style: UI.txt(16, null, FontWeight.w900),
          ),
        ),
      );
    }, childCount: etudiants.length),
  );
}
