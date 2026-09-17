import 'dart:async';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/core/widget/android_widget_bridge.dart';
import 'package:moment/core/widget/home_widget_sync_service.dart';
import 'package:moment/features/circles/domain/entities/circle.dart';
import 'package:moment/features/circles/domain/repositories/circle_repository.dart';
import 'package:moment/features/friends/domain/entities/friend_entities.dart';
import 'package:moment/features/friends/domain/repositories/friends_repository.dart';
import 'package:moment/features/moments/data/moment_context_service.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/moments/domain/entities/reaction.dart';
import 'package:moment/features/moments/domain/repositories/moment_repository.dart';
import 'package:moment/features/moments/domain/repositories/social_repository.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';
import 'package:moment/features/prompts/domain/entities/camera_prompt_context.dart';
import 'package:moment/features/prompts/domain/entities/daily_prompt.dart';
import 'package:moment/features/prompts/domain/repositories/prompt_repository.dart';
import 'package:moment/features/widget_preferences/domain/entities/widget_preferences.dart';
import 'package:moment/features/widget_preferences/domain/repositories/widget_preferences_repository.dart';
import 'package:uuid/uuid.dart';

enum HomeStatus { initial, loading, loaded, empty, failure }

class CircleHomeMoment extends Equatable {
  const CircleHomeMoment({
    required this.circle,
    this.moment,
    this.members = const [],
  });

  final Circle circle;
  final Moment? moment;
  final List<UserProfile> members;

