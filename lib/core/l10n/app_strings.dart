import '../../data/models/app_notification.dart';
import '../../data/models/farm_record.dart';
import '../../data/models/farm_task.dart';
import '../../data/models/guidance.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/weather.dart';
import '../utils/formatters.dart';

/// All UI strings for FASAL in English and Urdu.
///
/// Each string is defined once with both translations side by side, so a
/// missing translation is impossible by construction. Widgets access these via
/// `context.s` (see `app_localizations.dart`) — never hardcode UI text.
///
/// Agricultural *content* (crop names, guidance) is NOT here: it comes from the
/// repositories as [LocalizedText] so the backend can supply it later.
class AppStrings {
  const AppStrings({required this.isUrdu});

  final bool isUrdu;

  String get languageCode => isUrdu ? 'ur' : 'en';

  String _t(String en, String ur) => isUrdu ? ur : en;

  // ───────────────────────── General ─────────────────────────
  String get appName => _t('Fasal', 'فصل');
  String get tagline => _t('Helping Farmers Know What to Do and When', 'کسان کو بتائے — کیا کرنا ہے اور کب');
  String get continueLabel => _t('Continue', 'آگے بڑھیں');
  String get save => _t('Save', 'محفوظ کریں');
  String get cancel => _t('Cancel', 'منسوخ');
  String get delete => _t('Delete', 'حذف کریں');
  String get remove => _t('Remove', 'ہٹا دیں');
  String get edit => _t('Edit', 'تبدیل کریں');
  String get done => _t('Done', 'مکمل');
  String get back => _t('Back', 'واپس');
  String get next => _t('Next', 'اگلا');
  String get skip => _t('Skip', 'چھوڑیں');
  String get getStarted => _t('Get started', 'شروع کریں');
  String get retry => _t('Try again', 'دوبارہ کوشش کریں');
  String get close => _t('Close', 'بند کریں');
  String get seeAll => _t('See all', 'سب دیکھیں');
  String get listen => _t('Listen', 'سنیں');
  String get pause => _t('Pause', 'روکیں');
  String get resume => _t('Resume', 'جاری رکھیں');
  String get stop => _t('Stop', 'بند کریں');
  String get undo => _t('Undo', 'واپس لیں');
  String get optional => _t('optional', 'اختیاری');
  String get comingSoon => _t('Coming soon', 'جلد آ رہا ہے');
  String get sampleData => _t('Sample', 'نمونہ');
  String get loading => _t('Loading…', 'لوڈ ہو رہا ہے…');
  String get search => _t('Search', 'تلاش کریں');
  String get noResults => _t('Nothing found', 'کچھ نہیں ملا');

  // ───────────────────────── Language ─────────────────────────
  String get chooseLanguage => _t('Choose your language', 'اپنی زبان منتخب کریں');
  String get english => 'English';
  String get englishSub => 'Angrezi';
  String get urdu => 'اردو';
  String get urduSub => 'Urdu';
  String get language => _t('Language', 'زبان');

  // ───────────────────────── Onboarding ─────────────────────────
  String get onb1Title => _t('Know what to do, and when', 'جانیں کیا کرنا ہے، اور کب');
  String get onb1Body => _t(
    'Fasal tells you what your crop needs today — in simple words.',
    'فصل آپ کو آسان الفاظ میں بتاتی ہے کہ آج آپ کی فصل کو کیا چاہیے۔',
  );
  String get onb2Title => _t('Guidance for your crop', 'آپ کی فصل کے لیے رہنمائی');
  String get onb2Body => _t(
    'Add wheat, rice, cotton or more. Get a calendar from sowing to harvest.',
    'گندم، چاول، کپاس یا دوسری فصل شامل کریں۔ بوائی سے کٹائی تک کا کیلنڈر پائیں۔',
  );
  String get onb3Title => _t('Weather alerts that matter', 'کام کی موسمی اطلاعات');
  String get onb3Body => _t(
    'Rain, heat or cold coming? Fasal explains what it means for your field.',
    'بارش، گرمی یا سردی آ رہی ہے؟ فصل بتاتی ہے کہ آپ کے کھیت کے لیے اس کا کیا مطلب ہے۔',
  );
  String get onb4Title => _t('Water, fertilizer & reminders', 'پانی، کھاد اور یاد دہانی');
  String get onb4Body => _t(
    'Get reminders for irrigation and fertilizer. Tap Listen to hear any advice.',
    'آبپاشی اور کھاد کی یاد دہانی پائیں۔ کوئی بھی مشورہ سننے کے لیے "سنیں" دبائیں۔',
  );

