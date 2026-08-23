import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_breakpoints.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_hero_tags.dart';
import 'package:moment/core/widgets/moment_sheet_dialog.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/auth/domain/repositories/auth_repository.dart';
import 'package:moment/features/memories/domain/entities/daily_category.dart';
import 'package:moment/features/memories/domain/entities/memory.dart';
import 'package:moment/features/memories/domain/entities/memory_theme.dart';
import 'package:moment/features/memories/presentation/cubit/memory_cubit.dart';
import 'package:moment/features/memories/presentation/widgets/create_memory_sheet.dart';
import 'package:moment/features/memories/presentation/widgets/daily_category_rail.dart';
import 'package:moment/features/memories/presentation/widgets/memory_cover_hero.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/prompts/presentation/widgets/daily_prompt_card.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

class MemoriesPage extends StatelessWidget {
  const MemoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MemoryVaultCubit>()..load(),
      child: const _MemoriesView(),
    );
  }
}

class _MemoriesView extends StatefulWidget {
  const _MemoriesView();

  @override
  State<_MemoriesView> createState() => _MemoriesViewState();
}

class _MemoriesViewState extends State<_MemoriesView> {
  var _showVault = false;
  var _ready = false;
  var _onMemories = false;
  var _searchVisible = false;
  var _query = '';
  _DailyCategoryFilter _dailyFilter = _DailyCategoryFilter.all;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = GoRouterState.of(context).uri.path == AppRoutes.memories;
    if (!visible) {
      _onMemories = false;
      return;
    }
    if (_onMemories) return;
    _onMemories = true;
    if (!_ready) {
      _ready = true;
      return;
    }
    context.read<MemoryVaultCubit>().refreshDaily();
  }

  Future<void> _createMemory() async {
    final memory = await CreateMemorySheet.show(context);
    if (memory != null && mounted) {
      await context.push(AppRoutes.memory(memory.id));
      if (mounted) {
        await context.read<MemoryVaultCubit>().load();
      }
    }
  }

  Future<void> _confirmDeleteMemory(
    BuildContext context,
    MemorySummary memory,
  ) async {
    final confirmed = await MomentDialog.confirm(
      context,
      title: 'Delete memory?',
      message: 'This removes "${memory.title}" for everyone.',
      confirmLabel: 'Delete',
    );
    if (confirmed != true || !context.mounted) return;

    final deleted = await context.read<MemoryVaultCubit>().deleteMemory(
      memory.id,
    );
    if (!context.mounted) return;
    if (deleted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Memory deleted')));
    }
  }

  Future<void> _showMomentMenu(BuildContext context, Moment moment) async {
    final me = sl<AuthRepository>().currentUserId;
    final isSender = me != null && moment.sender.id == me;

    final action = await showModalBottomSheet<_MomentMenuAction>(
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
              _MomentMenuTile(
                icon: Icons.bookmark_add_outlined,
                label: 'Save to Vault',
                onTap: () =>
                    Navigator.pop(sheetContext, _MomentMenuAction.save),
              ),
              if (isSender)
                _MomentMenuTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete moment',
                  destructive: true,
                  onTap: () =>
                      Navigator.pop(sheetContext, _MomentMenuAction.delete),
                )
              else
                _MomentMenuTile(
                  icon: Icons.visibility_off_outlined,
                  label: 'Remove from Memories',
                  onTap: () =>
                      Navigator.pop(sheetContext, _MomentMenuAction.remove),
                ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    final cubit = context.read<MemoryVaultCubit>();
    switch (action) {
      case _MomentMenuAction.save:
        final saved = await cubit.saveMomentToVault(moment);
        if (!context.mounted) return;
        if (saved != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved to Vault')),
          );
        } else if (cubit.state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(cubit.state.errorMessage!)),
          );
        }
      case _MomentMenuAction.remove:
        final confirmed = await MomentDialog.confirm(
          context,
          title: 'Remove from Memories?',
          message: 'This moment will no longer appear in your daily feed.',
          confirmLabel: 'Remove',
        );
        if (confirmed != true || !context.mounted) return;
        final removed = await cubit.dismissRecentMoment(
          moment,
          isSender: false,
        );
        if (!context.mounted) return;
        if (removed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Moment removed')),
          );
        }
      case _MomentMenuAction.delete:
        final confirmed = await MomentDialog.confirm(
          context,
          title: 'Delete moment?',
          message: 'This permanently deletes the moment for everyone.',
          confirmLabel: 'Delete',
        );
        if (confirmed != true || !context.mounted) return;
        final deleted = await cubit.dismissRecentMoment(
          moment,
          isSender: true,
        );
        if (!context.mounted) return;
        if (deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Moment deleted')),
          );
        }
    }
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    if (_showVault) {
      final cubit = context.read<MemoryVaultCubit>();
      final current = cubit.state.filterType;
      await showModalBottomSheet<void>(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter vault',
                  style: SettingsType.body(Colors.white).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 12),
                _FilterOption(
                  label: 'All memories',
                  selected: current == null,
                  onTap: () {
                    cubit.setFilter(null);
                    Navigator.pop(sheetContext);
                  },
                ),
                for (final type in MemoryType.values)
                  _FilterOption(
                    label: type.label,
                    selected: current == type,
                    onTap: () {
                      cubit.setFilter(type);
                      Navigator.pop(sheetContext);
                    },
                  ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter daily',
                style: SettingsType.body(Colors.white).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 12),
              _FilterOption(
                label: 'All',
                selected: _dailyFilter == _DailyCategoryFilter.all,
                onTap: () {
                  setState(() => _dailyFilter = _DailyCategoryFilter.all);
                  Navigator.pop(sheetContext);
                },
              ),
              _FilterOption(
                label: 'Circles only',
                selected: _dailyFilter == _DailyCategoryFilter.circles,
                onTap: () {
                  setState(() => _dailyFilter = _DailyCategoryFilter.circles);
                  Navigator.pop(sheetContext);
                },
              ),
              _FilterOption(
                label: 'People only',
                selected: _dailyFilter == _DailyCategoryFilter.people,
                onTap: () {
                  setState(() => _dailyFilter = _DailyCategoryFilter.people);
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DailyCategory> _filteredDailyCategories(List<DailyCategory> categories) {
    final q = _query.trim().toLowerCase();
    var filtered = categories;

    filtered = switch (_dailyFilter) {
      _DailyCategoryFilter.all => filtered,
      _DailyCategoryFilter.circles => filtered
          .where((c) => c.kind == DailyCategoryKind.circle)
          .toList(),
      _DailyCategoryFilter.people => filtered
          .where((c) => c.kind == DailyCategoryKind.person)
          .toList(),
    };

    if (q.isEmpty) return filtered;

    return filtered.where((category) {
      if (category.title.toLowerCase().contains(q)) return true;
      return category.moments.any((moment) {
        final caption = moment.caption?.toLowerCase() ?? '';
        final sender = moment.sender.displayName.toLowerCase();
        return caption.contains(q) || sender.contains(q);
      });
    }).toList();
  }

  List<MemorySummary> _filteredVaultMemories(MemoryVaultState state) {
    final q = _query.trim().toLowerCase();
    var memories = state.filteredMemories;
    if (q.isEmpty) return memories;
    return memories.where((memory) {
      final title = memory.title.toLowerCase();
      final caption = memory.caption?.toLowerCase() ?? '';
      return title.contains(q) || caption.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = AppBreakpoints.contentMaxWidth(context);
    final padding = AppBreakpoints.pagePadding(context);

    return ColoredBox(
      color: AppColors.backgroundDark,
      child: BlocBuilder<MemoryVaultCubit, MemoryVaultState>(
        builder: (context, state) {
          return SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: switch (state.status) {
                  MemoryVaultStatus.loading ||
                  MemoryVaultStatus.initial ||
                  MemoryVaultStatus.saving => const _MemoriesShimmer(),
                  MemoryVaultStatus.failure => MomentErrorState(
                    message: state.errorMessage ?? 'Could not load memories.',
                    actionLabel: 'Retry',
                    onAction: () => context.read<MemoryVaultCubit>().load(),
                  ),
                  MemoryVaultStatus.loaded => RefreshIndicator(
                    color: AppColors.violet,
                    onRefresh: () => context.read<MemoryVaultCubit>().load(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: padding.copyWith(top: 20, bottom: 128),
                      children: [
                        _MemoriesHeader(
                          date: DateTime.now(),
                          showVaultActions: _showVault,
                          onCreateMemory: _createMemory,
                          onSearch: () => setState(() {
                            _searchVisible = !_searchVisible;
                            if (!_searchVisible) {
                              _query = '';
                              _searchController.clear();
                            }
                          }),
                          onFilter: () => _showFilterSheet(context),
                          searchActive: _searchVisible,
                        ),
                        if (_searchVisible) ...[
                          SizedBox(height: 12),
                          TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: SettingsType.body(Colors.white).copyWith(
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText: _showVault
                                  ? 'Search vault memories…'
                                  : 'Search moments or people…',
                              hintStyle: SettingsType.caption(
                                AppColors.textTertiaryDark,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: AppColors.textTertiaryDark,
                              ),
                              suffixIcon: _query.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _query = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: AppColors.surfaceElevatedDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              isDense: true,
                            ),
                            onChanged: (value) => setState(() => _query = value),
                          ),
                        ],
                        SizedBox(height: 22),
                        _JournalTabs(
                          vaultSelected: _showVault,
                          onVault: () => setState(() => _showVault = true),
                          onDaily: () => setState(() => _showVault = false),
                        ),
                        SizedBox(height: 24),
                        if (_showVault)
                          ..._vaultTab(context, state)
                        else
                          ..._dailyTab(context, state),
                      ],
                    ),
                  ),
                },
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _vaultTab(BuildContext context, MemoryVaultState state) {
    final memories = _filteredVaultMemories(state);
    if (memories.isEmpty) {
      return [
        MomentEmptyState(
          message: _query.isNotEmpty || state.filterType != null
              ? 'No memories match your search or filter.'
              : 'No saved memories yet.\nCreate one from your moments.',
        ),
      ];
    }

    return [
      for (final memory in memories) ...[
        _VaultCover(
          memory: memory,
          canDelete: memory.isOwner,
          onDelete: () => _confirmDeleteMemory(context, memory),
          onTap: () async {
            await context.push(AppRoutes.memory(memory.id));
            if (context.mounted) {
              await context.read<MemoryVaultCubit>().load();
            }
          },
        ),
        SizedBox(height: 28),
      ],
    ];
  }

  List<Widget> _dailyTab(BuildContext context, MemoryVaultState state) {
    final categories = _filteredDailyCategories(state.dailyCategories);
    return [
      const DailyPromptCard(darkStyle: true),
      if (categories.isEmpty)
        MomentEmptyState(
          message: _query.isNotEmpty || _dailyFilter != _DailyCategoryFilter.all
              ? 'No moments match your search or filter.'
              : 'Viewed moments land here after you open them.',
        )
      else
        for (final category in categories) ...[
          DailyCategoryRail(
            category: category,
            reactionsByMomentId: state.reactionsByMomentId,
            onOpenMoment: (moment) => context.push(
              AppRoutes.moment(
                moment.id,
                heroScope: MomentHeroTags.scopeMemories,
              ),
            ),
            onMomentMenu: (moment) => _showMomentMenu(context, moment),
          ),
          SizedBox(height: 28),
        ],
    ];
  }
}

enum _DailyCategoryFilter { all, circles, people }

enum _MomentMenuAction { save, remove, delete }

class _MomentMenuTile extends StatelessWidget {
  const _MomentMenuTile({
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
    final color = destructive ? AppColors.errorDark : Colors.white;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
      onTap: onTap,
    );
  }
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
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        label,
        style: SettingsType.body(
          selected ? Colors.white : AppColors.textSecondaryDark,
        ).copyWith(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      trailing: selected
          ? Icon(Icons.check_rounded, color: AppColors.violet, size: 18)
          : null,
      onTap: onTap,
    );
  }
}

class _MemoriesHeader extends StatelessWidget {
  const _MemoriesHeader({
    required this.date,
    this.showVaultActions = false,
    this.onCreateMemory,
    this.onSearch,
    this.onFilter,
    this.searchActive = false,
  });

  final DateTime date;
  final bool showVaultActions;
  final VoidCallback? onCreateMemory;
  final VoidCallback? onSearch;
  final VoidCallback? onFilter;
  final bool searchActive;

  @override
  Widget build(BuildContext context) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weekdays[date.weekday - 1].toUpperCase(),
                style: SettingsType.caption(AppColors.textTertiaryDark).copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                  fontSize: 9,
                ),
              ),
              SizedBox(height: 3),
              Text(
                '${date.day} ${months[date.month - 1]}',
                style: SettingsType.title(Colors.white).copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
        _HeaderIconButton(
          icon: Icons.search_rounded,
          onTap: onSearch ?? () {},
          active: searchActive,
        ),
        SizedBox(width: 4),
        _HeaderIconButton(
          icon: Icons.tune_rounded,
          onTap: onFilter ?? () {},
        ),
        if (showVaultActions && onCreateMemory != null) ...[
          SizedBox(width: 4),
          _HeaderIconButton(
            icon: Icons.add_rounded,
            onTap: onCreateMemory!,
          ),
        ],
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.accentSoftDark : AppColors.surfaceElevatedDark,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 16,
            color: active ? AppColors.violet : AppColors.textSecondaryDark,
          ),
        ),
      ),
    );
  }
}

