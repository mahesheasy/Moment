import 'dart:async';

import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/utils/relative_time.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_button.dart';
import 'package:moment/core/widgets/moment_controls.dart';
import 'package:moment/core/widgets/moment_sheet_dialog.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/friends/domain/entities/friend_entities.dart';
import 'package:moment/features/friends/presentation/cubit/friends_cubit.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

enum _FriendsTab { all, requests, suggested }

enum _FriendsSort { nameAsc, nameDesc, recent }

enum _FriendsFilter { all, recent, mutualOnly }

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FriendsCubit>()..load(),
      child: const _FriendsView(),
    );
  }
}

class _FriendsView extends StatefulWidget {
  const _FriendsView();

  @override
  State<_FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<_FriendsView> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;
  _FriendsTab _tab = _FriendsTab.all;
  _FriendsSort _sort = _FriendsSort.nameAsc;
  _FriendsFilter _filter = _FriendsFilter.all;

  String get _sortLabel => switch (_sort) {
    _FriendsSort.nameAsc => 'A to Z',
    _FriendsSort.nameDesc => 'Z to A',
    _FriendsSort.recent => 'Recent',
  };

  void _cycleSort() {
    setState(() {
      _sort = switch (_sort) {
        _FriendsSort.nameAsc => _FriendsSort.nameDesc,
        _FriendsSort.nameDesc => _FriendsSort.recent,
        _FriendsSort.recent => _FriendsSort.nameAsc,
      };
    });
  }

