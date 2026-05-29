enum TaskStatus {
  pendente('PENDENTE', 'Pendente'),
  emAndamento('EM_ANDAMENTO', 'Em andamento'),
  concluida('CONCLUIDA', 'Concluída');

  const TaskStatus(this.value, this.label);

  factory TaskStatus.fromValue(String value) {
    return TaskStatus.values.firstWhere((status) => status.value == value);
  }

  final String value;
  final String label;
}

enum TaskPriority {
  baixa('BAIXA', 'Baixa'),
  media('MEDIA', 'Média'),
  alta('ALTA', 'Alta');

  const TaskPriority(this.value, this.label);

  factory TaskPriority.fromValue(String value) {
    return TaskPriority.values.firstWhere((priority) => priority.value == value);
  }

  final String value;
  final String label;
}

class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.projectId,
    this.description,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: TaskPriority.fromValue(json['priority'] as String),
      status: TaskStatus.fromValue(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      projectId: json['projectId'] as int,
    );
  }

  factory TaskModel.fromDatabase(Map<String, Object?> row) {
    return TaskModel(
      id: row['id'] as int,
      title: row['title'] as String,
      description: row['description'] as String?,
      priority: TaskPriority.fromValue(row['priority'] as String),
      status: TaskStatus.fromValue(row['status'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      projectId: row['project_id'] as int,
    );
  }

  final int id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime createdAt;
  final int projectId;
}
