class ProjectModel {
  const ProjectModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.taskCount,
    this.description,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      taskCount: json['taskCount'] as int,
    );
  }

  factory ProjectModel.fromDatabase(Map<String, Object?> row) {
    return ProjectModel(
      id: row['id'] as int,
      name: row['name'] as String,
      description: row['description'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      taskCount: row['task_count'] as int,
    );
  }

  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final int taskCount;
}