  // ───────────────────────── Setup / profile ─────────────────────────
  String get tellUsAboutYou => _t('Tell us about you', 'اپنے بارے میں بتائیں');
  String get yourName => _t('Your name', 'آپ کا نام');
  String get yourNameHint => _t('e.g. Ahmed', 'مثلاً احمد');
  String get villageDistrict => _t('Village / District', 'گاؤں / ضلع');
  String get chooseDistrict => _t('Choose your district', 'اپنا ضلع منتخب کریں');
  String get searchDistrict => _t('Search district', 'ضلع تلاش کریں');
  String get useMyLocation => _t('Use my location', 'میری لوکیشن استعمال کریں');
  String get detectingLocation => _t('Finding your location…', 'آپ کی لوکیشن تلاش ہو رہی ہے…');
  String locationDemoSet(String place) => _t(
    'Location set to $place (demo — GPS comes in the next phase)',
    'لوکیشن $place رکھ دی گئی (ڈیمو — جی پی ایس اگلے مرحلے میں)',
  );
  String get locationDenied => _t(
    'Location permission was not given. Please choose your district from the list.',
    'لوکیشن کی اجازت نہیں ملی۔ براہِ کرم فہرست سے اپنا ضلع منتخب کریں۔',
  );
  String get farmName => _t('Farm name', 'فارم کا نام');
  String get farmNameHint => _t('e.g. Ahmed Farm', 'مثلاً احمد فارم');
  String get farmArea => _t('Farm area', 'رقبہ');
  String get unit => _t('Unit', 'اکائی');
  String get profileSaved => _t('Profile saved', 'پروفائل محفوظ ہو گیا');
  String get profile => _t('Profile', 'پروفائل');
  String get missingLocationTitle => _t('Add your location', 'اپنی لوکیشن شامل کریں');
  String get missingLocationBody =>
      _t('Weather and alerts need your district.', 'موسم اور اطلاعات کے لیے آپ کا ضلع ضروری ہے۔');

  String areaUnitLabel(AreaUnit u, {bool plural = true}) => switch (u) {
    AreaUnit.acre => _t(plural ? 'acres' : 'acre', 'ایکڑ'),
    AreaUnit.kanal => _t(plural ? 'kanal' : 'kanal', 'کنال'),
    AreaUnit.hectare => _t(plural ? 'hectares' : 'hectare', 'ہیکٹر'),
  };

  String areaWithUnit(double value, AreaUnit u) => '${Fmt.area(value)} ${areaUnitLabel(u, plural: value != 1)}';

  // ───────────────────────── Add / edit crop ─────────────────────────
  String get addYourCrop => _t('Add your crop', 'اپنی فصل شامل کریں');
  String get editCrop => _t('Edit crop', 'فصل میں تبدیلی');
  String get whichCrop => _t('Which crop?', 'کون سی فصل؟');
  String get variety => _t('Variety', 'قسم');
  String get sowingDate => _t('Sowing date', 'بوائی کی تاریخ');
  String get selectDate => _t('Select date', 'تاریخ منتخب کریں');
  String get seedUsedKg => _t('Seed used (kg)', 'استعمال شدہ بیج (کلو)');
  String get fieldName => _t('Field name', 'کھیت کا نام');
  String get fieldNameHint => _t('e.g. Canal side field', 'مثلاً نہر والا کھیت');
  String get startFasal => _t('Start Fasal', 'فصل شروع کریں');
  String get saveCrop => _t('Save crop', 'فصل محفوظ کریں');
  String get addLater => _t('I will add a crop later', 'فصل بعد میں شامل کروں گا');
  String get cropAdded => _t('Crop added', 'فصل شامل ہو گئی');
  String get cropUpdated => _t('Crop updated', 'فصل اپڈیٹ ہو گئی');
  String get cropDeleted => _t('Crop removed', 'فصل ہٹا دی گئی');
  String get removeCrop => _t('Remove crop', 'فصل ہٹائیں');
  String removeCropBody(String name) => _t(
    'Remove $name? Its calendar and tasks will be deleted. Your records are kept.',
    'کیا $name ہٹا دیں؟ اس کا کیلنڈر اور کام حذف ہو جائیں گے۔ آپ کا ریکارڈ محفوظ رہے گا۔',
  );
  String get errSelectCrop => _t('Please choose a crop', 'براہِ کرم فصل منتخب کریں');
  String get cropNotFound =>
      _t('This crop was not found. It may have been removed.', 'یہ فصل نہیں ملی۔ شاید ہٹا دی گئی ہے۔');

  // ───────────────────────── Validation ─────────────────────────
  String get errRequired => _t('This is required', 'یہ ضروری ہے');
  String get errTooLong => _t('Too long', 'بہت لمبا ہے');
  String get errAreaRequired => _t('Please enter farm area', 'براہِ کرم رقبہ لکھیں');
  String get errNumber => _t('Please enter a number', 'براہِ کرم نمبر لکھیں');
  String get errWholeNumber => _t('Please enter a whole number', 'براہِ کرم پورا نمبر لکھیں');
  String get errAreaPositive => _t('Area must be more than 0', 'رقبہ صفر سے زیادہ ہونا چاہیے');
  String get errAreaTooLarge => _t('That area looks too large', 'یہ رقبہ بہت زیادہ لگ رہا ہے');
  String get errPositive => _t('Must be more than 0', 'صفر سے زیادہ ہونا چاہیے');
  String get errTooLarge => _t('That number looks too large', 'یہ نمبر بہت بڑا لگ رہا ہے');
  String get errAmountRequired => _t('Please enter the amount', 'براہِ کرم رقم لکھیں');
  String get errSowingDateRequired => _t('Please select the sowing date', 'براہِ کرم بوائی کی تاریخ منتخب کریں');
  String get errSowingDateFuture =>
      _t('Sowing date can be at most 60 days ahead', 'بوائی کی تاریخ زیادہ سے زیادہ 60 دن آگے ہو سکتی ہے');
  String get errSowingDatePast =>
      _t('Sowing date cannot be more than a year ago', 'بوائی کی تاریخ ایک سال سے پرانی نہیں ہو سکتی');
  String get errDistrictRequired => _t('Please choose your district', 'براہِ کرم اپنا ضلع منتخب کریں');
  String get errCategory => _t('Please choose a type', 'براہِ کرم قسم منتخب کریں');
  String get genericErrorTitle => _t('Something went wrong', 'کچھ غلط ہو گیا');
  String get genericErrorBody => _t('Please check and try again.', 'براہِ کرم دوبارہ کوشش کریں۔');

