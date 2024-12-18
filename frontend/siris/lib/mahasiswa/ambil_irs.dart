import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:siris/class/JadwalIRS.dart';
import 'package:siris/class/MahasiswaInfo.dart';
import 'package:siris/navbar.dart';
import 'package:logging/logging.dart';

final loggerJadwal = Logger('AmbilIRSState');

class AmbilIRS extends StatefulWidget {
  final Map<String, dynamic> userData;

  const AmbilIRS({super.key, required this.userData});

  @override
  AmbilIRSState createState() => AmbilIRSState();
}

class AmbilIRSState extends State<AmbilIRS> {
  List<dynamic> mataKuliahList = []; 
  List<dynamic> jadwalList = [];
  List<dynamic> jadwalListIRS = [];
  List<MahasiswaInfo> infoMahasiswa = []; 
  dynamic selectedMataKuliah;
  dynamic selectedJadwal;
  List<dynamic> selectedMatKul = [];
  List<dynamic> selectedMatKulFetchJadwal = [];
  Map<String, List<dynamic>> jadwalMap = {}; 
  List<dynamic> takenMataKuliahList = [];
  get userData => widget.userData;
  late int maxSks;
  Map<String, dynamic> irsInfo = {'status_irs': 'Tidak Ada Data'};
  DateTime targetDate = DateTime(2024, 12, 16);
  DateTime now = DateTime.now();

  String totalSks = '0';
  String ipk = '0.0';
  String ips ='0.0';
  String currentSKS = '0.0';

  @override
  void initState() {
    super.initState();
    fetchMataKuliah();
    fetchIRSJadwal();
    fetchDaftarMataKuliah();
    fetchData();
    fetchIRSInfo();
    maxSks=20;
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
   final nim = userData['identifier'];
    final semester = userData['semester'];
    final String apiUrl = 'http://localhost:8080/mahasiswa/info-mahasiswa/$nim?semester=$semester';
    debugPrint("Semester : $semester");
    try {
      loggerJadwal.info("Fetching data mahasiswa, url: $apiUrl");
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        // Decode the JSON response
        final data = json.decode(response.body);
        setState(() {
          totalSks = data['total_sks'].toString();
          ipk = data['ipk'].toString();
          ips = data['ips'].toString();
          currentSKS = data['current_sks'].toString();
          updateMaxSks();
        });
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

  Future<void> fetchMataKuliah() async {
    final nim = userData['identifier'];
    final prodi = userData['jurusan'];
    final url = 'http://localhost:8080/mahasiswa/$nim/mata-kuliah?prodi=$prodi';
    final response = await http.get(Uri.parse(url));
    debugPrint('Nim ID: $nim, jurusan : $prodi');
    if (response.statusCode == 200) {
      setState(() {
        mataKuliahList = json.decode(response.body);
      });
      debugPrint("Anchor2 $mataKuliahList");
    } 
    else {
      loggerJadwal.severe('Error: ${response.statusCode}');
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil data mata kuliah')),
      );
      }
    }
  }