  Future<void> _showFilterSheet() async {
    final picked = await showModalBottomSheet<_FriendsFilter>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filter',
                style: SettingsType.title(AppColors.textPrimaryDark)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: AppSpacing.md),
              _FilterOption(
                label: 'All',
                selected: _filter == _FriendsFilter.all,
                onTap: () => Navigator.pop(sheetContext, _FriendsFilter.all),
              ),
              _FilterOption(
                label: 'Recently added',
                selected: _filter == _FriendsFilter.recent,
                onTap: () => Navigator.pop(sheetContext, _FriendsFilter.recent),
              ),
              _FilterOption(
                label: 'Mutual friends only',
                selected: _filter == _FriendsFilter.mutualOnly,
                onTap: () =>
                    Navigator.pop(sheetContext, _FriendsFilter.mutualOnly),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _filter = picked);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<FriendsCubit>().search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FriendsCubit, FriendsState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
          context.read<FriendsCubit>().clearMessages();
        }
        if (state.actionMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.actionMessage!)),
          );
          context.read<FriendsCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final isLoading =
            state.status == FriendsStatus.loading ||
            state.status == FriendsStatus.initial;
        final isSearching = _searchController.text.trim().length >= 2;

        return Scaffold(
          body: SafeArea(
            child: isLoading
                ? const _FriendsShimmer()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _FriendsHeader(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          0,
                        ),
                        child: _FriendsSearchField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          onFilterTap: _showFilterSheet,
                          onChanged: (v) {
                            _onSearchChanged(v);
                            setState(() {});
                          },
                        ),
                      ),
                      if (!isSearching) ...[
                        SizedBox(height: AppSpacing.lg),
                        _FriendsTabBar(
                          tab: _tab,
                          requestCount: state.pendingCount,
                          onChanged: (t) => setState(() => _tab = t),
                        ),
                      ],
                      Expanded(
                        child: RefreshIndicator(
                          color: AppColors.violet,
                          onRefresh: () => context.read<FriendsCubit>().load(),
                          child: isSearching
                              ? _SearchTab(
                                  state: state,
                                  query: _searchController.text.trim(),
                                  filter: _filter,
                                )
                              : _TabBody(
                                  tab: _tab,
                                  state: state,
                                  sort: _sort,
                                  filter: _filter,
                                  sortLabel: _sortLabel,
                                  onToggleSort: _cycleSort,
                                  onSeeAllSuggested: () =>
                                      setState(() => _tab = _FriendsTab.suggested),
                                  onSeeAllRequests: () =>
                                      setState(() => _tab = _FriendsTab.requests),
                                ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _FriendsHeader extends StatelessWidget {
  const _FriendsHeader();

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        canPop ? AppSpacing.sm : AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canPop)
            IconButton(
              onPressed: () => context.pop(),
              icon: Icon(AppIcons.back, color: Colors.white, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          Text(
            'Friends',
            style: SettingsType.title(AppColors.textPrimaryDark).copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: SettingsType.body(AppColors.textTertiaryDark),
              children: [
                const TextSpan(text: 'Your '),
                TextSpan(
                  text: 'people',
                  style: TextStyle(
                    foreground: Paint()
                      ..shader = AppColors.bloomGradient.createShader(
                        const Rect.fromLTWH(0, 0, 80, 20),
                      ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '. Your '),
                TextSpan(
                  text: 'moments',
                  style: TextStyle(
                    foreground: Paint()
                      ..shader = AppColors.bloomGradient.createShader(
                        const Rect.fromLTWH(0, 0, 100, 20),
                      ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsSearchField extends StatelessWidget {
  const _FriendsSearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: SettingsType.body(AppColors.textPrimaryDark),
      decoration: InputDecoration(
        hintText: 'Search friends or find people',
        hintStyle: SettingsType.body(AppColors.textTertiaryDark),
        prefixIcon: Icon(
          AppIcons.search,
          color: AppColors.textTertiaryDark,
          size: 20,
        ),
        suffixIcon: IconButton(
          onPressed: onFilterTap,
          icon: Icon(
            Icons.tune_rounded,
            color: AppColors.violet,
            size: 20,
          ),
          splashRadius: 20,
        ),
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.violet.withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}

class _FriendsTabBar extends StatelessWidget {
  const _FriendsTabBar({
    required this.tab,
    required this.requestCount,
    required this.onChanged,
  });

  final _FriendsTab tab;
  final int requestCount;
  final ValueChanged<_FriendsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          _TabItem(
            label: 'All Friends',
            selected: tab == _FriendsTab.all,
            onTap: () => onChanged(_FriendsTab.all),
          ),
          _TabItem(
            label: 'Requests',
            selected: tab == _FriendsTab.requests,
            badge: requestCount > 0 ? requestCount : null,
            onTap: () => onChanged(_FriendsTab.requests),
          ),
          _TabItem(
            label: 'Suggested',
            selected: tab == _FriendsTab.suggested,
            trailingIcon: Icons.auto_awesome_rounded,
            onTap: () => onChanged(_FriendsTab.suggested),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
    this.trailingIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (trailingIcon != null) ...[
                  Icon(
                    trailingIcon,
                    size: 12,
                    color: selected ? AppColors.violet : AppColors.textTertiaryDark,
                  ),
                  SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SettingsType.caption(
                      selected ? AppColors.textPrimaryDark : AppColors.textTertiaryDark,
                    ).copyWith(fontWeight: selected ? FontWeight.w600 : FontWeight.w500),
                  ),
                ),
                if (badge != null) ...[
                  SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.violet,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$badge',
                      style: SettingsType.caption(Colors.white).copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: selected ? AppColors.bloomGradient : null,
                color: selected ? null : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({
    required this.tab,
    required this.state,
    required this.sort,
    required this.filter,
    required this.sortLabel,
    required this.onToggleSort,
    required this.onSeeAllSuggested,
    required this.onSeeAllRequests,
  });

  final _FriendsTab tab;
  final FriendsState state;
  final _FriendsSort sort;
  final _FriendsFilter filter;
  final String sortLabel;
  final VoidCallback onToggleSort;
  final VoidCallback onSeeAllSuggested;
  final VoidCallback onSeeAllRequests;

  @override
  Widget build(BuildContext context) {
    return switch (tab) {
      _FriendsTab.all => _AllFriendsTab(
          state: state,
          sort: sort,
          filter: filter,
          sortLabel: sortLabel,
          onToggleSort: onToggleSort,
          onSeeAllSuggested: onSeeAllSuggested,
          onSeeAllRequests: onSeeAllRequests,
        ),
      _FriendsTab.requests => _RequestsTab(state: state),
      _FriendsTab.suggested => _SuggestedTab(state: state),
    };
  }
}

class _AllFriendsTab extends StatelessWidget {
  const _AllFriendsTab({
    required this.state,
    required this.sort,
    required this.filter,
    required this.sortLabel,
    required this.onToggleSort,
    required this.onSeeAllSuggested,
    required this.onSeeAllRequests,
  });

  final FriendsState state;
  final _FriendsSort sort;
  final _FriendsFilter filter;
  final String sortLabel;
  final VoidCallback onToggleSort;
  final VoidCallback onSeeAllSuggested;
  final VoidCallback onSeeAllRequests;

  @override
  Widget build(BuildContext context) {
    final friends = _filteredAndSortedFriends(state.friends, sort, filter);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.huge,
      ),
      children: [
        if (state.suggestions.isNotEmpty) ...[
          _SectionTitle(
            title: 'Suggested for you',
            showSeeAll: true,
            onSeeAllTap: onSeeAllSuggested,
          ),
          SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.suggestions.length,
              separatorBuilder: (_, _) => SizedBox(width: 16),
              itemBuilder: (context, i) =>
                  _SuggestedTile(suggestion: state.suggestions[i]),
            ),
          ),
          SizedBox(height: AppSpacing.xxl),
        ],
        if (state.incoming.isNotEmpty) ...[
          _SectionTitle(
            title: 'Friend Requests',
            showSeeAll: true,
            onSeeAllTap: onSeeAllRequests,
          ),
          SizedBox(height: AppSpacing.sm),
          ...state.incoming.take(3).map(
            (r) => _IncomingRequestRow(request: r),
          ),
          SizedBox(height: AppSpacing.xxl),
        ],
        _SectionTitle(
          title: 'Your friends',
          trailing: 'Sort by: $sortLabel',
          onTrailingTap: onToggleSort,
          trailingIcon: Icons.swap_vert_rounded,
        ),
        SizedBox(height: AppSpacing.sm),
        if (friends.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: Text(
              'Search by username to find people and grow your circle.',
              textAlign: TextAlign.center,
              style: SettingsType.body(AppColors.textTertiaryDark),
            ),
          )
        else
          ...friends.map((f) => _FriendListRow(friend: f)),
      ],
    );
  }
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({required this.state});

  final FriendsState state;

  @override
  Widget build(BuildContext context) {
    if (state.incoming.isEmpty && state.outgoing.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: AppSpacing.xxl),
          MomentEmptyState(message: 'No pending requests.'),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.huge,
      ),
      children: [
        if (state.incoming.isNotEmpty) ...[
          const _SectionTitle(title: 'Received'),
          SizedBox(height: AppSpacing.sm),
          ...state.incoming.map((r) => _IncomingRequestRow(request: r)),
          SizedBox(height: AppSpacing.xxl),
        ],
        if (state.outgoing.isNotEmpty) ...[
          const _SectionTitle(title: 'Requested'),
          SizedBox(height: AppSpacing.sm),
          ...state.outgoing.map((r) => _OutgoingRequestRow(request: r)),
        ],
      ],
    );
  }
}

class _SuggestedTab extends StatelessWidget {
  const _SuggestedTab({required this.state});

  final FriendsState state;

  @override
  Widget build(BuildContext context) {
    if (state.suggestions.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: AppSpacing.xxl),
          MomentEmptyState(message: 'No suggestions right now.'),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: state.suggestions.length,
      separatorBuilder: (_, _) => SizedBox(height: 4),
      itemBuilder: (context, i) => _SuggestedListRow(
        suggestion: state.suggestions[i],
      ),
    );
  }
}

class _SearchTab extends StatelessWidget {
  const _SearchTab({
    required this.state,
    required this.query,
    required this.filter,
  });

  final FriendsState state;
  final String query;
  final _FriendsFilter filter;

  @override
  Widget build(BuildContext context) {
    final results = _filterSearchResults(state.searchResults, filter);

    if (results.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _SectionTitle(title: 'Results for "$query"'),
          SizedBox(height: AppSpacing.xl),
          const MomentEmptyState(message: 'No people found.'),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _SectionTitle(title: 'Results for "$query"'),
        SizedBox(height: AppSpacing.md),
        for (final r in results) _SearchResultRow(result: r),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.showSeeAll = false,
    this.onSeeAllTap,
    this.trailing,
    this.onTrailingTap,
    this.trailingIcon,
  });

  final String title;
  final bool showSeeAll;
  final VoidCallback? onSeeAllTap;
  final String? trailing;
  final VoidCallback? onTrailingTap;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: SettingsType.title(AppColors.textPrimaryDark).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        if (showSeeAll)
          GestureDetector(
            onTap: onSeeAllTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Text(
                  'See all',
                  style: SettingsType.caption(AppColors.violet)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                Icon(AppIcons.chevronRight, size: 14, color: AppColors.violet),
              ],
            ),
          ),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailingTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Text(
                  trailing!,
                  style: SettingsType.caption(AppColors.violet)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                if (trailingIcon != null) ...[
                  SizedBox(width: 2),
                  Icon(trailingIcon, size: 16, color: AppColors.violet),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _SuggestedTile extends StatelessWidget {
  const _SuggestedTile({required this.suggestion});

  final SuggestedFriend suggestion;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendsCubit, FriendsState>(
      buildWhen: (prev, next) =>
          prev.actingOn != next.actingOn ||
          prev.suggestions != next.suggestions,
      builder: (context, state) {
        final cubit = context.read<FriendsCubit>();
        final profile = suggestion.profile;
        final mutual = suggestion.mutualFriendCount;
        final isSent = suggestion.relationship == FriendRelationship.requestSent;
        final canAdd = suggestion.relationship == FriendRelationship.none;
        final isSending = state.isActingOn('send:${profile.id}');
        final requestId = suggestion.pendingRequestId;
        final isCanceling =
            requestId != null && state.isActingOn('cancel:$requestId');

        return SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  MomentAvatar(
                    name: profile.displayName,
                    imageUrl: profile.avatarUrl,
                    size: 52,
                  ),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: _SuggestionActionBadge(
                      isLoading: isSending || isCanceling,
                      isSent: isSent,
                      onTap: () {
                        if (isSending || isCanceling) return;
                        if (canAdd) {
                          cubit.sendRequest(profile.id);
                        } else if (isSent && requestId != null) {
                          cubit.cancelRequest(requestId);
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                profile.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: SettingsType.caption(AppColors.textPrimaryDark)
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              Text(
                mutual > 0 ? '$mutual mutual' : 'Suggested',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: SettingsType.caption(AppColors.textTertiaryDark)
                    .copyWith(fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SuggestedListRow extends StatelessWidget {
  const _SuggestedListRow({required this.suggestion});

  final SuggestedFriend suggestion;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendsCubit, FriendsState>(
      buildWhen: (prev, next) =>
          prev.actingOn != next.actingOn ||
          prev.suggestions != next.suggestions,
      builder: (context, state) {
        final cubit = context.read<FriendsCubit>();
        final profile = suggestion.profile;
        final mutual = suggestion.mutualFriendCount;
        final isSent = suggestion.relationship == FriendRelationship.requestSent;
        final canAdd = suggestion.relationship == FriendRelationship.none;
        final isSending = state.isActingOn('send:${profile.id}');
        final requestId = suggestion.pendingRequestId;
        final isCanceling =
            requestId != null && state.isActingOn('cancel:$requestId');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  MomentAvatar(
                    name: profile.displayName,
                    imageUrl: profile.avatarUrl,
                    size: 44,
                  ),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: _SuggestionActionBadge(
                      isLoading: isSending || isCanceling,
                      isSent: isSent,
                      onTap: () {
                        if (isSending || isCanceling) return;
                        if (canAdd) {
                          cubit.sendRequest(profile.id);
                        } else if (isSent && requestId != null) {
                          cubit.cancelRequest(requestId);
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: SettingsType.title(AppColors.textPrimaryDark)
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      mutual > 0
                          ? '$mutual mutual friends'
                          : 'Suggested for you',
                      style: SettingsType.caption(AppColors.textTertiaryDark),
                    ),
                  ],
                ),
              ),
              if (isSent)
                _GradientPillButton(
                  label: 'Cancel',
                  compact: true,
                  isLoading: isCanceling,
                  onTap: requestId == null
                      ? null
                      : () => cubit.cancelRequest(requestId),
                )
              else if (canAdd)
                _GradientPillButton(
                  label: 'Add',
                  compact: true,
                  isLoading: isSending,
                  onTap: () => cubit.sendRequest(profile.id),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SuggestionActionBadge extends StatelessWidget {
  const _SuggestionActionBadge({
    required this.isLoading,
    required this.isSent,
    required this.onTap,
  });

  final bool isLoading;
  final bool isSent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: isSent ? AppColors.surfaceElevatedDark : AppColors.violet,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.backgroundDark, width: 2),
        ),
        child: isLoading
            ? Padding(
                padding: EdgeInsets.all(4),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                isSent ? Icons.close_rounded : Icons.person_add_alt_1_rounded,
                size: 12,
                color: isSent ? AppColors.textSecondaryDark : Colors.white,
              ),
      ),
    );
  }
}

class _IncomingRequestRow extends StatelessWidget {
  const _IncomingRequestRow({required this.request});

  final FriendRequest request;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendsCubit, FriendsState>(
      buildWhen: (prev, next) => prev.actingOn != next.actingOn,
      builder: (context, state) {
        final cubit = context.read<FriendsCubit>();
        final sender = request.sender;
        final isRejecting = state.isActingOn('reject:${request.id}');
        final isAccepting = state.isActingOn('accept:${request.id}');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              MomentAvatar(
                name: sender.displayName,
                imageUrl: sender.avatarUrl,
                size: 48,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sender.displayName,
                      style: SettingsType.title(AppColors.textPrimaryDark)
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '@${sender.username} · ${relativeTimeAgo(request.createdAt)}',
                      style: SettingsType.caption(AppColors.textTertiaryDark),
                    ),
                  ],
                ),
              ),
              _CircleIconButton(
                icon: Icons.close_rounded,
                isLoading: isRejecting,
                onTap: isRejecting || isAccepting
                    ? null
                    : () => cubit.rejectRequest(request.id),
              ),
              SizedBox(width: 8),
              _CircleIconButton(
                icon: Icons.check_rounded,
                filled: true,
                isLoading: isAccepting,
                onTap: isRejecting || isAccepting
                    ? null
                    : () => cubit.acceptRequest(request.id),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OutgoingRequestRow extends StatelessWidget {
  const _OutgoingRequestRow({required this.request});

  final FriendRequest request;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendsCubit, FriendsState>(
      buildWhen: (prev, next) => prev.actingOn != next.actingOn,
      builder: (context, state) {
        final receiver = request.receiver;
        final isCanceling = state.isActingOn('cancel:${request.id}');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              MomentAvatar(
                name: receiver.displayName,
                imageUrl: receiver.avatarUrl,
                size: 48,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receiver.displayName,
                      style: SettingsType.title(AppColors.textPrimaryDark)
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Pending · ${relativeTimeAgo(request.createdAt)}',
                      style: SettingsType.caption(AppColors.textTertiaryDark),
                    ),
                  ],
                ),
              ),
              _GradientPillButton(
                label: 'Cancel',
                compact: true,
                isLoading: isCanceling,
                onTap: isCanceling
                    ? null
                    : () => context.read<FriendsCubit>().cancelRequest(request.id),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FriendListRow extends StatelessWidget {
  const _FriendListRow({required this.friend});

  final FriendSummary friend;

  Future<void> _showActions(BuildContext context) async {
    final profile = friend.profile;
    final action = await showModalBottomSheet<_FriendMenuAction>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  MomentAvatar(
                    name: profile.displayName,
                    imageUrl: profile.avatarUrl,
                    size: 40,
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName,
                          style: SettingsType.title(AppColors.textPrimaryDark)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '@${profile.username}',
                          style: SettingsType.caption(AppColors.textTertiaryDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              _FriendMenuTile(
                icon: Icons.person_remove_outlined,
                label: 'Remove friend',
                onTap: () =>
                    Navigator.pop(sheetContext, _FriendMenuAction.remove),
              ),
              _FriendMenuTile(
                icon: Icons.block_outlined,
                label: 'Block',
                destructive: true,
                onTap: () =>
                    Navigator.pop(sheetContext, _FriendMenuAction.block),
              ),
              _FriendMenuTile(
                icon: Icons.flag_outlined,
                label: 'Report',
                destructive: true,
                onTap: () =>
                    Navigator.pop(sheetContext, _FriendMenuAction.report),
              ),
            ],
          ),
        ),
      ),
    );

    if (!context.mounted || action == null) return;

    switch (action) {
      case _FriendMenuAction.remove:
        final ok = await MomentDialog.confirm(
          context,
          title: 'Remove ${profile.displayName}?',
          message: 'You can send a new request later.',
          confirmLabel: 'Remove',
        );
        if (ok == true && context.mounted) {
          await context.read<FriendsCubit>().removeFriend(profile.id);
        }
      case _FriendMenuAction.block:
        final ok = await MomentDialog.confirm(
          context,
          title: 'Block ${profile.displayName}?',
          message: 'They cannot send you requests or moments.',
          confirmLabel: 'Block',
        );
        if (ok == true && context.mounted) {
          await context.read<FriendsCubit>().blockUser(profile.id);
        }
      case _FriendMenuAction.report:
        if (context.mounted) {
          await _showReportSheet(context, profile.id);
        }
    }
  }

  static Future<void> _showReportSheet(
    BuildContext context,
    String userId,
  ) async {
    const reasons = ['Spam', 'Harassment', 'Inappropriate content', 'Other'];
    var selected = reasons.first;
    final detailsController = TextEditingController();
    var isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Report user',
                    style: SettingsType.title(AppColors.textPrimaryDark)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: AppSpacing.md),
                  ...reasons.map(
                    (reason) => AbsorbPointer(
                      absorbing: isSubmitting,
                      child: MomentRadioRow<String>(
                        label: reason,
                        value: reason,
                        groupValue: selected,
                        onChanged: (value) {
                          if (value != null) {
                            setSheetState(() => selected = value);
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: detailsController,
                    enabled: !isSubmitting,
                    style: SettingsType.body(AppColors.textPrimaryDark),
                    decoration: InputDecoration(
                      labelText: 'Details (optional)',
                      labelStyle: SettingsType.caption(AppColors.textTertiaryDark),
                      filled: true,
                      fillColor: AppColors.surfaceElevatedDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  MomentButton(
                    label: 'Submit report',
                    isLoading: isSubmitting,
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setSheetState(() => isSubmitting = true);
                            await context.read<FriendsCubit>().reportUser(
                              userId,
                              selected,
                              details: detailsController.text,
                            );
                            if (context.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    detailsController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = friend.profile;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showActions(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  MomentAvatar(
                    name: profile.displayName,
                    imageUrl: profile.avatarUrl,
                    size: 48,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.backgroundDark,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: SettingsType.title(AppColors.textPrimaryDark)
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '@${profile.username}',
                      style: SettingsType.caption(AppColors.textTertiaryDark),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.more_horiz_rounded,
                size: 20,
                color: AppColors.textTertiaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _FriendMenuAction { remove, block, report }

class _FriendMenuTile extends StatelessWidget {
  const _FriendMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.violet : AppColors.textPrimaryDark;

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: SettingsType.body(color).copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({required this.result});

  final UserSearchResult result;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendsCubit, FriendsState>(
      buildWhen: (prev, next) =>
          prev.actingOn != next.actingOn ||
          prev.searchResults != next.searchResults,
      builder: (context, state) {
        final cubit = context.read<FriendsCubit>();
        final r = result;
        final isSending = state.isActingOn('send:${r.profile.id}');
        final isCanceling = r.pendingRequestId != null &&
            state.isActingOn('cancel:${r.pendingRequestId}');
        final isAccepting = r.pendingRequestId != null &&
            state.isActingOn('accept:${r.pendingRequestId}');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              MomentAvatar(
                name: r.profile.displayName,
                imageUrl: r.profile.avatarUrl,
                size: 48,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.profile.displayName,
                      style: SettingsType.title(AppColors.textPrimaryDark)
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      r.mutualFriendCount > 0
                          ? '@${r.profile.username} · ${r.mutualFriendCount} mutual'
                          : '@${r.profile.username}',
                      style: SettingsType.caption(AppColors.textTertiaryDark),
                    ),
                  ],
                ),
              ),
              switch (r.relationship) {
                FriendRelationship.none => _GradientPillButton(
                  label: 'Add',
                  compact: true,
                  isLoading: isSending,
                  onTap: () => cubit.sendRequest(r.profile.id),
                ),
                FriendRelationship.requestSent => _GradientPillButton(
                  label: 'Cancel',
                  compact: true,
                  isLoading: isCanceling,
                  onTap: r.pendingRequestId == null
                      ? null
                      : () => cubit.cancelRequest(r.pendingRequestId!),
                ),
                FriendRelationship.requestReceived => _GradientPillButton(
                  label: 'Accept',
                  compact: true,
                  isLoading: isAccepting,
                  onTap: r.pendingRequestId == null
                      ? null
                      : () => cubit.acceptRequest(r.pendingRequestId!),
                ),
                _ => Text(
                  'Friends',
                  style: SettingsType.caption(AppColors.textTertiaryDark),
                ),
              },
            ],
          ),
        );
      },
    );
  }
}

class _GradientPillButton extends StatelessWidget {
  const _GradientPillButton({
    required this.label,
    this.onTap,
    this.compact = false,
    this.enabled = true,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool compact;
  final bool enabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !isLoading;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: active ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: compact ? null : double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 20,
            vertical: compact ? 8 : 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: active ? AppColors.bloomGradient : null,
            color: active ? null : AppColors.surfaceElevatedDark,
          ),
          child: isLoading
              ? SizedBox(
                  width: compact ? 52 : 72,
                  height: 14,
                  child: Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  style: SettingsType.caption(
                    active ? Colors.white : AppColors.textTertiaryDark,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.isLoading = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.violet : AppColors.surfaceElevatedDark,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: filled ? Colors.white : AppColors.textSecondaryDark,
                  ),
                )
              : Icon(
                  icon,
                  size: 18,
                  color: filled ? Colors.white : AppColors.textSecondaryDark,
                ),
        ),
      ),
    );
  }
}

List<FriendSummary> _filteredAndSortedFriends(
  List<FriendSummary> friends,
  _FriendsSort sort,
  _FriendsFilter filter,
) {
  var list = [...friends];

  if (filter == _FriendsFilter.recent) {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    list = list.where((f) => f.since.isAfter(cutoff)).toList();
  }

  switch (sort) {
    case _FriendsSort.nameAsc:
      list.sort(
        (a, b) => a.profile.displayName.toLowerCase().compareTo(
          b.profile.displayName.toLowerCase(),
        ),
      );
    case _FriendsSort.nameDesc:
      list.sort(
        (a, b) => b.profile.displayName.toLowerCase().compareTo(
          a.profile.displayName.toLowerCase(),
        ),
      );
    case _FriendsSort.recent:
      list.sort((a, b) => b.since.compareTo(a.since));
  }

  return list;
}

List<UserSearchResult> _filterSearchResults(
  List<UserSearchResult> results,
  _FriendsFilter filter,
) {
  if (filter != _FriendsFilter.mutualOnly) return results;
  return results.where((r) => r.mutualFriendCount > 0).toList();
}

class _FilterOption extends StatelessWidget {
  const _FilterOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: SettingsType.body(
          selected ? AppColors.violet : AppColors.textPrimaryDark,
        ).copyWith(fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
      ),
      trailing: selected
          ? Icon(Icons.check_rounded, color: AppColors.violet, size: 20)
          : null,
    );
  }
}

class _FriendsShimmer extends StatelessWidget {
  const _FriendsShimmer();

  @override
  Widget build(BuildContext context) {
    return const MomentShimmer(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MomentShimmerBone(width: 100, height: 24, radius: 8),
            SizedBox(height: 8),
            MomentShimmerBone(width: 200, height: 12, radius: 6),
            SizedBox(height: AppSpacing.lg),
            MomentShimmerBone(width: double.infinity, height: 48, radius: 14),
            SizedBox(height: AppSpacing.lg),
            MomentShimmerBone(width: double.infinity, height: 32, radius: 8),
          ],
        ),
      ),
    );
  }
}
