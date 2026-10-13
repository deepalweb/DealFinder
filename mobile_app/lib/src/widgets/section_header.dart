import 'package:flutter/material.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader(
      {super.key,
      required this.title,
      this.subtitle,
      this.icon,
      this.onSeeAll});
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onSeeAll;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title, style: theme.textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: theme.textTheme.bodySmall)
                ],
              ])),
          if (onSeeAll != null)
            TextButton(
                onPressed: onSeeAll,
                child:
                    Text(AppLocalizations.of(context)?.viewAll ?? 'View all')),
        ]));
  }
}
