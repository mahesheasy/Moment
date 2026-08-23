import 'package:equatable/equatable.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';
import 'dart:typed_data';

enum MomentDeliveryStatus { pending, delivered, failed }

enum MomentSeenFilter { all, unseen, seen }

class Moment extends Equatable {
  const Moment({
    required this.id,
    required this.sender,
    required this.storagePath,
    required this.createdAt,
    this.imageUrl,
    this.caption,
    this.isSeen = false,
    this.deliveryStatus = MomentDeliveryStatus.delivered,
  });

  final String id;
  final UserProfile sender;
  final String storagePath;
  final String? imageUrl;
  final String? caption;
  final DateTime createdAt;
  final bool isSeen;
  final MomentDeliveryStatus deliveryStatus;

  @override
  List<Object?> get props => [
    id,
    sender,
    storagePath,
    imageUrl,
    caption,
    createdAt,
    isSeen,
    deliveryStatus,
  ];
}

class CreateMomentInput extends Equatable {
  const CreateMomentInput({
    required this.imageBytes,
    required this.mimeType,
    required this.recipientIds,
    this.caption,
    this.idempotencyKey,
  });

  final Uint8List imageBytes;
  final String mimeType;
  final List<String> recipientIds;
  final String? caption;
  final String? idempotencyKey;

  @override
  List<Object?> get props => [
    imageBytes,
    mimeType,
    recipientIds,
    caption,
    idempotencyKey,
  ];
}
