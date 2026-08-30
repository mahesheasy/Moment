import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/errors/postgrest_mapper.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/profile/data/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';

class MomentsRemoteDataSource {
  MomentsRemoteDataSource(this._client);

  final SupabaseClient _client;
  static const _bucket = 'moments';

  Future<Moment?> getLatestReceivedMoment(String userId) async {
    final data = await _client
        .from('moment_recipients')
        .select(
          'seen_at, delivery_status, moment:moments(*, sender:sender_id(*))',
        )
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return _mapMomentRow(Map<String, dynamic>.from(data));
  }

  Future<List<DateTime>> listActivityTimestamps(
    String userId, {
    int lookbackDays = 60,
  }) async {
    final since = DateTime.now()
        .subtract(Duration(days: lookbackDays))
        .toUtc()
        .toIso8601String();

    final sent = await _client
        .from('moments')
        .select('created_at')
        .eq('sender_id', userId)
        .gte('created_at', since);
    final received = await _client
        .from('moment_recipients')
        .select('created_at')
        .eq('recipient_id', userId)
        .gte('created_at', since);

    final days = <DateTime>{};
    for (final row in [...sent as List, ...received as List]) {
      final map = Map<String, dynamic>.from(row as Map);
      final createdAt = DateTime.parse(map['created_at'] as String).toUtc();
      days.add(DateTime(createdAt.year, createdAt.month, createdAt.day));
    }
    return days.toList();
  }

