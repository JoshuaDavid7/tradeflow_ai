import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/tables.dart';

part 'project_dao.g.dart';

@DriftAccessor(tables: [Projects])
class ProjectDao extends DatabaseAccessor<AppDatabase>
    with _$ProjectDaoMixin {
  ProjectDao(super.db);

  Future<List<Project>> getAllProjects(String userId) {
    return (select(projects)
          ..where((p) => p.userId.equals(userId))
          ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)]))
        .get();
  }

  Future<List<Project>> getProjectsByCustomer(
      String userId, String customerId) {
    return (select(projects)
          ..where(
              (p) => p.userId.equals(userId) & p.customerId.equals(customerId))
          ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)]))
        .get();
  }

  Future<Project?> getProjectById(String id) {
    return (select(projects)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> createProject(ProjectsCompanion project) {
    return into(projects).insert(project);
  }

  Future<void> updateProject(String id, ProjectsCompanion project) {
    return (update(projects)..where((p) => p.id.equals(id))).write(project);
  }

  Future<void> deleteProject(String id) {
    return (delete(projects)..where((p) => p.id.equals(id))).go();
  }
}