  // ───────────────────────── Home ─────────────────────────
  String get home => _t('Home', 'ہوم');
  String get greeting => _t('Assalam-o-Alaikum,', 'السلام علیکم،');
  String get farmer => _t('Farmer', 'کسان بھائی');
  String get weatherAlertLabel => _t('WEATHER ALERT', 'موسمی انتباہ');
  String get viewDetails => _t('View details', 'تفصیل دیکھیں');
  String dayN(int n) => _t('Day $n', 'دن $n');
  String cropDay(String crop, int day) => '$crop · ${dayN(day)}';
  String get expectedHarvest => _t('Expected harvest', 'متوقع کٹائی');
  String harvestRange(String from, String to) => _t('$from – $to', '$from تا $to');
  String expectedHarvestLine(String range) => _t('Expected harvest: $range', 'متوقع کٹائی: $range');
  String get harvestEstimateNote => _t('An estimate — may shift with weather', 'اندازہ — موسم کے مطابق بدل سکتا ہے');
  String get todaysTasks => _t('Today’s tasks', 'آج کے کام');
  String get cropCalendar => _t('Crop calendar', 'فصل کا کیلنڈر');
  String get askFasal => _t('Ask Fasal', 'فصل سے پوچھیں');
  String get askFasalSub => _t('Tap and speak your question', 'دبائیں اور اپنا سوال پوچھیں');
  String get thisWeek => _t('This week', 'اس ہفتے');
  String get sevenDayForecast => _t('7-day forecast', '7 دن کا موسم');
  String get cropCare => _t('Crop care', 'فصل کی دیکھ بھال');
  String get cropCareSub => _t('Fertilizer · Pests · Sprays', 'کھاد · کیڑے · اسپرے');
  String get irrigation => _t('Irrigation', 'آبپاشی');
  String get advice => _t('Advice', 'مشورے');
  String get alerts => _t('Alerts', 'انتباہ');
  String get notifications => _t('Notifications', 'اطلاعات');
  String get addCrop => _t('Add crop', 'فصل شامل کریں');
  String get addCropPlus => _t('+ Add your crop', '+ اپنی فصل شامل کریں');
  String get noCropsTitle => _t('No crops yet', 'ابھی کوئی فصل نہیں');
  String get noCropsBody => _t(
    'Add your first crop to get a calendar, tasks and advice.',
    'کیلنڈر، کام اور مشورے پانے کے لیے اپنی پہلی فصل شامل کریں۔',
  );
  String get noTasksToday =>
      _t('No tasks today. Your crop is on track!', 'آج کوئی کام نہیں۔ آپ کی فصل ٹھیک جا رہی ہے!');
  String get allTasksDone => _t('All of today’s tasks are done. Well done!', 'آج کے سب کام مکمل۔ شاباش!');
  String overdueCount(int n) =>
      _t(n == 1 ? '1 task is overdue' : '$n tasks are overdue', n == 1 ? '1 کام رہ گیا ہے' : '$n کام رہ گئے ہیں');
  String sowingInDays(int n) => _t('Sowing in $n days', '$n دن میں بوائی');
  String get readyForHarvest => _t('Ready for harvest', 'کٹائی کے لیے تیار');
  String get quickActions => _t('Quick actions', 'فوری کام');

  // ───────────────────────── Crops ─────────────────────────
  String get myCrops => _t('My Crops', 'میری فصلیں');
  String sownOn(String date) => _t('Sown $date', 'بوائی $date');
  String get daysSinceSowing => _t('Days since sowing', 'بوائی سے دن');
  String get nextTask => _t('Next', 'اگلا کام');
  String get noUpcomingTasks => _t('No upcoming tasks', 'کوئی آنے والا کام نہیں');
  String get stage => _t('Stage', 'مرحلہ');
  String stageWithName(String name) => _t('Stage: $name', 'مرحلہ: $name');
  String get nowBadge => _t('Now', 'ابھی');
  String daysRange(int a, int b) => _t('Day $a–$b', 'دن $a–$b');
  String get whatToDoNow => _t('What to do now', 'ابھی کیا کریں');
  String get whatsNext => _t('What is coming next', 'آگے کیا ہے');
  String get whatToAvoid => _t('What to avoid', 'کن باتوں سے بچیں');
  String get upcomingTasks => _t('Upcoming tasks', 'آنے والے کام');
  String get weatherForCrop => _t('Weather for your crop', 'آپ کی فصل کے لیے موسم');
  String get cropHistory => _t('Crop history', 'فصل کی تاریخ');
  String get history => _t('History', 'تاریخ');
  String get notSownYet => _t('Not sown yet', 'ابھی بوائی نہیں ہوئی');
  String get progress => _t('Progress', 'پیش رفت');
  String get overview => _t('Overview', 'خلاصہ');
  String get guidance => _t('Guidance', 'رہنمائی');
  String get selectCrop => _t('Select crop', 'فصل منتخب کریں');
  String percentComplete(int p) => _t('$p% of season', 'موسم کا $p%');

