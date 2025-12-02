part of 'settings_cubit.dart';

sealed class SettingsState extends Equatable {
  const SettingsState();
}

final class SettingsInitial extends SettingsState {
  @override
  List<Object> get props => [];
}

final class SettingsLoading extends SettingsState {
  @override
  List<Object> get props => [];
}

final class SettingsLoaded extends SettingsState {
  final double textEmbeddingMatcherThreshold;
  final double imageEmbeddingMatcherThreshold;
  final double combinedEmbeddingMatcherThreshold;
  final bool keywordMatcher;
  final int maxTags;

  const SettingsLoaded({
    required this.textEmbeddingMatcherThreshold,
    required this.imageEmbeddingMatcherThreshold,
    required this.combinedEmbeddingMatcherThreshold,
    required this.keywordMatcher,
    required this.maxTags,
  });

  @override
  List<Object> get props => [
    textEmbeddingMatcherThreshold,
    imageEmbeddingMatcherThreshold,
    combinedEmbeddingMatcherThreshold,
    keywordMatcher,
    maxTags,
  ];

  SettingsLoaded copyWith({
    double? textEmbeddingMatcherThreshold,
    double? imageEmbeddingMatcherThreshold,
    double? combinedEmbeddingMatcherThreshold,
    bool? keywordMatcher,
    int? maxTags,
  }) {
    return SettingsLoaded(
      textEmbeddingMatcherThreshold: textEmbeddingMatcherThreshold ?? this.textEmbeddingMatcherThreshold,
      imageEmbeddingMatcherThreshold: imageEmbeddingMatcherThreshold ?? this.imageEmbeddingMatcherThreshold,
      combinedEmbeddingMatcherThreshold: combinedEmbeddingMatcherThreshold ?? this.combinedEmbeddingMatcherThreshold,
      keywordMatcher: keywordMatcher ?? this.keywordMatcher,
      maxTags: maxTags ?? this.maxTags,
    );
  }
}
