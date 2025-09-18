class TrainingModel {
  final int id;
  final String title;
  final String? description;
  final int? participantCount;
  final String? standard;
  final String? duration;
  final String? createdAt;
  final String? updatedAt;
  final List<dynamic>? units;
  final List<dynamic>? activities;

  TrainingModel({
    required this.id,
    required this.title,
    this.description,
    this.participantCount,
    this.standard,
    this.duration,
    this.createdAt,
    this.updatedAt,
    this.units,
    this.activities,
  });

  factory TrainingModel.fromJson(Map<String, dynamic> json) {
    return TrainingModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      participantCount: json['participant_count'],
      standard: json['standard'],
      duration: json['duration'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      units: json['units'],
      activities: json['activities'],
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
      'units': units,
      'activities': activities,
    };
  }

  @override
  String toString() {
    return 'TrainingModel(id: $id, title: $title)';
  }
}

class TrainingResponse {
  final String message;
  final List<TrainingModel>? data;

  TrainingResponse({
    required this.message,
    this.data,
  });

  factory TrainingResponse.fromJson(Map<String, dynamic> json) {
    List<TrainingModel>? trainings;
    if (json['data'] != null) {
      trainings = (json['data'] as List)
          .map((item) => TrainingModel.fromJson(item))
          .toList();
    }

    return TrainingResponse(
      message: json['message'] ?? '',
      data: trainings,
    );
  }
}

class TrainingDetailResponse {
  final String message;
  final TrainingModel? data;

  TrainingDetailResponse({
    required this.message,
    this.data,
  });

  factory TrainingDetailResponse.fromJson(Map<String, dynamic> json) {
    return TrainingDetailResponse(
      message: json['message'] ?? '',
      data: json['data'] != null ? TrainingModel.fromJson(json['data']) : null,
    );
  }
}
