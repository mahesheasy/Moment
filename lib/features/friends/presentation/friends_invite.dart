import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum FriendInviteChannel { instagram, snapchat, messages, others }

class FriendInvite {
  const FriendInvite._();

  static String message(String? username) {
    final handle = username?.trim();
    if (handle == null || handle.isEmpty) {
      return 'Add me on Moment.';
    }
    return 'Add me on Moment — search @$handle';
  }

  static Future<void> send({
    required FriendInviteChannel channel,
    String? username,
  }) async {
    final text = message(username);
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
