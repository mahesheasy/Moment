import 'package:moment/core/deep_links/moment_qr_link.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum FriendInviteChannel { instagram, snapchat, messages, others }

class FriendInvite {
  const FriendInvite._();

  static String message(String? username, [String? userId]) {
    final handle = username?.trim();
    final link = userId == null || userId.isEmpty
        ? null
        : MomentQrLink.friendProfile(userId);
    if (handle == null || handle.isEmpty) {
      if (link == null) return 'Add me on Moment.';
      return 'Add me on Moment.\n$link';
    }
    if (link == null) {
      return 'Add me on Moment — search @$handle';
    }
    return 'Add me on Moment — scan my QR or search @$handle\n$link';
  }

  static Future<void> send({
    required FriendInviteChannel channel,
    String? username,
    String? userId,
  }) async {
    final text = message(username, userId);
    switch (channel) {
      case FriendInviteChannel.instagram:
        final opened = await _tryLaunch(Uri.parse('instagram://app'));
        if (!opened) await SharePlus.instance.share(ShareParams(text: text));
      case FriendInviteChannel.snapchat:
        final opened = await _tryLaunch(Uri.parse('snapchat://'));
        if (!opened) await SharePlus.instance.share(ShareParams(text: text));
      case FriendInviteChannel.messages:
        final sms = Uri(scheme: 'sms', queryParameters: {'body': text});
        final opened = await _tryLaunch(sms);
        if (!opened) await SharePlus.instance.share(ShareParams(text: text));
      case FriendInviteChannel.others:
        await SharePlus.instance.share(ShareParams(text: text));
    }
  }

  static Future<bool> _tryLaunch(Uri uri) async {
    try {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }
}
