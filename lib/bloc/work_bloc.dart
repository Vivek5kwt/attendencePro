import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/work.dart';
import '../repositories/work_repository.dart';
import 'work_event.dart';
import 'work_state.dart';

class WorkBloc extends Bloc<WorkEvent, WorkState> {
  WorkBloc({required WorkRepository repository})
      : _repository = repository,
        super(const WorkState()) {
    on<WorkStarted>(_onStarted);
    on<WorkRefreshed>(_onRefreshed);
    on<WorkAdded>(_onAdded);
    on<WorkDeleted>(_onDeleted);
    on<WorkUpdated>(_onUpdated);
    on<WorkActivated>(_onActivated);
    on<WorkMessageCleared>(_onMessageCleared);
    on<WorkAddStatusCleared>(_onAddStatusCleared);
    on<WorkUpdateStatusCleared>(_onUpdateStatusCleared);
    on<WorkProfileRefreshed>(_onProfileRefreshed);
  }

  final WorkRepository _repository;

  Future<void> _onStarted(WorkStarted event, Emitter<WorkState> emit) async {
    emit(
      state.copyWith(
        loadStatus: WorkLoadStatus.loading,
        lastErrorMessage: null,
        lastSuccessMessage: null,
        requiresAuthentication: false,
        feedbackKind: null,
      ),
    );

    final profile = await _repository.loadUserProfile();
    try {
      final works = await _repository.fetchWorks();
      emit(
        state.copyWith(
          loadStatus: WorkLoadStatus.success,
          works: works,
          userName: profile.name,
          userEmail: profile.displayContact,
          userPhone: profile.phone,
          userUsername: profile.username,
          userCountryCode: profile.countryCode,
          userLanguage: profile.language,
        ),
      );
    } on WorkAuthException {
      emit(
        state.copyWith(
          loadStatus: WorkLoadStatus.failure,
          works: const <Work>[],
          requiresAuthentication: true,
          userName: profile.name,
          userEmail: profile.displayContact,
          userPhone: profile.phone,
          userUsername: profile.username,
          userCountryCode: profile.countryCode,
          userLanguage: profile.language,
          feedbackKind: WorkFeedbackKind.load,
        ),
      );
    } on WorkRepositoryException catch (e) {
      emit(
        state.copyWith(
          loadStatus: WorkLoadStatus.failure,
          works: const <Work>[],
          lastErrorMessage: e.message,
          userName: profile.name,
          userEmail: profile.displayContact,
          userPhone: profile.phone,
          userUsername: profile.username,
          userCountryCode: profile.countryCode,
          userLanguage: profile.language,
          feedbackKind: WorkFeedbackKind.load,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          loadStatus: WorkLoadStatus.failure,
          works: const <Work>[],
          lastErrorMessage: 'Failed to load works. Please try again.',
          userName: profile.name,
          userEmail: profile.displayContact,
          userPhone: profile.phone,
          userUsername: profile.username,
          userCountryCode: profile.countryCode,
          userLanguage: profile.language,
          feedbackKind: WorkFeedbackKind.load,
        ),
      );
    }
  }

  Future<void> _onRefreshed(WorkRefreshed event, Emitter<WorkState> emit) async {
    emit(
      state.copyWith(
        isRefreshing: true,
        lastErrorMessage: null,
        lastSuccessMessage: null,
        requiresAuthentication: false,
        feedbackKind: null,
      ),
    );

    try {
      final works = await _repository.fetchWorks();
      emit(
        state.copyWith(
          isRefreshing: false,
          loadStatus: WorkLoadStatus.success,
          works: works,
        ),
      );
      event.completer?.complete();
    } on WorkAuthException {
      emit(
        state.copyWith(
          isRefreshing: false,
          loadStatus: WorkLoadStatus.failure,
          works: const <Work>[],
          requiresAuthentication: true,
          feedbackKind: WorkFeedbackKind.refresh,
        ),
      );
      event.completer?.complete();
    } on WorkRepositoryException catch (e) {
      emit(
        state.copyWith(
          isRefreshing: false,
          lastErrorMessage: e.message,
          feedbackKind: WorkFeedbackKind.refresh,
        ),
      );
      event.completer?.complete();
    } catch (_) {
      emit(
        state.copyWith(
          isRefreshing: false,
          lastErrorMessage: 'Unable to refresh works. Please try again.',
          feedbackKind: WorkFeedbackKind.refresh,
        ),
      );
      event.completer?.complete();
    }
  }

