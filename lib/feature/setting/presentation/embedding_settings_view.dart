part of 'settings_view.dart';

class _EmbeddingSettingsView extends HookWidget {
  final double defaultTextEmbeddingMatcher;
  final double defaultImageEmbeddingMatcher;
  final double defaultCombinedEmbeddingMatcher;
  final bool defaultKeywordMatcher;
  final int defaultMaxTags;

  const _EmbeddingSettingsView({
    required this.defaultTextEmbeddingMatcher,
    required this.defaultImageEmbeddingMatcher,
    required this.defaultCombinedEmbeddingMatcher,
    required this.defaultKeywordMatcher,
    required this.defaultMaxTags,
  });

  @override
  Widget build(BuildContext context) {
    final textEmbeddingMatcher = useState<double>(defaultTextEmbeddingMatcher);
    final imageEmbeddingMatcher = useState<double>(defaultImageEmbeddingMatcher);
    final combinedEmbeddingMatcher = useState<double>(defaultCombinedEmbeddingMatcher);
    final maxTags = useState<int>(defaultMaxTags);
    final keywordMatcher = useState<bool>(defaultKeywordMatcher);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: CupertinoPageScaffold(
        backgroundColor: UIColors.background,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.antiAlias,
          slivers: [
            CupertinoSliverNavigationBar(
              backgroundColor: UIColors.background,
              largeTitle: Text("Embedding Settings", style: UITextStyles.largeTitle),
              previousPageTitle: "Settings",
              heroTag: 'embedding_settings',
              stretch: true,
              border: null,
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: ShapeDecoration(shape: UIRadius.mdShape, color: UIColors.logo),
                    child: Text(
                      "The accuracy of automatic topic tagging can be adjusted using the sliders below. Lower values result in more tags being applied, while higher values yield fewer, more precise tags if any.",
                      style: UITextStyles.subheadline.copyWith(color: UIColors.primary),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ),
                Padding(
                  padding: UIInsets.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Text Embedding Matcher Threshold: ${textEmbeddingMatcher.value.toStringAsFixed(2)}"),
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoSlider(
                          value: textEmbeddingMatcher.value,
                          onChanged: (result) {
                            textEmbeddingMatcher.value = result;
                          },
                          min: 0.0,
                          max: 2.0,
                          divisions: 100,
                        ),
                      ),
                      UIGap.mdVertical(),
                      Text("Image Embedding Matcher Threshold: ${imageEmbeddingMatcher.value.toStringAsFixed(2)}"),
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoSlider(
                          value: imageEmbeddingMatcher.value,
                          onChanged: (result) {
                            imageEmbeddingMatcher.value = result;
                          },
                          min: 0.0,
                          max: 2.0,
                          divisions: 100,
                        ),
                      ),
                      UIGap.mdVertical(),
                      Text(
                        "Combined Embedding Matcher Threshold: ${combinedEmbeddingMatcher.value.toStringAsFixed(2)}",
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoSlider(
                          value: combinedEmbeddingMatcher.value,
                          onChanged: (result) {
                            combinedEmbeddingMatcher.value = result;
                          },
                          min: 0.0,
                          max: 2.0,
                          divisions: 100,
                        ),
                      ),
                      UIGap.mdVertical(),
                      Text("Max Tags per Item On Shared: ${maxTags.value}"),
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoSlider(
                          value: maxTags.value.toDouble(),
                          onChanged: (result) {
                            maxTags.value = result.toInt();
                          },
                          min: 1,
                          max: 10,
                          divisions: 9,
                        ),
                      ),
                      UIGap.mdVertical(),
                      CupertinoListTile(
                        padding: EdgeInsets.zero,
                        title: const Text("Use Keywords To Improve Matching With Baskets"),
                        trailing: CupertinoSwitch(
                          value: keywordMatcher.value,
                          onChanged: (value) {
                            keywordMatcher.value = value;
                          },
                        ),
                      ),
                      UIGap.mdVertical(),
                      SizedBox(
                        width: double.infinity,
                        child: UIOutlinedButton(
                          onPressed: () async {
                            await context
                                .read<SettingsCubit>()
                                .update(
                                  textThreshold: textEmbeddingMatcher.value,
                                  imageThreshold: imageEmbeddingMatcher.value,
                                  combinedThreshold: combinedEmbeddingMatcher.value,
                                  keywordMatcher: keywordMatcher.value,
                                  maxTags: maxTags.value,
                                )
                                .then((r) {
                                  if (!context.mounted) return;
                                  showCupertinoSnackbar(context, "Settings saved successfully");
                                  Navigator.of(context).pop();
                                });
                          },
                          child: const Text("Save Settings"),
                        ),
                      ),
                      UIGap.mdVertical(),
                      if (textEmbeddingMatcher.value != kdefaultTextEmbeddingMatcher ||
                          imageEmbeddingMatcher.value != kdefaultImageEmbeddingMatcher ||
                          combinedEmbeddingMatcher.value != kdefaultCombinedEmbeddingMatcher ||
                          keywordMatcher.value != kdefaultKeywordMatcher ||
                          maxTags.value != kdefaultMaxTags)
                        SizedBox(
                          width: double.infinity,
                          child: UIOutlinedButton(
                            onPressed: () {
                              textEmbeddingMatcher.value = kdefaultTextEmbeddingMatcher;
                              imageEmbeddingMatcher.value = kdefaultImageEmbeddingMatcher;
                              combinedEmbeddingMatcher.value = kdefaultCombinedEmbeddingMatcher;
                              keywordMatcher.value = kdefaultKeywordMatcher;
                              maxTags.value = kdefaultMaxTags;
                            },
                            child: const Text("Reset to Default"),
                          ),
                        ),
                    ],
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
