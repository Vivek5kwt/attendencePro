import 'dart:async';

import '../models/pending_contract_work.dart';
import '../models/work.dart';

abstract class WorkEvent {
  const WorkEvent();
}

class WorkStarted extends WorkEvent {
  const WorkStarted();
}

class WorkRefreshed extends WorkEvent {
  const WorkRefreshed({this.completer});

  final Completer<void>? completer;
}

class WorkAdded extends WorkEvent {
  const WorkAdded({
    required this.name,
    required this.hourlyRate,
    this.isContract = true,
    this.pendingContractWorks = const <PendingContractWork>[],
  });

  final String name;
  final num hourlyRate;
  final bool isContract;
  final List<PendingContractWork> pendingContractWorks;
}

class WorkDeleted extends WorkEvent {
  const WorkDeleted({
    required this.work,
    this.completer,
  });

  final Work work;
  final Completer<bool>? completer;
}

class WorkUpdated extends WorkEvent {
  const WorkUpdated({
    required this.work,
    required this.name,
    required this.hourlyRate,
    required this.isContract,
  });

  final Work work;
  final String name;
  final num hourlyRate;
  final bool isContract;
}

class WorkActivated extends WorkEvent {
  const WorkActivated({required this.work});

  final Work work;
}

class WorkMessageCleared extends WorkEvent {
  const WorkMessageCleared();
}

class WorkAddStatusCleared extends WorkEvent {
  const WorkAddStatusCleared();
}

class WorkUpdateStatusCleared extends WorkEvent {
  const WorkUpdateStatusCleared();
}

class WorkProfileRefreshed extends WorkEvent {
  const WorkProfileRefreshed();
}

class WorkCleared extends WorkEvent {
  const WorkCleared();
}
