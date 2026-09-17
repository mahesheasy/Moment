enum LegalDocumentType { terms, privacy }

class LegalSection {
  const LegalSection({required this.title, required this.body});

  final String title;
  final List<String> body;
}

/// In-app Terms of Service and Privacy Policy for Moment.
class LegalDocuments {
  const LegalDocuments._();

  static const lastUpdated = 'September 15, 2026';
  static const contactEmail = 'support@moment.app';

  static String title(LegalDocumentType type) {
    return switch (type) {
      LegalDocumentType.terms => 'Terms of Service',
      LegalDocumentType.privacy => 'Privacy Policy',
    };
  }

  static List<LegalSection> sections(LegalDocumentType type) {
    return switch (type) {
      LegalDocumentType.terms => _termsSections,
      LegalDocumentType.privacy => _privacySections,
    };
  }

  static const _termsSections = [
    LegalSection(
      title: 'Welcome to Moment',
      body: [
        'Moment is a private social app for sharing photo moments, chatting with friends, '
            'and staying close through home-screen widgets. By creating an account or using '
            'Moment, you agree to these Terms of Service.',
        'If you do not agree, please do not use the app.',
      ],
    ),
    LegalSection(
      title: 'Your account',
      body: [
        'You must be at least 13 years old to use Moment. You are responsible for keeping '
            'your login credentials secure and for activity on your account.',
        'Provide accurate profile information and choose a username that does not violate '
            'these terms or impersonate another person.',
      ],
    ),
    LegalSection(
      title: 'Moments, chat & circles',
      body: [
        'You may send photo moments to friends, participate in chats, and join circles. '
            'You retain ownership of content you create, but you grant Moment a limited '
            'license to host, display, and deliver that content to the people you choose.',
        'Do not send illegal, abusive, harassing, or sexually exploitative content. Do not '
            'use Moment to spam, scrape, or reverse engineer the service.',
      ],
    ),
    LegalSection(
      title: 'Widgets & notifications',
      body: [
        'Moment offers optional home-screen widgets and push notifications so you can see '
            'new moments from friends. Widget display is controlled by your in-app privacy '
            'settings and may show blurred previews until you open a moment.',
        'You can customize or disable widgets and notifications at any time in Settings.',
      ],
    ),
    LegalSection(
      title: 'Moment+ & subscriptions',
      body: [
        'Some features require Moment+, a paid subscription. Prices, billing periods, and '
            'included features are shown before purchase. Subscriptions renew automatically '
            'unless cancelled through your app store account settings.',
      ],
    ),
    LegalSection(
      title: 'Safety & enforcement',
      body: [
        'You can block users, report problems, and control who can reach you. We may remove '
            'content or suspend accounts that violate these terms or harm other users.',
        'We may update Moment over time. Continued use after changes means you accept the '
            'updated terms.',
      ],
    ),
    LegalSection(
      title: 'Disclaimer',
      body: [
        'Moment is provided "as is" without warranties. To the extent permitted by law, '
            'Moment is not liable for indirect or consequential damages arising from your '
            'use of the service.',
        'For questions about these terms, contact us at $contactEmail.',
      ],
    ),
  ];

  static const _privacySections = [
    LegalSection(
      title: 'Overview',
      body: [
        'Moment respects your privacy. This policy explains what we collect, how we use it, '
            'and the choices you have when you share moments with friends.',
        'Moment is built for close connections—not public broadcasting. You control who '
            'receives your moments through friends, circles, and privacy settings.',
      ],
    ),
    LegalSection(
      title: 'Information we collect',
      body: [
        'Account data: email, username, display name, profile photo, and authentication '
            'identifiers needed to sign you in.',
        'Content you create: photos (moments), captions, chat messages, reactions, circle '
            'memberships, and memories you save.',
        'Usage data: app interactions, device type, push notification tokens, and crash '
            'logs to keep Moment reliable.',
        'Widget data: your widget preferences, privacy mode, and locally cached previews '
            'so home-screen widgets can update when the app is closed.',
      ],
    ),
    LegalSection(
      title: 'How we use information',
      body: [
        'We use your data to operate Moment: deliver moments to friends, sync chats in '
            'real time, show notifications, render widgets, and personalize your experience.',
        'We use presence signals (such as last seen) so friends can see when you are online '
            'in chat. You can limit notifications and widget exposure in Settings.',
        'We do not sell your personal information.',
      ],
    ),
    LegalSection(
      title: 'Sharing with others',
      body: [
        'Moments and messages are shared only with the friends or circles you select. '
            'Other users see your profile name, photo, and content you send them.',
        'We use infrastructure providers (such as cloud hosting and push delivery) to run '
            'the service. They process data on our behalf under contractual safeguards.',
        'We may disclose information if required by law or to protect users and the platform.',
      ],
    ),
    LegalSection(
      title: 'Photos, camera & storage',
      body: [
        'Moment needs camera and photo library access when you capture or send moments. '
            'Media is uploaded securely and stored so recipients can view it.',
        'You can delete moments and memories in the app. Deleting your account removes your '
            'profile and associated data subject to reasonable backup retention periods.',
      ],
    ),
    LegalSection(
      title: 'Your choices',
      body: [
        'Update profile and notification settings in the app.',
        'Control widget privacy per sender or globally from Widget settings.',
        'Block users, report content, and sign out or delete your account from Settings.',
        'Disable push notifications or remove the home-screen widget from your device.',
      ],
    ),
    LegalSection(
      title: 'Children',
      body: [
        'Moment is not intended for children under 13. If you believe a child has provided '
            'personal information, contact us at $contactEmail and we will take appropriate '
            'steps to remove it.',
      ],
    ),
    LegalSection(
      title: 'Changes & contact',
      body: [
        'We may update this Privacy Policy from time to time. We will post the revised '
            'version in the app with an updated effective date.',
        'Questions or requests about privacy can be sent to $contactEmail.',
      ],
    ),
  ];
}
