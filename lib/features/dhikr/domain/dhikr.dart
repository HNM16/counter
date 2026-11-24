import 'package:flutter/foundation.dart';

@immutable
class Dhikr {
  const Dhikr({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.createdAt,
    this.suggestedCount,
    this.reference,
    this.isCustom = false,
    this.isFavorite = false,
    this.sortOrder = 0,
  });

  final String id;
  final String arabic;
  final String transliteration;
  final String translation;

  /// Optional repetition target. Built-in values are only set where a
  /// well-known narration mentions a number (see [reference]).
  final int? suggestedCount;

  /// Source note shown to the user. Never shown as a ruling.
  final String? reference;
  final bool isCustom;
  final bool isFavorite;
  final int sortOrder;
  final DateTime createdAt;

  Dhikr copyWith({
    String? arabic,
    String? transliteration,
    String? translation,
    int? suggestedCount,
    bool clearSuggestedCount = false,
    bool? isFavorite,
    int? sortOrder,
  }) {
    return Dhikr(
      id: id,
      arabic: arabic ?? this.arabic,
      transliteration: transliteration ?? this.transliteration,
      translation: translation ?? this.translation,
      suggestedCount: clearSuggestedCount ? null : (suggestedCount ?? this.suggestedCount),
      reference: reference,
      isCustom: isCustom,
      isFavorite: isFavorite ?? this.isFavorite,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Dhikr &&
      other.id == id &&
      other.arabic == arabic &&
      other.transliteration == transliteration &&
      other.translation == translation &&
      other.suggestedCount == suggestedCount &&
      other.reference == reference &&
      other.isCustom == isCustom &&
      other.isFavorite == isFavorite &&
      other.sortOrder == sortOrder;

  @override
  int get hashCode =>
      Object.hash(id, arabic, transliteration, translation, suggestedCount, reference, isCustom, isFavorite, sortOrder);
}

abstract interface class DhikrRepository {
  /// Inserts built-in entries that are missing. Existing rows (including the
  /// user's favorite flags) are left untouched.
  Future<void> ensureSeeded();

  Future<List<Dhikr>> all();

  Future<Dhikr?> byId(String id);

  Future<Dhikr> create({
    required String arabic,
    required String transliteration,
    required String translation,
    int? suggestedCount,
  });

  Future<void> update(Dhikr dhikr);

  /// Deletes a custom entry. Built-in entries cannot be deleted.
  Future<void> delete(String id);
}
