import 'package:equatable/equatable.dart';
import 'package:moment/features/memories/domain/entities/memory_theme.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

class MemorySummary extends Equatable {
  const MemorySummary({
    required this.id,
    required this.title,
    required this.ownerId,
    required this.momentCount,
    required this.participantCount,
    required this.dayCount,
    required this.createdAt,
    required this.memoryType,
    required this.theme,
    this.caption,
    this.coverImageUrl,
    this.startsAt,
    this.endsAt,
    this.memoryDate,
    this.circleId,
    this.promptId,
    this.coverMomentId,
    this.isOwner = false,
  });

  final String id;
  final String title;
  final String ownerId;
  final int momentCount;
  final int participantCount;
  final int dayCount;
  final DateTime createdAt;
  final MemoryType memoryType;
  final MemoryTheme theme;
  final String? caption;
  final String? coverImageUrl;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? memoryDate;
  final String? circleId;
  final String? promptId;
  final String? coverMomentId;
  final bool isOwner;

  String get monthYearLabel {
    final date = memoryDate ?? startsAt ?? createdAt;
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
    return '${months[date.toLocal().month - 1]} ${date.toLocal().year}';
  }

  String? get dateRangeLabel {
    final start = startsAt;
    final end = endsAt;
    if (start == null || end == null) return null;
    return '${_formatDate(start)} – ${_formatDate(end)}';
  }

  String? get memoryDateLabel {
    final date = memoryDate;
    if (date == null) return null;
    return _formatDate(date);
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.toLocal().month - 1]} ${date.toLocal().day}, ${date.toLocal().year}';
  }

  @override
  List<Object?> get props => [
    id,
    title,
    ownerId,
    momentCount,
    participantCount,
    dayCount,
    createdAt,
    memoryType,
    theme,
    caption,
    coverImageUrl,
    startsAt,
    endsAt,
    memoryDate,
    circleId,
    promptId,
    coverMomentId,
    isOwner,
  ];
}

class MemoryChapter extends Equatable {
  const MemoryChapter({
    required this.id,
    required this.title,
    required this.position,
    this.caption,
    this.startsAt,
    this.endsAt,
  });

  final String id;
  final String title;
  final int position;
  final String? caption;
  final DateTime? startsAt;
  final DateTime? endsAt;

  @override
  List<Object?> get props => [id, title, position, caption, startsAt, endsAt];
}

class MemoryDetail extends Equatable {
  const MemoryDetail({
    required this.summary,
    required this.items,
    required this.participants,
    required this.chapters,
    this.isOwner = false,
  });

  final MemorySummary summary;
  final List<MemoryTimelineItem> items;
  final List<UserProfile> participants;
  final List<MemoryChapter> chapters;
  final bool isOwner;

  List<MemoryTimelineItem> itemsForChapter(String? chapterId) {
    return items.where((item) => item.chapterId == chapterId).toList();
  }

  @override
  List<Object?> get props => [summary, items, participants, chapters, isOwner];
}

class MemoryTimelineItem extends Equatable {
  const MemoryTimelineItem({
    required this.moment,
    required this.position,
    this.chapterId,
  });

  final Moment moment;
  final int position;
  final String? chapterId;

  @override
  List<Object?> get props => [moment, position, chapterId];
}

class CreateMemoryFromPromptInput extends Equatable {
  const CreateMemoryFromPromptInput({
    required this.title,
    required this.circleId,
    required this.promptId,
  });

  final String title;
  final String circleId;
  final String promptId;

  @override
  List<Object?> get props => [title, circleId, promptId];
}

class CreateAdvancedMemoryInput extends Equatable {
  const CreateAdvancedMemoryInput({
    required this.title,
    required this.memoryType,
    this.caption,
    this.theme = MemoryTheme.minimal,
    this.memoryDate,
    this.circleId,
  });

  final String title;
  final MemoryType memoryType;
  final String? caption;
  final MemoryTheme theme;
  final DateTime? memoryDate;
  final String? circleId;

  @override
  List<Object?> get props => [
    title,
    memoryType,
    caption,
    theme,
    memoryDate,
    circleId,
  ];
}

class UpdateMemoryInput extends Equatable {
  const UpdateMemoryInput({
    required this.memoryId,
    required this.title,
    this.caption,
    this.theme = MemoryTheme.minimal,
    this.memoryDate,
    this.coverMomentId,
    this.coverStoragePath,
  });

  final String memoryId;
  final String title;
  final String? caption;
  final MemoryTheme theme;
  final DateTime? memoryDate;
  final String? coverMomentId;
  final String? coverStoragePath;

  @override
  List<Object?> get props => [
    memoryId,
    title,
    caption,
    theme,
    memoryDate,
    coverMomentId,
    coverStoragePath,
  ];
}

class UpsertMemoryChapterInput extends Equatable {
  const UpsertMemoryChapterInput({
    required this.memoryId,
    required this.title,
    this.chapterId,
    this.caption,
    this.position = 0,
  });

  final String memoryId;
  final String title;
  final String? chapterId;
  final String? caption;
  final int position;

  @override
  List<Object?> get props => [memoryId, title, chapterId, caption, position];
}