  Future<void> _onAdded(WorkAdded event, Emitter<WorkState> emit) async {
    if (state.addStatus == WorkActionStatus.inProgress) {
      return;
    }

    final previousWorkIds = state.works.map((work) => work.id).toSet();

    emit(
      state.copyWith(
        addStatus: WorkActionStatus.inProgress,
        lastErrorMessage: null,
        lastSuccessMessage: null,
        requiresAuthentication: false,
        feedbackKind: null,
      ),
    );

    try {
      final result = await _repository.createWork(
        name: event.name,
        hourlyRate: event.hourlyRate,
        isContract: event.isContract,
      );
      final successMessage = (result.message ?? '').trim();
      final works = await _repository.fetchWorks();
      Work? createdWork;
      for (final work in works) {
        if (!previousWorkIds.contains(work.id)) {
          createdWork = work;
          break;
        }
      }
      emit(
        state.copyWith(
          addStatus: WorkActionStatus.success,
          works: works,
          loadStatus: WorkLoadStatus.success,
          lastSuccessMessage: successMessage,
          feedbackKind: WorkFeedbackKind.add,
        ),
      );
      if (createdWork != null && !createdWork.isActive) {
        add(WorkActivated(work: createdWork));
      }
    } on WorkAuthException {
      emit(
        state.copyWith(
          addStatus: WorkActionStatus.failure,
          requiresAuthentication: true,
          feedbackKind: WorkFeedbackKind.add,
        ),
      );
    } on WorkRepositoryException catch (e) {
      emit(
        state.copyWith(
          addStatus: WorkActionStatus.failure,
          lastErrorMessage: e.message,
          feedbackKind: WorkFeedbackKind.add,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          addStatus: WorkActionStatus.failure,
          lastErrorMessage: 'Unable to save work. Please try again.',
          feedbackKind: WorkFeedbackKind.add,
        ),
      );
    }
  }

  Future<void> _onUpdated(WorkUpdated event, Emitter<WorkState> emit) async {
    if (state.updateStatus == WorkActionStatus.inProgress) {
      return;
    }

    emit(
      state.copyWith(
        updateStatus: WorkActionStatus.inProgress,
        lastErrorMessage: null,
        lastSuccessMessage: null,
        requiresAuthentication: false,
        feedbackKind: null,
      ),
    );

    try {
      final result = await _repository.updateWork(
        work: event.work,
        name: event.name,
        hourlyRate: event.hourlyRate,
        isContract: event.isContract,
      );
      final successMessage = (result.message ?? '').trim();
      final works = await _repository.fetchWorks();
      emit(
        state.copyWith(
          updateStatus: WorkActionStatus.success,
          works: works,
          loadStatus: WorkLoadStatus.success,
          lastSuccessMessage: successMessage,
          feedbackKind: WorkFeedbackKind.update,
        ),
      );
    } on WorkAuthException {
      emit(
        state.copyWith(
          updateStatus: WorkActionStatus.failure,
          requiresAuthentication: true,
          feedbackKind: WorkFeedbackKind.update,
        ),
      );
    } on WorkRepositoryException catch (e) {
      emit(
        state.copyWith(
          updateStatus: WorkActionStatus.failure,
          lastErrorMessage: e.message,
          feedbackKind: WorkFeedbackKind.update,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          updateStatus: WorkActionStatus.failure,
          lastErrorMessage: 'Unable to update work. Please try again.',
          feedbackKind: WorkFeedbackKind.update,
        ),
      );
    }
  }

