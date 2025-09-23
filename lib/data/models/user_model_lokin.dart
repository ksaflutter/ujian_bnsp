class UserModelLokin {
  final int id;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final String? profilePhoto;
  final String createdAt;
  final String updatedAt;
  final TrainingModelLokin? training;
  final List<BatchModelLokin> batches;

  UserModelLokin({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    this.profilePhoto,
    required this.createdAt,
    required this.updatedAt,
    this.training,
    this.batches = const [],
  });

  factory UserModelLokin.fromJson(Map<String, dynamic> json) {
    // Debug print untuk melihat struktur JSON
    print('UserModel JSON: $json');

    // Parse training dengan multiple fallback
    TrainingModelLokin? training;
    try {
      if (json['training'] != null) {
        training = TrainingModelLokin.fromJson(json['training']);
      } else if (json['trainings'] != null &&
          json['trainings'] is List &&
          (json['trainings'] as List).isNotEmpty) {
        // Fallback jika data training ada di field 'trainings' dan ambil yang pertama
        training =
            TrainingModelLokin.fromJson((json['trainings'] as List).first);
      }
    } catch (e) {
      print('Error parsing training: $e');
      training = null;
    }

    // Parse batches dengan multiple fallback
    List<BatchModelLokin> batches = [];
    try {
      if (json['batches'] != null && json['batches'] is List) {
        batches = (json['batches'] as List)
            .map((batch) => BatchModelLokin.fromJson(batch))
            .toList();
      } else if (json['batch'] != null) {
        // Fallback jika data batch ada di field 'batch' (singular)
        if (json['batch'] is List) {
          batches = (json['batch'] as List)
              .map((batch) => BatchModelLokin.fromJson(batch))
              .toList();
        } else {
          // Jika batch adalah object tunggal
          batches = [BatchModelLokin.fromJson(json['batch'])];
        }
      } else if (json['user_batches'] != null && json['user_batches'] is List) {
        // Fallback lain jika ada di field 'user_batches'
        batches = (json['user_batches'] as List)
            .map((batch) => BatchModelLokin.fromJson(batch))
            .toList();
      }
    } catch (e) {
      print('Error parsing batches: $e');
      batches = [];
    }

    print('Parsed batches count: ${batches.length}');
    if (batches.isNotEmpty) {
      print('First batch: ${batches.first.batchKe}');
    }

    return UserModelLokin(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      emailVerifiedAt: json['email_verified_at'],
      profilePhoto: json['profile_photo'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      training: training,
      batches: batches,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'email_verified_at': emailVerifiedAt,
      'profile_photo': profilePhoto,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'training': training?.toJson(),
      'batches': batches.map((batch) => batch.toJson()).toList(),
    };
  }

  UserModelLokin copyWith({
    int? id,
    String? name,
    String? email,
    String? emailVerifiedAt,
    String? profilePhoto,
    String? createdAt,
    String? updatedAt,
    TrainingModelLokin? training,
    List<BatchModelLokin>? batches,
  }) {
    return UserModelLokin(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      training: training ?? this.training,
      batches: batches ?? this.batches,
    );
  }

  @override
  String toString() {
    return 'UserModelLokin(id: $id, name: $name, email: $email, training: $training, batches: $batches)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModelLokin && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  static fromUserDataLokin(UserDataLokin userData) {}
}

// User data with token for authentication
class UserDataLokin {
  final String token;
  final UserModelLokin user;

  UserDataLokin({required this.token, required this.user});

  factory UserDataLokin.fromJson(Map<String, dynamic> json) {
    return UserDataLokin(
      token: json['token'] ?? '',
      user: UserModelLokin.fromJson(json['user'] ?? {}),
    );
  }

  get id => user.id;
  get name => user.name;
  get email => user.email;
  get emailVerifiedAt => user.emailVerifiedAt;
  get createdAt => user.createdAt;
  get updatedAt => user.updatedAt;
  get training => user.training;
  get batches => user.batches;

  Map<String, dynamic> toJson() {
    return {'token': token, 'user': user.toJson()};
  }
}

// Response model for user-related API calls
class UserResponseLokin {
  final String message;
  final UserDataLokin? data;

  UserResponseLokin({required this.message, this.data});

  factory UserResponseLokin.fromJson(Map<String, dynamic> json) {
    return UserResponseLokin(
      message: json['message'] ?? '',
      data: json['data'] != null ? UserDataLokin.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'message': message, 'data': data?.toJson()};
  }
}

// Training model for registration
class TrainingModelLokin {
  final int id;
  final String title;
  final String? description;
  final int? participantCount;
  final String? standard;
  final String? duration;
  final String? createdAt;
  final String? updatedAt;

  TrainingModelLokin({
    required this.id,
    required this.title,
    this.description,
    this.participantCount,
    this.standard,
    this.duration,
    this.createdAt,
    this.updatedAt,
  });

  factory TrainingModelLokin.fromJson(Map<String, dynamic> json) {
    return TrainingModelLokin(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      participantCount: json['participant_count'],
      standard: json['standard'],
      duration: json['duration'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'participant_count': participantCount,
      'standard': standard,
      'duration': duration,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  String toString() => 'TrainingModelLokin(id: $id, title: $title)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrainingModelLokin && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Batch model for registration
class BatchModelLokin {
  final int id;
  final String batchKe;
  final String startDate;
  final String endDate;
  final String? createdAt;
  final String? updatedAt;
  final List<TrainingModelLokin> trainings;

  BatchModelLokin({
    required this.id,
    required this.batchKe,
    required this.startDate,
    required this.endDate,
    this.createdAt,
    this.updatedAt,
    this.trainings = const [],
  });

  factory BatchModelLokin.fromJson(Map<String, dynamic> json) {
    // Debug print untuk batch parsing
    print('Batch JSON: $json');

    return BatchModelLokin(
      id: json['id'] ?? 0,
      batchKe: json['batch_ke'] ??
          json['name'] ??
          json['batch_name'] ??
          'Batch ${json['id'] ?? ''}',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      trainings: json['trainings'] != null
          ? (json['trainings'] as List)
              .map((item) => TrainingModelLokin.fromJson(item))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_ke': batchKe,
      'start_date': startDate,
      'end_date': endDate,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'trainings': trainings.map((training) => training.toJson()).toList(),
    };
  }

  @override
  String toString() => 'BatchModelLokin(id: $id, batchKe: $batchKe)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BatchModelLokin && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