  Future<List<JadwalIRS>> fetchIRSJadwal() async {
    final nim = userData['identifier'];
    final semester = userData['semester'];
    final String url = 'http://localhost:8080/mahasiswa/all-jadwal/$nim?semester=$semester';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Iterasi data dan masukkan ke dalam map
        for (var item in data) {
          loggerJadwal.info('Mata Kuliah: ${item['nama_mk']}, Status: ${item['status']}');  // Log untuk memeriksa status tiap item
          final kodeMK = item['kode_mk'];
          if (jadwalMap.containsKey(kodeMK)) {
            jadwalMap[kodeMK]!.add(item);
          } else {
            jadwalMap[kodeMK] = [item];
          }
        }
        setState(() {});
        return data.map((item) => JadwalIRS.fromJson(item)).toList();
      } else {
        throw Exception('Gagal mengambil data jadwal.');
      }
    } catch (e) {
      loggerJadwal.severe('Error: $e');
      return [];
    }
  }

  Future<void> fetchJadwal(String kodeMK) async {
    loggerJadwal.info('Fetching Data Jadwal: $kodeMK');
    final url = 'http://localhost:8080/mahasiswa/$kodeMK/jadwal-mata-kuliah';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      setState(() {
        final mataKuliahData = mataKuliahList.firstWhere((mataKuliah) => mataKuliah['kode_mk'] == kodeMK);
        jadwalList = json.decode(response.body).map((jadwal) {
          return {
            ...jadwal,
            'nama_mk': mataKuliahData['nama_mk'],
            'status': mataKuliahData['status'],
            'kode_mk': mataKuliahData['kode_mk'],
            'semester': mataKuliahData['semester'],
            'sks': mataKuliahData['sks'],
          };
        }).toList();
        debugPrint("JadwalList : $jadwalList");
      });
    } else {
      Map<String, dynamic> e = json.decode(response.body);
      loggerJadwal.severe('Status: ${response.statusCode}, Message: ${e['message']}');
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data jadwal $kodeMK')),
        );
      }
    }
  }

  Future<bool> addJadwalToIRS(String kodeMK, int jadwalID) async {
    final nim = widget.userData['identifier'];
    final ips = double.tryParse(ipk); // Menggunakan nilai IPS yang sudah didapat
    final currentSks = int.tryParse(currentSKS); // SKS yang sudah diambil

    loggerJadwal.severe("anchorr", mataKuliahList);
    // Cari SKS dari mataKuliahList berdasarkan kodeMK
    final mataKuliah = mataKuliahList.firstWhere(
      (mk) => mk['kode_mk'] == kodeMK,
      orElse: () => null, // Menghindari error jika tidak ditemukan
    );

    if (mataKuliah == null) {
      // Jika mata kuliah tidak ditemukan, tampilkan pesan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mata kuliah telah diambil')),
      );
      // loggerJadwal.severe('Mata kuliah dengan kode $kodeMK tidak ditemukan.');
      return false;
    }

    final sksMataKuliah = mataKuliah['sks']; // Ambil SKS mata kuliah yang akan ditambahkan

    if (currentSks != null && sksMataKuliah != null) {
      // Hitung total SKS jika jadwal ini ditambahkan
      final totalSksAfterAdding = currentSks + sksMataKuliah;

      // Tentukan batasan SKS berdasarkan IPS
      if (ips != null) {
        if (ips >= 3) {
          maxSks = 24; // Jika IPS >= 3, maksimal 24 SKS
        } else if (ips >= 2.5 && ips < 3) {
          maxSks = 22; // Jika IPS antara 2.5 dan 2.99, maksimal 22 SKS
        } else {
          maxSks = 20; // Jika IPS < 2.5, maksimal 20 SKS
        }
      } else {
        // Jika IPS tidak valid, anggap sebagai 0
        maxSks = 20;
      }

      // Periksa apakah total SKS setelah ditambahkan melebihi batasan
      if (totalSksAfterAdding > maxSks) {
        // Jika SKS yang sudah diambil + SKS mata kuliah lebih dari batasan, tampilkan pesan error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anda tidak dapat menambah jadwal karena total SKS melebihi batas.')),
        );
        loggerJadwal.severe('Gagal menambahkan jadwal: Total SKS melebihi batas. IPS: $ips, Max SKS: $maxSks, Current SKS: $currentSks, Mata Kuliah SKS: $sksMataKuliah');
        return false;
      }
    }

    // Jika SKS masih memungkinkan untuk ditambah, lanjutkan ke proses menambah jadwal ke IRS
    final url = 'http://localhost:8080/mahasiswa/$nim/add-irs?kode_mk=$kodeMK&jadwal_id=$jadwalID';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'nim': nim,
          'kode_mk': kodeMK,
          'jadwal_id': jadwalID.toString(),
        },
      );

      if (response.statusCode == 200) {
        // Jadwal berhasil ditambahkan
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jadwal berhasil ditambahkan ke IRS')),
        );
        loggerJadwal.info('Status Code: ${response.statusCode}, Message: Berhasil Menambahkan Jadwal');
        return true; // Berhasil
      } else {
        // Gagal menambahkan jadwal
        final Map<String, dynamic> error = json.decode(response.body);
        loggerJadwal.severe('Status Code: ${response.statusCode}, Message: ${error['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan jadwal ke IRS: ${error['message']}')),
        );
        return false; // Gagal
      }
    } catch (e) {
      // Tangani kesalahan
      loggerJadwal.severe('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
      return false; // Gagal
    }
  }

  Future<void> removeJadwalFromIRS(String kodeMK, int jadwalID) async {
  final nim = widget.userData['identifier']; // NIM dari user data
  final url = 'http://localhost:8080/mahasiswa/$nim/remove-irs?kode_mk=$kodeMK&jadwal_id=$jadwalID';

  try {
    final response = await http.delete(Uri.parse(url));
    if(mounted){
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jadwal berhasil dihapus dari IRS')),
        );
        fetchJadwalIRS(); // Refresh jadwal IRS list
      } 
      else if (response.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data tidak ditemukan di IRS')),
        );
      } 
      else {
        Map<String,dynamic> e = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus jadwal dari IRS')),
        );
        loggerJadwal.severe('Status Code: ${response.statusCode}, Message: ${e['message']}');
      }
    }
  } catch (e) {
    loggerJadwal.severe('Error: $e');
    if(mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan, coba lagi nanti')),
      );
    }
  }
}
Future<void> fetchIRSInfo() async {
  final nim = widget.userData['identifier'];
  final semester = widget.userData['semester'];
  final url = 'http://localhost:8080/mahasiswa/$nim/irs-info?semester=$semester';
  debugPrint("semester : $semester , nim : $nim");
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
      debugPrint("status_irs : $irsInfo");
    } else {
      print('Failed to fetch IRS info: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching IRS info: $e');
  }
}


  Future<void> fetchJadwalIRS() async {
    final nim = widget.userData['identifier'];
    final url = 'http://localhost:8080/mahasiswa/$nim/jadwal';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      setState(() {
        jadwalListIRS = json.decode(response.body);
      });
    } else {
      Map<String, dynamic> e = json.decode(response.body);
      loggerJadwal.severe('Status Code: ${response.statusCode}, Message: ${e['message']}');
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil data jadwal IRS')),
        );
      }
    }
  }


   Future<void> fetchDaftarMataKuliah() async {
    final String url = 'http://localhost:8080/mahasiswa/daftar-matkul/${widget.userData['identifier']}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          takenMataKuliahList = json.decode(response.body);
        });
        debugPrint("taken $takenMataKuliahList");
      } else {
        setState(() {
          takenMataKuliahList.clear();
        });
        
        throw Exception('Failed to load mata kuliah');
      }
    } catch (e) {
      setState(() {
          takenMataKuliahList.clear();
        });
      debugPrint('Error fetching mata kuliah: $e');
    }
  }

  void showDeleteConfirmationDialog(String kodeMK, int jadwalID) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Penghapusan'),
          content: const Text('Apakah Anda yakin ingin menghapus jadwal ini?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Tidak'),
            ),
            TextButton(
              onPressed: () async  {
                // Placeholder for delete action
                showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return const Center(child: CircularProgressIndicator());
                    },
                );
                await removeJadwalFromIRS(kodeMK, jadwalID);
                if(context.mounted){
                  Navigator.of(context).pop(); // Tutup loader
                  Navigator.of(context).pop(); // Tutup loader

                  // Refresh data di halaman utama
                    setState(() async {
                     jadwalMap.clear(); // Membersihkan data lama
                      // Fetch data terbaru setelah jadwal ditambahkan
                        await fetchData();
                        await fetchMataKuliah(); // Memuat mata kuliah terbaru
                        await fetchIRSJadwal();  // Memuat jadwal IRS terbaru
                        debugPrint("takenmaktlu: $takenMataKuliahList");
                        takenMataKuliahList= [];
                        await fetchDaftarMataKuliah(); // Memuat daftar mata kuliah yang tersedia
                    });
                }
              },
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );
  }


  int getDayIndex(String day) {
  const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];
  return days.indexOf(day);
  
}

