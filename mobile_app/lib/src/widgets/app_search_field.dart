import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// iOS-style search field: rounded gray fill, leading magnifier, and a
/// trailing "Cancel" button that slides in while focused (the classic
/// UISearchBar pattern), rather than Material's outlined TextField.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onCancel,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onCancel;
  final bool autofocus;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() {
        setState(() => _focused = _focusNode.hasFocus);
      });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleCancel() {
    widget.controller?.clear();
    widget.onChanged?.call('');
    _focusNode.unfocus();
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = isDark ? AppColors.cardDark : const Color(0xFFEDEDF0);
    final showCancel = _focused || (widget.controller?.text.isNotEmpty ?? false);

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.search,
                  size: 18,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    autofocus: widget.autofocus,
                    onChanged: (value) {
                      setState(() {});
                      widget.onChanged?.call(value);
                    },
                    onSubmitted: widget.onSubmitted,
                    textInputAction: TextInputAction.search,
                    style: TextStyle(
                      fontSize: AppTypeScale.body,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: widget.hintText ?? 'Search',
                      hintStyle: TextStyle(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (showCancel)
                  GestureDetector(
                    onTap: () {
                      widget.controller?.clear();
                      widget.onChanged?.call('');
                      setState(() {});
                    },
                    child: Icon(
                      CupertinoIcons.clear_circled_solid,
                      size: 18,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: showCancel
              ? Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md),
                  child: GestureDetector(
                    onTap: _handleCancel,
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: AppTypeScale.body,
                        color: AppColors.ceylonInk,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: 0),
        ),
      ],
    );
  }
}