  @override
  List<Object?> get props => [circle, moment, members];
}

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.moment,
    this.reactions,
    this.storyMoments = const [],
    this.storyIndex = 0,
    this.circleFeed = const [],
    this.errorMessage,
    this.actionMessage,
  });

  final HomeStatus status;
  final Moment? moment;
  final MomentReactionSummary? reactions;
  final List<Moment> storyMoments;
  final int storyIndex;
  final List<CircleHomeMoment> circleFeed;
  final String? errorMessage;
  final String? actionMessage;

  HomeState copyWith({
    HomeStatus? status,
    Moment? moment,
    MomentReactionSummary? reactions,
    List<Moment>? storyMoments,
    int? storyIndex,
    List<CircleHomeMoment>? circleFeed,
    String? errorMessage,
    String? actionMessage,
    bool clearMessages = false,
    bool clearReactions = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      moment: moment ?? this.moment,
      reactions: clearReactions ? null : reactions ?? this.reactions,
      storyMoments: storyMoments ?? this.storyMoments,
      storyIndex: storyIndex ?? this.storyIndex,
      circleFeed: circleFeed ?? this.circleFeed,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      actionMessage: clearMessages ? null : actionMessage ?? this.actionMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    moment,
    reactions,
    storyMoments,
    storyIndex,
    circleFeed,
    errorMessage,
    actionMessage,
  ];
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(
    this._moments,
    this._widgetBridge,
    this._social,
    this._widgetPreferences,
    this._widgetSync,
    this._circles,
  ) : super(const HomeState());

  final MomentRepository _moments;
  final AndroidWidgetBridge _widgetBridge;
  final SocialRepository _social;
  final WidgetPreferencesRepository _widgetPreferences;
  final HomeWidgetSyncService _widgetSync;
  final CircleRepository _circles;

  Future<void> load() async {
    emit(state.copyWith(status: HomeStatus.loading, clearMessages: true));

    final prefsResult = await _widgetPreferences.getPreferences();
    final preferences = switch (prefsResult) {
      Success(:final value) => value.preferences,
      Failed() => WidgetPreferences.defaults(),
    };
    await _widgetBridge.syncPreferences(preferences);

    final widgetResult = await _moments.getWidgetMoment(preferences);
    final unseenResult = await _moments.listReceivedMoments(
      limit: 40,
      seenFilter: MomentSeenFilter.unseen,
    );
    final unseen = switch (unseenResult) {
      Success(:final value) => value,
      Failed() => const <Moment>[],
    };
    final circleFeed = await _loadCircleFeed(unseen);

    switch (widgetResult) {
      case Success():
        if (unseen.isEmpty) {
          emit(HomeState(status: HomeStatus.empty, circleFeed: circleFeed));
        } else {
          final featured = unseen.first;
          final reactions = await _loadReactions(featured.id);
          emit(
            HomeState(
              status: HomeStatus.loaded,
              moment: featured,
              reactions: reactions,
              storyMoments: unseen,
              storyIndex: 0,
              circleFeed: circleFeed,
            ),
          );
        }
        await _widgetSync.sync(promoteLatest: true);
      case Failed(:final failure):
        emit(
          HomeState(status: HomeStatus.failure, errorMessage: failure.message),
        );
    }
  }

  Future<List<CircleHomeMoment>> _loadCircleFeed(List<Moment> moments) async {
    final circlesResult = await _circles.getMyCircles();
    final circles = switch (circlesResult) {
      Success(:final value) => value,
      Failed() => const <Circle>[],
    };

    return Future.wait(
      circles.map((circle) async {
        final membersResult = await _circles.getCircleMembers(circle.id);
        final members = switch (membersResult) {
          Success(:final value) =>
            value.map((member) => member.profile).toList(),
          Failed() => const <UserProfile>[],
        };
        final memberIds = members.map((profile) => profile.id).toSet();

        Moment? latest;
        for (final moment in moments) {
          if (memberIds.contains(moment.sender.id)) {
            latest = moment;
            break;
          }
        }
        return CircleHomeMoment(
          circle: circle,
          moment: latest,
          members: members.take(2).toList(),
        );
      }),
    );
  }

  Future<void> nextStory() {
    final current = state.moment;
    if (current == null) return Future.value();
    return markViewed(current.id);
  }

  Future<void> previousStory() {
    return _showAt(state.storyIndex - 1);
  }

  Future<void> markViewed(String momentId) async {
    await _widgetSync.onMomentViewed(momentId);
    unawaited(_moments.markSeen(momentId));
    if (isClosed) return;

    final remaining = state.storyMoments
        .where((moment) => moment.id != momentId)
        .toList();
    if (remaining.isEmpty) {
      emit(HomeState(status: HomeStatus.empty, circleFeed: state.circleFeed));
      return;
    }

    final index = state.storyIndex.clamp(0, remaining.length - 1);
    await _showInbox(remaining, index);
  }

  Future<void> _showAt(int index) async {
    final stories = state.storyMoments;
    if (stories.isEmpty || index < 0 || index >= stories.length) return;
    await _showInbox(stories, index);
  }

  Future<void> _showInbox(List<Moment> stories, int index) async {
    final moment = stories[index];
    emit(
      state.copyWith(
        status: HomeStatus.loaded,
        storyMoments: stories,
        storyIndex: index,
        moment: moment,
        clearReactions: true,
        clearMessages: true,
      ),
    );
    final reactions = await _loadReactions(moment.id);
    if (isClosed || state.moment?.id != moment.id) return;
    emit(state.copyWith(reactions: reactions));
  }

  Future<void> react(ReactionType type) async {
    final moment = state.moment;
    if (moment == null) return;

    final result = await _social.react(momentId: moment.id, reaction: type);
    switch (result) {
      case Success():
        final reactions = await _loadReactions(moment.id);
        emit(state.copyWith(reactions: reactions));
      case Failed(:final failure):
        emit(state.copyWith(errorMessage: failure.message));
    }
  }

  Future<void> pingSender() async {
    final moment = state.moment;
    if (moment == null) return;
    await pingMoment(moment);
  }

  Future<void> pingMoment(Moment moment) async {
    final result = await _social.sendPing(
      recipientId: moment.sender.id,
      momentId: moment.id,
      emoji: '👋',
    );
    switch (result) {
      case Success():
        emit(
          state.copyWith(
            actionMessage: 'Ping sent to ${moment.sender.displayName}.',
          ),
        );
      case Failed(:final failure):
        emit(state.copyWith(errorMessage: failure.message));
    }
  }

  Future<void> reactOnMoment(
    String momentId, {
    ReactionType type = ReactionType.heart,
  }) async {
    final result = await _social.react(momentId: momentId, reaction: type);
    switch (result) {
      case Success():
        if (state.moment?.id == momentId) {
          final reactions = await _loadReactions(momentId);
          emit(state.copyWith(reactions: reactions));
        } else {
          emit(state.copyWith(actionMessage: 'Reacted'));
        }
      case Failed(:final failure):
        emit(state.copyWith(errorMessage: failure.message));
    }
  }

  Future<MomentReactionSummary?> _loadReactions(String momentId) async {
    final result = await _social.getReactionSummary(momentId);
    return switch (result) {
      Success(:final value) => value,
      Failed() => null,
    };
  }
}

