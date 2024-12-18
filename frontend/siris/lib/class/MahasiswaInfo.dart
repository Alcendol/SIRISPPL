class MahasiswaInfo {
  final String nim;
  final String idsem;
  final double ipk;
  final double ips;
  final int totalSks;
  final int currentSks;
  final int angkatan;
  final int currentSemester;

  MahasiswaInfo({
    required this.nim,
    required this.idsem,
    required this.ipk,
    required this.ips,
    required this.totalSks,
    required this.currentSks,
    required this.angkatan,
    required this.currentSemester,
  });

  factory MahasiswaInfo.fromJson(Map<String, dynamic> json) {
    return MahasiswaInfo(
      nim: json['nim'],
      idsem: json['idsem'],
      ipk: json['ipk'].toDouble(),
      ips: json['ips'].toDouble(),
      totalSks: json['total_sks'],
      currentSks: json['current_sks'],
      angkatan: json['angkatan'],
      currentSemester: json['current_semester'],
    );
  }
}