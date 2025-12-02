import 'package:bloc/bloc.dart';
import 'package:digipocket/feature/setting/data/repository/shared_pref_repository.dart';
import 'package:digipocket/feature/shared_item/shared_item.dart';
import 'package:digipocket/feature/user_topic/user_topic.dart';
import 'package:equatable/equatable.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SharedPrefRepository sharedPrefRepository;
  final UserTopicsCubit userTopicsCubit;
  final SharedItemsCubit sharedItemsCubit;
  SettingsCubit({required this.sharedPrefRepository, required this.userTopicsCubit, required this.sharedItemsCubit})
    : super(SettingsInitial());

  void init() {
    emit(SettingsLoading());
    final textThreshold = sharedPrefRepository.getTextEmbeddingMatcher();
    final imageThreshold = sharedPrefRepository.getImageEmbeddingMatcher();
    final combinedThreshold = sharedPrefRepository.getCombinedEmbeddingMatcher();
    final keywordMatcher = sharedPrefRepository.getKeywordMatcher();
    final maxTags = sharedPrefRepository.getMaxTags();
    emit(
      SettingsLoaded(
        textEmbeddingMatcherThreshold: textThreshold,
        imageEmbeddingMatcherThreshold: imageThreshold,
        combinedEmbeddingMatcherThreshold: combinedThreshold,
        keywordMatcher: keywordMatcher,
        maxTags: maxTags,
      ),
    );
  }

  Future<void> update({
    required double textThreshold,
    required double imageThreshold,
    required double combinedThreshold,
    required bool keywordMatcher,
    required int maxTags,
  }) async {
    await sharedPrefRepository.setTextEmbeddingMatcher(textThreshold);
    await sharedPrefRepository.setImageEmbeddingMatcher(imageThreshold);
    await sharedPrefRepository.setCombinedEmbeddingMatcher(combinedThreshold);
    await sharedPrefRepository.setKeywordMatcher(keywordMatcher);
    await sharedPrefRepository.setMaxTags(maxTags);
    emit(
      SettingsLoaded(
        textEmbeddingMatcherThreshold: textThreshold,
        imageEmbeddingMatcherThreshold: imageThreshold,
        combinedEmbeddingMatcherThreshold: combinedThreshold,
        keywordMatcher: keywordMatcher,
        maxTags: maxTags,
      ),
    );
  }

  Future<void> resetSharedItems() async {
    await sharedItemsCubit.clearAll();
  }

  Future<void> resetUserTopics() async {
    await userTopicsCubit.clearAll();
  }
}