enum CameraStatus { initial, picking, preview, uploading, success, failure }

class CameraState extends Equatable {
  const CameraState({
    this.status = CameraStatus.initial,
    this.imageBytes,
    this.mimeType,
    this.friends = const [],
    this.circles = const [],
    this.currentUserId,
    this.selectedRecipientIds = const {},
    this.selectedCircleIds = const {},
    this.caption = '',
    this.searchQuery = '',
    this.uploadProgress = 0,
    this.isLoadingRecipients = true,
    this.useFrontCamera = false,
    this.flashEnabled = false,
    this.errorMessage,
    this.idempotencyKey,
    this.promptText,
    this.promptId,
    this.promptCircleId,
    this.sentMomentId,
    this.reviewRating = 0,
    this.reviewText = '',
    this.decorations = const {},
    this.locationLabel,
    this.weatherLabel,
    this.timeLabel,
    this.includeLocation = false,
    this.includeWeather = false,
    this.includeTime = false,
    this.includeStreak = false,
    this.streakCount = 0,
    this.isLoadingContext = false,
  });

  final CameraStatus status;
  final Uint8List? imageBytes;
  final String? mimeType;
  final List<FriendSummary> friends;
  final List<Circle> circles;
  final String? currentUserId;
  final Set<String> selectedRecipientIds;
  final Set<String> selectedCircleIds;
  final String caption;
  final String searchQuery;
  final double uploadProgress;
  final bool isLoadingRecipients;
  final bool useFrontCamera;
  final bool flashEnabled;
  final String? errorMessage;
  final String? idempotencyKey;
  final String? promptText;
  final String? promptId;
  final String? promptCircleId;
  final String? sentMomentId;
  final int reviewRating;
  final String reviewText;
  final Set<String> decorations;
  final String? locationLabel;
  final String? weatherLabel;
  final String? timeLabel;
  final bool includeLocation;
  final bool includeWeather;
  final bool includeTime;
  final bool includeStreak;
  final int streakCount;
  final bool isLoadingContext;

  bool get isAllSelected {
    if (friends.isEmpty && circles.isEmpty) return false;
    final friendIds = friends.map((f) => f.profile.id).toSet();
    final circleIds = circles.map((c) => c.id).toSet();
    return selectedRecipientIds.containsAll(friendIds) &&
        selectedCircleIds.containsAll(circleIds) &&
        selectedRecipientIds.length == friendIds.length &&
        selectedCircleIds.length == circleIds.length;
  }

  bool get isPromptMode =>
      promptId != null && promptCircleId != null && promptId!.isNotEmpty;

  bool get isCircleMode => promptCircleId != null;

  bool get hasSelection =>
      selectedRecipientIds.isNotEmpty || selectedCircleIds.isNotEmpty;

  List<Circle> get filteredCircles {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return circles;
    return circles
        .where((circle) => circle.name.toLowerCase().contains(query))
        .toList();
  }

  List<FriendSummary> get filteredFriends {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return friends;
    return friends
        .where(
          (friend) =>
              friend.profile.displayName.toLowerCase().contains(query) ||
              friend.profile.username.toLowerCase().contains(query),
        )
        .toList();
  }

  String get sentToLabel {
    final names = <String>[];
    for (final id in selectedCircleIds) {
      for (final circle in circles) {
        if (circle.id == id) names.add(circle.name);
      }
    }
    for (final id in selectedRecipientIds) {
      if (id == currentUserId) {
        names.add('you');
        continue;
      }
      for (final friend in friends) {
        if (friend.profile.id == id) names.add(friend.profile.displayName);
      }
    }
    if (names.isEmpty) return 'Your moment is on its way.';
    if (names.length == 1) return 'Sent to ${names.first}';
    if (names.length == 2) return 'Sent to ${names[0]} and ${names[1]}';
    return 'Sent to ${names.first} and ${names.length - 1} others';
  }

