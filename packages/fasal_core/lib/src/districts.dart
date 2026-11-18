import 'models/localized_text.dart';

class District {
  const District(this.name, this.province, this.lat, this.lon);
  final LocalizedText name;
  final LocalizedText province;

  /// Approximate district centre, used for weather lookups.
  final double lat;
  final double lon;
}

/// Major agricultural districts. Phase 2 can load the full list from the backend.
const List<District> kDistricts = [
  // Punjab
  District(LocalizedText('Sahiwal', 'ساہیوال'), LocalizedText('Punjab', 'پنجاب'), 30.66, 73.11),
  District(LocalizedText('Faisalabad', 'فیصل آباد'), LocalizedText('Punjab', 'پنجاب'), 31.42, 73.08),
  District(LocalizedText('Multan', 'ملتان'), LocalizedText('Punjab', 'پنجاب'), 30.2, 71.47),
  District(LocalizedText('Okara', 'اوکاڑہ'), LocalizedText('Punjab', 'پنجاب'), 30.81, 73.45),
  District(LocalizedText('Bahawalpur', 'بہاولپور'), LocalizedText('Punjab', 'پنجاب'), 29.4, 71.68),
  District(LocalizedText('Bahawalnagar', 'بہاولنگر'), LocalizedText('Punjab', 'پنجاب'), 29.99, 73.25),
  District(LocalizedText('Rahim Yar Khan', 'رحیم یار خان'), LocalizedText('Punjab', 'پنجاب'), 28.42, 70.3),
  District(LocalizedText('Vehari', 'وہاڑی'), LocalizedText('Punjab', 'پنجاب'), 30.04, 72.35),
  District(LocalizedText('Khanewal', 'خانیوال'), LocalizedText('Punjab', 'پنجاب'), 30.3, 71.93),
  District(LocalizedText('Lodhran', 'لودھراں'), LocalizedText('Punjab', 'پنجاب'), 29.54, 71.63),
  District(LocalizedText('Pakpattan', 'پاکپتن'), LocalizedText('Punjab', 'پنجاب'), 30.34, 73.39),
  District(LocalizedText('Sargodha', 'سرگودھا'), LocalizedText('Punjab', 'پنجاب'), 32.08, 72.67),
  District(LocalizedText('Jhang', 'جھنگ'), LocalizedText('Punjab', 'پنجاب'), 31.27, 72.32),
  District(LocalizedText('Toba Tek Singh', 'ٹوبہ ٹیک سنگھ'), LocalizedText('Punjab', 'پنجاب'), 30.97, 72.48),
  District(LocalizedText('Gujranwala', 'گوجرانوالہ'), LocalizedText('Punjab', 'پنجاب'), 32.16, 74.19),
  District(LocalizedText('Sheikhupura', 'شیخوپورہ'), LocalizedText('Punjab', 'پنجاب'), 31.71, 73.99),
  District(LocalizedText('Sialkot', 'سیالکوٹ'), LocalizedText('Punjab', 'پنجاب'), 32.49, 74.53),
  District(LocalizedText('Kasur', 'قصور'), LocalizedText('Punjab', 'پنجاب'), 31.12, 74.45),
  District(LocalizedText('Lahore', 'لاہور'), LocalizedText('Punjab', 'پنجاب'), 31.55, 74.34),
  District(LocalizedText('Dera Ghazi Khan', 'ڈیرہ غازی خان'), LocalizedText('Punjab', 'پنجاب'), 30.05, 70.63),
  District(LocalizedText('Muzaffargarh', 'مظفر گڑھ'), LocalizedText('Punjab', 'پنجاب'), 30.07, 71.19),
  District(LocalizedText('Layyah', 'لیہ'), LocalizedText('Punjab', 'پنجاب'), 30.96, 70.94),
  // Sindh
  District(LocalizedText('Hyderabad', 'حیدرآباد'), LocalizedText('Sindh', 'سندھ'), 25.4, 68.37),
  District(LocalizedText('Sukkur', 'سکھر'), LocalizedText('Sindh', 'سندھ'), 27.71, 68.86),
  District(LocalizedText('Larkana', 'لاڑکانہ'), LocalizedText('Sindh', 'سندھ'), 27.56, 68.21),
  District(LocalizedText('Mirpur Khas', 'میرپور خاص'), LocalizedText('Sindh', 'سندھ'), 25.53, 69.01),
  District(LocalizedText('Nawabshah', 'نواب شاہ'), LocalizedText('Sindh', 'سندھ'), 26.24, 68.41),
  District(LocalizedText('Sanghar', 'سانگھڑ'), LocalizedText('Sindh', 'سندھ'), 26.05, 68.95),
  District(LocalizedText('Badin', 'بدین'), LocalizedText('Sindh', 'سندھ'), 24.66, 68.84),
  // Khyber Pakhtunkhwa
  District(LocalizedText('Peshawar', 'پشاور'), LocalizedText('Khyber Pakhtunkhwa', 'خیبر پختونخوا'), 34.01, 71.58),
  District(LocalizedText('Mardan', 'مردان'), LocalizedText('Khyber Pakhtunkhwa', 'خیبر پختونخوا'), 34.2, 72.04),
  District(LocalizedText('Charsadda', 'چارسدہ'), LocalizedText('Khyber Pakhtunkhwa', 'خیبر پختونخوا'), 34.15, 71.74),
  District(
    LocalizedText('Dera Ismail Khan', 'ڈیرہ اسماعیل خان'),
    LocalizedText('Khyber Pakhtunkhwa', 'خیبر پختونخوا'),
    31.83,
    70.9,
  ),
  // Balochistan
  District(LocalizedText('Nasirabad', 'نصیر آباد'), LocalizedText('Balochistan', 'بلوچستان'), 28.55, 68.22),
  District(LocalizedText('Jaffarabad', 'جعفر آباد'), LocalizedText('Balochistan', 'بلوچستان'), 28.37, 68.35),
];

/// Profile stores the English district name as the stable key;
/// this finds the matching entry for localised display.
District? findDistrict(String englishName) {
  for (final d in kDistricts) {
    if (d.name.en.toLowerCase() == englishName.toLowerCase()) return d;
  }
  return null;
}
