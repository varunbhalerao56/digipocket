import 'package:digipocket/feature/setting/presentation/cubit/settings_cubit.dart';
import 'package:digipocket/global/themes/themes.dart';
import 'package:digipocket/global/widgets/cupertino_buttons.dart';
import 'package:digipocket/global/widgets/cupertino_filter_chips.dart';
import 'package:digipocket/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return state is SettingsLoaded
            ? _SettingsView(
                defaultTextEmbeddingMatcher: state.textEmbeddingMatcherThreshold,
                defaultImageEmbeddingMatcher: state.imageEmbeddingMatcherThreshold,
                defaultCombinedEmbeddingMatcher: state.combinedEmbeddingMatcherThreshold,
              )
            : CupertinoPageScaffold(
                backgroundColor: UIColors.background,
                child: Center(child: CupertinoActivityIndicator()),
              );
      },
      listener: (context, state) {},
    );
  }
}

class _SettingsView extends HookWidget {
  final double defaultTextEmbeddingMatcher;
  final double defaultImageEmbeddingMatcher;
  final double defaultCombinedEmbeddingMatcher;

  const _SettingsView({
    required this.defaultTextEmbeddingMatcher,
    required this.defaultImageEmbeddingMatcher,
    required this.defaultCombinedEmbeddingMatcher,
  });

  @override
  Widget build(BuildContext context) {
    final textEmbeddingMatcher = useState<double>(0.0);
    final imageEmbeddingMatcher = useState<double>(0.0);
    final combinedEmbeddingMatcher = useState<double>(0.0);

    useEffect(() {
      textEmbeddingMatcher.value = defaultTextEmbeddingMatcher;
      imageEmbeddingMatcher.value = defaultImageEmbeddingMatcher;
      combinedEmbeddingMatcher.value = defaultCombinedEmbeddingMatcher;
      return null;
    }, []);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: CupertinoPageScaffold(
        backgroundColor: UIColors.background,
        child: CustomScrollView(
          physics: BouncingScrollPhysics(),
          clipBehavior: Clip.antiAlias,
          slivers: [
            CupertinoSliverNavigationBar(
              backgroundColor: UIColors.background,
              largeTitle: Text("Settings", style: UITextStyles.largeTitle),
              previousPageTitle: "Home",
              heroTag: 'user_settings',

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
                          onChangeEnd: (value) {
                            textEmbeddingMatcher.value = value;
                          },
                        ),
                      ),

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
                          onChangeEnd: (value) {
                            imageEmbeddingMatcher.value = value;
                          },
                        ),
                      ),

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
                          onChangeEnd: (value) {
                            combinedEmbeddingMatcher.value = value;
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
                                )
                                .then((r) {
                                  if (!context.mounted) return;
                                  showCupertinoSnackbar(context, "Settings saved successfully");
                                  Navigator.of(context).pop();
                                });
                          },
                          child: Text("Save Settings"),
                        ),
                      ),

                      UIGap.mdVertical(),

                      if (textEmbeddingMatcher.value != kdefaultTextEmbeddingMatcher ||
                          imageEmbeddingMatcher.value != kdefaultImageEmbeddingMatcher ||
                          combinedEmbeddingMatcher.value != kdefaultCombinedEmbeddingMatcher)
                        SizedBox(
                          width: double.infinity,
                          child: UIOutlinedButton(
                            onPressed: () {
                              textEmbeddingMatcher.value = kdefaultTextEmbeddingMatcher;
                              imageEmbeddingMatcher.value = kdefaultImageEmbeddingMatcher;
                              combinedEmbeddingMatcher.value = kdefaultCombinedEmbeddingMatcher;
                            },
                            child: Text("Reset to Default"),
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
