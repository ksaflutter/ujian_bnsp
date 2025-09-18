class StatsModel {
  final int totalAbsen;
  final int totalMasuk;
  final int totalIzin;
  final bool sudahAbsenHariIni;

  StatsModel({
    required this.totalAbsen,
    required this.totalMasuk,
    required this.totalIzin,
    required this.sudahAbsenHariIni,
  });

  factory StatsModel.fromJson(Map<String, dynamic> json) {
    return StatsModel(
      totalAbsen: json['total_absen'] ?? 0,
      totalMasuk: json['total_masuk'] ?? 0,
      totalIzin: json['total_izin'] ?? 0,
      sudahAbsenHariIni: json['sudah_absen_hari_ini'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_absen': totalAbsen,
      'total_masuk': totalMasuk,
      'total_izin': totalIzin,
      'sudah_absen_hari_ini': sudahAbsenHariIni,
    };
  }

  // Getter untuk persentase kehadiran
  double get persentaseKehadiran {
    if (totalAbsen == 0) return 0.0;
    return (totalMasuk / totalAbsen) * 100;
  }

  // Getter untuk persentase izin
  double get persentaseIzin {
    if (totalAbsen == 0) return 0.0;
    return (totalIzin / totalAbsen) * 100;
  }

  @override
  String toString() {
    return 'StatsModel(totalAbsen: $totalAbsen, totalMasuk: $totalMasuk, totalIzin: $totalIzin, sudahAbsenHariIni: $sudahAbsenHariIni)';
  }
}

class StatsResponse {
  final String message;
  final StatsModel? data;

  StatsResponse({required this.message, this.data});

  factory StatsResponse.fromJson(Map<String, dynamic> json) {
    return StatsResponse(
      message: json['message'] ?? '',
      data: json['data'] != null ? StatsModel.fromJson(json['data']) : null,
    );
  }
}
