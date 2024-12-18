import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:siris/mahasiswa/ambil_irs.dart';
import 'dart:convert';
import 'package:siris/navbar.dart';
import 'package:siris/class/JadwalIRS.dart';
import 'package:logging/logging.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart'; // For printing support

final loggerIRS = Logger('IRSPageState');
int ipdf = 1;

class IRSPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const IRSPage({super.key, required this.userData});


  @override
  IRSPageState createState() => IRSPageState();
}


class IRSPageState extends State<IRSPage> {  
  List<JadwalIRS> jadwalIRS = [];
  int? selectedSemester;
  late int semester;
  DateTime today = DateTime.now();  
  String getFormattedDate() {
    return DateFormat('d MMMM yyyy').format(today);
  } 

  get userData => widget.userData;

  @override
  void initState() {
    super.initState();
    
    // Set semester default, misalnya dari userData["semester"]
    selectedSemester = userData["semester"];
    fetchIRSJadwal(selectedSemester!);
    
  }
  Future<void> fetchIRSJadwal(int semester) async {
  final nim = widget.userData["identifier"];
  final prodi = widget.userData['jurusan'];
  final url = 'http://localhost:8080/mahasiswa/$nim/jadwal-irs?semester=$semester';
  loggerIRS.info('Fetching jadwal for semester: $semester at URL: $url');
  debugPrint("Prodi : $prodi");
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      
      // Print each item in data
      data.forEach((item) {
        debugPrint("Item in data: $item");
      });

      setState(() {
        jadwalIRS = data.map((item) => JadwalIRS.fromJson(item)).toList();
        // Print the processed jadwalIRS list
        debugPrint("Processed JadwalIRS: $jadwalIRS");
      });
    } else {
      // Handle error
      Map<String, dynamic> e = json.decode(response.body);
      loggerIRS.severe('Status Code: ${response.statusCode}, Error Message: ${e['message']}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil data jadwal IRS')),
        );
      }
    }
  } catch (e) {
    loggerIRS.severe('Unexpected error: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan saat mengambil data jadwal IRS')),
      );
    }
  }
}

mapJadwal(jadwalIRS) {
          return jadwalIRS.map((jadwal) {
            return {
              'main': [
                jadwal.KodeMK,
                jadwal.NamaMK,
                jadwal.Kelas,
                jadwal.SKS.toString(),
                jadwal.Ruangan,
                jadwal.status,
                jadwal.DosenPengampu.join(','),
              ],
              'sub': "${jadwal.Hari} pukul ${jadwal.JamMulai} - ${jadwal.JamSelesai}",
            };
          }).toList();
  }


  @override
