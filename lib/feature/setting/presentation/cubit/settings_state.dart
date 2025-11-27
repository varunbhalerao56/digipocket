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

  const SettingsLoaded({
    required this.textEmbeddingMatcherThreshold,
    required this.imageEmbeddingMatcherThreshold,
    required this.combinedEmbeddingMatcherThreshold,
  });

  @override
  List<Object> get props => [
    textEmbeddingMatcherThreshold,
    imageEmbeddingMatcherThreshold,
    combinedEmbeddingMatcherThreshold,
  ];

  SettingsLoaded copyWith({
    double? textEmbeddingMatcherThreshold,
    double? imageEmbeddingMatcherThreshold,
    double? combinedEmbeddingMatcherThreshold,
  }) {
    return SettingsLoaded(
      textEmbeddingMatcherThreshold: textEmbeddingMatcherThreshold ?? this.textEmbeddingMatcherThreshold,
      imageEmbeddingMatcherThreshold: imageEmbeddingMatcherThreshold ?? this.imageEmbeddingMatcherThreshold,
      combinedEmbeddingMatcherThreshold: combinedEmbeddingMatcherThreshold ?? this.combinedEmbeddingMatcherThreshold,
    );
  }
}
