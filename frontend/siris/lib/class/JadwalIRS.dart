import 'package:siris/class/Jadwal.dart';
class JadwalIRS extends Jadwal {
  final String status;

  JadwalIRS({
    required super.idJadwal,
    required super.KodeMK,
    required super.NamaMK,
    required super.Ruangan,
    required super.Hari,
    required super.JamMulai,
    required super.JamSelesai,
    required super.Kelas,
    required super.SKS,
    required super.DosenPengampu,
    required this.status, //Status pengambilan
  });

  factory JadwalIRS.fromJson(Map<String, dynamic> json) {
    return JadwalIRS(
      idJadwal: json['jadwal_id'],
      KodeMK: json['kode_mk'],
      NamaMK: json['nama_mk'],
      Ruangan: json['kode_ruangan'],
      Hari: json['hari'],
      JamMulai: json['jam_mulai'],
      JamSelesai: json['jam_selesai'],
      Kelas: json['kelas'],
      SKS: json['sks'],
      DosenPengampu: List<String>.from(json['dosen_pengampu']),
      status: json['status'],
    );
  }
}