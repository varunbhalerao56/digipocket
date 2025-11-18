import 'package:bloc/bloc.dart';
import 'package:digipocket/feature/fonnex/fonnex.dart';
import 'package:digipocket/global/errors/errors.dart';
import 'package:equatable/equatable.dart';

part 'fonnex_state.dart';

class FonnexCubit extends Cubit<FonnexState> {
  FonnexCubit() : super(FonnexInitial());

  init() async {
    emit(FonnexLoading());
    try {
      final embeddingModel = FonnexEmbeddingRepository.nomic();

      await embeddingModel.initializeText();
      await embeddingModel.initializeVision();

      emit(FonnexDataLoaded(embeddingModel));
    } catch (e) {
      emit(FonnexError(AppException('Failed to initialize Fonnex repository: $e')));
    }
  }
}
