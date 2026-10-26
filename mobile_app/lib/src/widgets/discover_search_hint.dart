import 'dart:async';
import 'package:flutter/material.dart';

/// Examples explain search scope, without suggesting that inventory is guaranteed.
class DiscoverSearchHint extends StatefulWidget {
  const DiscoverSearchHint(
      {super.key,
      required this.suggestions,
      required this.searchLabel,
      this.fontSize = 14,
      this.maxLines = 2});
  final List<String> suggestions;
  final String searchLabel;
  final double fontSize;
  final int maxLines;

  @override
  State<DiscoverSearchHint> createState() => _DiscoverSearchHintState();
}

class _DiscoverSearchHintState extends State<DiscoverSearchHint> {
  Timer? _timer;
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    final media = MediaQuery.of(context);
    if (media.disableAnimations || media.accessibleNavigation) {
      _index = 0;
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted ||
          !TickerMode.valuesOf(context).enabled ||
          ModalRoute.of(context)?.isCurrent == false ||
          widget.suggestions.length < 2) {
        return;
      }
      setState(() => _index = (_index + 1) % widget.suggestions.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hint = widget.suggestions.isEmpty
        ? widget.searchLabel
        : widget.suggestions[_index % widget.suggestions.length];
    return Semantics(
        label: widget.searchLabel,
        child: ExcludeSemantics(
            child: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.centerLeft,
              children: [...previous, if (current != null) current]),
          child: Text(hint,
              key: ValueKey(hint),
              maxLines: widget.maxLines,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: widget.fontSize,
                  height: 1.3,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        )));
  }
}