  // ───────────────────────── Calendar & tasks ─────────────────────────
  String get comingNext => _t('Coming next', 'آگے آنے والا');
  String get upcoming => _t('Upcoming', 'آنے والے');
  String get completed => _t('Completed', 'مکمل');
  String get overdue => _t('Overdue', 'رہ گئے');
  String get fullTimeline => _t('Full timeline', 'مکمل ٹائم لائن');
  String get noTasksForDay => _t('No tasks on this day', 'اس دن کوئی کام نہیں');
  String get nothingHere => _t('Nothing here yet', 'یہاں ابھی کچھ نہیں');
  String get markDone => _t('Mark as done', 'مکمل کریں');
  String get markNotDone => _t('Mark as not done', 'نامکمل کریں');
  String get reminder => _t('Reminder', 'یاد دہانی');
  String get reminderOff => _t('Off', 'بند');
  String get reminderSameDay => _t('On the day', 'اسی دن');
  String get reminderDayBefore => _t('1 day before', 'ایک دن پہلے');
  String get reminderSaved => _t('Reminder saved', 'یاد دہانی محفوظ ہو گئی');
  String get reminderNote => _t(
    'Phone reminders will be sent once notifications are connected (next phase).',
    'نوٹیفکیشن جڑنے کے بعد فون پر یاد دہانی آئے گی (اگلا مرحلہ)۔',
  );
  String dueOn(String date) => _t('Due $date', 'تاریخ $date');
  String inDays(int n) => _t(n == 1 ? 'Tomorrow' : 'In about $n days', n == 1 ? 'کل' : 'تقریباً $n دن میں');
  String daysAgo(int n) => _t(n == 1 ? 'Yesterday' : '$n days ago', n == 1 ? 'کل (گزشتہ)' : '$n دن پہلے');
  String get today => _t('Today', 'آج');
  String get tomorrow => _t('Tomorrow', 'کل');
  String get taskCompleted => _t('Task done — added to your records', 'کام مکمل — ریکارڈ میں شامل');
  String get taskReopened => _t('Task marked as not done', 'کام نامکمل کر دیا گیا');
  String get allCrops => _t('All crops', 'سب فصلیں');
  String get noOverdue => _t('No overdue tasks', 'کوئی کام نہیں رہا');
  String get nextSevenDays => _t('Next 7 days', 'اگلے 7 دن');
  String get tasksEmptyBody => _t('Add a crop to see your farming tasks.', 'اپنے کام دیکھنے کے لیے فصل شامل کریں۔');

  String importance(Importance i) => switch (i) {
    Importance.high => _t('Important', 'اہم'),
    Importance.medium => _t('Normal', 'عام'),
    Importance.low => _t('Optional', 'اختیاری'),
  };

  String taskType(TaskType t) => switch (t) {
    TaskType.seedPrep => _t('Seed preparation', 'بیج کی تیاری'),
    TaskType.sowing => _t('Sowing', 'بوائی'),
    TaskType.irrigation => _t('Irrigation', 'آبپاشی'),
    TaskType.fertilizer => _t('Fertilizer', 'کھاد'),
    TaskType.inspection => _t('Crop inspection', 'فصل کا معائنہ'),
    TaskType.weeding => _t('Weed control', 'جڑی بوٹیوں کی تلفی'),
    TaskType.pestMonitoring => _t('Pest monitoring', 'کیڑوں کی نگرانی'),
    TaskType.harvestPrep => _t('Harvest preparation', 'کٹائی کی تیاری'),
    TaskType.harvest => _t('Harvest', 'کٹائی'),
  };

  String taskStatus(TaskStatus st) => switch (st) {
    TaskStatus.done => completed,
    TaskStatus.overdue => overdue,
    TaskStatus.today => today,
    TaskStatus.upcoming => upcoming,
  };