int getTimeIndex(String time) {
  // Extract hour from time string (e.g., "10:00" -> 10)
  final hour = int.parse(time.split(':')[0]);
  return hour - 7; // Subtract 7 since rows start from 07:00
}


bool isTimeOverlapping(String start1, String end1, String start2, String end2) {
  // Ekstrak jam dan menit dari format HH:MM:SS
  TimeOfDay parseTime(String time) {
    final parts = time.split(':'); // Pisahkan berdasarkan ':'
    return TimeOfDay(
      hour: int.parse(parts[0]), // Jam
      minute: int.parse(parts[1]), // Menit
    );
  }

  // Konversi waktu menjadi TimeOfDay
  final timeStart1 = parseTime(start1);
  final timeEnd1 = parseTime(end1);
  final timeStart2 = parseTime(start2);
  final timeEnd2 = parseTime(end2);

  // Periksa apakah interval waktu bertabrakan
  return !(timeEnd1.hour < timeStart2.hour ||
      (timeEnd1.hour == timeStart2.hour && timeEnd1.minute <= timeStart2.minute) ||
      timeStart1.hour > timeEnd2.hour ||
      (timeStart1.hour == timeEnd2.hour && timeStart1.minute >= timeEnd2.minute));
}

void showConflictDialog(String namaMK, String kodeMK) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Jadwal Bentrok"),
        content: Text(
          "Jadwal untuk mata kuliah $namaMK ($kodeMK) bertabrakan dengan jadwal lain yang sudah diambil. Silakan pilih jadwal lain.",
        ),
        actions: <Widget>[
          TextButton(
            child: Text("OK"),
            onPressed: () {
              Navigator.of(context).pop(); // Tutup dialog
            },
          ),
        ],
      );
    },
  );
}

