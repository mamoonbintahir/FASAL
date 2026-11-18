import '../../data/models/localized_text.dart';

class District {
  const District(this.name, this.province);
  final LocalizedText name;
  final LocalizedText province;
}

/// Major agricultural districts. Phase 2 can load the full list from the backend.
const List<District> kDistricts = [
  // Punjab
  District(LocalizedText('Sahiwal', 'ساہیوال'), LocalizedText('Punjab', 'پنجاب')),
  District(LocalizedText('Faisalabad', 'فیصل آباد'), LocalizedText('Punjab', 'پنجاب')),
  District(LocalizedText('Multan', 'ملتان'), LocalizedText('Punjab', 'پنجاب')),
  District(LocalizedText('Okara', 'اوکاڑہ'), LocalizedText('Punjab', 'پنجاب')),
  District(LocalizedText('Bahawalpur', 'بہاولپور'), LocalizedText('Punjab', 'پنجاب')),
  District(LocalizedText('Bahawalnagar', 'بہاولنگر'), LocalizedText('Punjab', 'پنجاب')),
  District(LocalizedText('Rahim Yar Khan', 'رحیم یار خان'), LocalizedText('Punjab', 'پنجاب')),
  District(LocalizedText('Vehari', 'وہاڑی'), LocalizedText('Punjab', 'پنجاب')),
  District(LocalizedText('Khanewal', 'خانیوال'), LocalizedText('Punjab', 'پنجاب')),
  District(LocalizedText('Lodhran', 'لودھراں'), LocalizedText('Punjab', 'پنجاب')),
  District(LocalizedText('Pakpattan', 'پاکپتن'), LocalizedText('Punjab', 'پنجاب')),
  District(LocalizedText('Sargodha', 'سرگودھا'), LocalizedText('Punjab', 'پنجاب')),
  District(LocalizedText('Jhang', 'جھنگ'), LocalizedText('Punjab', 'پنجاب')),
  District(LocalizedText('Toba Tek Singh', 'ٹوبہ ٹیک سنگھ'), LocalizedText('Punjab', 'پنجاب')),
  District(LocalizedText('Gujranwala', 'گوجرانوالہ'), LocalizedText('Punjab', 'پنجاب')),
  District(LocalizedText('Sheikhupura', 'شیخوپورہ'), LocalizedText('Punjab', 'پنجاب')),
  District(LocalizedText('Sialkot', 'سیالکوٹ'), LocalizedText('Punjab', 'پنجاب')),
  District(LocalizedText('Kasur', 'قصور'), LocalizedText('Punjab', 'پنجاب')),
  District(LocalizedText('Lahore', 'لاہور'), LocalizedText('Punjab', 'پنجاب')),
  District(LocalizedText('Dera Ghazi Khan', 'ڈیرہ غازی خان'), LocalizedText('Punjab', 'پنجاب')),
  District(LocalizedText('Muzaffargarh', 'مظفر گڑھ'), LocalizedText('Punjab', 'پنجاب')),
  District(LocalizedText('Layyah', 'لیہ'), LocalizedText('Punjab', 'پنجاب')),
  // Sindh
  District(LocalizedText('Hyderabad', 'حیدرآباد'), LocalizedText('Sindh', 'سندھ')),
  District(LocalizedText('Sukkur', 'سکھر'), LocalizedText('Sindh', 'سندھ')),
  District(LocalizedText('Larkana', 'لاڑکانہ'), LocalizedText('Sindh', 'سندھ')),
  District(LocalizedText('Mirpur Khas', 'میرپور خاص'), LocalizedText('Sindh', 'سندھ')),
  District(LocalizedText('Nawabshah', 'نواب شاہ'), LocalizedText('Sindh', 'سندھ')),
  District(LocalizedText('Sanghar', 'سانگھڑ'), LocalizedText('Sindh', 'سندھ')),
  District(LocalizedText('Badin', 'بدین'), LocalizedText('Sindh', 'سندھ')),
  // Khyber Pakhtunkhwa
  District(LocalizedText('Peshawar', 'پشاور'), LocalizedText('Khyber Pakhtunkhwa', 'خیبر پختونخوا')),
  District(LocalizedText('Mardan', 'مردان'), LocalizedText('Khyber Pakhtunkhwa', 'خیبر پختونخوا')),
  District(LocalizedText('Charsadda', 'چارسدہ'), LocalizedText('Khyber Pakhtunkhwa', 'خیبر پختونخوا')),
  District(LocalizedText('Dera Ismail Khan', 'ڈیرہ اسماعیل خان'), LocalizedText('Khyber Pakhtunkhwa', 'خیبر پختونخوا')),
  // Balochistan
  District(LocalizedText('Nasirabad', 'نصیر آباد'), LocalizedText('Balochistan', 'بلوچستان')),
  District(LocalizedText('Jaffarabad', 'جعفر آباد'), LocalizedText('Balochistan', 'بلوچستان')),
];

/// Profile stores the English district name as the stable key;
/// this finds the matching entry for localised display.
District? findDistrict(String englishName) {
  for (final d in kDistricts) {
    if (d.name.en.toLowerCase() == englishName.toLowerCase()) return d;
  }
  return null;
}