  Future<Moment?> getLatestReceivedMomentFromSender({
    required String userId,
    required String senderId,
  }) async {
    final data = await _client
        .from('moment_recipients')
        .select(
          'seen_at, delivery_status, moment:moments!inner(*, sender:sender_id(*))',
        )
        .eq('recipient_id', userId)
        .eq('moment.sender_id', senderId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return _mapMomentRow(Map<String, dynamic>.from(data));
  }

  Future<Moment?> getLatestReceivedMomentFromCircle({
    required String userId,
    required String circleId,
  }) async {
    final members = await _client
        .from('circle_members')
        .select('user_id')
        .eq('circle_id', circleId);

    final senderIds = (members as List)
        .map((row) => (row as Map)['user_id'] as String)
        .where((id) => id != userId)
        .toList();

    if (senderIds.isEmpty) return null;

    final data = await _client
        .from('moment_recipients')
        .select(
          'seen_at, delivery_status, moment:moments!inner(*, sender:sender_id(*))',
        )
        .eq('recipient_id', userId)
        .inFilter('moment.sender_id', senderIds)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return _mapMomentRow(Map<String, dynamic>.from(data));
  }

  Future<List<String>> listCircleMemberIds(String circleId) async {
    final members = await _client
        .from('circle_members')
        .select('user_id')
        .eq('circle_id', circleId);
    return (members as List)
        .map((row) => (row as Map)['user_id'] as String)
        .toList();
  }

  Future<Moment> getMoment(String momentId, String userId) async {
    final data = await _client
        .from('moments')
        .select('*, sender:sender_id(*)')
        .eq('id', momentId)
        .single();

    final recipient = await _client
        .from('moment_recipients')
        .select('seen_at, delivery_status')
        .eq('moment_id', momentId)
        .eq('recipient_id', userId)
        .maybeSingle();

    return _mapMomentFromJson(
      Map<String, dynamic>.from(data),
      seenAt: recipient?['seen_at'] as String?,
      deliveryStatus: recipient?['delivery_status'] as String?,
    );
  }

  Future<List<Moment>> listMomentsSharedToCircle({
    required String circleId,
  }) async {
    final memberIds = await listCircleMemberIds(circleId);
    if (memberIds.isEmpty) return [];

    final memberSet = memberIds.toSet();
    final byId = <String, Moment>{};

    final promptData = await _client
        .from('prompt_responses')
        .select('moment:moment_id(*, sender:sender_id(*))')
        .eq('circle_id', circleId)
        .order('created_at', ascending: false);

    for (final row in promptData as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final momentJson = map['moment'] as Map?;
      if (momentJson == null) continue;
      final moment = await _mapMomentFromJson(
        Map<String, dynamic>.from(momentJson),
      );
      byId[moment.id] = moment;
    }

    final broadcastData = await _client
        .from('moments')
        .select(
          '*, sender:sender_id(*), recipients:moment_recipients(recipient_id)',
        )
        .inFilter('sender_id', memberIds)
        .order('created_at', ascending: false)
        .limit(40);

    for (final row in broadcastData as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final senderId = map['sender_id'] as String;
      final recipients = (map['recipients'] as List?)
              ?.map((entry) => (entry as Map)['recipient_id'] as String)
              .toSet() ??
          {};
      final expectedRecipients =
          memberSet.where((id) => id != senderId).toSet();
      if (expectedRecipients.isEmpty ||
          !expectedRecipients.every(recipients.contains)) {
        continue;
      }

      final momentJson = Map<String, dynamic>.from(map)..remove('recipients');
      final moment = await _mapMomentFromJson(momentJson);
      byId[moment.id] = moment;
    }

    final moments = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return moments;
  }

  Future<List<Moment>> listReceivedMoments({
    required String userId,
    int limit = 20,
    int offset = 0,
    MomentSeenFilter seenFilter = MomentSeenFilter.all,
  }) async {
    var query = _client
        .from('moment_recipients')
        .select(
          'seen_at, delivery_status, moment:moments(*, sender:sender_id(*))',
        )
        .eq('recipient_id', userId);

    query = switch (seenFilter) {
      MomentSeenFilter.unseen => query.isFilter('seen_at', null),
      MomentSeenFilter.seen => query.not('seen_at', 'is', null),
      MomentSeenFilter.all => query,
    };

    final data = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final rows = data as List;
    final moments = await Future.wait(
      rows.map((row) => _mapMomentRow(Map<String, dynamic>.from(row as Map))),
    );
    moments.sort((a, b) {
      final byTime = b.createdAt.compareTo(a.createdAt);
      if (byTime != 0) return byTime;
      return b.id.compareTo(a.id);
    });
    return moments;
  }

  Future<List<Moment>> listSentMoments({
    required String userId,
    int limit = 40,
    int offset = 0,
  }) async {
    final data = await _client
        .from('moments')
        .select('*, sender:sender_id(*)')
        .eq('sender_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final rows = data as List;
    return Future.wait(
      rows.map(
        (row) => _mapMomentFromJson(Map<String, dynamic>.from(row as Map)),
      ),
    );
  }

  Future<Moment> createMoment({
    required String senderId,
    required Uint8List imageBytes,
    required String mimeType,
    required List<String> recipientIds,
    String? caption,
    String? idempotencyKey,
  }) async {
    if (recipientIds.isEmpty) {
      throw const ValidationFailure(
        message: 'Choose yourself or at least one friend.',
      );
    }

    final momentId = const Uuid().v4();
    final extension = switch (mimeType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    final storagePath = '$senderId/$momentId.$extension';

    await _client.storage
        .from(_bucket)
        .uploadBinary(
          storagePath,
          imageBytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );

    try {
      final inserted = await _client
          .from('moments')
          .insert({
            'id': momentId,
            'sender_id': senderId,
            'storage_path': storagePath,
            'caption': caption?.trim().isEmpty == true ? null : caption?.trim(),
            'idempotency_key': idempotencyKey,
          })
          .select('*, sender:sender_id(*)')
          .single();

      await _client
          .from('moment_recipients')
          .insert(
            recipientIds
                .map(
                  (recipientId) => {
                    'moment_id': momentId,
                    'recipient_id': recipientId,
                    'delivery_status': 'delivered',
                    'delivered_at': DateTime.now().toUtc().toIso8601String(),
                  },
                )
                .toList(),
          );

      return _mapMomentFromJson(Map<String, dynamic>.from(inserted));
    } on Object {
      await _client.storage.from(_bucket).remove([storagePath]);
      rethrow;
    }
  }

  Future<void> markSeen({
    required String momentId,
    required String userId,
  }) async {
    await _client
        .from('moment_recipients')
        .update({'seen_at': DateTime.now().toUtc().toIso8601String()})
        .eq('moment_id', momentId)
        .eq('recipient_id', userId);
  }

  Future<void> removeFromFeed({
    required String momentId,
    required String userId,
  }) async {
    await _client
        .from('moment_recipients')
        .delete()
        .eq('moment_id', momentId)
        .eq('recipient_id', userId);
  }

  Future<void> deleteSentMoment({
    required String momentId,
    required String senderId,
  }) async {
    final data = await _client
        .from('moments')
        .select('storage_path')
        .eq('id', momentId)
        .eq('sender_id', senderId)
        .maybeSingle();

    if (data == null) {
      throw const ValidationFailure(message: 'Moment not found.');
    }

    await _client.from('moments').delete().eq('id', momentId);

    final storagePath = data['storage_path'] as String?;
    if (storagePath != null && storagePath.isNotEmpty) {
      await _client.storage.from(_bucket).remove([storagePath]);
    }
  }

  Future<String> signedUrl(String storagePath) async {
    return _client.storage.from(_bucket).createSignedUrl(storagePath, 3600);
  }

  Failure mapError(Object error) {
    if (error is PostgrestException) {
      if (error.code == '23505') {
        return const ValidationFailure(
          message: 'This moment was already sent.',
        );
      }
      return mapPostgrestError(
        error,
        fallback: 'Could not send moment. Please try again.',
      );
    }
    if (error is StorageException) {
      return StorageFailure(cause: error);
    }
    if (error is Failure) return error;
    return UnknownFailure(cause: error);
  }

  Future<Moment> _mapMomentRow(Map<String, dynamic> row) async {
    final momentJson = Map<String, dynamic>.from(row['moment'] as Map);
    return _mapMomentFromJson(
      momentJson,
      seenAt: row['seen_at'] as String?,
      deliveryStatus: row['delivery_status'] as String?,
    );
  }

  Future<Moment> _mapMomentFromJson(
    Map<String, dynamic> json, {
    String? seenAt,
    String? deliveryStatus,
  }) async {
    final storagePath = json['storage_path'] as String;
    final imageUrl = await signedUrl(storagePath);
    final sender = ProfileModel.fromJson(
      Map<String, dynamic>.from(json['sender'] as Map),
    ).toEntity();

    return Moment(
      id: json['id'] as String,
      sender: sender,
      storagePath: storagePath,
      imageUrl: imageUrl,
      caption: json['caption'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      isSeen: seenAt != null,
      deliveryStatus: _parseDeliveryStatus(deliveryStatus),
    );
  }

  MomentDeliveryStatus _parseDeliveryStatus(String? value) {
    return switch (value) {
      'pending' => MomentDeliveryStatus.pending,
      'failed' => MomentDeliveryStatus.failed,
      _ => MomentDeliveryStatus.delivered,
    };
  }
}