  Future<void> _onDeleted(WorkDeleted event, Emitter<WorkState> emit) async {
    if (state.deletingWorkId != null) {
      event.completer?.complete(false);
      return;
    }

    emit(
      state.copyWith(
        deletingWorkId: event.work.id,
        lastErrorMessage: null,
        lastSuccessMessage: null,
        requiresAuthentication: false,
        feedbackKind: null,
      ),
    );

    try {
      final result = await _repository.deleteWork(event.work);
      final successMessage = (result.message ?? '').trim();
      final updated = state.works.where((w) => w.id != event.work.id).toList();
      emit(
        state.copyWith(
          deletingWorkId: null,
          works: updated,
          lastSuccessMessage: successMessage,
          feedbackKind: WorkFeedbackKind.delete,
        ),
      );
      event.completer?.complete(true);
    } on WorkAuthException {
      emit(
        state.copyWith(
          deletingWorkId: null,
          requiresAuthentication: true,
          feedbackKind: WorkFeedbackKind.delete,
        ),
      );
      event.completer?.complete(false);
    } on WorkRepositoryException catch (e) {
      emit(
        state.copyWith(
          deletingWorkId: null,
          lastErrorMessage: e.message,
          feedbackKind: WorkFeedbackKind.delete,
        ),
      );
      event.completer?.complete(false);
    } catch (_) {
      emit(
        state.copyWith(
          deletingWorkId: null,
          lastErrorMessage: 'Unable to delete work. Please try again.',
          feedbackKind: WorkFeedbackKind.delete,
        ),
      );
      event.completer?.complete(false);
    }
  }

  void _onMessageCleared(
    WorkMessageCleared event,
    Emitter<WorkState> emit,
  ) {
    emit(state.clearMessages());
  }

  void _onAddStatusCleared(
    WorkAddStatusCleared event,
    Emitter<WorkState> emit,
  ) {
    if (state.addStatus != WorkActionStatus.idle) {
      emit(state.copyWith(addStatus: WorkActionStatus.idle));
    }
  }

  void _onUpdateStatusCleared(
    WorkUpdateStatusCleared event,
    Emitter<WorkState> emit,
  ) {
    if (state.updateStatus != WorkActionStatus.idle) {
      emit(state.copyWith(updateStatus: WorkActionStatus.idle));
    }
  }

  Future<void> _onActivated(
    WorkActivated event,
    Emitter<WorkState> emit,
  ) async {
    if (state.activateStatus == WorkActionStatus.inProgress &&
        state.activatingWorkId != event.work.id) {
      return;
    }

    emit(
      state.copyWith(
        activateStatus: WorkActionStatus.inProgress,
        activatingWorkId: event.work.id,
        lastErrorMessage: null,
        lastSuccessMessage: null,
        requiresAuthentication: false,
        feedbackKind: null,
      ),
    );

    try {
      final result = await _repository.activateWork(event.work);
      final successMessage = (result.message ?? '').trim();
      final works = await _repository.fetchWorks();
      emit(
        state.copyWith(
          activateStatus: WorkActionStatus.success,
          activatingWorkId: null,
          works: works,
          loadStatus: WorkLoadStatus.success,
          lastSuccessMessage: successMessage,
          feedbackKind: WorkFeedbackKind.activate,
        ),
      );
    } on WorkAuthException {
      emit(
        state.copyWith(
          activateStatus: WorkActionStatus.failure,
          activatingWorkId: null,
          requiresAuthentication: true,
          feedbackKind: WorkFeedbackKind.activate,
        ),
      );
    } on WorkRepositoryException catch (e) {
      emit(
        state.copyWith(
          activateStatus: WorkActionStatus.failure,
          activatingWorkId: null,
          lastErrorMessage: e.message,
          feedbackKind: WorkFeedbackKind.activate,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          activateStatus: WorkActionStatus.failure,
          activatingWorkId: null,
          lastErrorMessage: 'Unable to set active work. Please try again.',
          feedbackKind: WorkFeedbackKind.activate,
        ),
      );
    }
  }

  Future<void> _onProfileRefreshed(
    WorkProfileRefreshed event,
    Emitter<WorkState> emit,
  ) async {
    final profile = await _repository.loadUserProfile();
    emit(
      state.copyWith(
        userName: profile.name,
        userEmail: profile.displayContact,
        userPhone: profile.phone,
        userUsername: profile.username,
        userCountryCode: profile.countryCode,
        userLanguage: profile.language,
      ),
    );
  }
}