  // ───────────────────────── Crop care ─────────────────────────
  String get fertilizer => _t('Fertilizer', 'کھاد');
  String get pests => _t('Pests', 'کیڑے');
  String get sprays => _t('Sprays', 'اسپرے');
  String get thisStage => _t('now', 'ابھی');
  String stageNow(String stage) => _t('$stage stage · now', 'مرحلہ $stage · ابھی');
  String stageLater(String stage) => _t('$stage stage', 'مرحلہ $stage');
  String get purpose => _t('Purpose', 'مقصد');
  String get timing => _t('When', 'کب');
  String get howToApply => _t('How to apply', 'کیسے ڈالیں');
  String get precautions => _t('Precautions', 'احتیاط');
  String get symptoms => _t('Signs to look for', 'علامات');
  String get prevention => _t('Prevention', 'بچاؤ');
  String get riskAfterRain => _t('Risk rises after rain', 'بارش کے بعد خطرہ بڑھ جاتا ہے');
  String get pestLabel => _t('Pest', 'کیڑا');
  String get diseaseLabel => _t('Disease', 'بیماری');
  String get sampleGuidanceNote => _t(
    'Sample guidance for demo. Confirm with your local agriculture extension office and always follow the product label for doses.',
    'ڈیمو کے لیے نمونہ رہنمائی۔ اپنے مقامی محکمہ زراعت سے تصدیق کریں اور مقدار کے لیے ہمیشہ پیکٹ پر لکھی ہدایات پر عمل کریں۔',
  );
  String get verifiedGuidanceNote => _t(
    'From verified agricultural guidance. Always follow the product label for doses.',
    'تصدیق شدہ زرعی رہنمائی۔ مقدار کے لیے ہمیشہ پیکٹ پر لکھی ہدایات پر عمل کریں۔',
  );
  String get photoDiagnosis => _t('Check a leaf with a photo', 'تصویر سے پتہ چیک کریں');
  String get photoDiagnosisBody => _t(
    'Photo diagnosis is planned for a future version. It does not work yet.',
    'تصویر سے تشخیص اگلے ورژن میں آئے گی۔ یہ ابھی کام نہیں کرتی۔',
  );
  String get productCategory => _t('Type of product', 'دوا کی قسم');
  String get safety => _t('Safety', 'حفاظت');
  String get warnings => _t('Warnings', 'خبردار');
  String get noDoseNote => _t(
    'Fasal does not give doses. Ask an agriculture officer and read the label.',
    'فصل دوا کی مقدار نہیں بتاتی۔ زراعت افسر سے پوچھیں اور لیبل پڑھیں۔',
  );
  String get noGuidance => _t('No guidance for this crop yet', 'اس فصل کے لیے ابھی رہنمائی نہیں');
  String get earlierStage => _t('Earlier stage', 'پچھلا مرحلہ');
  String get laterStage => _t('Later stage', 'اگلا مرحلہ');

  // ───────────────────────── Irrigation ─────────────────────────
  String get irrigationGuidance => _t('Irrigation guidance', 'آبپاشی کی رہنمائی');
  String get nextSuggestedIrrigation => _t('Next suggested irrigation', 'اگلی تجویز کردہ آبپاشی');
  String get rainForecast => _t('Rain forecast', 'بارش کی پیشگوئی');
  String get criticalStages => _t('Critical water stages', 'پانی کے اہم مراحل');
  String get irrigationReminders => _t('Remember', 'یاد رکھیں');
  String get noRainExpected => _t('No significant rain expected this week', 'اس ہفتے خاص بارش متوقع نہیں');
  String rainExpectedOn(String day, int pct) => _t('Rain likely $day ($pct%)', '$day بارش کا امکان ($pct%)');

  // ───────────────────────── Weather ─────────────────────────
  String get weather => _t('Weather', 'موسم');
  String get rain => _t('Rain', 'بارش');
  String get wind => _t('Wind', 'ہوا');
  String get humidity => _t('Humidity', 'نمی');
  String feelsLike(int t) => _t('Feels like $t°', 'محسوس $t°');
  String whatThisMeans(String crop) => _t('What this means for your $crop', 'آپ کی $crop کے لیے اس کا مطلب');
  String get whatThisMeansGeneric => _t('What this means for your farm', 'آپ کے کھیت کے لیے اس کا مطلب');
  String kmh(int v) => _t('$v km/h', '$v کلومیٹر/گھنٹہ');
  String updatedAt(String time) => _t('Updated $time', 'اپڈیٹ $time');
  String get sampleWeatherNote => _t(
    'Sample weather for demo — live forecast comes in the next phase.',
    'ڈیمو کے لیے نمونہ موسم — اصل پیشگوئی اگلے مرحلے میں۔',
  );
  String get weatherUnavailable => _t('Weather is not available', 'موسم دستیاب نہیں');
  String get weatherUnavailableBody =>
      _t('Check your internet connection and try again.', 'اپنا انٹرنیٹ چیک کریں اور دوبارہ کوشش کریں۔');
  String get dayDetails => _t('Day details', 'دن کی تفصیل');
  String get rainChance => _t('Chance of rain', 'بارش کا امکان');
  String get lowHigh => _t('Low / High', 'کم / زیادہ');

  String condition(WeatherCondition c) => switch (c) {
    WeatherCondition.sunny => _t('Sunny', 'دھوپ'),
    WeatherCondition.partlyCloudy => _t('Partly cloudy', 'جزوی بادل'),
    WeatherCondition.cloudy => _t('Cloudy', 'بادل'),
    WeatherCondition.lightRain => _t('Light rain', 'ہلکی بارش'),
    WeatherCondition.heavyRain => _t('Heavy rain', 'تیز بارش'),
    WeatherCondition.thunderstorm => _t('Thunderstorm', 'آندھی اور بارش'),
    WeatherCondition.fog => _t('Fog', 'دھند'),
    WeatherCondition.windy => _t('Windy', 'تیز ہوا'),
  };

