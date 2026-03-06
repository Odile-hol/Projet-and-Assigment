import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const MyApp());

class Etudiant {
  final String nom;
  final List<double> notes;

  Etudiant({required this.nom, required this.notes});

  double get moyenne =>
      notes.isEmpty ? 0 : notes.reduce((a, b) => a + b) / notes.length;

  String get grade {
    final m = moyenne;
    if (m >= 16) return "Excellent";
    if (m >= 14) return "Très Bien";
    if (m >= 12) return "Bien";
    if (m >= 10) return "Admis";
    return "Échec";
  }

  String get letter => switch (grade) {
    "Excellent" => "A+",
    "Très Bien" => "A",
    "Bien" => "B",
    "Admis" => "C",
    _ => "F",
  };

  Color get color => switch (letter) {
    "A+" => const Color(0xFF00C853),
    "A" => const Color(0xFF6200EA),
    "B" => const Color(0xFF00B0FF),
    "C" => const Color(0xFFFFAB00),
    _ => const Color(0xFFFF1744),
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const CalculateurPage(),
    );
  }
}

class CalculateurPage extends StatefulWidget {
  const CalculateurPage({super.key});
  @override
  State<CalculateurPage> createState() => _CalculateurPageState();
}

class _CalculateurPageState extends State<CalculateurPage>
    with SingleTickerProviderStateMixin {
  final nomController = TextEditingController();
  final noteController = TextEditingController();
  List<double> notesTemporaires = [];
  Etudiant? etudiantActuel;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  }

  void toutEffacer() => setState(() {
    notesTemporaires.clear();
    etudiantActuel = null;
    nomController.clear();
    noteController.clear();
    _controller.reverse();
  });

  Future<void> importerExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result != null) {
        Uint8List bytes = result.files.single.bytes!;
        var decoder = SpreadsheetDecoder.decodeBytes(bytes);
        var table = decoder.tables.values.first;

        String? nomImport;
        var nouvellesNotes = table.rows
            .where((row) => row.length >= 3)
            .map((row) {
              nomImport ??= row[1]?.toString();
              return double.tryParse(
                row[2]?.toString().replaceAll(',', '.') ?? "",
              );
            })
            .whereType<double>()
            .toList();

        setState(() {
          notesTemporaires.addAll(nouvellesNotes);
          if (nomImport != null && nomController.text.isEmpty)
            nomController.text = nomImport!;
        });
      }
    } catch (e) {
      _showSnack("Erreur d'importation", Colors.red);
    }
  }

  void _addNote() {
    double? n = double.tryParse(noteController.text.replaceAll(',', '.'));
    if (n != null && n <= 20) {
      setState(() {
        notesTemporaires.add(n);
        noteController.clear();
      });
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildMainInputCard(),
                  const SizedBox(height: 20),
                  _buildNotesGrid(),
                  if (etudiantActuel != null) _buildResultCard(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (notesTemporaires.isEmpty)
            return _showSnack("Aucune note saisie", Colors.orange);
          setState(() {
            etudiantActuel = Etudiant(
              nom: nomController.text.isEmpty ? "Étudiant" : nomController.text,
              notes: List.from(notesTemporaires),
            );
            _controller.forward(from: 0);
          });
        },
        icon: const Icon(Icons.analytics_rounded),
        label: const Text(
          "Générer le Bilan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar.large(
      expandedHeight: 120,
      backgroundColor: Colors.white,
      title: Text(
        "Bilan Scolaire",
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          onPressed: toutEffacer,
          icon: const Icon(Icons.refresh, color: Colors.red),
        ),
      ],
    );
  }

  Widget _buildMainInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: nomController,
            decoration: InputDecoration(
              hintText: "Nom de l'étudiant",
              prefixIcon: const Icon(Icons.person),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: noteController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Note / 20",
                    prefixIcon: const Icon(Icons.star),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _addNote(),
                ),
              ),
              const SizedBox(width: 8),
              _buildActionButton(Icons.add, Colors.indigo, _addNote),
              const SizedBox(width: 8),
              _buildActionButton(
                Icons.table_chart_rounded,
                Colors.teal,
                importerExcel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 54,
        width: 54,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildNotesGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: notesTemporaires
          .asMap()
          .entries
          .map(
            (e) => Chip(
              label: Text(
                e.value.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onDeleted: () => setState(() => notesTemporaires.removeAt(e.key)),
              backgroundColor: Colors.white,
            ),
          )
          .toList(),
    );
  }

  Widget _buildResultCard() {
    final e = etudiantActuel!;
    return ScaleTransition(
      scale: _animation,
      child: Container(
        margin: const EdgeInsets.only(top: 25, bottom: 100),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: e.color.withValues(alpha: 0.1), blurRadius: 30),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: e.color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    e.nom,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      e.letter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  Text(
                    e.moyenne.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 70,
                      fontWeight: FontWeight.bold,
                      color: e.color,
                    ),
                  ),
                  Text(
                    e.grade.toUpperCase(),
                    style: TextStyle(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: SizedBox(
                height: 100,
                child: BarChart(
                  BarChartData(
                    titlesData: const FlTitlesData(show: false),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: e.notes
                        .asMap()
                        .entries
                        .map(
                          (en) => BarChartGroupData(
                            x: en.key,
                            barRods: [
                              BarChartRodData(
                                toY: en.value,
                                color: e.color,
                                width: 14,
                                borderRadius: BorderRadius.circular(4),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: 20,
                                  color: Colors.grey.shade100,
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