  CameraState copyWith({
    CameraStatus? status,
    Uint8List? imageBytes,
    String? mimeType,
    List<FriendSummary>? friends,
    List<Circle>? circles,
    String? currentUserId,
    Set<String>? selectedRecipientIds,
    Set<String>? selectedCircleIds,
    String? caption,
    String? searchQuery,
    double? uploadProgress,
    bool? isLoadingRecipients,
    bool? useFrontCamera,
    bool? flashEnabled,
    String? errorMessage,
    String? idempotencyKey,
    String? promptText,
    String? promptId,
    String? promptCircleId,
    String? sentMomentId,
    int? reviewRating,
    String? reviewText,
    Set<String>? decorations,
    String? locationLabel,
    String? weatherLabel,
    String? timeLabel,
    bool? includeLocation,
    bool? includeWeather,
    bool? includeTime,
    bool? includeStreak,
    int? streakCount,
    bool? isLoadingContext,
  }) {
    return CameraState(
      status: status ?? this.status,
      imageBytes: imageBytes ?? this.imageBytes,
      mimeType: mimeType ?? this.mimeType,
      friends: friends ?? this.friends,
      circles: circles ?? this.circles,
      currentUserId: currentUserId ?? this.currentUserId,
      selectedRecipientIds: selectedRecipientIds ?? this.selectedRecipientIds,
      selectedCircleIds: selectedCircleIds ?? this.selectedCircleIds,
      caption: caption ?? this.caption,
      searchQuery: searchQuery ?? this.searchQuery,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isLoadingRecipients: isLoadingRecipients ?? this.isLoadingRecipients,
      useFrontCamera: useFrontCamera ?? this.useFrontCamera,
      flashEnabled: flashEnabled ?? this.flashEnabled,
      errorMessage: errorMessage,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      promptText: promptText ?? this.promptText,
      promptId: promptId ?? this.promptId,
      promptCircleId: promptCircleId ?? this.promptCircleId,
      sentMomentId: sentMomentId ?? this.sentMomentId,
      reviewRating: reviewRating ?? this.reviewRating,
      reviewText: reviewText ?? this.reviewText,
      decorations: decorations ?? this.decorations,
      locationLabel: locationLabel ?? this.locationLabel,
      weatherLabel: weatherLabel ?? this.weatherLabel,
      timeLabel: timeLabel ?? this.timeLabel,
      includeLocation: includeLocation ?? this.includeLocation,
      includeWeather: includeWeather ?? this.includeWeather,
      includeTime: includeTime ?? this.includeTime,
      includeStreak: includeStreak ?? this.includeStreak,
      streakCount: streakCount ?? this.streakCount,
      isLoadingContext: isLoadingContext ?? this.isLoadingContext,
    );
  }

  String get composedCaption {
    final parts = <String>[];
    final trimmedCaption = caption.trim();
    if (trimmedCaption.isNotEmpty) parts.add(trimmedCaption);

    final trimmedReview = reviewText.trim();
    if (reviewRating > 0 || trimmedReview.isNotEmpty) {
      final stars = reviewRating > 0 ? '${'★' * reviewRating}${'☆' * (5 - reviewRating)}' : '';
      if (trimmedReview.isNotEmpty && stars.isNotEmpty) {
        parts.add('$stars · $trimmedReview');
      } else if (trimmedReview.isNotEmpty) {
        parts.add(trimmedReview);
      } else {
        parts.add(stars);
      }
    }

    if (includeLocation && locationLabel != null && locationLabel!.isNotEmpty) {
      parts.add('📍 $locationLabel');
    }
    if (includeWeather && weatherLabel != null && weatherLabel!.isNotEmpty) {
      parts.add('🌤 $weatherLabel');
    }
    if (includeTime && timeLabel != null && timeLabel!.isNotEmpty) {
      parts.add('🕐 $timeLabel');
    }
    if (includeStreak && streakCount > 0) {
      parts.add('🔥 $streakCount');
    }

    for (final tag in decorations) {
      parts.add('#$tag');
    }

    final composed = parts.join('\n');
    if (composed.length <= 280) return composed;
    return composed.substring(0, 277).trimRight() + '...';
  }

  @override
  List<Object?> get props => [
    status,
    imageBytes,
    mimeType,
    friends,
    circles,
    currentUserId,
    selectedRecipientIds,
    selectedCircleIds,
    caption,
    searchQuery,
    uploadProgress,
    isLoadingRecipients,
    useFrontCamera,
    flashEnabled,
    errorMessage,
    idempotencyKey,
    promptText,
    promptId,
    promptCircleId,
    sentMomentId,
    reviewRating,
    reviewText,
    decorations,
    locationLabel,
    weatherLabel,
    timeLabel,
    includeLocation,
    includeWeather,
    includeTime,
    includeStreak,
    streakCount,
    isLoadingContext,
  ];
}

