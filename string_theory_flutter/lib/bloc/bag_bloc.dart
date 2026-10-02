import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:string_theory_client/string_theory_client.dart';

import 'bag_event.dart';
import 'bag_state.dart';

export 'bag_event.dart';
export 'bag_state.dart';

class BagBloc extends Bloc<BagEvent, BagState> {
  final Client client;

  BagBloc({required this.client}) : super(const BagInitial()) {
    on<LoadBag>((event, emit) async {
      // Pending implementation in Story 1.3
    });
    on<AddRacquet>((event, emit) async {
      // Pending implementation in Story 1.3
    });
    on<DeleteRacquet>((event, emit) async {
      // Pending implementation in Story 1.3
    });
    on<SetPrimaryRacquet>((event, emit) async {
      // Pending implementation in Story 1.3
    });
  }
}
