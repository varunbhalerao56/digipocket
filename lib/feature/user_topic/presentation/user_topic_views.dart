import 'package:digipocket/feature/user_topic/data/model/user_topic_model.dart';
import 'package:digipocket/feature/user_topic/presentation/cubit/user_topic_cubit.dart';
import 'package:digipocket/global/themes/themes.dart';
import 'package:digipocket/global/widgets/cupertino_buttons.dart';
import 'package:digipocket/global/widgets/cupertino_filter_chips.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class UserTopicView extends HookWidget {
  const UserTopicView({super.key});

  @override
  Widget build(BuildContext context) {
    final topicTitle = useTextEditingController();
    final topicDetails = useTextEditingController();
    final isTopicActive = useState<bool>(true);

    final formKey = useMemoized(() => GlobalKey<FormState>());

    final selectedTopic = useState<UserTopic?>(null);

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
              largeTitle: Text("Baskets", style: UITextStyles.largeTitle),
              previousPageTitle: "Home",
              heroTag: 'user_topics_nav_bar',
              trailing: selectedTopic.value != null
                  ? UIIconButton(
                      icon: const Icon(CupertinoIcons.delete_solid, color: UIColors.error),
                      onPressed: () {
                        context.read<UserTopicsCubit>().deleteItem(selectedTopic.value!.id!);
                        selectedTopic.value = null;
                        topicTitle.clear();
                        topicDetails.clear();
                        isTopicActive.value = true;
                      },
                    )
                  : null,

              stretch: true,
              border: null,
            ),

            BlocConsumer<UserTopicsCubit, UserTopicState>(
              listener: (context, state) {
                // TODO: implement listener
              },
              builder: (context, state) {
                if (state is UserTopicLoading) {
                  return _LoadingView(message: 'Loading Basket...');
                }

                if (state is UserTopicError) {
                  return SliverFillRemaining(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 150),
                      child: Center(child: Text('Error: ${state.message}', style: UITextStyles.body)),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                        decoration: ShapeDecoration(shape: UIRadius.mdShape, color: UIColors.logo),
                        child: Text(
                          "Once you create a basket, your items can be automatically or manually be sorted into it based on their content. You cannot edit the basket name after creation.",
                          style: UITextStyles.subheadline.copyWith(color: UIColors.primary),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ),
                    UIGap.mdVertical(),
                    Container(
                      clipBehavior: Clip.antiAlias,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: ShapeDecoration(
                        shape: UIRadius.mdShape,
                        color: selectedTopic.value != null ? UIColors.border : UIColors.card,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 300),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: CupertinoTextField(
                            readOnly: selectedTopic.value != null,

                            controller: topicTitle,
                            maxLines: 1,
                            style: UITextStyles.body,
                            placeholder: "Basket Name",
                            enableInteractiveSelection: selectedTopic.value == null,
                            textInputAction: TextInputAction.done,
                            decoration: BoxDecoration(
                              // border: Border/,
                              borderRadius: UIRadius.mdBorder,
                            ),
                          ),
                        ),
                      ),
                    ),
                    UIGap.mdVertical(),

                    Container(
                      clipBehavior: Clip.antiAlias,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: ShapeDecoration(shape: UIRadius.mdShape, color: UIColors.card),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 300),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: CupertinoTextField(
                            controller: topicDetails,
                            maxLines: 3,
                            style: UITextStyles.body,
                            placeholder: "More details/keywords to help sort items into this basket (optional)",

                            textInputAction: TextInputAction.done,
                            decoration: BoxDecoration(
                              // border: Border/,
                              borderRadius: UIRadius.mdBorder,
                            ),
                          ),
                        ),
                      ),
                    ),

                    UIGap.mdVertical(),

                    // UIGap.mdVertical(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRSuperellipse(
                        borderRadius: UIRadius.mdBorder,
                        child: CupertinoListTile(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          backgroundColor: UIColors.card,
                          title: Text("Open Basket", style: UITextStyles.body),
                          subtitle: Text(
                            "If opened, items can be sorted into this basket",
                            style: UITextStyles.caption,
                          ),
                          trailing: CupertinoSwitch(
                            // This bool value toggles the switch.
                            value: isTopicActive.value,
                            activeTrackColor: UIColors.primary,
                            onChanged: (bool? value) {
                              isTopicActive.value = value ?? true;
                            },
                          ),
                        ),
                      ),
                    ),

                    UIGap.mdVertical(),
                    UIGap.sVertical(),

                    if (selectedTopic.value != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),

                        child: Row(
                          children: [
                            Expanded(
                              child: UIPrimaryButton(
                                onPressed: () {
                                  FocusScope.of(context).unfocus();

                                  context.read<UserTopicsCubit>().updateItem(
                                    UserTopic(
                                      id: selectedTopic.value!.id,
                                      name: topicTitle.text,
                                      description: topicDetails.text,
                                      isActive: isTopicActive.value,
                                      createdAt: selectedTopic.value!.createdAt,
                                      updatedAt: DateTime.now().millisecondsSinceEpoch,
                                    ),
                                  );

                                  showCupertinoSnackbar(context, "Basket updated successfully");
                                },
                                child: Text(
                                  "Save Basket",
                                  style: UITextStyles.subheadline.copyWith(color: UIColors.background),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (selectedTopic.value == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),

                        child: UIPrimaryButton(
                          onPressed: () {
                            FocusScope.of(context).unfocus();

                            final alreadyExists =
                                (state is UserTopicLoaded) &&
                                state.items.any(
                                  (element) => element.name.toLowerCase() == topicTitle.text.toLowerCase(),
                                );

                            if (topicTitle.text.isEmpty ||
                                topicTitle.text.length < 3 ||
                                topicTitle.text.trim().isEmpty ||
                                alreadyExists) {
                              showCupertinoDialog(
                                context: context,
                                builder: (context) {
                                  return CupertinoAlertDialog(
                                    title: Text('Error'),
                                    content: Text(
                                      alreadyExists
                                          ? "This topic already exists"
                                          : 'Please enter a valid basket name with at least 3 characters.',
                                    ),
                                    actions: <Widget>[
                                      CupertinoDialogAction(
                                        isDefaultAction: true,
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              return;
                            }

                            context.read<UserTopicsCubit>().addUserTopic(
                              name: topicTitle.text,
                              details: topicDetails.text,
                              isActive: isTopicActive.value,
                            );
                            topicTitle.clear();
                            topicDetails.clear();
                            isTopicActive.value = true;
                            selectedTopic.value = null;
                          },
                          child: Text(
                            "Create Basket",
                            style: UITextStyles.subheadline.copyWith(color: UIColors.background),
                          ),
                        ),
                      ),

                    UIGap.mdVertical(),

                    if (state is UserTopicLoaded && state.items.isNotEmpty)
                      CupertinoListTile(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text('Your Baskets', style: UITextStyles.headline.copyWith(color: UIColors.primary)),
                        trailing: selectedTopic.value != null
                            ? UIIconButton(
                                size: 22,
                                onPressed: () {
                                  selectedTopic.value = null;
                                  topicTitle.clear();
                                  topicDetails.clear();
                                  isTopicActive.value = true;
                                },
                                icon: Icon(CupertinoIcons.clear_circled_solid, color: UIColors.primary, size: 20),
                              )
                            : null,
                      ),

                    Padding(padding: UIInsets.horizontal, child: UIDivider.horizontal),
                    UIGap.mdVertical(),

                    Container(
                      margin: UIInsets.horizontal,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.start,
                        children: [
                          if (state is UserTopicLoaded) ...[
                            for (var category in state.items)
                              CupertinoFilterChipSecondary(
                                label: category.name,
                                selected: selectedTopic.value?.id == category.id,
                                onSelected: () {
                                  selectedTopic.value = category;
                                  topicTitle.text = category.name;
                                  topicDetails.text = category.description ?? "";
                                  isTopicActive.value = category.isActive;
                                },
                              ),
                          ],
                        ],
                      ),
                    ),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  final String message;

  const _LoadingView({required this.message});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 150),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 100, child: Image.asset("assets/loading2.gif")),
              UIGap.mdVertical(),
              Text(message, style: UITextStyles.body, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
