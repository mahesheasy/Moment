import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/widgets/moment_scaffold.dart';
import 'package:moment/core/widgets/moment_sheet_dialog.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/chat/presentation/cubit/chat_thread_cubit.dart';
import 'package:moment/features/chat/presentation/models/moment_timeline_models.dart';
import 'package:moment/features/chat/presentation/theme/moment_space_theme.dart';
import 'package:moment/features/chat/presentation/utils/chat_message_actions.dart';
import 'package:moment/features/chat/presentation/utils/moment_timeline_mapper.dart';
import 'package:moment/features/chat/presentation/widgets/chat_edit_message_sheet.dart';
import 'package:moment/features/chat/presentation/widgets/chat_message_actions_sheet.dart';
import 'package:moment/features/chat/presentation/widgets/chat_message_info_sheet.dart';
import 'package:moment/features/chat/presentation/widgets/chat_reply_banner.dart';
import 'package:moment/features/chat/presentation/widgets/chat_thread_blocked.dart';
import 'package:moment/features/chat/presentation/widgets/chat_thread_menu.dart';
import 'package:moment/features/chat/presentation/widgets/chat_thread_shimmer.dart';
import 'package:moment/features/chat/presentation/widgets/chat_typing_indicator.dart';
import 'package:moment/features/chat/presentation/widgets/moment_space/moment_space_composer.dart';
import 'package:moment/features/chat/presentation/widgets/moment_space/moment_space_header.dart';
import 'package:moment/features/chat/presentation/widgets/moment_space/moment_space_timeline.dart';
import 'package:moment/features/friends/domain/entities/friend_entities.dart';
import 'package:moment/features/friends/domain/repositories/friends_repository.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

class ChatThreadPage extends StatefulWidget {
  const ChatThreadPage({
    required this.userId,
    this.otherUser,
    super.key,
  });

  final String userId;
  final UserProfile? otherUser;

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _composerFocus = FocusNode();
  UserProfile? _resolvedUser;
  var _loadingProfile = false;

  @override
  void initState() {
    super.initState();
    _resolvedUser = widget.otherUser;
    if (_resolvedUser == null) _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);
    final result = await sl<FriendsRepository>().getFriendProfile(widget.userId);
    if (!mounted) return;
    if (result is Success<UserProfile>) {
      setState(() {
        _resolvedUser = result.value;
        _loadingProfile = false;
      });
    } else {
      setState(() => _loadingProfile = false);
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final position = _scrollController.position;
      if (!position.hasContentDimensions) return;

      final target = position.maxScrollExtent;
      if (target <= position.pixels) return;

      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _pickImage(BuildContext context) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (file == null || !context.mounted) return;

    final bytes = await file.readAsBytes();
    final mime = file.mimeType ?? 'image/jpeg';
    if (!context.mounted) return;
    await context.read<ChatThreadCubit>().sendImage(
      bytes: bytes,
      mimeType: mime,
    );
  }

  void _onSwipeReply(BuildContext context, MomentTimelineEntry entry) {
    final cubit = context.read<ChatThreadCubit>();
    final message = cubit.messageById(entry.id);
    if (message == null) return;
    cubit.setReplyTo(message);
    _composerFocus.requestFocus();
  }

  Future<void> _onReact(
    BuildContext context,
    MomentTimelineEntry entry,
  ) async {
    final cubit = context.read<ChatThreadCubit>();
    final emoji = await showChatReactionPicker(context);
    if (emoji == null || !context.mounted) return;
    unawaited(cubit.reactToMessage(entry.id, emoji));
  }

  Future<void> _onMessageLongPress(
    BuildContext context,
    MomentTimelineEntry entry,
  ) async {
    final cubit = context.read<ChatThreadCubit>();
    final message = cubit.messageById(entry.id);
    if (message == null) return;
    final user = _resolvedUser;
    if (user == null) return;

    final preview = chatMessagePreview(message);

    final action = await showChatMessageActionsSheet(
      context: context,
      message: message,
      previewText: preview,
      onQuickReact: (emoji) => cubit.reactToMessage(message.id, emoji),
    );
    if (!context.mounted || action == null) return;

    switch (action) {
      case ChatMessageSheetAction.reply:
        cubit.setReplyTo(message);
        _composerFocus.requestFocus();
      case ChatMessageSheetAction.star:
        await cubit.toggleMessageStar(message.id);
      case ChatMessageSheetAction.edit:
        final edited = await showChatEditMessageSheet(
          context: context,
          initialText: message.body,
        );
        if (edited != null && context.mounted) {
          await cubit.editMessage(message.id, edited);
        }
      case ChatMessageSheetAction.info:
        await showChatMessageInfoSheet(
          context: context,
          message: message,
          otherUserName: user.displayName,
        );
      case ChatMessageSheetAction.react:
        final emoji = await showChatReactionPicker(context);
        if (emoji != null) {
          await cubit.reactToMessage(message.id, emoji);
        }
      case ChatMessageSheetAction.copy:
        await copyChatMessageText(context, preview);
      case ChatMessageSheetAction.deleteForMe:
        await cubit.deleteMessageForMe(message.id);
      case ChatMessageSheetAction.deleteForEveryone:
        final ok = await MomentDialog.confirm(
          context,
          title: 'Delete for everyone?',
          message: 'This message will be removed for all participants.',
          confirmLabel: 'Delete',
        );
        if (ok == true && context.mounted) {
          await cubit.deleteMessageForEveryone(message.id);
        }
    }
  }