  // ───────────────────────── Alerts ─────────────────────────
  String get weatherAlerts => _t('Weather alerts', 'موسمی انتباہ');
  String get active => _t('Active', 'جاری');
  String get past => _t('Past', 'گزشتہ');
  String get markAllRead => _t('Mark all read', 'سب پڑھ لیے');
  String get noAlerts => _t('No weather alerts right now', 'ابھی کوئی موسمی انتباہ نہیں');
  String get noAlertsBody =>
      _t('We will tell you when rain, heat or cold is coming.', 'بارش، گرمی یا سردی آنے پر ہم آپ کو بتائیں گے۔');
  String get recommendedAction => _t('What to do', 'کیا کریں');
  String get affectedCrops => _t('Affects', 'متاثرہ فصل');
  String get newLabel => _t('New', 'نیا');

  String severity(AlertSeverity s) => switch (s) {
    AlertSeverity.info => _t('Advisory', 'معلومات'),
    AlertSeverity.warning => _t('Warning', 'انتباہ'),
    AlertSeverity.severe => _t('Severe', 'شدید'),
  };

  // ───────────────────────── Notifications ─────────────────────────
  String get noNotifications => _t('No notifications', 'کوئی اطلاع نہیں');
  String get noNotificationsBody =>
      _t('Reminders and alerts will appear here.', 'یاد دہانیاں اور انتباہ یہاں نظر آئیں گے۔');
  String get earlier => _t('Earlier', 'پہلے');
  String get notificationDeleted => _t('Notification removed', 'اطلاع ہٹا دی گئی');
  String get notificationsDemoNote => _t(
    'Sample notifications. Push notifications arrive in the next phase.',
    'نمونہ اطلاعات۔ پُش نوٹیفکیشن اگلے مرحلے میں۔',
  );

  String notificationType(NotificationType t) => switch (t) {
    NotificationType.task => _t('Task reminders', 'کاموں کی یاد دہانی'),
    NotificationType.stage => _t('Crop stage updates', 'فصل کے مرحلے'),
    NotificationType.weather => _t('Weather alerts', 'موسمی انتباہ'),
    NotificationType.irrigation => _t('Irrigation reminders', 'آبپاشی کی یاد دہانی'),
    NotificationType.fertilizer => _t('Fertilizer reminders', 'کھاد کی یاد دہانی'),
    NotificationType.general => _t('General updates', 'عام اطلاعات'),
  };

  // ───────────────────────── Ask Fasal ─────────────────────────
  String get tapAndSpeak => _t('Tap and speak your question', 'دبائیں اور اپنا سوال بولیں');
  String get tryAsking => _t('Try asking', 'یہ پوچھ کر دیکھیں');
  String get typeYourQuestion => _t('Type your question…', 'اپنا سوال لکھیں…');
  String get voiceInputSoonTitle => _t('Voice questions are coming', 'آواز سے سوال جلد');
  String get voiceInputSoonBody => _t(
    'Speaking your question will work in the next phase. For now, tap a question below or type it.',
    'سوال بول کر پوچھنا اگلے مرحلے میں کام کرے گا۔ ابھی نیچے دیا گیا سوال دبائیں یا لکھیں۔',
  );
  String get sampleAnswerNote => _t(
    'Sample answer from your crop calendar and weather. Not live AI.',
    'آپ کے فصل کیلنڈر اور موسم سے نمونہ جواب۔ یہ ابھی اصل AI نہیں۔',
  );
  String get askQ1 => _t('When should I water my crop?', 'مجھے فصل کو پانی کب دینا چاہیے؟');
  String get askQ2 => _t('Rain is coming, should I irrigate today?', 'بارش آ رہی ہے، کیا آج پانی دوں؟');
  String get askQ3 => _t('Which fertilizer is due now?', 'ابھی کون سی کھاد ڈالنی ہے؟');
  String get askQ4 => _t('What pests should I watch for?', 'کن کیڑوں پر نظر رکھوں؟');
  String get you => _t('You', 'آپ');

  // ───────────────────────── Advice ─────────────────────────
  String get farmingAdvice => _t('Farming advice', 'کاشتکاری مشورے');
  String get noAdvice => _t('No advice in this category right now', 'ابھی اس حصے میں کوئی مشورہ نہیں');

  String adviceCategory(AdviceCategory c) => switch (c) {
    AdviceCategory.today => _t('Today', 'آج'),
    AdviceCategory.cropCare => _t('Crop care', 'دیکھ بھال'),
    AdviceCategory.irrigation => _t('Irrigation', 'آبپاشی'),
    AdviceCategory.fertilizer => _t('Fertilizer', 'کھاد'),
    AdviceCategory.pests => _t('Pests', 'کیڑے'),
    AdviceCategory.weather => _t('Weather', 'موسم'),
  };

