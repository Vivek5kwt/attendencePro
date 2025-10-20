import 'dart:async';

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
  });

  final String name;
  final num hourlyRate;
  final bool isContract;
}

class WorkDeleted extends WorkEvent {
  const WorkDeleted({
    required this.work,
    this.completer,
  });

  final Work work;
  final Completer<bool>? completer;
}

class WorkMessageCleared extends WorkEvent {
  const WorkMessageCleared();
}

class WorkAddStatusCleared extends WorkEvent {
  const WorkAddStatusCleared();
}
