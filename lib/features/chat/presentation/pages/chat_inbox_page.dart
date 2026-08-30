import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/features/chat/presentation/theme/chat_typography.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/core/widgets/moment_button.dart';
import 'package:moment/core/widgets/moment_scaffold.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/chat/domain/entities/chat_entities.dart';
import 'package:moment/features/chat/presentation/cubit/chat_inbox_cubit.dart';
import 'package:moment/features/chat/presentation/theme/chat_theme.dart';
import 'package:moment/features/chat/presentation/widgets/chat_friend_chip.dart';
import 'package:moment/features/chat/presentation/widgets/chat_inbox_menu.dart';
import 'package:moment/features/chat/presentation/widgets/chat_inbox_tile.dart';
import 'package:moment/features/chat/presentation/widgets/chat_search_bar.dart';
import 'package:moment/features/chat/presentation/widgets/chat_shimmer.dart';
import 'package:moment/core/widgets/moment_sheet_dialog.dart';
import 'package:moment/features/chat/presentation/widgets/chat_thread_menu.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

class ChatInboxPage extends StatelessWidget {
  const ChatInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ChatInboxView();
  }
}

class _ChatInboxView extends StatefulWidget {
  const _ChatInboxView();

  @override
  State<_ChatInboxView> createState() => _ChatInboxViewState();
}

class _ChatInboxViewState extends State<_ChatInboxView> {
  final _searchController = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openThread(BuildContext context, UserProfile user) {
    context.push(AppRoutes.chatThread(user.id), extra: user);
  }