  // ───────────────────────── Records ─────────────────────────
  String get records => _t('Records', 'ریکارڈ');
  String get totalSpentSeason => _t('Total spent this season', 'اس موسم میں کل خرچ');
  String get activities => _t('Activities', 'سرگرمیاں');
  String get expenses => _t('Expenses', 'اخراجات');
  String get addActivity => _t('+ Add activity', '+ سرگرمی شامل کریں');
  String get addExpense => _t('+ Add expense', '+ خرچ شامل کریں');
  String get addActivityTitle => _t('Add activity', 'سرگرمی شامل کریں');
  String get addExpenseTitle => _t('Add expense', 'خرچ شامل کریں');
  String get amountRs => _t('Amount (Rs)', 'رقم (روپے)');
  String get date => _t('Date', 'تاریخ');
  String get note => _t('Note', 'نوٹ');
  String get noteHint => _t('Anything to remember', 'کوئی یاد رکھنے والی بات');
  String get crop => _t('Crop', 'فصل');
  String get wholeFarm => _t('Whole farm', 'پورا فارم');
  String get noActivities => _t('No activities recorded', 'کوئی سرگرمی درج نہیں');
  String get noExpenses => _t('No expenses recorded', 'کوئی خرچ درج نہیں');
  String get recordAdded => _t('Saved to records', 'ریکارڈ میں محفوظ');
  String get recordDeleted => _t('Record deleted', 'ریکارڈ حذف ہو گیا');
  String get deleteRecordTitle => _t('Delete this record?', 'یہ ریکارڈ حذف کریں؟');
  String rs(int amount) => _t('Rs ${Fmt.thousands(amount)}', 'Rs ${Fmt.thousands(amount)}');
  String get type => _t('Type', 'قسم');

  String activityType(ActivityType t) => switch (t) {
    ActivityType.sowing => _t('Sowing', 'بوائی'),
    ActivityType.irrigation => _t('Irrigation', 'آبپاشی'),
    ActivityType.fertilizer => _t('Fertilizer', 'کھاد'),
    ActivityType.spray => _t('Spray', 'اسپرے'),
    ActivityType.weeding => _t('Weeding', 'گوڈی'),
    ActivityType.inspection => _t('Inspection', 'معائنہ'),
    ActivityType.harvest => _t('Harvest', 'کٹائی'),
    ActivityType.note => _t('Note', 'نوٹ'),
    ActivityType.other => _t('Other', 'دیگر'),
  };

  String expenseCategory(ExpenseCategory c) => switch (c) {
    ExpenseCategory.seeds => _t('Seeds', 'بیج'),
    ExpenseCategory.fertilizer => _t('Fertilizer', 'کھاد'),
    ExpenseCategory.pesticide => _t('Pesticide', 'زرعی دوا'),
    ExpenseCategory.labor => _t('Labor', 'مزدوری'),
    ExpenseCategory.irrigation => _t('Irrigation', 'آبپاشی'),
    ExpenseCategory.machinery => _t('Machinery', 'مشینری'),
    ExpenseCategory.other => _t('Other', 'دیگر'),
  };

  // ───────────────────────── History ─────────────────────────
  String get cropAddedEvent => _t('Crop added to Fasal', 'فصل ایپ میں شامل کی گئی');
  String get sowingEvent => _t('Sowing', 'بوائی');
  String get addNote => _t('Add note', 'نوٹ شامل کریں');
  String get noteSaved => _t('Note saved', 'نوٹ محفوظ ہو گیا');
  String get writeNote => _t('Write a note about this crop', 'اس فصل کے بارے میں نوٹ لکھیں');

