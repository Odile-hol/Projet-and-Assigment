import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/etudiant.dart';

class PdfService {
  static Future<void> exporter(
    List<Etudiant> etudiants,
    double moyenneG,
    int admis,
    int echecs,
  ) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _header(dateStr),
          pw.SizedBox(height: 20),
          _stats(etudiants.length, moyenneG, admis, echecs),
          pw.SizedBox(height: 25),
          pw.TableHelper.fromTextArray(
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.indigo900,
            ),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            data: [
              ['RANG', 'NOM', 'MOYENNE', 'MENTION', 'GRADE'],
              ...etudiants.asMap().entries.map(
                (e) => [
                  '${e.key + 1}',
                  e.value.nom,
                  e.value.moyenne.toStringAsFixed(2),
                  e.value.mention,
                  e.value.grade,
                ],
              ),
            ],
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static pw.Widget _header(String d) => pw.Container(
    padding: const pw.EdgeInsets.all(15),
    decoration: const pw.BoxDecoration(
      color: PdfColors.indigo900,
      borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          "PROCES-VERBAL DE NOTES",
          style: pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          d,
          style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
        ),
      ],
    ),
  );

  static pw.Widget _stats(int t, double m, int a, int e) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      _box("EFFECTIF", "$t", PdfColors.blueGrey800),
      _box("MOYENNE", m.toStringAsFixed(2), PdfColors.indigo700),
      _box("ADMIS", "$a", PdfColors.teal700),
      _box("ÉCHECS", "$e", PdfColors.red700),
    ],
  );

  static pw.Widget _box(String l, String v, PdfColor c) => pw.Container(
    width: 100,
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      color: c,
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Column(
      children: [
        pw.Text(
          l,
          style: const pw.TextStyle(color: PdfColors.white, fontSize: 8),
        ),
        pw.Text(
          v,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
