import 'package:flutter/material.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import '../models/promotion.dart';
import '../utils/bank_card_promotion_support.dart';
import '../services/favorites_manager.dart';
import '../services/app_session.dart';
import '../services/saved_offer_service.dart';
import 'sign_in_gate.dart';

class OfferSaveButton extends StatefulWidget {
  const OfferSaveButton(
      {super.key,
      required this.offer,
      this.compact = false,
      this.heart = false});
  final Promotion offer;
  final bool compact, heart;
  @override
  State<OfferSaveButton> createState() => _OfferSaveButtonState();
}

class _OfferSaveButtonState extends State<OfferSaveButton> {
  bool _saved = false;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    FavoritesManager.changes.addListener(_refresh);
    AppSession.changes.addListener(_refresh);
    _refresh();
  }

  @override
  void didUpdateWidget(OfferSaveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offer.id != widget.offer.id) _refresh();
  }

  @override
  void dispose() {
    FavoritesManager.changes.removeListener(_refresh);
    AppSession.changes.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _refresh() async {
    final id = widget.offer.id;
    final saved = await FavoritesManager.isFavorite(id);
    if (mounted && id == widget.offer.id) setState(() => _saved = saved);
  }

  Future<void> _toggle() async {
    setState(() => _busy = true);
    try {
      if (!await requireSignIn(context) || !mounted) return;
      final next = !await FavoritesManager.isFavorite(widget.offer.id);
      await SavedOfferService.setSaved(widget.offer, next);
      if (!mounted) return;
      setState(() => _saved = next);
      if (next &&
          widget.offer.merchantId == null &&
          BankCardPromotionSupport.isBankCardPromotion(widget.offer)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.savedOnDevice)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.saveOfferFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unsupported = widget.offer.merchantId == null &&
        BankCardPromotionSupport.isBankCardPromotion(widget.offer);
    final button = IconButton(
        iconSize: widget.compact ? 18 : 24,
        style: widget.compact
            ? IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant)
            : null,
        tooltip: unsupported
            ? l10n.bankOffersTab
            : _saved
                ? l10n.removeFavorite
                : l10n.saveFavorites,
        onPressed: _busy || unsupported ? null : _toggle,
        isSelected: _saved,
        selectedIcon:
            Icon(widget.heart ? Icons.favorite : Icons.bookmark_rounded),
        icon: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(widget.heart
                ? Icons.favorite_border
                : Icons.bookmark_border_rounded));
    if (widget.compact) {
      return SizedBox(
          width: 48,
          height: 48,
          child: Stack(alignment: Alignment.center, children: [
            Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        Theme.of(context).colorScheme.surfaceContainerLowest)),
            button,
          ]));
    }
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: const CircleBorder(),
      child: button,
    );
  }
}