  Future<void> _onHeaderMenu(BuildContext context, UserProfile user) async {
    final cubit = context.read<ChatThreadCubit>();
    final action = await showChatThreadMenu(
      context,
      user,
      relationship: cubit.state.relationship,
    );
    if (!context.mounted || action == null) return;
    await handleChatThreadMenuAction(
      context: context,
      user: user,
      action: action,
      onBlock: cubit.blockUser,
      onUnblock: cubit.unblockUser,
    );
  }

  Future<void> _confirmUnblock(BuildContext context, UserProfile user) async {
    final ok = await MomentDialog.confirm(
      context,
      title: 'Unblock ${user.displayName}?',
      message:
          'They will be able to send you friend requests and messages again.',
      confirmLabel: 'Unblock',
    );
    if (ok == true && context.mounted) {
      await context.read<ChatThreadCubit>().unblockUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _resolvedUser;
    if (user == null) {
      return MomentScaffold(
        backgroundColor: MomentSpaceTheme.background,
        appBar: MomentAppBar(
          leading: IconButton(
            icon: const Icon(AppIcons.back, size: 20),
            onPressed: () => context.pop(),
          ),
          title: 'Moments',
        ),
        body: _loadingProfile
            ? const MomentLoading()
            : MomentErrorState(
                message: 'Could not load this space.',
                actionLabel: 'Try again',
                onAction: _loadProfile,
              ),
      );
    }

    return BlocProvider(
      create: (_) => sl<ChatThreadCubit>(param1: user)..load(),
      child: BlocConsumer<ChatThreadCubit, ChatThreadState>(
        listenWhen: (prev, next) =>
            prev.messages.length != next.messages.length ||
            prev.errorMessage != next.errorMessage,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          _scrollToEnd();
        },
        builder: (context, state) {
          final currentUserId =
              context.read<ChatThreadCubit>().currentUserId ?? '';
          final rows = MomentTimelineMapper.buildRows(
            messages: state.messages,
            tab: MomentSpaceTab.moments,
            otherUserName: user.displayName,
            currentUserId: currentUserId,
          );
          final isBlocked = state.isBlocked;
          final showShimmer = !state.hasCompletedInitialLoad;

          return MomentScaffold(
            backgroundColor: MomentSpaceTheme.background,
            body: Column(
              children: [
                MomentSpaceHeader(
                  user: user,
                  showHero:
                      state.hasCompletedInitialLoad && state.messages.isNotEmpty,
                  onMenu: () => _onHeaderMenu(context, user),
                ),
                Expanded(
                  child: showShimmer
                      ? const ChatThreadShimmer()
                      : state.status == ChatThreadStatus.error &&
                            state.messages.isEmpty
                      ? MomentErrorState(
                          message:
                              state.errorMessage ?? 'Could not load messages.',
                          actionLabel: 'Try again',
                          onAction: () =>
                              context.read<ChatThreadCubit>().load(),
                        )
                      : isBlocked && state.messages.isEmpty
                      ? ChatThreadBlockedNotice(
                          user: user,
                          relationship: state.relationship,
                          centered: true,
                        )
                      : MomentSpaceTimeline(
                          rows: rows,
                          otherUser: user,
                          scrollController: _scrollController,
                          onAddReaction: (entry) => _onReact(context, entry),
                          onLongPress: (MomentTimelineEntry entry) =>
                              _onMessageLongPress(context, entry),
                          onReply: isBlocked
                              ? null
                              : (MomentTimelineEntry entry) =>
                                    _onSwipeReply(context, entry),
                        ),
                ),
                if (!isBlocked) ...[
                  if (state.otherUserTyping) ChatTypingIndicator(user: user),
                  if (state.replyTo != null)
                    ChatReplyBanner(
                      reply: state.replyTo!,
                      onClose: () =>
                          context.read<ChatThreadCubit>().clearReply(),
                    ),
                  MomentSpaceComposer(
                    controller: _inputController,
                    focusNode: _composerFocus,
                    isSending: state.status == ChatThreadStatus.sending,
                    onTextChanged: (text) => context
                        .read<ChatThreadCubit>()
                        .onComposerChanged(text),
                    onSend: () {
                      final text = _inputController.text;
                      if (text.trim().isEmpty) return;
                      _inputController.clear();
                      context.read<ChatThreadCubit>().sendMessage(text);
                    },
                    onPlus: () {},
                    onPickImage: () => _pickImage(context),
                    onSparkle: () => context.push(AppRoutes.camera),
                  ),
                ] else
                  ChatThreadBlockedBar(
                    user: user,
                    relationship: state.relationship,
                    isActing: state.isActingOnRelationship,
                    onUnblock: state.relationship == FriendRelationship.blocked
                        ? () => _confirmUnblock(context, user)
                        : null,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
