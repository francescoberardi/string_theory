import 'package:equatable/equatable.dart';
import 'package:string_theory_client/string_theory_client.dart';

abstract class BagState extends Equatable {
  const BagState();

  @override
  List<Object?> get props => [];
}

class BagInitial extends BagState {
  const BagInitial();
}

class BagLoading extends BagState {
  const BagLoading();
}

class BagLoaded extends BagState {
  final List<Racquet> racquets;

  /// Transient failure to surface once as an error SnackBar.
  final String? errorMessage;

  /// Transient, non-blocking notice (e.g. offline save or sync result) to
  /// surface once as an informational SnackBar.
  final String? infoMessage;

  /// Sessions logged offline that are still waiting to reach the server.
  final int pendingSyncCount;

  const BagLoaded(
    this.racquets, {
    this.errorMessage,
    this.infoMessage,
    this.pendingSyncCount = 0,
  });

  @override
  List<Object?> get props => [
    racquets,
    errorMessage,
    infoMessage,
    pendingSyncCount,
  ];
}

class BagError extends BagState {
  final String message;

  const BagError(this.message);

  @override
  List<Object?> get props => [message];
}
