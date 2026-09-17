import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/core/widgets/moment_scaffold.dart';
import 'package:moment/features/settings/domain/legal_documents.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({required this.type, super.key});

  final LegalDocumentType type;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    final sections = LegalDocuments.sections(type);

    return MomentScaffold(
      appBar: MomentAppBar(
        title: LegalDocuments.title(type),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(AppIcons.back, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.sm,
          AppSpacing.xxl,
          AppSpacing.huge,
        ),
        children: [
          Text(
            'Last updated ${LegalDocuments.lastUpdated}',
            style: SettingsType.caption(mc.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final section in sections) ...[
            Text(
              section.title,
              style: SettingsType.title(mc.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final paragraph in section.body) ...[
              Text(
                paragraph,
                style: SettingsType.body(mc.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(
            'Contact: ${LegalDocuments.contactEmail}',
            style: SettingsType.body(mc.accent),
          ),
        ],
      ),
    );
  }
}