class _JournalTabs extends StatelessWidget {
  const _JournalTabs({
    required this.vaultSelected,
    required this.onVault,
    required this.onDaily,
  });

  final bool vaultSelected;
  final VoidCallback onVault;
  final VoidCallback onDaily;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TabLabel(label: 'Daily', selected: !vaultSelected, onTap: onDaily),
        SizedBox(width: 28),
        _TabLabel(
          label: 'Vault',
          selected: vaultSelected,
          onTap: onVault,
          trailing: Icon(
            Icons.lock_outline_rounded,
            size: 13,
            color: vaultSelected
                ? AppColors.violet
                : AppColors.textTertiaryDark,
          ),
        ),
      ],
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: SettingsType.body(
                    selected ? Colors.white : AppColors.textTertiaryDark,
                  ).copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                if (trailing != null) ...[
                  SizedBox(width: 5),
                  trailing!,
                ],
              ],
            ),
            SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: selected ? 28 : 0,
              decoration: BoxDecoration(
                color: AppColors.violet,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VaultCover extends StatelessWidget {
  const _VaultCover({
    required this.memory,
    required this.onTap,
    this.canDelete = false,
    this.onDelete,
  });

  final MemorySummary memory;
  final VoidCallback onTap;
  final bool canDelete;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppRadius.xxlAll,
        child: Stack(
          children: [
            MemoryCoverHero(
              memoryId: memory.id,
              imageUrl: memory.coverImageUrl,
              aspectRatio: 4 / 5,
            ),
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Color(0xD9000000),
                      ],
                      stops: [0, 0.52, 1],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memory.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    [
                      memory.monthYearLabel,
                      '${memory.momentCount} ${memory.momentCount == 1 ? 'photo' : 'photos'}',
                    ].join('   ·   '),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (canDelete)
              Positioned(
                top: 12,
                right: 12,
                child: MemoryDeleteIconButton(
                  compact: true,
                  onPressed: onDelete,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MemoriesShimmer extends StatelessWidget {
  const _MemoriesShimmer();

  @override
  Widget build(BuildContext context) {
    return const MomentShimmer(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MomentShimmerBone(width: 88, height: 10, radius: 6),
            SizedBox(height: AppSpacing.md),
            MomentShimmerBone(width: 140, height: 32, radius: 10),
            SizedBox(height: AppSpacing.xxxl),
            MomentShimmerBone(height: 420, radius: 22),
          ],
        ),
      ),
    );
  }
}