class CameraCubit extends Cubit<CameraState> {
  CameraCubit(
    this._moments,
    this._friends,
    this._prompts,
    this._circles,
    this._userIdProvider, {
    CameraPromptContext? promptContext,
  }) : _promptContext = promptContext,
       super(CameraState(idempotencyKey: const Uuid().v4()));

  final MomentRepository _moments;
  final FriendsRepository _friends;
  final PromptRepository _prompts;
  final CircleRepository _circles;
  final String? Function() _userIdProvider;
  final CameraPromptContext? _promptContext;
  final MomentContextService _contextService = MomentContextService();

  Future<void> initialize() async {
    final promptContext = _promptContext;
    if (promptContext != null) {
      emit(
        state.copyWith(
          promptId: promptContext.hasPrompt ? promptContext.promptId : null,
          promptCircleId: promptContext.circleId,
          promptText: promptContext.promptText,
          isLoadingRecipients: true,
        ),
      );
    } else {
      emit(state.copyWith(isLoadingRecipients: true));
    }

    final currentUserId = _userIdProvider();
    final friendsResult = await _friends.getFriends();
    final circlesResult = await _circles.getMyCircles();

    final friends = switch (friendsResult) {
      Success(:final value) => value,
      Failed() => const <FriendSummary>[],
    };
    final circles = switch (circlesResult) {
      Success(:final value) => value,
      Failed() => const <Circle>[],
    };

    var selected = <String>{};
    var selectedCircles = <String>{};
    var promptText = state.promptText;

    if (promptContext != null) {
      selectedCircles = {promptContext.circleId};
      if (promptContext.hasPrompt &&
          (promptText == null || promptText.isEmpty)) {
        final promptResult = await _prompts.getTodaysPrompt();
        switch (promptResult) {
          case Success(:final value):
            promptText = value.promptText;
          case Failed():
            break;
        }
      }

      final membersResult = await _circles.getCircleMembers(
        promptContext.circleId,
      );
      switch (membersResult) {
        case Success(:final value):
          selected = value
              .map((member) => member.profile.id)
              .where((id) => id != currentUserId)
              .toSet();
        case Failed():
          break;
      }
    } else if (friends.isEmpty && circles.isEmpty && currentUserId != null) {
      selected = {currentUserId};
    }

    final error = switch (friendsResult) {
      Failed(:final failure) => failure.message,
      Success() => switch (circlesResult) {
        Failed(:final failure) => failure.message,
        Success() => null,
      },
    };

    emit(
      state.copyWith(
        friends: friends,
        circles: circles,
        currentUserId: currentUserId,
        status: CameraStatus.initial,
        selectedRecipientIds: selected,
        selectedCircleIds: selectedCircles,
        promptText: promptText,
        isLoadingRecipients: false,
        errorMessage: error,
      ),
    );
  }

  void setPreview({required Uint8List bytes, required String mimeType}) {
    emit(
      state.copyWith(
        status: CameraStatus.preview,
        imageBytes: bytes,
        mimeType: mimeType,
      ),
    );
  }

  void setCaption(String caption) {
    emit(state.copyWith(caption: caption));
  }

  void setReviewRating(int rating) {
    emit(state.copyWith(reviewRating: rating.clamp(0, 5)));
  }

  void setReviewText(String text) {
    emit(state.copyWith(reviewText: text));
  }

  void toggleDecoration(String tag) {
    final next = Set<String>.from(state.decorations);
    if (next.contains(tag)) {
      next.remove(tag);
    } else {
      next.add(tag);
    }
    emit(state.copyWith(decorations: next));
  }

  void toggleIncludeLocation() {
    emit(state.copyWith(includeLocation: !state.includeLocation));
  }

  void toggleIncludeWeather() {
    emit(state.copyWith(includeWeather: !state.includeWeather));
  }

  void toggleIncludeTime() {
    emit(state.copyWith(includeTime: !state.includeTime));
  }

  void toggleIncludeStreak() {
    emit(state.copyWith(includeStreak: !state.includeStreak));
  }

