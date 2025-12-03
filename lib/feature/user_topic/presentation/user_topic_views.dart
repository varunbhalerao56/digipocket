import 'package:digipocket/feature/user_topic/user_topic.dart';
import 'package:digipocket/global/themes/themes.dart';
import 'package:digipocket/global/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class UserTopicView extends HookWidget {
  const UserTopicView({super.key});

  @override
  Widget build(BuildContext context) {
    final topicTitle = useTextEditingController();
    final topicDetails = useTextEditingController();
    final isTopicActive = useState<bool>(true);

    final selectedTopic = useState<UserTopic?>(null);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: CupertinoPageScaffold(
        backgroundColor: UIColors.background,
        child: Stack(
          children: [
            CustomScrollView(
              physics: BouncingScrollPhysics(),
              clipBehavior: Clip.antiAlias,
              slivers: [
                CupertinoSliverNavigationBar(
                  backgroundColor: UIColors.background,
                  largeTitle: Text("Baskets", style: UITextStyles.largeTitle),
                  previousPageTitle: "Home",
                  heroTag: 'home_nav_bar',
                  trailing: selectedTopic.value != null
                      ? UIIconButton(
                          icon: const Icon(CupertinoIcons.delete_solid, color: UIColors.error),
                          onPressed: () {
                            context.read<UserTopicsCubit>().deleteItem(selectedTopic.value!.id);
                            selectedTopic.value = null;
                            topicTitle.clear();
                            topicDetails.clear();
                            isTopicActive.value = true;

                            showCupertinoSnackbar(context, "Basket deleted successfully");
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                          decoration: BoxDecoration(color: UIColors.logo),
                          child: Text(
                            "Your items can be sorted into it based on their content. You cannot edit the basket name after creation.",
                            style: UITextStyles.subheadline.copyWith(color: UIColors.primary),
                            textAlign: TextAlign.justify,
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
                                placeholder:
                                    "More details/keywords to help sort items into this basket (min 10 characters)",
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
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: ShapeDecoration(
                            shape: UIRadius.mdShape.copyWith(side: BorderSide(color: UIColors.border)),
                            color: UIColors.background,
                          ),
                          child: CupertinoListTile(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),

                            title: Text("Open Basket", style: UITextStyles.bodyBold),
                            subtitle: Text("If open, items can be sorted into basket", style: UITextStyles.subheadline),
                            trailing: CupertinoSwitch(
                              // This bool value toggles the switch.
                              value: isTopicActive.value,
                              activeTrackColor: UIColors.logo,
                              onChanged: (bool? value) {
                                isTopicActive.value = value ?? true;
                              },
                            ),
                          ),
                        ),

                        UIGap.xlVertical(),
                      ]),
                    );
                  },
                ),
              ],
            ),

            if (bottomInset < 100)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BlocBuilder<UserTopicsCubit, UserTopicState>(
                  builder: (context, state) {
                    return SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: ShapeDecoration(
                              shape: UIRadius.mdShape.copyWith(side: BorderSide(color: UIColors.border)),
                              color: UIColors.background,
                            ),
                            child: CupertinoListTile(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              title: Text("Manage Existing Basket", style: UITextStyles.bodyBold),
                              subtitle: Text("Select a basket to edit or delete", style: UITextStyles.subheadline),
                              trailing: const Icon(CupertinoIcons.settings_solid, color: UIColors.primary),
                              onTap: () {
                                showCupertinoModalPopup(
                                  context: context,

                                  builder: (context) {
                                    return SafeArea(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        decoration: ShapeDecoration(shape: UIRadius.mdShape, color: UIColors.primary),
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(maxHeight: 400),
                                          child: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                UIGap.sVertical(),
                                                CupertinoListTile(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                  title: Text(
                                                    'Your Baskets',
                                                    style: UITextStyles.headline.copyWith(color: UIColors.background),
                                                  ),
                                                ),

                                                Padding(
                                                  padding: UIInsets.horizontal,
                                                  child: UIDivider.horizontalExtraThin,
                                                ),
                                                UIGap.mdVertical(),

                                                Container(
                                                  margin: UIInsets.horizontal,
                                                  child: Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    crossAxisAlignment: WrapCrossAlignment.start,
                                                    alignment: WrapAlignment.start,
                                                    children: [
                                                      ...[
                                                        for (var category
                                                            in state is UserTopicLoaded ? state.items : <UserTopic>[])
                                                          CupertinoFilterChip(
                                                            label: category.name,
                                                            selected: selectedTopic.value?.id == category.id,
                                                            onSelected: () {
                                                              selectedTopic.value = category;
                                                              topicTitle.text = category.name;
                                                              topicDetails.text = category.description ?? "";
                                                              isTopicActive.value = category.isActive;

                                                              HapticFeedback.selectionClick();

                                                              Navigator.of(context).pop();
                                                            },
                                                          ),
                                                      ],
                                                    ],
                                                  ),
                                                ),

                                                UIGap.mdVertical(),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                          UIGap.lVertical(),

                          if (selectedTopic.value != null) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),

                              child: Row(
                                children: [
                                  Expanded(
                                    child: UITextButton(
                                      onPressed: () {
                                        if (state is UserTopicLoading) return;

                                        FocusScope.of(context).unfocus();

                                        selectedTopic.value = null;
                                        topicTitle.clear();
                                        topicDetails.clear();
                                        isTopicActive.value = true;
                                      },
                                      child: Text(
                                        "Clear Selection",
                                        style: UITextStyles.subheadlineBold.copyWith(color: UIColors.primary),
                                      ),
                                    ),
                                  ),

                                  UIGap.sHorizontal(),
                                  Expanded(
                                    child: UIPrimaryButton(
                                      onPressed: () {
                                        if (state is UserTopicLoading) return;

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
                                      child: state is UserTopicLoading
                                          ? CupertinoActivityIndicator()
                                          : Text(
                                              "Save Basket",
                                              style: UITextStyles.subheadlineBold.copyWith(color: UIColors.background),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (selectedTopic.value == null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),

                              child: SizedBox(
                                width: double.infinity,
                                child: UIPrimaryButton(
                                  onPressed: () {
                                    if (state is UserTopicLoading) return;

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

                                    if (topicDetails.text.isEmpty || topicDetails.text.length < 10) {
                                      showCupertinoDialog(
                                        context: context,
                                        builder: (context) {
                                          return CupertinoAlertDialog(
                                            title: Text('Error'),
                                            content: Text(
                                              'Please provide more details or keywords with at least 10 characters to help sort items into this basket.',
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

                                    showCupertinoSnackbar(context, "Basket created successfully");
                                  },
                                  child: state is UserTopicLoading
                                      ? CupertinoActivityIndicator()
                                      : Text(
                                          "Create Basket",
                                          style: UITextStyles.subheadlineBold.copyWith(color: UIColors.background),
                                        ),
                                ),
                              ),
                            ),
                          UIGap.mdVertical(),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
