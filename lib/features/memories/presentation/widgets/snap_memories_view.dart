import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/widgets/moment_cached_image.dart';
import 'package:moment/core/widgets/moment_hero_tags.dart';
import 'package:moment/core/widgets/moment_sheet_dialog.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/auth/domain/repositories/auth_repository.dart';
import 'package:moment/features/memories/domain/entities/memory.dart';
import 'package:moment/features/memories/presentation/cubit/memory_cubit.dart';
import 'package:moment/features/memories/presentation/widgets/create_memory_sheet.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

const _snapYellow = Color(0xFFFFFC00);

enum SnapMemoriesMode { overlay, tab }

enum _SnapMemoriesTab { home, cameraRoll, vault, screenshots }

class SnapMemoriesView extends StatefulWidget {
  const SnapMemoriesView({
    super.key,
    this.mode = SnapMemoriesMode.tab,
    this.onDismiss,
  });

  final SnapMemoriesMode mode;
  final VoidCallback? onDismiss;

  @override
  State<SnapMemoriesView> createState() => _SnapMemoriesViewState();
}

class _SnapMemoriesViewState extends State<SnapMemoriesView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  _SnapMemoriesTab _tab = _SnapMemoriesTab.home;
  var _query = '';
  var _selectMode = false;
  final _selectedIds = <String>{};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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

  void _handleDismiss() {
    if (widget.mode == SnapMemoriesMode.overlay) {
      widget.onDismiss?.call();
      return;
    }
    context.go(AppRoutes.home);
  }

  List<Moment> _filteredMoments(List<Moment> moments) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return moments;
    return moments.where((moment) {
      final caption = moment.caption?.toLowerCase() ?? '';
      final sender = moment.sender.displayName.toLowerCase();
      return caption.contains(q) || sender.contains(q);
    }).toList();
  }

  List<MemorySummary> _filteredVault(List<MemorySummary> memories) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return memories;
    return memories.where((memory) {
      final title = memory.title.toLowerCase();
      final caption = memory.caption?.toLowerCase() ?? '';
      return title.contains(q) || caption.contains(q);
    }).toList();
  }

  Map<DateTime, List<Moment>> _groupByDay(List<Moment> moments) {
    final grouped = <DateTime, List<Moment>>{};
    for (final moment in moments) {
      final local = moment.createdAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      grouped.putIfAbsent(day, () => []).add(moment);
    }
    return grouped;
  }

  String _flashbackLabel(DateTime day) {
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
    return 'Flashback from ${months[day.month - 1]} ${day.day}';
  }

  Future<void> _openMoment(Moment moment) async {
    await context.push(
      AppRoutes.moment(moment.id, heroScope: MomentHeroTags.scopeMemories),
    );
    if (mounted) {
      await context.read<MemoryVaultCubit>().refreshDaily();
    }
  }

  Future<void> _showMomentMenu(Moment moment) async {
    final me = sl<AuthRepository>().currentUserId;
    final isSender = me != null && moment.sender.id == me;

    final action = await showModalBottomSheet<_MomentMenuAction>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MomentMenuTile(
                icon: Icons.bookmark_add_outlined,
                label: 'Save to Vault',
                onTap: () => Navigator.pop(sheetContext, _MomentMenuAction.save),
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
    if (action == null || !mounted) return;

    final cubit = context.read<MemoryVaultCubit>();
    switch (action) {
      case _MomentMenuAction.save:
        final saved = await cubit.saveMomentToVault(moment);
        if (!mounted) return;
        if (saved != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved to Vault')),
          );
        }
      case _MomentMenuAction.remove:
        final confirmed = await MomentDialog.confirm(
          context,
          title: 'Remove from Memories?',
          message: 'This moment will no longer appear in your feed.',
          confirmLabel: 'Remove',
        );
        if (confirmed == true && mounted) {
          await cubit.dismissRecentMoment(moment, isSender: false);
        }
      case _MomentMenuAction.delete:
        final confirmed = await MomentDialog.confirm(
          context,
          title: 'Delete moment?',
          message: 'This permanently deletes the moment for everyone.',
          confirmLabel: 'Delete',
        );
        if (confirmed == true && mounted) {
          await cubit.dismissRecentMoment(moment, isSender: true);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return ColoredBox(
      color: Colors.black,
      child: BlocBuilder<MemoryVaultCubit, MemoryVaultState>(
        builder: (context, state) {
          if (state.status == MemoryVaultStatus.loading ||
              state.status == MemoryVaultStatus.initial) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (state.status == MemoryVaultStatus.failure) {
            return MomentErrorState(
              message: state.errorMessage ?? 'Could not load memories.',
              actionLabel: 'Retry',
              onAction: () => context.read<MemoryVaultCubit>().load(),
            );
          }

          final moments = _filteredMoments(state.recentMoments);
          final vault = _filteredVault(state.memories);
          final flashbacks = _groupByDay(moments).entries.toList()
            ..sort((a, b) => b.key.compareTo(a.key));

          return Stack(
            children: [
              RefreshIndicator(
                color: _snapYellow,
                backgroundColor: const Color(0xFF1C1C1C),
                onRefresh: () => context.read<MemoryVaultCubit>().load(),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(child: SizedBox(height: top + 8)),
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildSearch()),
                    SliverToBoxAdapter(child: _buildTabs()),
                    ..._buildTabContent(
                      moments: moments,
                      vault: vault,
                      flashbacks: flashbacks,
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: 96 + bottom),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16 + bottom,
                child: _CreateFab(onTap: _createMemory),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: _handleDismiss,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          Expanded(
            child: Text(
              'Memories',
              textAlign: TextAlign.center,
              style: SettingsType.title(Colors.white).copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() {
              _selectMode = !_selectMode;
              if (!_selectMode) _selectedIds.clear();
            }),
            icon: Icon(
              _selectMode
                  ? Icons.check_circle_rounded
                  : Icons.check_circle_outline_rounded,
              color: _selectMode ? _snapYellow : Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        style: SettingsType.body(Colors.white).copyWith(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Places, dates, etc.',
          hintStyle: SettingsType.body(const Color(0xFF8E8E93)).copyWith(
            fontSize: 15,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF8E8E93),
            size: 22,
          ),
          filled: true,
          fillColor: const Color(0xFF1C1C1C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (value) => setState(() => _query = value),
      ),
    );
  }

  Widget _buildTabs() {
    const tabs = [
      (_SnapMemoriesTab.home, 'Home'),
      (_SnapMemoriesTab.cameraRoll, 'Camera Roll'),
      (_SnapMemoriesTab.vault, 'Vault'),
      (_SnapMemoriesTab.screenshots, 'Screenshots'),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final (tab, label) = tabs[index];
          final selected = _tab == tab;
          return GestureDetector(
            onTap: () => setState(() => _tab = tab),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  label,
                  style: SettingsType.body(
                    selected ? Colors.white : const Color(0xFF8E8E93),
                  ).copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 2,
                  width: selected ? 28 : 0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildTabContent({
    required List<Moment> moments,
    required List<MemorySummary> vault,
    required List<MapEntry<DateTime, List<Moment>>> flashbacks,
  }) {
    return switch (_tab) {
      _SnapMemoriesTab.home => _buildHomeTab(moments, flashbacks),
      _SnapMemoriesTab.cameraRoll => _buildMomentsGrid(moments, 'Camera Roll'),
      _SnapMemoriesTab.vault => _buildVaultGrid(vault),
      _SnapMemoriesTab.screenshots => _buildMomentsGrid(
        moments
            .where(
              (m) =>
                  (m.caption?.toLowerCase().contains('screenshot') ?? false) ||
                  m.storagePath.toLowerCase().contains('screenshot'),
            )
            .toList(),
        'Screenshots',
      ),
    };
  }

  List<Widget> _buildHomeTab(
    List<Moment> moments,
    List<MapEntry<DateTime, List<Moment>>> flashbacks,
  ) {
    return [
      if (flashbacks.isNotEmpty) ...[
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Text(
              'Flashbacks',
              style: TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: flashbacks.take(6).length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final entry = flashbacks[index];
                final cover = entry.value.first;
                return _FlashbackCard(
                  label: _flashbackLabel(entry.key),
                  imageUrl: cover.imageUrl,
                  onTap: () => _openMoment(cover),
                );
              },
            ),
          ),
        ),
      ],
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(
            'Recently Added',
            style: TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 88,
          child: moments.isEmpty
              ? const Center(
                  child: Text(
                    'No snaps yet',
                    style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: moments.take(12).length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final moment = moments[index];
                    return _SnapThumbnail(
                      imageUrl: moment.imageUrl,
                      size: 72,
                      onTap: () => _openMoment(moment),
                      onLongPress: () => _showMomentMenu(moment),
                      selected: _selectedIds.contains(moment.id),
                      selectMode: _selectMode,
                      onSelectToggle: () => setState(() {
                        if (_selectedIds.contains(moment.id)) {
                          _selectedIds.remove(moment.id);
                        } else {
                          _selectedIds.add(moment.id);
                        }
                      }),
                    );
                  },
                ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
          child: Text(
            '${moments.length} Snaps',
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      _momentsSliverGrid(moments),
    ];
  }

  List<Widget> _buildMomentsGrid(List<Moment> moments, String emptyLabel) {
    if (moments.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: MomentEmptyState(message: 'No $emptyLabel yet.'),
          ),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text(
            '${moments.length} Snaps',
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      _momentsSliverGrid(moments),
    ];
  }

  List<Widget> _buildVaultGrid(List<MemorySummary> vault) {
    if (vault.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: MomentEmptyState(
              message: 'No saved memories yet.\nTap Create to start one.',
            ),
          ),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text(
            '${vault.length} Memories',
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 0.72,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final memory = vault[index];
              return GestureDetector(
                onTap: () async {
                  await context.push(AppRoutes.memory(memory.id));
                  if (context.mounted) {
                    await context.read<MemoryVaultCubit>().load();
                  }
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (memory.coverImageUrl != null)
                      MomentCachedImage(
                        imageUrl: memory.coverImageUrl!,
                        fit: BoxFit.cover,
                      )
                    else
                      const ColoredBox(color: Color(0xFF1C1C1C)),
                    Positioned(
                      left: 6,
                      right: 6,
                      bottom: 6,
                      child: Text(
                        memory.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            childCount: vault.length,
          ),
        ),
      ),
    ];
  }

  Widget _momentsSliverGrid(List<Moment> moments) {
    if (moments.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: MomentEmptyState(
            message: 'Snaps you send and receive appear here.',
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final moment = moments[index];
            return _SnapThumbnail(
              imageUrl: moment.imageUrl,
              onTap: () => _openMoment(moment),
              onLongPress: () => _showMomentMenu(moment),
              selected: _selectedIds.contains(moment.id),
              selectMode: _selectMode,
              onSelectToggle: () => setState(() {
                if (_selectedIds.contains(moment.id)) {
                  _selectedIds.remove(moment.id);
                } else {
                  _selectedIds.add(moment.id);
                }
              }),
            );
          },
          childCount: moments.length,
        ),
      ),
    );
  }
}

class _FlashbackCard extends StatelessWidget {
  const _FlashbackCard({
    required this.label,
    required this.imageUrl,
    required this.onTap,
  });

  final String label;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF1C1C1C),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              MomentCachedImage(imageUrl: imageUrl!, fit: BoxFit.cover)
            else
              const ColoredBox(color: Color(0xFF2C2C2E)),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SnapThumbnail extends StatelessWidget {
  const _SnapThumbnail({
    required this.imageUrl,
    required this.onTap,
    required this.onLongPress,
    required this.selected,
    required this.selectMode,
    required this.onSelectToggle,
    this.size,
  });

  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool selected;
  final bool selectMode;
  final VoidCallback onSelectToggle;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final child = imageUrl != null
        ? MomentCachedImage(imageUrl: imageUrl!, fit: BoxFit.cover)
        : const ColoredBox(color: Color(0xFF1C1C1C));

    final content = Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (selectMode)
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onSelectToggle,
              child: Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: selected ? _snapYellow : Colors.white70,
                size: 20,
              ),
            ),
          ),
      ],
    );

    if (size != null) {
      return GestureDetector(
        onTap: selectMode ? onSelectToggle : onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          width: size,
          height: size,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: content,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: selectMode ? onSelectToggle : onTap,
      onLongPress: onLongPress,
      child: content,
    );
  }
}

class _CreateFab extends StatelessWidget {
  const _CreateFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _snapYellow,
      elevation: 4,
      shadowColor: Colors.black45,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Colors.black, size: 22),
              SizedBox(width: 4),
              Text(
                'Create',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
          fontSize: 14,
        ),
      ),
      onTap: onTap,
    );
  }
}