Future<bool?> showAddConfirmationDialog(BuildContext context, String namaMk) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Konfirmasi Tambah Jadwal'),
        content: Text('Apakah Anda yakin ingin menambahkan mata kuliah "$namaMk" ke IRS?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Pilih "Tidak"
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true), // Pilih "Ya"
            child: const Text('Ya'),
          ),
        ],
      );
    },
  );
}

void showAfterPengisianDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Sudah lewat batas Penggantian IRS"),
        content: Text(
          "Jadwal pada IRS hanya bisa dibatalkan",
        ),
        actions: <Widget>[
          TextButton(
            child: Text("OK"),
            onPressed: () {
              Navigator.of(context).pop(); // Tutup dialog
            },
          ),
        ],
      );
    },
  );
}

void showAkhirPengisianDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Sudah lewat batas Pengisian"),
        content: Text(
          "Sudah tidak bisa mengubah IRS sama sekali",
        ),
        actions: <Widget>[
          TextButton(
            child: Text("OK"),
            onPressed: () {
              Navigator.of(context).pop(); // Tutup dialog
            },
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    Duration difference = now.difference(targetDate);
    int daysDifference = difference.inDays;
    return Scaffold(
      appBar: Navbar(userData: userData),
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[200],  // Set the background color to light gray
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Container( 
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      // decoration: BoxDecoration(
                      //   border: Border.all(
                      //     color: Colors.blue, // Border color
                      //     width: 2.0, // Border width
                      //   ),
                      //   borderRadius: BorderRadius.circular(10), // Optional: Rounded corners
                      // ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.person, // Edit icon
                                color: Colors.black,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Detail Mahasiswa',
                                textAlign: TextAlign.left,
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                            ],),
                          const SizedBox(height: 20),
                          Table(
                            columnWidths: const {
                              0: FractionColumnWidth(0.4),
                              1: FractionColumnWidth(0.6),
                            },
                            children: [
                              TableRow(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Nama', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(':', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(userData['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              TableRow(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('NIM', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(':', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(userData['identifier'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              TableRow(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Semester', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(':', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                 Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      userData['semester'].toString(), // Konversi int ke String
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              TableRow(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('IPK', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(':', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(ipk, style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              TableRow(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('IPS', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(':', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(ips, style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              TableRow(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('SKS yang bisa diambil', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(':', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(maxSks.toString(), style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          DropdownButton<dynamic>(
                            hint: const Text("Pilih Mata Kuliah"),
                            value: selectedMataKuliah,
                            isExpanded: true,
                            onChanged: (irsInfo['status_irs'] != 'Disetujui' && daysDifference <= 3 ) // Hanya aktif jika selisih <= 14 hari
                              ? (newValue) {
                                  setState(() {
                                    selectedMataKuliah = newValue;
                                    // Reset jadwal saat mata kuliah diubah
                                    // fetchJadwal(newValue['kode_mk']);
                                  });
                                }
                              : null, // Disable dropdown jika lebih dari 2 minggu
                            items: mataKuliahList
                                .where((mataKuliah) => !selectedMatKul.contains(mataKuliah))
                                .map<DropdownMenuItem<dynamic>>((mataKuliah) {
                                return DropdownMenuItem<dynamic>(
                                  value: mataKuliah,
                                  child: Text('${mataKuliah['kode_mk']} - ${mataKuliah['nama_mk']}'),
                                );
                              }).toList(),
                          ),

                          ElevatedButton(
                            onPressed: selectedMataKuliah != null
                                ? () async {
                                      await fetchJadwal(selectedMataKuliah['kode_mk']); // Fetch jadwal asynchronously

                                      setState(() {
                                      // Tambahkan ke selectedMatKul (list mata kuliah yang dipilih)
                                      selectedMatKul.add(selectedMataKuliah);

                                      // Perbarui jadwalMap untuk kode_mk yang dipilih
                                      jadwalMap[selectedMataKuliah['kode_mk']] = List.from(jadwalList); 

                                      // Perbarui takenMataKuliahList tanpa duplikasi
                                      if (!takenMataKuliahList.contains(selectedMataKuliah)) {
                                        takenMataKuliahList.add(selectedMataKuliah);
                                      }

                                      // Reset selectedMataKuliah setelah ditambahkan
                                      selectedMataKuliah = null; 

                                      // Debugging untuk memantau isi jadwalMap
                                      debugPrint("JadwalMap:");
                                      jadwalMap.forEach((kodeMk, jadwalList) {
                                        debugPrint('Kode MK: $kodeMk');
                                        debugPrint('Jadwal: $jadwalList');
                                      });
                                    });
                          
                                    debugPrint("Selected matkul $selectedMatKul");
                                    debugPrint("selectedMatKulJadwal $selectedMatKulFetchJadwal");
                                  }

                                : null,
                            child: const Row (
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  ),
                                SizedBox(width: 8), 
                                Text("Tambah Mata Kuliah"),
                              ],),
                            
                          ),
                        ],
                      )
                    ),
                    
                    const SizedBox(height: 10),
                    
                    const SizedBox(height: 20),
  
                  Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: takenMataKuliahList.map((mk) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  top: BorderSide(color: Colors.grey, width: 4),
                                  bottom: BorderSide(color: Colors.grey, width: 4),
                                  right: BorderSide(color: Colors.grey, width: 4),
                                  left: BorderSide(color: Colors.grey, width: 16),
                                ),
                              ),
                              child: Text(
                                "${mk['nama_mk']} - ${mk['kode_mk']}",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            flex : 3,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal:16),
              child :Column(
                children: [
                  Row( 
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Tabel Jadwal",
                        textAlign: TextAlign.left,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue[900], // Warna biru tua
                              borderRadius: BorderRadius.circular(8), // Membuat sudut melengkung
                            ),
                            child: Text(
                              "Jumlah SKS Diambil : $currentSKS",
                              style: const TextStyle(
                                color: Colors.white, // Warna teks putih
                                fontWeight: FontWeight.bold, // Teks tebal
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          // _buildSaveButton()
                        ],
                      )
                  ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (daysDifference > 3 && daysDifference <= 5) 
                      Text(
                          "Tidak bisa menambah jadwal lagi",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      if (daysDifference > 5) 
                        Text(
                          "Sudah tidak bisa mengubah IRS lagi",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Table(
                      border: TableBorder.all(), // Add borders for each cell
                      children: [
                        // Header row with days of the week
                        TableRow(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              color: Colors.blueGrey,
                              child: const Text(
                                'Time\\Day',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            ...['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'].map((day) {
                              return Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.blueGrey,
                                child: Text(
                                  day,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              );
                            }),
                          ],
                        ),
                        // Rows with time slots
                        ...List.generate(15, (index) {
                          final time = "${(7 + index).toString().padLeft(2, '0')}:00";
                        
                          return TableRow(
                            
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.blueGrey[100],
                                child: Text(time, textAlign: TextAlign.center),
                              ),
                              ...List.generate(5, (dayIndex) {
                                // Find the event for the current time and day
                                List<Widget> events = [];
                                jadwalMap.forEach((kodeMk, jadwalList) {
                                  for (var jadwal in jadwalList) {
                                    final dayIndexMap = getDayIndex(jadwal['hari']);
                                    final timeIndexMap = getTimeIndex(jadwal['jam_mulai']);
                                    final status = jadwal['status']; // ambil status jadwal

                                    // print('Kode MK: $kodeMk');
                                    // debugPrint('Jadwal: ${jadwal['id_jadwal']}');

                                    // print('eventDayIndex: $dayIndexMap, eventTimeIndex: $timeIndexMap');
                                    // print('dayIndex: $dayIndex, timeIndex: $index');


                                    if (dayIndex == dayIndexMap && index == timeIndexMap) {
                                       String eventText = '${jadwal['nama_mk']} ($kodeMk)\n'
                                        '${jadwal['hari']} ${jadwal['jam_mulai']} - ${jadwal['jam_selesai']}\n'
                                        '${jadwal['kode_ruangan']} ${jadwal['kelas']} • ${jadwal['sks']} SKS'; // Tambahkan enter (\n) antar elemen

                                        // Cek konflik dengan jadwal "diambil"
                                        bool hasConflict = false;
                                        if (status != 'diambil') { // Hanya cek konflik untuk jadwal yang tidak "diambil"
                                          jadwalMap.forEach((_, otherJadwals) {
                                            for (var otherJadwal in otherJadwals) {
                                              if (otherJadwal['status'] == 'diambil' &&
                                                  otherJadwal['hari'] == jadwal['hari'] &&
                                                  isTimeOverlapping(
                                                    jadwal['jam_mulai'], jadwal['jam_selesai'],
                                                    otherJadwal['jam_mulai'], otherJadwal['jam_selesai'],
                                                  )) {
                                                hasConflict = true;
                                                jadwal['status']='konflik';
                                              }
                                            }
                                          });
                                        }
                                      events.add(
                                        Padding(
                                          padding: const EdgeInsets.all(4.0), // Tambahkan padding untuk jarak antar tombol
                                          child: ElevatedButton(
                                            onPressed: (irsInfo['status_irs'] == 'Disetujui')
                                              ? null
                                              : () async {
                                                  if (daysDifference <= 3) {
                                                    // Dalam 2 minggu: Bisa tambah atau hapus jadwal
                                                    if (hasConflict) {
                                                      showConflictDialog(jadwal['nama_mk'], jadwal['kode_mk']);
                                                    } else if (status == 'diambil') {
                                                      showDeleteConfirmationDialog(jadwal['kode_mk'], jadwal['id_jadwal']);
                                                    } else {
                                                      final confirm = await showAddConfirmationDialog(context, jadwal['nama_mk']);
                                                      if (confirm == true) {
                                                        final success = await addJadwalToIRS(jadwal['kode_mk'], jadwal['jadwal_id']);
                                                        if (success) {
                                                          setState(() async {
                                                            jadwalMap.clear();
                                                            await fetchData();
                                                            await fetchMataKuliah();
                                                            await fetchIRSJadwal();
                                                            await fetchDaftarMataKuliah();
                                                          });
                                                        }
                                                      }
                                                    }
                                                  } else if (daysDifference <= 5) {
                                                    // Antara minggu ke-2 dan ke-4: Hanya bisa hapus jadwal
                                                    if (status == 'diambil') {
                                                      showDeleteConfirmationDialog(jadwal['kode_mk'], jadwal['id_jadwal']);
                                                    } else {
                                                      showAfterPengisianDialog();
                                                    }
                                                  } else {
                                                    // Lebih dari 4 minggu: Tombol dinonaktifkan
                                                    showAkhirPengisianDialog();
                                                  }
                                                },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: (hasConflict 
                                                  ? Colors.red 
                                                  : (status != 'diambil' 
                                                      ? Colors.grey 
                                                      : Colors.blue)),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8.0), // Bentuk kotak dengan sudut tumpul
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Padding dalam tombol
                                            ),
                                            child: Text(
                                              eventText,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                              fontWeight: FontWeight.bold, // Teks menjadi tebal
                                              fontSize: 14.0, // Ukuran teks yang sesuai
                                              color: Colors.white, // Warna teks agar kontras dengan tombol
                                            ),
                                            ),
                                          ),
                                        ),

                                    );
                                    }
                                  }
                                });

                                return Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    children: events, // Add all events in column to avoid overlap
                                  ),// Empty if no event
                                );
                              }),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),


                ],)
            )
            )
        ],
        )
    );
  }
}

  // Widget _buildSaveButton(){
  //   return ElevatedButton(
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: Colors.greenAccent, // Button background color
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(24), // Rounded edges
  //             ),
  //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //           ),
  //           onPressed: () {
  //             // Add button action here
  //           },
  //           child: const Row(
  //             mainAxisSize: MainAxisSize.min, // Keeps the button compact
  //             children: [
  //               Icon(
  //                 Icons.save, // Edit icon
  //                 color: Colors.white,
  //               ),
  //               SizedBox(width: 8), // Space between icon and text
  //               Text(
  //                 'Simpan IRS',
  //                 style: TextStyle(
  //                   color: Colors.white,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         );
          
  // }

  Widget _buildCourseCard(String event){
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(8),
      width: 40,
      decoration: BoxDecoration(
        color: Colors.green[300],
        border: Border(
          top:BorderSide(color: Colors.grey, width: 4),
          bottom:BorderSide(color: Colors.grey, width: 4),
          right:BorderSide(color: Colors.grey, width: 4),
          left: BorderSide(color: Colors.grey, width: 16)
        )
      ),
      child: Text(
        event,
        style: TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Widget _buildCourseCard2(){
  //   return a;
  // }