Widget build(BuildContext context) {
  return MaterialApp(
    home: Scaffold(
      appBar: Navbar(userData: userData),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  margin: const EdgeInsets.only(top: 32),
                  child: const Text(
                    'Isian Rencana Studi',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
                // Dropdown and Button Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _DropdownSelection(
                        currentSemester: widget.userData["semester"],
                        onSemesterChanged: (int semester) {
                          setState(() {
                            selectedSemester = semester;
                          });
                          fetchIRSJadwal(semester);
                        },
                      ),
                     Row(children: [
                      _buildEditButton(),
                      SizedBox(width: 16),
                      buildPrintButton()
                     ],)
                    ],
                  ),
                ),
                // Table with horizontal scrolling
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 100),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        dataRowMinHeight: 48.0,
                        columnSpacing: 16.0,
                        headingRowColor: MaterialStateProperty.resolveWith(
                          (states) => const Color(0xFF162953),
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Mata Kuliah',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          DataColumn(
                            label: Text(
                              'Ruangan',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Hari',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Jam Mulai',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Jam Selesai',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Kelas',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'SKS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Status',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Dosen Pengampu',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        rows: jadwalIRS.map((jadwal) {
                          return DataRow(cells: [
                            DataCell(Text('${jadwal.KodeMK ?? 'N/A'} - ${jadwal.NamaMK ?? 'N/A'}')),
                            DataCell(Text(jadwal.Ruangan ?? 'N/A')),
                            DataCell(Text(jadwal.Hari ?? 'N/A')),
                            DataCell(Text(jadwal.JamMulai ?? 'N/A')),
                            DataCell(Text(jadwal.JamSelesai ?? 'N/A')),
                            DataCell(Text(jadwal.Kelas ?? 'N/A')),
                            DataCell(Text(jadwal.SKS?.toString() ?? '0')), // Pastikan untuk menangani null pada SKS
                            DataCell(Text(jadwal.status ?? 'N/A')),
                            DataCell(Text(jadwal.DosenPengampu?.join(", ") ?? 'N/A')),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}




Widget _buildEditButton() {
  final bool isButtonEnabled = selectedSemester == widget.userData['semester'];

  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: isButtonEnabled ? Colors.blue : Colors.grey, // Ubah warna tombol jika diperlukan
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24), // Rounded edges
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    onPressed: isButtonEnabled
        ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AmbilIRS(
                  userData: widget.userData, // Kirim userData ke halaman baru
                ),
              ),
            );
          }
        : null, // Disabled button
    child: const Row(
      mainAxisSize: MainAxisSize.min, // Keeps the button compact
      children: [
        Icon(
          Icons.edit, // Edit icon
          color: Colors.white,
        ),
        SizedBox(width: 8), // Space between icon and text
        Text(
          'Edit IRS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

Widget buildPrintButton() {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.pink[700],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Rounded edges
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    onPressed: () async {
      // Generate PDF
      final pdf = pw.Document();
      final userData = widget.userData;
      final data = mapJadwal(jadwalIRS);
      final String tanggal = getFormattedDate();
      
      // Add a page to the PDF
      pdf.addPage(
        pw.Page(
          margin: pw.EdgeInsets.zero,
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: pw.EdgeInsets.all(24),
              child: pw.Column(
                // mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children :[ 
                      pw.Column(
                        children: [
                         pw.Text("ISIAN RENCANA STUDI", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                         pw.Text("Semester Ganjil TA 2024/2025", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        ]
                      )
                    ]
                  ),
                  pw.Divider(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Container(
                        margin: pw.EdgeInsets.symmetric(vertical: 16),
                        width: PdfPageFormat.a4.width / 2,
                        child: pw.Table(
                          columnWidths: const {
                            0: pw.FractionColumnWidth(0.4),
                            1: pw.FractionColumnWidth(0.6),
                          },
                          children: [
                            pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: pw.EdgeInsets.all(3.0),
                                  child: pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text('Nama',
                                        style:
                                            pw.TextStyle(fontSize: 8)),
                                      pw.Text(':',
                                        style:
                                            pw.TextStyle(fontSize: 8)),
                                    ],
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(3.0),
                                  child: pw.Text(
                                      widget.userData['name'],
                                      style:  pw.TextStyle(
                                          fontSize: 8)),
                                ),
                              ],
                            ),
                            pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: pw.EdgeInsets.all(3.0),
                                  child: pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text('NIM',
                                          style:
                                              pw.TextStyle(fontSize: 8)),
                                      pw.Text(':',
                                          style:
                                              pw.TextStyle(fontSize: 8)),
                                    ],
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(3.0),
                                  child: pw.Text(
                                      widget.userData['identifier'],
                                      style:  pw.TextStyle(
                                          fontSize: 8)),
                                ),
                              ],
                            ),
                            pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: pw.EdgeInsets.all(3.0),
                                  child: pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text('Program Studi',
                                        style:
                                            pw.TextStyle( fontSize: 8)),
                                      pw.Text(':',
                                        style:
                                            pw.TextStyle(fontSize: 8)),
                                    ],
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(3.0),
                                  child: pw.Text(
                                      widget.userData['jurusan'],
                                      style:  pw.TextStyle(
                                          fontSize: 8)),
                                ),
                              ],
                            ),
                            pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: pw.EdgeInsets.all(3.0),
                                  child: pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text('Dosen Wali',
                                        style:
                                            pw.TextStyle(fontSize: 8)),
                                      pw.Text(':',
                                        style:
                                            pw.TextStyle(fontSize: 8)),
                                    ],
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(3.0),
                                  child: pw.Text(
                                      widget.userData['dosen_wali_name'],
                                      style:  pw.TextStyle(
                                          fontSize: 8)),
                                ),
                              ],
                            ),
                          ]
                        ),
                      ),
                      pw.Container(
                        height: 80, // Set the maximum height
                        width: 80 * (3 / 4), // Dynamically calculate width to keep 3:4 ratio
                        child: pw.Image(
                          pw.MemoryImage(base64Decode(userData['profile_image_base64'])),
                          fit: pw.BoxFit.cover, // Ensures the image fits while maintaining aspect ratio
                        ),
                      ),
                    ]
                  ),
                  pw.Divider(),
                  pw.Table(
                    children: [
                      // Header
                      pw.TableRow(
                        children: [
                          // Merge dua kolom menjadi satu
                          pw.Table(
                            //border: pw.TableBorder.symmetric(inside: pw.BorderSide(color: PdfColors.black)),
                            columnWidths: const {
                                0: pw.FractionColumnWidth(0.1),
                                1: pw.FractionColumnWidth(0.1),
                                2: pw.FractionColumnWidth(0.25),
                                3: pw.FractionColumnWidth(0.1),
                                4: pw.FractionColumnWidth(0.1),
                                5: pw.FractionColumnWidth(0.1),
                                6: pw.FractionColumnWidth(0.1),
                                7: pw.FractionColumnWidth(0.5),
                              },
                            border: pw.TableBorder.all(width: 0.25, color: PdfColors.black),
                            defaultColumnWidth: const pw.IntrinsicColumnWidth(flex: 0.5),
                            children: [
                              // Row Header
                              pw.TableRow(
                                children: [
                                  pw.Container(
                                    alignment: pw.Alignment.center,
                                    padding: const pw.EdgeInsets.all(2),
                                    child: pw.Text('No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
                                  ),
                                  pw.Container(
                                    alignment: pw.Alignment.center,
                                    padding: const pw.EdgeInsets.all(2),
                                    child: pw.Text('Kode', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
                                  ),
                                  pw.Container(
                                    alignment: pw.Alignment.center,
                                    padding: const pw.EdgeInsets.all(2),
                                    child: pw.Text('Mata Kuliah', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
                                  ),
                                  pw.Container(
                                    alignment: pw.Alignment.center,
                                    padding: const pw.EdgeInsets.all(2),
                                    child: pw.Text('Kelas', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
                                  ),
                                  pw.Container(
                                    alignment: pw.Alignment.center,
                                    padding: const pw.EdgeInsets.all(2),
                                    child: pw.Text('SKS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
                                  ),
                                  pw.Container(
                                    alignment: pw.Alignment.center,
                                    padding: const pw.EdgeInsets.all(2),
                                    child: pw.Text('Ruang', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
                                  ),
                                  pw.Container(
                                    alignment: pw.Alignment.center,
                                    padding: const pw.EdgeInsets.all(2),
                                    child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
                                  ),
                                  pw.Container(
                                    alignment: pw.Alignment.center,
                                    padding: const pw.EdgeInsets.all(2),
                                    child: pw.Text('Nama Dosen', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
                                  ),
                                ]
                              ),
                            ]
                          )
                        ]
                      ),
                      // Row Isi Looping
                      pw.TableRow(
                        children: [
                          pw.Table(
                            columnWidths: const {
                                0: pw.FractionColumnWidth(0.1),
                                1: pw.FractionColumnWidth(1.25)
                              },
                            border: pw.TableBorder.all(width: 0.25, color: PdfColors.black),
                            children: [
                              for(int i = 0; i <data.length; i++) ... [
                                pw.TableRow(
                                  children: [
                                    // Kolom Nomer
                                    pw.Container(
                                      alignment: pw.Alignment.center,
                                      // padding: const pw.EdgeInsets.all(8),
                                      child: pw.Text((i+1).toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7), textAlign: pw.TextAlign.center),
                                    ),
                                    pw.Table(
                                      border: pw.TableBorder.all(width: 0.25, color: PdfColors.black),
                                      children: [
                                        pw.TableRow(
                                          children: [
                                            pw.Table(
                                              columnWidths: const {
                                                0: pw.FractionColumnWidth(0.1),
                                                1: pw.FractionColumnWidth(0.25),
                                                2: pw.FractionColumnWidth(0.1),
                                                3: pw.FractionColumnWidth(0.1),
                                                4: pw.FractionColumnWidth(0.1),
                                                5: pw.FractionColumnWidth(0.1),
                                                6: pw.FractionColumnWidth(0.5),
                                              },
                                              border: pw.TableBorder.all(width: 0.5, color: PdfColors.black),
                                              children: [
                                                  pw.TableRow(
                                                    children: (data[i]['main'] as List<dynamic>)
                                                    .map<pw.Widget>((cell) => pw.Padding(
                                                      padding: const pw.EdgeInsets.all(5),
                                                      child: pw.Text(cell,
                                                      style: const pw.TextStyle(fontSize: 7),
                                                      textAlign: pw.TextAlign.left),
                                                      ))
                                                    .toList(),
                                                  ),
                                                ],
                                            ),
                                          ]
                                        ),
                                        pw.TableRow(
                                          children: [
                                            pw.Table(
                                              border: pw.TableBorder.all(width: 0.25, color: PdfColors.black),
                                              children: [
                                                pw.TableRow(
                                                  children: [
                                                    pw.Container(
                                                      alignment: pw.Alignment.centerLeft,
                                                      padding: const pw.EdgeInsets.all(2),
                                                      child: pw.Text(
                                                        ' ${data[i]['sub']?.toString()}',
                                                        style: pw.TextStyle(fontSize: 7),
                                                        textAlign: pw.TextAlign.left,
                                                      ),
                                                    ),
                                                  ])
                                              ] 
                                            ),
                                          ]
                                        )
                                      ]
                                    )
                                  ]
                                ),
                              ]
                            ]
                          )
                        ]
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children:[
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Align(
                            alignment: pw.Alignment.topLeft,  // Aligns text to the left
                            child: pw.Text(
                              "Pembimbing Akademik",
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.SizedBox(height: 40),
                                        pw.Align(
                            alignment: pw.Alignment.topLeft,  // Aligns text to the left
                            child: pw.Text(
                              widget.userData['dosen_wali_name'],
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                                        pw.Align(
                            alignment: pw.Alignment.topLeft,  // Aligns text to the left
                            child: pw.Text(
                              "NIP. ${widget.userData['dosen_wali_nip']}",
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                        ]
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Align(
                            alignment: pw.Alignment.topLeft,  // Aligns text to the left
                            child: pw.Text(
                              "Semarang ,$tanggal",
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Align(
                            alignment: pw.Alignment.topLeft,  // Aligns text to the left
                            child: pw.Text(
                              "Mahasiswa",
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                                        pw.SizedBox(height: 40),
                          pw.Align(
                            alignment: pw.Alignment.topLeft,  // Aligns text to the left
                            child: pw.Text(
                              widget.userData['name'],
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Align(
                            alignment: pw.Alignment.topLeft,  // Aligns text to the left
                            child: pw.Text(
                              "NIM.${widget.userData['identifier']}",
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                        ]
                      )
                    ] 
                  )
                ],
              ),
            );
          },
        ),
    
      );
      // Print or share the PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    },
    child: Row(
      mainAxisSize: MainAxisSize.min, // Keeps the button compact
      children: [
        Icon(
          Icons.document_scanner, // Edit icon
          color: Colors.white,
        ),
        const SizedBox(width: 8), // Space between icon and text
        Text(
          'Cetak IRS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

}

class _DropdownSelection extends StatefulWidget {
  final int currentSemester;
  final Function(int) onSemesterChanged;

  const _DropdownSelection({required this.currentSemester, required this.onSemesterChanged});

  @override
  _DropdownSelectionState createState() => _DropdownSelectionState();
}

class _DropdownSelectionState extends State<_DropdownSelection> {
  // Define a list of options
  late List<int> semesterItems;
  int? selectedSemester;

  @override
  void initState() {
    super.initState();
    selectedSemester = widget.currentSemester;
    semesterItems = List<int>.generate(widget.currentSemester, (index) => index + 1);
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: selectedSemester,
      hint: const Text('Pilih Semester'),
      isExpanded: false,
      menuWidth: 240,
      icon: const Icon(Icons.arrow_drop_down),
      underline: Container(
        height: 2,
        color: Colors.blue,
      ),
      items: semesterItems.map((int value) {
        return DropdownMenuItem<int>(
          value: value,
          child: Text('Semester $value'),
        );
      }).toList(),
      onChanged: (int? newValue) {
        setState(() {
          selectedSemester = newValue;
        });
        widget.onSemesterChanged(newValue!);
      },
    );
  }
}