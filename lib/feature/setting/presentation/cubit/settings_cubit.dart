import 'package:bloc/bloc.dart';
import 'package:digipocket/feature/setting/data/repository/shared_pref_repository.dart';
import 'package:equatable/equatable.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SharedPrefRepository sharedPrefRepository;
  SettingsCubit({required this.sharedPrefRepository}) : super(SettingsInitial());

  void init() {
    emit(SettingsLoading());
    final textThreshold = sharedPrefRepository.getTextEmbeddingMatcher();
    final imageThreshold = sharedPrefRepository.getImageEmbeddingMatcher();
    final combinedThreshold = sharedPrefRepository.getCombinedEmbeddingMatcher();
    emit(
      SettingsLoaded(
        textEmbeddingMatcherThreshold: textThreshold,
        imageEmbeddingMatcherThreshold: imageThreshold,
        combinedEmbeddingMatcherThreshold: combinedThreshold,
      ),
    );
  }

  Future<void> update({
    required double textThreshold,
    required double imageThreshold,
    required double combinedThreshold,
  }) async {
    await sharedPrefRepository.setTextEmbeddingMatcher(textThreshold);
    await sharedPrefRepository.setImageEmbeddingMatcher(imageThreshold);
    await sharedPrefRepository.setCombinedEmbeddingMatcher(combinedThreshold);
    emit(
      SettingsLoaded(
        textEmbeddingMatcherThreshold: textThreshold,
        imageEmbeddingMatcherThreshold: imageThreshold,
        combinedEmbeddingMatcherThreshold: combinedThreshold,
      ),
    );
  }
}
