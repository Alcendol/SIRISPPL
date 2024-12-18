import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:siris/class/JadwalIRS.dart';
import 'package:siris/navbar.dart';
import 'package:logging/logging.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

final loggerIRSDetail = Logger('IRSDetailPageState');

class IRSDetailPage extends StatefulWidget {
  final Map<String, dynamic> mahasiswa;
  final Map<String, dynamic> userData;

  const IRSDetailPage({super.key, required this.mahasiswa, required this.userData});

  @override
  IRSDetailPageState createState() => IRSDetailPageState();
}

class IRSDetailPageState extends State<IRSDetailPage> {
  List<JadwalIRS> jadwalIRS = [];
  Map<String, dynamic> irsInfo = {'status_irs': 'Belum Diisi'};
  late int selectedSemester; // Default semester
  get mahasiswa => widget.mahasiswa;
  get userData => widget.userData;
  int maxSks = 0;

  String totalSks = '0';
  String ipk = '0.0';
  String ips = '0.0';
  String currentSKS = '0.0';

  @override
  void initState() {
    super.initState();
    // Fetch jadwal IRS untuk semester default
    selectedSemester = widget.mahasiswa["semester"] ?? 5;
    fetchIRSJadwal(selectedSemester);
    fetchData();
    fetchIRSInfo(widget.mahasiswa["semester"]);
  }

  void updateMaxSks() {
    if (double.tryParse(ips) != null) {
      double parsedIps = double.parse(ips);
      if (parsedIps >= 3) {
        maxSks = 24;
      } else if (parsedIps >= 2.5 && parsedIps < 3) {
        maxSks = 22;
      } else {
        maxSks = 20;
      }
    }
      setState(() {}); // Perbarui UI jika diperlukan
  }

