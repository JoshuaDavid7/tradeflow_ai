import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/job.dart';
import '../../data/repositories/job_repository.dart';
import '../../data/services/supabase_service.dart';
import '../../core/errors/error_handler.dart';

/// Job list state
class JobListState {
  final List<Job> jobs;
  final bool isLoading;
  final String? error;

  const JobListState({
    this.jobs = const [],
    this.isLoading = false,
    this.error,
  });

  JobListState copyWith({
    List<Job>? jobs,
    bool? isLoading,
    String? error,
  }) {
    return JobListState(
      jobs: jobs ?? this.jobs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Job list notifier
class JobListNotifier extends StateNotifier<JobListState> {
  final IJobRepository _repository;
  final String? _userId;

  JobListNotifier(this._repository, this._userId) : super(const JobListState()) {
    if (_userId != null) {
      Future<void>(loadJobs);
    }
  }

  /// Load all jobs
  Future<void> loadJobs() async {
    if (_userId == null) {
      state = state.copyWith(error: 'User not authenticated');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final jobs = await _repository.getJobs(_userId!);
      
      state = state.copyWith(
        jobs: jobs,
        isLoading: false,
      );

      ErrorHandler.debug('Jobs loaded successfully', {'count': jobs.length});
    } catch (error, stackTrace) {
      final errorMessage = ErrorHandler.handle(error, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  /// Create new job
  Future<Job?> createJob(Job job) async {
    try {
      final created = await _repository.createJob(job);
      
      // Add to local state
      state = state.copyWith(
        jobs: [created, ...state.jobs],
      );

      ErrorHandler.info('Job created successfully', {'id': created.id});
      return created;
    } catch (error, stackTrace) {
      final errorMessage = ErrorHandler.handle(error, stackTrace);
      state = state.copyWith(error: errorMessage);
      return null;
    }
  }

  /// Update existing job
  Future<bool> updateJob(String id, Job job) async {
    try {
      final updated = await _repository.updateJob(id, job);
      
      // Update in local state
      final updatedJobs = state.jobs
          .map<Job>((j) => j.id == id ? updated : j)
          .toList();

      state = state.copyWith(jobs: updatedJobs);

      ErrorHandler.info('Job updated successfully', {'id': id});
      return true;
    } catch (error, stackTrace) {
      final errorMessage = ErrorHandler.handle(error, stackTrace);
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  /// Delete job
  Future<bool> deleteJob(String id) async {
    try {
      await _repository.deleteJob(id);
      
      // Remove from local state
      final updatedJobs = state.jobs.where((j) => j.id != id).toList();
      state = state.copyWith(jobs: updatedJobs);

      ErrorHandler.info('Job deleted successfully', {'id': id});
      return true;
    } catch (error, stackTrace) {
      final errorMessage = ErrorHandler.handle(error, stackTrace);
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  /// Refresh jobs
  Future<void> refresh() => loadJobs();
}

/// Provider for job list
final jobListProvider = StateNotifierProvider<JobListNotifier, JobListState>((ref) {
  final repository = ref.watch(jobRepositoryProvider);
  final userId = ref.watch(userIdProvider);
  
  return JobListNotifier(repository, userId);
});

/// Provider for job statistics
final jobStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(jobRepositoryProvider);
  final userId = ref.watch(userIdProvider);

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  return await repository.getJobStats(userId);
});

/// Provider for active jobs
final activeJobsProvider = Provider<List<Job>>((ref) {
  final jobs = ref.watch(jobListProvider).jobs;
  return jobs.where((job) => job.status.isActive).toList();
});

/// Provider for paid jobs
final paidJobsProvider = Provider<List<Job>>((ref) {
  final jobs = ref.watch(jobListProvider).jobs;
  return jobs.where((job) => job.status.isPaid).toList();
});

/// Provider for draft jobs
final draftJobsProvider = Provider<List<Job>>((ref) {
  final jobs = ref.watch(jobListProvider).jobs;
  return jobs.where((job) => job.status == JobStatus.draft).toList();
});
