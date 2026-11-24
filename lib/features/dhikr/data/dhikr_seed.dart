import '../domain/dhikr.dart';

/// Built-in library.
///
/// Suggested counts are only provided where a widely known narration in the
/// major hadith collections mentions a number; otherwise the field is left
/// empty and the user chooses their own target. References are given for
/// further reading and are not presented as rulings.
abstract final class DhikrSeed {
  static const subhanallah = 'subhanallah';
  static const alhamdulillah = 'alhamdulillah';
  static const allahuAkbar = 'allahu_akbar';
  static const astaghfirullah = 'astaghfirullah';
  static const tahlil = 'la_ilaha_illallah';
  static const subhanallahWaBihamdihi = 'subhanallah_wa_bihamdihi';
  static const subhanallahAlAzim = 'subhanallah_al_azim';
  static const salawat = 'salawat';

  static const defaultId = subhanallah;

  static const _afterPrayer =
      'Mentioned 33 times each - with Alhamdulillah and Allahu Akbar - after the '
      'obligatory prayers (Sahih Muslim 597).';

  static final List<Dhikr> entries = [
    Dhikr(
      id: subhanallah,
      arabic: 'سُبْحَانَ اللَّهِ',
      transliteration: 'Subhan Allah',
      translation: 'Glory be to Allah.',
      suggestedCount: 33,
      reference: _afterPrayer,
      sortOrder: 0,
      createdAt: DateTime.utc(2024),
    ),
    Dhikr(
      id: alhamdulillah,
      arabic: 'الْحَمْدُ لِلَّهِ',
      transliteration: 'Alhamdulillah',
      translation: 'All praise is due to Allah.',
      suggestedCount: 33,
      reference: _afterPrayer,
      sortOrder: 1,
      createdAt: DateTime.utc(2024),
    ),
    Dhikr(
      id: allahuAkbar,
      arabic: 'اللَّهُ أَكْبَرُ',
      transliteration: 'Allahu Akbar',
      translation: 'Allah is the Greatest.',
      suggestedCount: 33,
      reference: _afterPrayer,
      sortOrder: 2,
      createdAt: DateTime.utc(2024),
    ),
    Dhikr(
      id: astaghfirullah,
      arabic: 'أَسْتَغْفِرُ اللَّهَ',
      transliteration: 'Astaghfirullah',
      translation: 'I seek the forgiveness of Allah.',
      suggestedCount: 100,
      reference:
          'The Prophet (peace be upon him) said he sought Allah\'s forgiveness a '
          'hundred times a day (Sahih Muslim 2702).',
      sortOrder: 3,
      createdAt: DateTime.utc(2024),
    ),
    Dhikr(
      id: tahlil,
      arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ',
      transliteration: 'La ilaha illa Allah',
      translation: 'There is no god but Allah.',
      reference: 'Described as the best remembrance (Jami\' at-Tirmidhi 3383).',
      sortOrder: 4,
      createdAt: DateTime.utc(2024),
    ),
    Dhikr(
      id: subhanallahWaBihamdihi,
      arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      transliteration: 'Subhan Allahi wa bihamdihi',
      translation: 'Glory be to Allah, and praise be to Him.',
      suggestedCount: 100,
      reference:
          'Whoever says it a hundred times in a day has their sins forgiven, even '
          'if they are like the foam of the sea (Sahih al-Bukhari 6405; Sahih Muslim 2691).',
      sortOrder: 5,
      createdAt: DateTime.utc(2024),
    ),
    Dhikr(
      id: subhanallahAlAzim,
      arabic: 'سُبْحَانَ اللَّهِ الْعَظِيمِ',
      transliteration: 'Subhan Allahil-Azim',
      translation: 'Glory be to Allah, the Magnificent.',
      reference:
          'One of two phrases described as light on the tongue, heavy on the '
          'scale and beloved to the Most Merciful (Sahih al-Bukhari 6406; Sahih Muslim 2694).',
      sortOrder: 6,
      createdAt: DateTime.utc(2024),
    ),
    Dhikr(
      id: salawat,
      arabic: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ',
      transliteration: 'Allahumma salli \'ala Muhammad',
      translation: 'O Allah, send blessings upon Muhammad.',
      reference:
          'Whoever sends blessings upon the Prophet once, Allah sends blessings '
          'upon them ten times (Sahih Muslim 408).',
      sortOrder: 7,
      createdAt: DateTime.utc(2024),
    ),
  ];
}