  void selectAllRecipients() {
    final friendIds = state.friends.map((f) => f.profile.id).toSet();
    final circleIds = state.circles.map((c) => c.id).toSet();
    emit(
      state.copyWith(
        selectedRecipientIds: friendIds,
        selectedCircleIds: circleIds,
        errorMessage: null,
      ),
    );
  }

  void selectOnlyRecipient(String id) {
    emit(
      state.copyWith(
        selectedRecipientIds: {id},
        selectedCircleIds: const {},
        errorMessage: null,
      ),
    );
  }

  void selectOnlyCircle(String id) {
    emit(
      state.copyWith(
        selectedRecipientIds: const {},
        selectedCircleIds: {id},
        errorMessage: null,
      ),
    );
  }

  Future<void> loadMomentContext() async {
    emit(state.copyWith(isLoadingContext: true));
    final snapshot = await _contextService.load();
    final streakCount = switch (await _moments.getMomentStreak()) {
      Success(:final value) => value,
      Failed() => 0,
    };
    emit(
      state.copyWith(
        isLoadingContext: false,
        locationLabel: snapshot.locationLabel,
        weatherLabel: snapshot.weatherLabel,
        timeLabel: snapshot.timeLabel,
        streakCount: streakCount,
      ),
    );
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void toggleFlash() {
    emit(state.copyWith(flashEnabled: !state.flashEnabled));
  }

  void toggleCameraFacing() {
    emit(state.copyWith(useFrontCamera: !state.useFrontCamera));
  }

  Future<void> reloadRecipients() async {
    final friendsResult = await _friends.getFriends();
    final circlesResult = await _circles.getMyCircles();
    final friends = switch (friendsResult) {
      Success(:final value) => value,
      Failed() => state.friends,
    };
    final circles = switch (circlesResult) {
      Success(:final value) => value,
      Failed() => state.circles,
    };
    emit(state.copyWith(friends: friends, circles: circles));
  }

  void toggleRecipient(String id) {
    final selected = Set<String>.from(state.selectedRecipientIds);
    if (selected.contains(id)) {
      selected.remove(id);
    } else {
      selected.add(id);
    }
    emit(state.copyWith(selectedRecipientIds: selected, errorMessage: null));
  }

  void toggleCircle(String id) {
    final selected = Set<String>.from(state.selectedCircleIds);
    if (selected.contains(id)) {
      selected.remove(id);
    } else {
      selected.add(id);
    }
    emit(state.copyWith(selectedCircleIds: selected, errorMessage: null));
  }

  Future<bool> send() async {
    final bytes = state.imageBytes;
    final mimeType = state.mimeType;
    if (bytes == null || mimeType == null) return false;

    emit(state.copyWith(status: CameraStatus.uploading, uploadProgress: 0.2));
    final recipientIds = await _resolvedRecipientIds();
    if (recipientIds.isEmpty) {
      emit(
        state.copyWith(
          status: CameraStatus.preview,
          errorMessage: 'Choose a circle, a friend, or send it to yourself.',
          uploadProgress: 0,
        ),
      );
      return false;
    }

    final result = await _moments.createMoment(
      CreateMomentInput(
        imageBytes: bytes,
        mimeType: mimeType,
        recipientIds: recipientIds.toList(),
        caption: state.composedCaption.isEmpty ? null : state.composedCaption,
        idempotencyKey: state.idempotencyKey,
      ),
    );

    switch (result) {
      case Success(:final value):
        final promptId = state.promptId;
        final circleId = state.promptCircleId;
        if (promptId != null && circleId != null) {
          final responseResult = await _prompts.recordResponse(
            RecordPromptResponseInput(
              promptId: promptId,
              circleId: circleId,
              momentId: value.id,
            ),
          );
          if (responseResult case Failed(:final failure)) {
            emit(
              state.copyWith(
                status: CameraStatus.failure,
                errorMessage: failure.message,
                uploadProgress: 0,
              ),
            );
            return false;
          }
        }
        emit(
          state.copyWith(
            status: CameraStatus.success,
            uploadProgress: 1,
            sentMomentId: value.id,
          ),
        );
        return true;
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: CameraStatus.failure,
            errorMessage: failure.message,
            uploadProgress: 0,
          ),
        );
        return false;
    }
  }

  Future<Set<String>> _resolvedRecipientIds() async {
    final ids = Set<String>.from(state.selectedRecipientIds);
    for (final circleId in state.selectedCircleIds) {
      final result = await _circles.getCircleMembers(circleId);
      if (result case Success(:final value)) {
        for (final member in value) {
          if (member.profile.id != state.currentUserId) {
            ids.add(member.profile.id);
          }
        }
      }
    }
    return ids;
  }
}

