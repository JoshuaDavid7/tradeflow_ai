/// Project status
enum ProjectStatus {
  active('Active'),
  completed('Completed'),
  archived('Archived');

  final String displayName;
  const ProjectStatus(this.displayName);
}

/// Project model — a job/project under a customer
class Project {
  final String id;
  final String userId;
  final String customerId;
  final String name;
  final String? description;
  final ProjectStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  const Project({
    required this.id,
    required this.userId,
    required this.customerId,
    required this.name,
    this.description,
    this.status = ProjectStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  Project copyWith({
    String? id,
    String? userId,
    String? customerId,
    String? name,
    String? description,
    ProjectStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return Project(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
