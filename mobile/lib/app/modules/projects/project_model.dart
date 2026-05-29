class ProjectModel {
  const ProjectModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.taskCount,
    this.workers = const [],
    this.description,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      workers: _readWorkers(json['workers']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      taskCount: json['taskCount'] as int,
    );
  }

  factory ProjectModel.fromDatabase(Map<String, Object?> row) {
    return ProjectModel(
      id: row['id'] as int,
      name: row['name'] as String,
      description: row['description'] as String?,
      workers: _readWorkers(row['workers']),
      createdAt: DateTime.parse(row['created_at'] as String),
      taskCount: row['task_count'] as int,
    );
  }

  final int id;
  final String name;
  final String? description;
  final List<String> workers;
  final DateTime createdAt;
  final int taskCount;
}

List<String> _readWorkers(Object? value) {
  if (value is List) {
    return value.whereType<String>().toList();
  }

  if (value is String && value.trim().isNotEmpty) {
    return value
        .split('\n')
        .map((worker) => worker.trim())
        .where((worker) => worker.isNotEmpty)
        .toList();
  }

  return const [];
}