enum MomentDetailStatus { initial, loading, loaded, failure }

class MomentDetailState extends Equatable {
  const MomentDetailState({
    this.status = MomentDetailStatus.initial,
    this.moment,
    this.reactions,
    this.errorMessage,
    this.actionMessage,
  });

  final MomentDetailStatus status;
  final Moment? moment;
  final MomentReactionSummary? reactions;
  final String? errorMessage;
  final String? actionMessage;

  MomentDetailState copyWith({
    MomentDetailStatus? status,
    Moment? moment,
    MomentReactionSummary? reactions,
    String? errorMessage,
    String? actionMessage,
    bool clearMessages = false,
  }) {
    return MomentDetailState(
      status: status ?? this.status,
      moment: moment ?? this.moment,
      reactions: reactions ?? this.reactions,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      actionMessage: clearMessages ? null : actionMessage ?? this.actionMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    moment,
    reactions,
    errorMessage,
    actionMessage,
  ];
}

class MomentDetailCubit extends Cubit<MomentDetailState> {
  MomentDetailCubit(
    this._moments,
    this._social,
    this._widgetSync,
    this._momentId,
  ) : super(const MomentDetailState());

  final MomentRepository _moments;
  final SocialRepository _social;
  final HomeWidgetSyncService _widgetSync;
  final String _momentId;

  Future<void> load() async {
    emit(
      state.copyWith(status: MomentDetailStatus.loading, clearMessages: true),
    );

    // User opened this moment — advance widget even if server already has seen_at.
    await _widgetSync.onMomentViewed(_momentId);

    final result = await _moments.getMoment(_momentId);
    switch (result) {
      case Success(:final value):
        final reactions = await _loadReactions(_momentId);
        emit(
          MomentDetailState(
            status: MomentDetailStatus.loaded,
            moment: value,
            reactions: reactions,
          ),
        );
        if (!value.isSeen) {
          unawaited(_moments.markSeen(_momentId));
        }
      case Failed(:final failure):
        emit(
          MomentDetailState(
            status: MomentDetailStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> react(ReactionType type) async {
    final result = await _social.react(momentId: _momentId, reaction: type);
    switch (result) {
      case Success():
        final reactions = await _loadReactions(_momentId);
        emit(state.copyWith(reactions: reactions));
      case Failed(:final failure):
        emit(state.copyWith(errorMessage: failure.message));
    }
  }

  Future<void> pingSender() async {
    final moment = state.moment;
    final senderId = moment?.sender.id;
    if (senderId == null) return;

    final result = await _social.sendPing(
      recipientId: senderId,
      momentId: _momentId,
      emoji: '👋',
    );
    switch (result) {
      case Success():
        emit(state.copyWith(actionMessage: 'Ping sent.'));
      case Failed(:final failure):
        emit(state.copyWith(errorMessage: failure.message));
    }
  }

  Future<MomentReactionSummary?> _loadReactions(String momentId) async {
    final result = await _social.getReactionSummary(momentId);
    return switch (result) {
      Success(:final value) => value,
      Failed() => null,
    };
  }
}

class MemoriesCubit extends Cubit<MemoriesState> {
  MemoriesCubit(this._moments) : super(const MemoriesState());

  final MomentRepository _moments;

  Future<void> load() async {
    emit(const MemoriesState(status: MemoriesStatus.loading));
    final result = await _moments.listReceivedMoments();
    switch (result) {
      case Success(:final value):
        emit(MemoriesState(status: MemoriesStatus.loaded, moments: value));
      case Failed(:final failure):
        emit(
          MemoriesState(
            status: MemoriesStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }
}

enum MemoriesStatus { initial, loading, loaded, failure }

class MemoriesState extends Equatable {
  const MemoriesState({
    this.status = MemoriesStatus.initial,
    this.moments = const [],
    this.errorMessage,
  });

  final MemoriesStatus status;
  final List<Moment> moments;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, moments, errorMessage];
}
