import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:siris/class/JadwalIRS.dart';

class JadwalPDFPage extends StatelessWidget {
  final List<JadwalIRS> jadwalIRS;
  var userData;
  
  JadwalPDFPage({super.key, required this.jadwalIRS, required this.userData});

  // Fungsi untuk membuat PDF
  Future<void> _generatePDF(BuildContext context) async {
    final pdf = pw.Document();
    
    // Menambahkan konten ke PDF
    pdf.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          children: [
            pw.Text('Daftar Jadwal IRS', style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Kode MK', 'Nama MK', 'Ruangan', 'Hari', 'Jam Mulai', 'Jam Selesai', 'Kelas', 'SKS', 'Dosen Pengampu'],
              data: jadwalIRS.map((jadwal) {
                return [
                  jadwal.KodeMK,
                  jadwal.NamaMK,
                  jadwal.Ruangan,
                  jadwal.Hari,
                  jadwal.JamMulai,
                  jadwal.JamSelesai,
                  jadwal.Kelas,
                  jadwal.SKS.toString(),
                  jadwal.DosenPengampu.join(", ")
                ];
              }).toList(),
            ),
          ],
        );
      },
    ));

    // Menyimpan file PDF
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF162953),
        title: Text("Jadwal IRS PDF"),
      ),
      body: Column(
        children: [
           // Displaying user info (name, NIM, Dosen Wali, SKS status)
          Text('Nama: ${userData['name']}'),
          Text('NIM: ${userData['identifier']}'),
          Text('Dosen Wali: ${userData['dosen_wali_name'] ?? "Not assigned"}'),
          Text('SKS: 6'), // Assuming SKS is 6 as an example, replace accordingly
          // You can then display the jadwalIRS data as needed
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Daftar Jadwal IRS',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    DataTable(
                      columnSpacing: 16.0,
                      headingRowColor: MaterialStateProperty.resolveWith(
                        (states) => const Color(0xFF162953),
                      ),
                      columns: const [
                        DataColumn(
                          label: Text('Kode MK', style: TextStyle(color: Colors.white)),
                        ),
                        DataColumn(
                          label: Text('Nama MK', style: TextStyle(color: Colors.white)),
                        ),
                        DataColumn(
                          label: Text('Ruangan', style: TextStyle(color: Colors.white)),
                        ),
                        DataColumn(
                          label: Text('Hari', style: TextStyle(color: Colors.white)),
                        ),
                        DataColumn(
                          label: Text('Jam Mulai', style: TextStyle(color: Colors.white)),
                        ),
                        DataColumn(
                          label: Text('Jam Selesai', style: TextStyle(color: Colors.white)),
                        ),
                        DataColumn(
                          label: Text('Kelas', style: TextStyle(color: Colors.white)),
                        ),
                        DataColumn(
                          label: Text('SKS', style: TextStyle(color: Colors.white)),
                        ),
                        DataColumn(
                          label: Text('Dosen Pengampu', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                      rows: jadwalIRS.map((jadwal) {
                        return DataRow(cells: [
                          DataCell(Text('${jadwal.KodeMK} - ${jadwal.NamaMK}')),
                          DataCell(Text(jadwal.NamaMK)),
                          DataCell(Text(jadwal.Ruangan)),
                          DataCell(Text(jadwal.Hari)),
                          DataCell(Text(jadwal.JamMulai)),
                          DataCell(Text(jadwal.JamSelesai)),
                          DataCell(Text(jadwal.Kelas)),
                          DataCell(Text(jadwal.SKS.toString())),
                          DataCell(Text(jadwal.DosenPengampu.join(", "))),
                        ]);
                      }).toList(),
                    ),
                    ElevatedButton(
                      onPressed: () => _generatePDF(context),
                      child: Text("Export to PDF"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
