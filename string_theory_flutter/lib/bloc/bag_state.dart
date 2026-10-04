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
  final String? errorMessage;

  const BagLoaded(this.racquets, {this.errorMessage});

  @override
  List<Object?> get props => [racquets, errorMessage];
}

class BagError extends BagState {
  final String message;

  const BagError(this.message);

  @override
  List<Object?> get props => [message];
}
