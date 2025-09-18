class BatchModel {
  final int id;
  final String batchKe;
  final String startDate;
  final String endDate;
  final String? createdAt;
  final String? updatedAt;
  final List<TrainingBatchModel>? trainings;

  BatchModel({
    required this.id,
    required this.batchKe,
    required this.startDate,
    required this.endDate,
    this.createdAt,
    this.updatedAt,
    this.trainings,
  });

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    List<TrainingBatchModel>? trainings;
    if (json['trainings'] != null) {
      trainings = (json['trainings'] as List)
          .map((item) => TrainingBatchModel.fromJson(item))
          .toList();
    }

    return BatchModel(
      id: json['id'] ?? 0,
      batchKe: json['batch_ke'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      trainings: trainings,
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
      'trainings': trainings?.map((e) => e.toJson()).toList(),
    };
  }

  String get displayName {
    return 'Batch $batchKe ($startDate - $endDate)';
  }

  @override
  String toString() {
    return 'BatchModel(id: $id, batchKe: $batchKe, startDate: $startDate, endDate: $endDate)';
  }
}

class TrainingBatchModel {
  final int id;
  final String title;
  final PivotModel? pivot;

  TrainingBatchModel({
    required this.id,
    required this.title,
    this.pivot,
  });

  factory TrainingBatchModel.fromJson(Map<String, dynamic> json) {
    return TrainingBatchModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      pivot: json['pivot'] != null ? PivotModel.fromJson(json['pivot']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'pivot': pivot?.toJson(),
    };
  }
}

class PivotModel {
  final String trainingBatchId;
  final String trainingId;

  PivotModel({
    required this.trainingBatchId,
    required this.trainingId,
  });

  factory PivotModel.fromJson(Map<String, dynamic> json) {
    return PivotModel(
      trainingBatchId: json['training_batch_id'] ?? '',
      trainingId: json['training_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'training_batch_id': trainingBatchId,
      'training_id': trainingId,
    };
  }
}

class BatchResponse {
  final String message;
  final List<BatchModel>? data;

  BatchResponse({
    required this.message,
    this.data,
  });

  factory BatchResponse.fromJson(Map<String, dynamic> json) {
    List<BatchModel>? batches;
    if (json['data'] != null) {
      batches = (json['data'] as List)
          .map((item) => BatchModel.fromJson(item))
          .toList();
    }

    return BatchResponse(
      message: json['message'] ?? '',
      data: batches,
    );
  }
}