  // ───────────────────────── Settings ─────────────────────────
  String get settings => _t('Settings', 'ترتیبات');
  String get location => _t('Location', 'لوکیشن');
  String get notificationPrefs => _t('Notifications', 'اطلاعات');
  String get voice => _t('Voice', 'آواز');
  String get speechSpeed => _t('Speaking speed', 'بولنے کی رفتار');
  String get slow => _t('Slow', 'آہستہ');
  String get normal => _t('Normal', 'عام');
  String get fast => _t('Fast', 'تیز');
  String get testVoice => _t('Test voice', 'آواز آزمائیں');
  String get voiceSample => _t(
    'Assalam-o-Alaikum. This is how Fasal will read advice to you.',
    'السلام علیکم۔ فصل آپ کو مشورے اس طرح پڑھ کر سنائے گی۔',
  );
  String get units => _t('Units', 'اکائیاں');
  String get defaultAreaUnit => _t('Area unit', 'رقبے کی اکائی');
  String get about => _t('About Fasal', 'فصل کے بارے میں');
  String get version => _t('Version', 'ورژن');
  String get aboutBody => _t(
    'Fasal helps Pakistani farmers know what to do and when. This is the Phase 1 demo: weather, guidance and answers are sample data and are not yet expert-verified.',
    'فصل پاکستانی کسانوں کو بتاتی ہے کہ کیا کرنا ہے اور کب۔ یہ پہلے مرحلے کا ڈیمو ہے: موسم، رہنمائی اور جوابات نمونہ ہیں اور ابھی ماہرین سے تصدیق شدہ نہیں۔',
  );
  String get privacy => _t('Privacy', 'رازداری');
  String get privacyBody => _t(
    'In this version your information stays on your phone. Nothing is sent to a server. When online features are added, we will ask before sharing anything.',
    'اس ورژن میں آپ کی معلومات صرف آپ کے فون پر رہتی ہیں۔ کچھ بھی سرور پر نہیں بھیجا جاتا۔ آن لائن سہولیات آنے پر کچھ بھی شیئر کرنے سے پہلے اجازت لی جائے گی۔',
  );
  String get help => _t('Help & support', 'مدد');
  String get helpQ1 => _t('How do I add a crop?', 'فصل کیسے شامل کروں؟');
  String get helpA1 => _t(
    'Go to My Crops and tap “+ Add your crop”. Choose the crop, sowing date and area.',
    '"میری فصلیں" میں جائیں اور "+ اپنی فصل شامل کریں" دبائیں۔ فصل، بوائی کی تاریخ اور رقبہ منتخب کریں۔',
  );
  String get helpQ2 => _t('How do I hear advice?', 'مشورہ کیسے سنوں؟');
  String get helpA2 => _t('Tap the 🔊 Listen button on any card.', 'کسی بھی کارڈ پر 🔊 سنیں کا بٹن دبائیں۔');
  String get helpQ3 => _t('Is the advice verified?', 'کیا مشورے تصدیق شدہ ہیں؟');
  String get helpA3 => _t(
    'Not yet. This demo uses sample advice. Always confirm with your local agriculture office.',
    'ابھی نہیں۔ اس ڈیمو میں نمونہ مشورے ہیں۔ ہمیشہ اپنے مقامی محکمہ زراعت سے تصدیق کریں۔',
  );
  String get contactSupport =>
      _t('Support email: support@fasal.app (placeholder)', 'سپورٹ ای میل: support@fasal.app (عارضی)');
  String get demoOptions => _t('Demo options', 'ڈیمو کی ترتیبات');
  String get simulateWeatherError => _t('Simulate weather unavailable', 'موسم دستیاب نہ ہونے کی مشق');
  String get loadSampleFarm => _t('Load sample farm (wheat, day 38)', 'نمونہ فارم شامل کریں (گندم، دن 38)');
  String get sampleFarmLoaded => _t('Sample farm added', 'نمونہ فارم شامل ہو گیا');
  String get restartDemo => _t('Restart demo', 'ڈیمو دوبارہ شروع کریں');
  String get restartDemoBody => _t(
    'This clears your profile, crops and records on this phone and starts again.',
    'اس سے اس فون پر آپ کا پروفائل، فصلیں اور ریکارڈ صاف ہو جائیں گے اور ایپ نئے سرے سے شروع ہو گی۔',
  );
  String get speechVoiceLanguage => _t('Voice follows the app language', 'آواز ایپ کی زبان کے مطابق ہے');

  // ───────────────────────── Voice / TTS ─────────────────────────
  String get ttsUnavailable => _t('Voice is not available on this phone', 'اس فون پر آواز دستیاب نہیں');
  String get urduVoiceMissing => _t(
    'Urdu voice is not installed on this phone. Reading in English instead.',
    'اس فون پر اردو آواز انسٹال نہیں۔ انگریزی میں پڑھا جا رہا ہے۔',
  );

  // ───────────────────────── Dates ─────────────────────────
  static const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _monthsLongEn = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _monthsUr = [
    'جنوری',
    'فروری',
    'مارچ',
    'اپریل',
    'مئی',
    'جون',
    'جولائی',
    'اگست',
    'ستمبر',
    'اکتوبر',
    'نومبر',
    'دسمبر',
  ];
  static const _daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _daysLongEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _daysUr = ['پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار'];

  String monthShort(int month) => isUrdu ? _monthsUr[month - 1] : _monthsEn[month - 1];
  String monthLong(int month) => isUrdu ? _monthsUr[month - 1] : _monthsLongEn[month - 1];
  String weekdayShort(int weekday) => isUrdu ? _daysUr[weekday - 1] : _daysEn[weekday - 1];
  String weekdayLong(int weekday) => isUrdu ? _daysUr[weekday - 1] : _daysLongEn[weekday - 1];

  /// "15 Nov"
  String shortDate(DateTime d) => '${d.day} ${monthShort(d.month)}';

  /// "15 Nov 2026"
  String fullDate(DateTime d) => '${d.day} ${monthShort(d.month)} ${d.year}';

  /// "10 April"
  String dayMonth(DateTime d) => '${d.day} ${monthLong(d.month)}';

  /// "14:05" / "2:05 PM"
  String time(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return isUrdu ? '$h:$m ${d.hour < 12 ? 'صبح' : 'شام'}' : '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  /// Relative label for a date: Today / Tomorrow / In 3 days / 2 days ago.
  String relativeDay(int daysFromToday) {
    if (daysFromToday == 0) return today;
    if (daysFromToday > 0) return inDays(daysFromToday);
    return daysAgo(-daysFromToday);
  }
}
