class Jadwal {
  final int idJadwal;
  final String KodeMK;
  final String NamaMK;
  final String Ruangan;
  final String Hari;
  final String JamMulai;
  final String JamSelesai;
  final String Kelas;
  final int SKS;
  final List<String> DosenPengampu;

  Jadwal({
    required this.idJadwal,
    required this.KodeMK,
    required this.NamaMK,
    required this.Ruangan,
    required this.Hari,
    required this.JamMulai,
    required this.JamSelesai,
    required this.Kelas,
    required this.SKS,
    required this.DosenPengampu
  });

  factory Jadwal.fromJson(Map<String, dynamic> json) {
    return Jadwal(
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
    );
  }
}

