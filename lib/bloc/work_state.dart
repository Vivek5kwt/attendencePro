import 'package:equatable/equatable.dart';

import '../models/work.dart';

enum WorkLoadStatus { initial, loading, success, failure }

enum WorkActionStatus { idle, inProgress, success, failure }

enum WorkFeedbackKind { load, refresh, add, update, delete }

class WorkState extends Equatable {
  const WorkState({
    this.loadStatus = WorkLoadStatus.initial,
    this.addStatus = WorkActionStatus.idle,
    this.updateStatus = WorkActionStatus.idle,
    this.works = const <Work>[],
    this.isRefreshing = false,
    this.lastErrorMessage,
    this.lastSuccessMessage,
    this.requiresAuthentication = false,
    this.deletingWorkId,
    this.userName,
    this.userEmail,
    this.feedbackKind,
  });

  final WorkLoadStatus loadStatus;
  final WorkActionStatus addStatus;
  final WorkActionStatus updateStatus;
  final List<Work> works;
  final bool isRefreshing;
  final String? lastErrorMessage;
  final String? lastSuccessMessage;
  final bool requiresAuthentication;
  final String? deletingWorkId;
  final String? userName;
  final String? userEmail;
  final WorkFeedbackKind? feedbackKind;

  bool get isLoading => loadStatus == WorkLoadStatus.loading;

  static const _sentinel = Object();

  WorkState copyWith({
    WorkLoadStatus? loadStatus,
    WorkActionStatus? addStatus,
    WorkActionStatus? updateStatus,
    List<Work>? works,
    bool? isRefreshing,
    Object? lastErrorMessage = _sentinel,
    Object? lastSuccessMessage = _sentinel,
    bool? requiresAuthentication,
    Object? deletingWorkId = _sentinel,
    Object? feedbackKind = _sentinel,
    String? userName,
    String? userEmail,
  }) {
    return WorkState(
      loadStatus: loadStatus ?? this.loadStatus,
      addStatus: addStatus ?? this.addStatus,
      updateStatus: updateStatus ?? this.updateStatus,
      works: works ?? this.works,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      lastErrorMessage: identical(lastErrorMessage, _sentinel)
          ? this.lastErrorMessage
          : lastErrorMessage as String?,
      lastSuccessMessage: identical(lastSuccessMessage, _sentinel)
          ? this.lastSuccessMessage
          : lastSuccessMessage as String?,
      requiresAuthentication:
          requiresAuthentication ?? this.requiresAuthentication,
      deletingWorkId: identical(deletingWorkId, _sentinel)
          ? this.deletingWorkId
          : deletingWorkId as String?,
      feedbackKind: identical(feedbackKind, _sentinel)
          ? this.feedbackKind
          : feedbackKind as WorkFeedbackKind?,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
    );
  }

  WorkState clearMessages() {
    return copyWith(
      lastErrorMessage: null,
      lastSuccessMessage: null,
      requiresAuthentication: false,
      feedbackKind: null,
    );
  }

  @override
  List<Object?> get props => [
        loadStatus,
        addStatus,
        updateStatus,
        works,
        isRefreshing,
        lastErrorMessage,
        lastSuccessMessage,
        requiresAuthentication,
        deletingWorkId,
        userName,
        userEmail,
        feedbackKind,
      ];
}