  Future<void> _showConversationMenu(
    BuildContext context,
    ChatConversation conversation,
  ) async {
    final cubit = context.read<ChatInboxCubit>();
    final relationship = await cubit.getRelationship(conversation.otherUser.id);
    if (!context.mounted) return;

    final action = await showChatInboxMenu(
      context,
      conversation,
      relationship: relationship,
    );
    if (!context.mounted || action == null) return;

    final user = conversation.otherUser;
    final conversationId = conversation.id;

    switch (action) {
      case ChatInboxMenuAction.viewProfile:
        context.push(AppRoutes.friend(user.id));
      case ChatInboxMenuAction.pin:
        await _showActionResult(
          context,
          cubit.pinConversation(conversationId),
          successMessage: 'Chat pinned',
        );
      case ChatInboxMenuAction.unpin:
        await _showActionResult(
          context,
          cubit.unpinConversation(conversationId),
          successMessage: 'Chat unpinned',
        );
      case ChatInboxMenuAction.mute:
        await _showActionResult(
          context,
          cubit.muteConversation(conversationId),
          successMessage: 'Messages muted',
        );
      case ChatInboxMenuAction.unmute:
        await _showActionResult(
          context,
          cubit.unmuteConversation(conversationId),
          successMessage: 'Messages unmuted',
        );
      case ChatInboxMenuAction.deleteChat:
        final ok = await MomentDialog.confirm(
          context,
          title: 'Delete chat?',
          message:
              'All messages in this chat will be permanently deleted. You can start a fresh conversation anytime.',
          confirmLabel: 'Delete',
        );
        if (ok == true && context.mounted) {
          await _showActionResult(
            context,
            cubit.deleteConversation(conversationId),
            successMessage: 'Chat deleted',
          );
        }
      case ChatInboxMenuAction.block:
        await handleChatThreadMenuAction(
          context: context,
          user: user,
          action: ChatThreadMenuAction.block,
          onBlock: () async {
            final error = await cubit.blockUser(user.id);
            if (context.mounted && error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error)),
              );
            }
          },
        );
      case ChatInboxMenuAction.unblock:
        await handleChatThreadMenuAction(
          context: context,
          user: user,
          action: ChatThreadMenuAction.unblock,
          onUnblock: () async {
            final error = await cubit.unblockUser(user.id);
            if (context.mounted && error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error)),
              );
            }
          },
        );
    }
  }

  Future<void> _showActionResult(
    BuildContext context,
    Future<String?> action, {
    required String successMessage,
  }) async {
    final error = await action;
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _matches(UserProfile user) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return user.displayName.toLowerCase().contains(q) ||
        user.username.toLowerCase().contains(q);
  }

  List<ChatConversation> _filterConversations(List<ChatConversation> items) {
    if (_query.isEmpty) return items;
    return items.where((c) => _matches(c.otherUser)).toList();
  }

  List<UserProfile> _filterFriends(List<UserProfile> items) {
    if (_query.isEmpty) return items;
    return items.where(_matches).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatInboxCubit, ChatInboxState>(
      builder: (context, state) {
        final conversations = _filterConversations(state.conversations);
        final friends = _filterFriends(state.friendsWithoutChat);
        final showShimmer = !state.hasCompletedInitialLoad &&
            state.status != ChatInboxStatus.error;

        return MomentScaffold(
          backgroundColor: ChatTheme.threadBackground,
          body: ColoredBox(
            color: ChatTheme.threadBackdrop(context.isDarkMode),
            child: RefreshIndicator(
              color: ChatTheme.accent,
              onRefresh: () => context.read<ChatInboxCubit>().load(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final minBodyHeight =
                      (constraints.maxHeight - 220).clamp(200.0, 480.0);

                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              8,
                              16,
                              4,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chat',
                                  style: ChatTypography.inboxTitle(context),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Message your friends',
                                  style: ChatTypography.inboxSubtitle(
                                    color: ChatTheme.tertiaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: ChatSearchBar(
                          controller: _searchController,
                          onChanged: (value) =>
                              setState(() => _query = value.trim()),
                        ),
                      ),
                      if (showShimmer) ...[
                        const SliverToBoxAdapter(child: ChatInboxShimmer()),
                      ] else if (state.status == ChatInboxStatus.error &&
                          state.conversations.isEmpty)
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: minBodyHeight,
                            child: MomentErrorState(
                              message:
                                  state.errorMessage ?? 'Could not load chats.',
                              actionLabel: 'Try again',
                              onAction: () =>
                                  context.read<ChatInboxCubit>().load(),
                            ),
                          ),
                        )
                      else ...[
                        if (friends.isNotEmpty && _query.isEmpty)
                          SliverToBoxAdapter(
                            child: ChatFriendsRow(
                              friends: friends,
                              onTap: (user) => _openThread(context, user),
                            ),
                          ),
                        if (conversations.isEmpty &&
                            state.status == ChatInboxStatus.ready)
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: minBodyHeight,
                              child: _ChatEmptyState(
                                hasFriends: friends.isNotEmpty ||
                                    state.friendsWithoutChat.isNotEmpty,
                                isSearching: _query.isNotEmpty,
                                onStartChat: friends.isNotEmpty
                                    ? () => _openThread(context, friends.first)
                                    : null,
                              ),
                            ),
                          )
                        else ...[
                          const SliverToBoxAdapter(
                            child: ChatSectionHeader(title: 'Messages'),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final conversation = conversations[index];
                                return ChatInboxTile(
                                  conversation: conversation,
                                  isTyping: state.typingUserIds
                                      .contains(conversation.otherUser.id),
                                  onTap: () => _openThread(
                                    context,
                                    conversation.otherUser,
                                  ),
                                  onLongPress: () => _showConversationMenu(
                                    context,
                                    conversation,
                                  ),
                                );
                              },
                              childCount: conversations.length,
                            ),
                          ),
                        ],
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 110)),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({
    required this.hasFriends,
    required this.isSearching,
    this.onStartChat,
  });

  final bool hasFriends;
  final bool isSearching;
  final VoidCallback? onStartChat;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: ChatTheme.actionGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              isSearching ? 'No results' : 'No messages yet',
              style: ChatTypography.inboxTitle(context).copyWith(fontSize: 20),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isSearching
                  ? 'Try another name or username.'
                  : hasFriends
                  ? 'Tap a friend above to start chatting.'
                  : 'Add friends first, then come back to chat.',
              textAlign: TextAlign.center,
              style: ChatTypography.inboxSubtitle(
                color: ChatTheme.tertiaryText,
              ),
            ),
            if (onStartChat != null) ...[
              const SizedBox(height: AppSpacing.xl),
              MomentButton(
                label: 'Start chatting',
                onPressed: onStartChat,
                expanded: false,
                size: MomentButtonSize.medium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
