class AttendanceModelLokin {
  final int? id;
  final String attendanceDate;
  final String? checkInTime;
  final String? checkOutTime;
  final double? checkInLat;
  final double? checkInLng;
  final double? checkOutLat;
  final double? checkOutLng;
  final String? checkInAddress;
  final String? checkOutAddress;
  final String? checkInLocation;
  final String? checkOutLocation;
  final String status; // masuk, izin
  final String? alasanIzin;
  final String? createdAt;
  final String? updatedAt;

  AttendanceModelLokin({
    this.id,
    required this.attendanceDate,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLat,
    this.checkInLng,
    this.checkOutLat,
    this.checkOutLng,
    this.checkInAddress,
    this.checkOutAddress,
    this.checkInLocation,
    this.checkOutLocation,
    required this.status,
    this.alasanIzin,
    this.createdAt,
    this.updatedAt,
  });

  factory AttendanceModelLokin.fromJson(Map<String, dynamic> json) {
    return AttendanceModelLokin(
      id: json['id'],
      attendanceDate: json['attendance_date'] ?? '',
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
      checkInLat: json['check_in_lat']?.toDouble(),
      checkInLng: json['check_in_lng']?.toDouble(),
      checkOutLat: json['check_out_lat']?.toDouble(),
      checkOutLng: json['check_out_lng']?.toDouble(),
      checkInAddress: json['check_in_address'],
      checkOutAddress: json['check_out_address'],
      checkInLocation: json['check_in_location'],
      checkOutLocation: json['check_out_location'],
      status: json['status'] ?? '',
      alasanIzin: json['alasan_izin'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attendance_date': attendanceDate,
      'check_in_time': checkInTime,
      'check_out_time': checkOutTime,
      'check_in_lat': checkInLat,
      'check_in_lng': checkInLng,
      'check_out_lat': checkOutLat,
      'check_out_lng': checkOutLng,
      'check_in_address': checkInAddress,
      'check_out_address': checkOutAddress,
      'check_in_location': checkInLocation,
      'check_out_location': checkOutLocation,
      'status': status,
      'alasan_izin': alasanIzin,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  bool get hasCheckedIn => checkInTime != null;
  bool get hasCheckedOut => checkOutTime != null;
  bool get isPermission => status == 'izin';
  bool get isPresent => status == 'masuk';

  String get displayStatus {
    switch (status) {
      case 'masuk':
        return 'Hadir';
      case 'izin':
        return 'Izin';
      default:
        return status;
    }
  }

  AttendanceModelLokin copyWith({
    int? id,
    String? attendanceDate,
    String? checkInTime,
    String? checkOutTime,
    double? checkInLat,
    double? checkInLng,
    double? checkOutLat,
    double? checkOutLng,
    String? checkInAddress,
    String? checkOutAddress,
    String? checkInLocation,
    String? checkOutLocation,
    String? status,
    String? alasanIzin,
    String? createdAt,
    String? updatedAt,
  }) {
    return AttendanceModelLokin(
      id: id ?? this.id,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInLat: checkInLat ?? this.checkInLat,
      checkInLng: checkInLng ?? this.checkInLng,
      checkOutLat: checkOutLat ?? this.checkOutLat,
      checkOutLng: checkOutLng ?? this.checkOutLng,
      checkInAddress: checkInAddress ?? this.checkInAddress,
      checkOutAddress: checkOutAddress ?? this.checkOutAddress,
      checkInLocation: checkInLocation ?? this.checkInLocation,
      checkOutLocation: checkOutLocation ?? this.checkOutLocation,
      status: status ?? this.status,
      alasanIzin: alasanIzin ?? this.alasanIzin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Response model for attendance operations
class AttendanceResponseLokin {
  final String message;
  final AttendanceModelLokin? data;

  AttendanceResponseLokin({required this.message, this.data});

  factory AttendanceResponseLokin.fromJson(Map<String, dynamic> json) {
    return AttendanceResponseLokin(
      message: json['message'] ?? '',
      data: json['data'] != null
          ? AttendanceModelLokin.fromJson(json['data'])
          : null,
    );
  }

  get attendance => null;
}

// History response model
class AttendanceHistoryResponseLokin {
  final String message;
  final List<AttendanceModelLokin> data;

  AttendanceHistoryResponseLokin({required this.message, required this.data});

  factory AttendanceHistoryResponseLokin.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryResponseLokin(
      message: json['message'] ?? '',
      data: json['data'] != null
          ? (json['data'] as List)
              .map((item) => AttendanceModelLokin.fromJson(item))
              .toList()
          : [],
    );
  }
}
