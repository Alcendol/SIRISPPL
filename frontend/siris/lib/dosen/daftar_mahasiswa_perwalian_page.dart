import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:siris/mahasiswa/detail_irs_mahasiswa.dart';
import 'package:siris/navbar.dart';

class DaftarMahasiswaPerwalianPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DaftarMahasiswaPerwalianPage({super.key, required this.userData});

  @override
  DaftarMahasiswaPerwalianPageState createState() =>
      DaftarMahasiswaPerwalianPageState();
}

class DaftarMahasiswaPerwalianPageState
    extends State<DaftarMahasiswaPerwalianPage> {
  List<dynamic> mahasiswaList = [];
  List<int> angkatanList = [];
  int? selectedAngkatan;
  bool isLoading = false;
  Map<String, dynamic> irsInfo = {'status_irs': 'Tidak Ada Data'};

  get userData => widget.userData;

  @override
  void initState() {
    super.initState();
    fetchMahasiswaPerwalian();
    fetchAngkatan();
  }

  Future<String> fetchIRSInfo(String nim, int semester) async {
    final url =
        'http://localhost:8080/mahasiswa/$nim/irs-info?semester=$semester';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return data[0]['status'];
        } else {
          return 'Tidak Ada Data';
        }
      } else {
        print('Failed to fetch IRS info: ${response.statusCode}');
        return 'Tidak Ada Data';
      }
    } catch (e) {
      print('Error fetching IRS info: $e');
      return 'Tidak Ada Data';
    }
  }

  Future<void> fetchAngkatan() async {
    final nip = widget.userData['identifier'];
    final url = 'http://localhost:8080/dosen/$nip/angkatan';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      setState(() {
        angkatanList = List<int>.from(json.decode(response.body));
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil data angkatan')),
        );
      }
    }
  }

  Future<void> fetchMahasiswaPerwalian() async {
    if (selectedAngkatan == null) return;

    setState(() {
      isLoading = true;
    });

    final nip = widget.userData['identifier'];
    final url =
        'http://localhost:8080/dosen/$nip/mahasiswa?angkatan=$selectedAngkatan';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> fetchedList = json.decode(response.body);

      // Update mahasiswaList with IRS info
      for (var mahasiswa in fetchedList) {
        final statusIrs =
            await fetchIRSInfo(mahasiswa['nim'], mahasiswa['semester']);
        mahasiswa['status_irs'] =
            statusIrs; // Tambahkan status IRS ke setiap mahasiswa
      }

      setState(() {
        mahasiswaList = fetchedList;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil data mahasiswa')),
        );
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Navbar(userData: userData),
      body: LayoutBuilder(builder: (context, constraints) {
        return Container(
            padding: EdgeInsets.symmetric(horizontal: 40),
            color: Colors.grey[200],
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 40),
              margin: EdgeInsets.symmetric(vertical: 40),
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 32),
                    child: const Text(
                      'Daftar Mahasiswa Perwalian',
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Dropdown untuk memilih angkatan
                        DropdownButton<int>(
                          hint: const Text("Pilih Angkatan"),
                          value: selectedAngkatan,
                          onChanged: (int? newValue) {
                            setState(() {
                              selectedAngkatan = newValue;
                            });
                            fetchMahasiswaPerwalian(); // Mem-fetch data mahasiswa sesuai angkatan
                          },
                          items: angkatanList
                              .map<DropdownMenuItem<int>>((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text('Angkatan $value'),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        // Tabel Mahasiswa
                        isLoading
                            ? const CircularProgressIndicator()
                            : MahasiswaTable(
                                mahasiswaList: mahasiswaList,
                                selectedAngkatan: selectedAngkatan,
                                irsInfo: irsInfo,
                                onDetailPressed: (mahasiswa) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => IRSDetailPage(
                                        mahasiswa: mahasiswa,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ));
      }),
    );
  }
}

class MahasiswaTable extends StatelessWidget {
  final List<dynamic> mahasiswaList;
  final int? selectedAngkatan;
  final Map<String, dynamic> irsInfo; // Add this parameter
  final Function(dynamic mahasiswa) onDetailPressed;

  const MahasiswaTable({
    super.key,
    required this.mahasiswaList,
    this.selectedAngkatan,
    required this.irsInfo, // Add this
    required this.onDetailPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // child: Card(
      //   // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      //   // elevation: 4,
      //   margin: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          // color: Colors.white,
        ),
        child: Column(
          children: [
            // Header tabel
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF162953), // Biru tua
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: const [
                    Expanded(child: Text('NIM', style: _headerTextStyle)),
                    Expanded(child: Text('Nama', style: _headerTextStyle)),
                    Expanded(child: Text('Status', style: _headerTextStyle)),
                    SizedBox(
                        width: 80,
                        child: Text('Aksi', style: _headerTextStyle)),
                  ],
                ),
              ),
            ),
            // Isi tabel
            ...mahasiswaList.map((mahasiswa) {
              return Container(
                decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.5)),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(mahasiswa['nim'] ?? '',
                            style: _contentTextStyle),
                      ),
                      Expanded(
                        child: Text(mahasiswa['nama'] ?? '',
                            style: _contentTextStyle),
                      ),
                      Expanded(
                        child: Text(mahasiswa['status_irs'] ?? 'Tidak Ada Data',
                            style: _contentTextStyle),
                      ),
                      SizedBox(
                        width: 80,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          onPressed: () => onDetailPressed(mahasiswa),
                          child: const Text(
                            'Detail',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Warna putih
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
      // ),
    );
  }
}

const TextStyle _headerTextStyle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.bold,
  fontSize: 14,
);

const TextStyle _contentTextStyle = TextStyle(
  color: Colors.black,
  fontSize: 14,
);