  // Fungsi untuk mem-fetch data dari API
  Future<void> fetchData() async {
    final nim = widget.mahasiswa['nim'];
    final semester = widget.mahasiswa['semester'];
    final String apiUrl =
        'http://localhost:8080/mahasiswa/info-mahasiswa/$nim?semester=$semester';
    debugPrint("Semester : $semester");
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // Decode the JSON response
        final data = json.decode(response.body);
        setState(() {
          totalSks = data['total_sks'].toString();
          ipk = data['ipk'].toString();
          ips = data['ips'].toString();
          currentSKS = data['current_sks'].toString();
        });
        updateMaxSks();
      } else {
        setState(() {
          totalSks = 'Error';
          ipk = 'Error';
          ips = 'Error';
          currentSKS = 'Error';
        });
        print('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        totalSks = 'Error';
        ipk = 'Error';
        ips = 'Error';
        currentSKS = 'Error';
      });
      print('Error fetching data: $e');
    }
  }

  Future<void> fetchIRSJadwal(int semester) async {
    final nim = widget.mahasiswa["nim"];
    final url =
        'http://localhost:8080/mahasiswa/$nim/jadwal-irs?semester=$semester';
    loggerIRSDetail
        .info('Fetching jadwal for semester: $semester at URL: $url');

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        jadwalIRS = data.map((item) => JadwalIRS.fromJson(item)).toList();
      });
    } else {
      // Handle error
      loggerIRSDetail.severe(
          'Error fetching data: ${response.statusCode}, body: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil data jadwal IRS')),
      );
    }
  }

  Future<void> unapproveIRS(String nim, int semester) async {
    final url =
        'http://localhost:8080/mahasiswa/$nim/unapprove-irs?semester=$semester';
    // Endpoint untuk unapprove
    debugPrint("Nim : $nim, semester : $semester");
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'semester': semester}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Status IRS berhasil diubah menjadi Pending')),
          );
          // Perbarui data IRS
          fetchIRSInfo(semester);
          fetchIRSJadwal(semester);
        } else {
          throw Exception('Unexpected status: ${result['status']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error unapproving IRS: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan, coba lagi')),
      );
    }
  }

  Future<void> approveIRS(String nim, int semester) async {
    final url =
        'http://localhost:8080/mahasiswa/$nim/approve-irs?semester=$semester'; // Semester sebagai query parameter
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'semester': semester}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'already_approved') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('IRS sudah disetujui sebelumnya')),
          );
        } else if (result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('IRS berhasil disetujui')),
          );
          // Reload jadwal IRS
          fetchIRSJadwal(selectedSemester);
        } else {
          throw Exception('Unexpected status: ${result['status']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error approving IRS: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan, coba lagi')),
      );
    }
  }

  Future<void> fetchIRSInfo(int semester) async {
    final nim = widget.mahasiswa['nim'];
    final url =
        'http://localhost:8080/mahasiswa/$nim/irs-info?semester=$semester';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            // Update status IRS berdasarkan data pertama yang ditemukan
            irsInfo['status_irs'] = data[0]['status'];
          });
        } else {
          setState(() {
            irsInfo['status_irs'] = 'Tidak Ada Data';
          });
        }
      } else {
        print('Failed to fetch IRS info: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching IRS info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Navbar(userData: userData),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 40),
        color: Colors.grey[200],
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 40),
          margin: EdgeInsets.symmetric(vertical: 40),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kartu Detail Mahasiswa

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Detail Mahasiswa",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Nama: ${widget.mahasiswa['nama']}"),
                            Text("NIM: ${widget.mahasiswa['nim']}"),
                            Text("Semester: $selectedSemester"),
                            Text("IPK: $ipk"),
                          ],
                        ),
                        const SizedBox(width: 32),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("IPS: $ips"),
                            Text("Maks Beban SKS: $maxSks"),
                            Text("Status IRS: ${irsInfo['status_irs']}"),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(),
              // Header Tabel dan Dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Isian Rencana Studi",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      value: selectedSemester,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedSemester = value;
                            fetchIRSJadwal(value);
                            fetchIRSInfo(value);
                          });
                        }
                      },

                      underline:
                          SizedBox(), // Menghilangkan garis bawah dropdown
                      items: List.generate(
                        widget.mahasiswa[
                            'semester'], // Maksimal semester mahasiswa
                        (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text(
                            "Semester ${index + 1}",
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Tabel Jadwal IRS
              Container(
                // width:
                width:
                    double.infinity, // Make the container take the full width
                margin: const EdgeInsets.symmetric(horizontal: 16),

                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width),
                    child: DataTable(
                      columnSpacing: 16,
                      headingRowColor: WidgetStateProperty.resolveWith(
                        (states) =>
                            const Color(0xFF162953), // Warna header biru muda
                      ),
                      columns: [
                        DataColumn(
                          label: Text(
                            'No',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Kode',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
                            'Dosen',
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
                      ],
                      rows: jadwalIRS.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final jadwal = entry.value;
                        return DataRow(cells: [
                          DataCell(Text(index.toString())),
                          DataCell(Text(jadwal.KodeMK)),
                          DataCell(Text(jadwal.NamaMK)),
                          DataCell(Text(jadwal.Kelas)),
                          DataCell(Text(jadwal.SKS.toString())),
                          DataCell(Text(jadwal.DosenPengampu.join(', '))),
                          DataCell(Text(jadwal.status)),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tombol Setuju dan Unapprove
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: (selectedSemester < widget.mahasiswa['semester']) || irsInfo['status_irs'] == 'Disetujui'
                        ? null // Disable tombol jika selectedSemester < semester mahasiswa
                        : () async {
                            // Menjalankan fungsi approveIRS
                            await approveIRS(
                                widget.mahasiswa['nim'], selectedSemester);

                            // Memanggil fungsi untuk mendapatkan data terbaru dan merefresh halaman
                            setState(() {
                              fetchData();
                              fetchIRSInfo(widget.mahasiswa["semester"]);
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (selectedSemester <
                              widget.mahasiswa['semester'])
                          ? Colors.grey // Tombol menjadi abu-abu jika disabled
                          : Colors.blue, // Warna biru untuk tombol aktif
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            10), // Membuat sudut tombol melengkung
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, // Padding horizontal dalam tombol
                        vertical: 12, // Padding vertical dalam tombol
                      ),
                    ),
                    child: const Text('Setuju',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: (selectedSemester <
                                widget.mahasiswa['semester']) ||
                            irsInfo['status_irs'] != 'Disetujui'
                        ? null // Disable tombol jika selectedSemester < semester mahasiswa atau status IRS bukan 'Disetujui'
                        : () async {
                            await unapproveIRS(
                                widget.mahasiswa['nim'], selectedSemester);
                            setState(() {
                              fetchData();
                              fetchIRSInfo(widget.mahasiswa["semester"]);
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (selectedSemester <
                                  widget.mahasiswa['semester']) ||
                              irsInfo['status_irs'] != 'Disetujui'
                          ? Colors.grey // Tombol menjadi abu-abu jika disabled
                          : Colors.red, // Tombol merah jika aktif
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            10), // Membuat sudut tombol melengkung
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, // Padding horizontal dalam tombol
                        vertical: 12, // Padding vertical dalam tombol
                      ),
                    ),
                    child: const Text('Batal Setujui',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  buildPrintButton()
                ],
              ),
            ],
          ),
        ),
      ),
    );
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


  DateTime today = DateTime.now();  
  String getFormattedDate() {
    return DateFormat('d MMMM yyyy').format(today);
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
                                        widget.mahasiswa['nama'],
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
                                        widget.mahasiswa['nim'],
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
                                        widget.mahasiswa['jurusan'] ?? '',
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
                                        widget.userData['name'],
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
                            pw.MemoryImage(base64Decode(widget.mahasiswa['profile_image_base64'])),
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
                                widget.userData['name'],
                                style: pw.TextStyle(fontSize: 8),
                              ),
                            ),
                                          pw.Align(
                              alignment: pw.Alignment.topLeft,  // Aligns text to the left
                              child: pw.Text(
                                "NIP. ${widget.userData['identifier']}",
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
                                widget.mahasiswa['nama'],
                                style: pw.TextStyle(fontSize: 8),
                              ),
                            ),
                            pw.Align(
                              alignment: pw.Alignment.topLeft,  // Aligns text to the left
                              child: pw.Text(
                                "NIM.${widget.mahasiswa['nim']}",
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
