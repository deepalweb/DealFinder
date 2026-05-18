import '../models/category.dart';
import '../models/promotion.dart';

class BankCardPromotionSupport {
  static const String categoryId = 'bank_cards';

  static const List<String> _bankNames = [
    'commercial bank',
    'combank',
    'hnb',
    'hatton national bank',
    'sampath',
    'seylan',
    'boc',
    'bank of ceylon',
    'peoples bank',
    'peoples bank',
    'ntb',
    'nations trust',
    'dfcc',
    'pan asia',
    'union bank',
    'hsbc',
    'amex',
    'american express',
    'standard chartered',
    'scb',
    'cargills bank',
    'nsb',
  ];

  static const List<String> _categoryTerms = [
    'bank',
    'banks',
    'banking',
    'card',
    'cards',
    'credit card',
    'debit card',
    'mastercard',
    'visa',
    'cashback',
    'installment',
    'instalment',
    'emi',
    '0% interest',
    '0 interest',
  ];

  static String _corpus(Promotion promotion) {
    return [
      promotion.title,
      promotion.description,
      promotion.discount,
      promotion.code,
      promotion.category,
      promotion.merchantName,
      promotion.bankName,
      promotion.offerType,
      promotion.cardTypes.join(' '),
      promotion.termsAndConditions,
      promotion.location,
    ].whereType<String>().join(' ').toLowerCase();
  }

  static bool isBankCardPromotion(Promotion promotion) {
    final normalizedCategory = normalizeCategoryId(promotion.category);
    if (normalizedCategory == categoryId) return true;
    if ((promotion.bankName ?? '').trim().isNotEmpty) return true;
    if (promotion.cardTypes.isNotEmpty) return true;
    if ((promotion.offerType ?? '').trim().isNotEmpty) return true;

    final corpus = _corpus(promotion);
    final mentionsCard =
        corpus.contains('credit card') ||
        corpus.contains('debit card') ||
        corpus.contains(' bank card') ||
        corpus.contains(' cards') ||
        corpus.contains(' mastercard') ||
        corpus.contains(' visa ');
    final mentionsBank = _bankNames.any(corpus.contains);
    final mentionsOfferType =
        corpus.contains('cashback') ||
        corpus.contains('installment') ||
        corpus.contains('instalment') ||
        corpus.contains('emi');

    return mentionsCard || (mentionsBank && mentionsOfferType);
  }

  static String effectiveCategoryId(Promotion promotion) {
    if (isBankCardPromotion(promotion)) return categoryId;

    final normalized = normalizeCategoryId(promotion.category);
    return normalized.isEmpty ? 'other' : normalized;
  }

  static String? bankName(Promotion promotion) {
    final explicit = promotion.bankName?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final corpus = _corpus(promotion);
    for (final bank in _bankNames) {
      if (corpus.contains(bank)) {
        return bank
            .split(' ')
            .map(
              (part) => part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' ');
      }
    }
    return null;
  }

  static List<String> cardTypes(Promotion promotion) {
    if (promotion.cardTypes.isNotEmpty) {
      return promotion.cardTypes
          .map((type) => switch (type.trim().toLowerCase()) {
                'credit' => 'Credit',
                'debit' => 'Debit',
                'prepaid' => 'Prepaid',
                _ => type,
              })
          .toList();
    }
    final corpus = _corpus(promotion);
    final results = <String>[];
    if (corpus.contains('credit')) results.add('Credit');
    if (corpus.contains('debit')) results.add('Debit');
    if (results.isEmpty && isBankCardPromotion(promotion)) {
      results.add('Card Offer');
    }
    return results;
  }

  static List<String> offerTypes(Promotion promotion) {
    final explicit = promotion.offerType?.trim().toLowerCase();
    if (explicit != null && explicit.isNotEmpty) {
      return [_prettifyOfferType(explicit)];
    }
    final corpus = _corpus(promotion);
    final results = <String>[];

    if (corpus.contains('cashback')) results.add('Cashback');
    if (corpus.contains('installment') ||
        corpus.contains('instalment') ||
        corpus.contains('emi')) {
      results.add('Installment');
    }
    if (corpus.contains('dining') || corpus.contains('restaurant')) {
      results.add('Dining');
    }
    if (corpus.contains('fuel') || corpus.contains('petrol')) {
      results.add('Fuel');
    }
    if (corpus.contains('supermarket') || corpus.contains('grocery')) {
      results.add('Grocery');
    }
    if (corpus.contains('travel') || corpus.contains('hotel')) {
      results.add('Travel');
    }
    if (corpus.contains('online')) results.add('Online');
    if (corpus.contains('electronics') ||
        corpus.contains('laptop') ||
        corpus.contains('mobile')) {
      results.add('Electronics');
    }

    return results.take(2).toList();
  }

  static String? minimumSpendLabel(Promotion promotion) {
    if (promotion.minimumSpend != null && promotion.minimumSpend! > 0) {
      return 'Min spend Rs. ${promotion.minimumSpend!.toStringAsFixed(0)}';
    }
    final corpus = _corpus(promotion);
    final match = RegExp(r'(min(?:imum)? spend[^0-9]{0,12}|spend over[^0-9]{0,12}|above[^0-9]{0,12})(rs\.?|lkr)?\s*([\d,]+)', caseSensitive: false)
        .firstMatch(corpus);
    if (match == null) return null;
    final amount = match.group(3);
    if (amount == null || amount.isEmpty) return null;
    return 'Min spend Rs. $amount';
  }

  static List<String> searchTerms(Promotion promotion) {
    final terms = <String>[
      if (isBankCardPromotion(promotion)) ..._categoryTerms,
      ...cardTypes(promotion),
      ...offerTypes(promotion),
      if (bankName(promotion) != null) bankName(promotion)!,
    ];
    return terms;
  }

  static String? maximumBenefitLabel(Promotion promotion) {
    if (promotion.maximumBenefit == null || promotion.maximumBenefit! <= 0) {
      return null;
    }
    return 'Max benefit Rs. ${promotion.maximumBenefit!.toStringAsFixed(0)}';
  }

  static String _prettifyOfferType(String value) {
    switch (value) {
      case 'cashback':
        return 'Cashback';
      case 'installment':
        return 'Installment';
      case 'discount':
        return 'Discount';
      case 'dining':
        return 'Dining';
      case 'grocery':
        return 'Grocery';
      case 'fuel':
        return 'Fuel';
      case 'travel':
        return 'Travel';
      case 'electronics':
        return 'Electronics';
      case 'online':
        return 'Online';
      default:
        return value
            .split('_')
            .map((part) => part.isEmpty
                ? part
                : '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
    }
  }
}
