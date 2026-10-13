import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class AppSearchField extends StatefulWidget {
  const AppSearchField(
      {super.key,
      this.controller,
      this.hintText,
      this.onChanged,
      this.onSubmitted,
      this.onCancel,
      this.autofocus = false});
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
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _internal = TextEditingController();
  TextEditingController get _controller => widget.controller ?? _internal;
  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_changed);
    _controller.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _internal).removeListener(_changed);
      _controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _internal.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
        duration: AppMotion.duration(context, 160),
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color:
                    _focusNode.hasFocus ? scheme.primary : Colors.transparent,
                width: 1.5)),
        child: Row(children: [
          Padding(
              padding: const EdgeInsets.only(left: 16, right: 10),
              child: Icon(CupertinoIcons.search,
                  size: 20, color: scheme.onSurfaceVariant)),
          Expanded(
              child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(fontSize: 16, color: scheme.onSurface),
                  decoration: InputDecoration(
                      filled: false,
                      hintText: widget.hintText ?? 'Search',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      isDense: true))),
          if (_controller.text.isNotEmpty)
            IconButton(
                tooltip: AppLocalizations.of(context)!.clearSearchLabel,
                onPressed: _clear,
                icon: Icon(CupertinoIcons.clear_circled_solid,
                    size: 19, color: scheme.onSurfaceVariant)),
          const SizedBox(width: 8),
        ]));
  }
}
