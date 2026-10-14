import 'package:flutter/material.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key, this.title, required this.children});
  final String? title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title != null)
        Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
            child: Semantics(
                header: true,
                child: Text(title!, style: theme.textTheme.titleMedium))),
      Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: theme.colorScheme.outlineVariant)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 64, endIndent: 16),
            children[i],
          ]
        ]),
      ),
    ]);
  }
}

class ProfileActionTile extends StatelessWidget {
  const ProfileActionTile(
      {super.key,
      required this.icon,
      required this.title,
      this.subtitle,
      this.onTap});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(11)),
          child: Icon(icon,
              size: 20, color: theme.colorScheme.onPrimaryContainer)),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing:
          onTap == null ? null : const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
