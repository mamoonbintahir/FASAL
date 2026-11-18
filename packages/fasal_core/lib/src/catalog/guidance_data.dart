// SAMPLE guidance content for the Phase 1 demo.
//
// Deliberately contains NO fertilizer quantities, NO pesticide product names
// and NO doses. Everything is marked GuidanceSource.sample. Expert-validated
// content will replace this via the backend in Phase 2.

import '../models/guidance.dart';
import '../models/localized_text.dart';

typedef _L = LocalizedText;

const _labelRule = _L(
  'Use the quantity from your local extension office or the bag label.',
  'مقدار اپنے مقامی محکمہ زراعت یا بوری پر لکھی ہدایت کے مطابق رکھیں۔',
);
const _noWind = _L(
  'Do not apply in strong wind or just before heavy rain.',
  'تیز ہوا میں یا تیز بارش سے ذرا پہلے نہ ڈالیں۔',
);
const _gloves = _L('Wear gloves and wash hands after handling.', 'دستانے پہنیں اور بعد میں ہاتھ دھوئیں۔');

const List<FertilizerGuide> kFertilizerGuides = [
  // Wheat
  FertilizerGuide(
    id: 'w_f0',
    cropTypeId: 'wheat',
    stageIndex: 0,
    name: _L('Basal fertilizer at sowing', 'بوائی کے وقت بنیادی کھاد'),
    purpose: _L('Gives young roots phosphorus and early strength.', 'جڑوں کو فاسفورس اور ابتدائی طاقت دیتی ہے۔'),
    timing: _L('At sowing time.', 'بوائی کے وقت۔'),
    howTo: _L(
      'Mix into soil at sowing. Use quantity from your local extension office or bag label.',
      'بوائی کے وقت زمین میں ملائیں۔ مقدار محکمہ زراعت یا بوری کی ہدایت سے لیں۔',
    ),
    precautions: [_labelRule, _gloves],
  ),
  FertilizerGuide(
    id: 'w_f1',
    cropTypeId: 'wheat',
    stageIndex: 1,
    name: _L('Nitrogen top-dressing', 'نائٹروجن کھاد کا چھٹا'),
    purpose: _L('Helps the plant make more tillers (shoots).', 'پودے کو زیادہ شاخیں بنانے میں مدد دیتی ہے۔'),
    timing: _L('With or just before the next irrigation.', 'اگلے پانی کے ساتھ یا اس سے ذرا پہلے۔'),
    howTo: _L(
      'Apply with or just before the next irrigation. Use quantity from your local extension office or bag label.',
      'اگلے پانی کے ساتھ یا اس سے ذرا پہلے ڈالیں۔ مقدار محکمہ زراعت یا بوری کی ہدایت سے لیں۔',
    ),
    precautions: [_labelRule, _noWind, _gloves],
  ),
  FertilizerGuide(
    id: 'w_f2',
    cropTypeId: 'wheat',
    stageIndex: 2,
    name: _L('Second nitrogen split', 'نائٹروجن کی دوسری قسط'),
    purpose: _L('Supports stem growth before heading.', 'سٹے نکلنے سے پہلے تنے کی بڑھوتری میں مدد۔'),
    timing: _L('Early jointing, with irrigation.', 'گانٹھ بننے کے شروع میں، پانی کے ساتھ۔'),
    howTo: _L(
      'Broadcast evenly with irrigation. Follow label or extension office for quantity.',
      'پانی کے ساتھ یکساں چھٹا دیں۔ مقدار کے لیے لیبل یا محکمہ زراعت کی ہدایت دیکھیں۔',
    ),
    precautions: [_labelRule, _noWind],
  ),
  // Rice
  FertilizerGuide(
    id: 'r_f1',
    cropTypeId: 'rice',
    stageIndex: 1,
    name: _L('Nitrogen at tillering', 'شاخیں نکلنے پر نائٹروجن'),
    purpose: _L('Supports more tillers.', 'زیادہ شاخوں میں مدد۔'),
    timing: _L('About 3–4 weeks after transplanting.', 'منتقلی کے تقریباً 3–4 ہفتے بعد۔'),
    howTo: _L(
      'Apply in shallow standing water. Quantity from extension office or bag label.',
      'کم گہرے کھڑے پانی میں ڈالیں۔ مقدار محکمہ زراعت یا بوری کی ہدایت سے۔',
    ),
    precautions: [_labelRule],
  ),
  FertilizerGuide(
    id: 'r_f2',
    cropTypeId: 'rice',
    stageIndex: 2,
    name: _L('Zinc check', 'زنک کی جانچ'),
    purpose: _L('Rice fields in Punjab often lack zinc.', 'پنجاب میں دھان کے کھیتوں میں اکثر زنک کی کمی ہوتی ہے۔'),
    timing: _L('If leaves show brown spots early.', 'اگر پتوں پر شروع میں بھورے دھبے ہوں۔'),
    howTo: _L(
      'Ask your agriculture office about a soil test and zinc.',
      'مٹی کے ٹیسٹ اور زنک کے بارے میں محکمہ زراعت سے پوچھیں۔',
    ),
    precautions: [_labelRule],
  ),
  // Cotton
  FertilizerGuide(
    id: 'c_f1',
    cropTypeId: 'cotton',
    stageIndex: 1,
    name: _L('Nitrogen in splits', 'نائٹروجن قسطوں میں'),
    purpose: _L('Steady growth without too much leaf.', 'زیادہ پتوں کے بغیر متوازن بڑھوتری۔'),
    timing: _L('With irrigations from vegetative to flowering.', 'بڑھوتری سے پھول تک پانی کے ساتھ۔'),
    howTo: _L(
      'Split into parts with irrigation. Quantity from extension office or bag label.',
      'پانی کے ساتھ حصوں میں ڈالیں۔ مقدار محکمہ زراعت یا بوری کی ہدایت سے۔',
    ),
    precautions: [_labelRule, _noWind],
  ),
  // Maize
  FertilizerGuide(
    id: 'm_f1',
    cropTypeId: 'maize',
    stageIndex: 1,
    name: _L('Nitrogen side-dressing', 'نائٹروجن کی سائیڈ ڈریسنگ'),
    purpose: _L('Maize needs nitrogen during fast growth.', 'تیز بڑھوتری میں مکئی کو نائٹروجن چاہیے۔'),
    timing: _L('Knee-high stage, with irrigation.', 'گھٹنے تک اونچائی پر، پانی کے ساتھ۔'),
    howTo: _L(
      'Place along the rows and irrigate. Quantity from extension office or bag label.',
      'قطاروں کے ساتھ ڈال کر پانی دیں۔ مقدار محکمہ زراعت یا بوری کی ہدایت سے۔',
    ),
    precautions: [_labelRule],
  ),
  // Sugarcane
  FertilizerGuide(
    id: 's_f1',
    cropTypeId: 'sugarcane',
    stageIndex: 1,
    name: _L('Nitrogen at tillering', 'شاخیں نکلنے پر نائٹروجن'),
    purpose: _L('More tillers mean more canes.', 'زیادہ شاخیں یعنی زیادہ گنے۔'),
    timing: _L('In splits during tillering.', 'شاخیں نکلنے کے دوران قسطوں میں۔'),
    howTo: _L(
      'Apply near rows before irrigation. Quantity from extension office or bag label.',
      'پانی سے پہلے قطاروں کے قریب ڈالیں۔ مقدار محکمہ زراعت یا بوری کی ہدایت سے۔',
    ),
    precautions: [_labelRule],
  ),
  // Potato
  FertilizerGuide(
    id: 'p_f1',
    cropTypeId: 'potato',
    stageIndex: 1,
    name: _L('Top-dressing with earthing up', 'مٹی چڑھاتے وقت کھاد'),
    purpose: _L('Feeds the plant before tubers start.', 'آلو بننے سے پہلے پودے کو خوراک۔'),
    timing: _L('At first earthing up.', 'پہلی بار مٹی چڑھاتے وقت۔'),
    howTo: _L(
      'Apply beside the ridge and cover with soil. Quantity from extension office or bag label.',
      'پٹڑی کے ساتھ ڈال کر مٹی سے ڈھانپیں۔ مقدار محکمہ زراعت یا بوری کی ہدایت سے۔',
    ),
    precautions: [_labelRule, _gloves],
  ),
];

const List<PestGuide> kPestGuides = [
  // Wheat
  PestGuide(
    id: 'w_aphid',
    cropTypeId: 'wheat',
    kind: PestKind.pest,
    emoji: '🐛',
    name: _L('Aphids (Tela)', 'سست تیلہ'),
    watchWindow: _L('Watch from now to heading', 'ابھی سے سٹے نکلنے تک نظر رکھیں'),
    symptoms: _L(
      'Small green insects under leaves and on ears. Leaves may curl and feel sticky.',
      'پتوں کے نیچے اور سٹوں پر چھوٹے سبز کیڑے۔ پتے مڑ سکتے ہیں اور چپچپے ہو سکتے ہیں۔',
    ),
    prevention: _L(
      'Check weekly. Ladybirds eat aphids — avoid needless sprays. If many plants are affected, contact an agriculture officer before spraying.',
      'ہر ہفتے دیکھیں۔ لیڈی برڈ تیلہ کھاتی ہے — بلاوجہ اسپرے نہ کریں۔ اگر بہت پودے متاثر ہوں تو اسپرے سے پہلے زراعت افسر سے رابطہ کریں۔',
    ),
  ),
  PestGuide(
    id: 'w_rust',
    cropTypeId: 'wheat',
    kind: PestKind.disease,
    emoji: '🍂',
    name: _L('Yellow rust', 'پیلی کنگی'),
    watchWindow: _L('Risk rises after rain', 'بارش کے بعد خطرہ بڑھ جاتا ہے'),
    symptoms: _L(
      'Yellow stripes of powder on leaves. Powder comes off on your finger.',
      'پتوں پر پیلے سفوف کی دھاریاں۔ انگلی لگانے سے سفوف اتر آتا ہے۔',
    ),
    prevention: _L(
      'Grow resistant varieties. Check leaves after rain or fog and report spots to your agriculture office.',
      'بیماری برداشت کرنے والی اقسام کاشت کریں۔ بارش یا دھند کے بعد پتے دیکھیں اور دھبے ہوں تو محکمہ زراعت کو بتائیں۔',
    ),
    riskAfterRain: true,
  ),
  PestGuide(
    id: 'w_termite',
    cropTypeId: 'wheat',
    kind: PestKind.pest,
    emoji: '🐜',
    name: _L('Termites', 'دیمک'),
    watchWindow: _L('Early stages, in dry sandy fields', 'شروع کے مراحل میں، خشک ریتلے کھیتوں میں'),
    symptoms: _L(
      'Plants dry up in patches and pull out easily.',
      'پودے ٹکڑیوں میں سوکھ جاتے ہیں اور آسانی سے اکھڑ جاتے ہیں۔',
    ),
    prevention: _L(
      'Use well-rotted manure only. Timely irrigation reduces damage.',
      'صرف گلی سڑی گوبر کی کھاد استعمال کریں۔ بروقت پانی سے نقصان کم ہوتا ہے۔',
    ),
  ),
  // Rice
  PestGuide(
    id: 'r_borer',
    cropTypeId: 'rice',
    kind: PestKind.pest,
    emoji: '🐛',
    name: _L('Stem borer', 'تنے کی سنڈی'),
    watchWindow: _L('Tillering to flowering', 'شاخیں نکلنے سے پھول تک'),
    symptoms: _L(
      'Dead centre shoots; white empty panicles later.',
      'درمیانی شاخ سوکھ جاتی ہے؛ بعد میں سفید خالی بالیاں۔',
    ),
    prevention: _L(
      'Remove stubble after harvest. Consult an agriculture officer if damage spreads.',
      'کٹائی کے بعد مڈھ تلف کریں۔ نقصان بڑھے تو زراعت افسر سے مشورہ کریں۔',
    ),
  ),
  PestGuide(
    id: 'r_blast',
    cropTypeId: 'rice',
    kind: PestKind.disease,
    emoji: '🍂',
    name: _L('Rice blast', 'جھلساؤ (بلاسٹ)'),
    watchWindow: _L('Humid weather, after rain', 'مرطوب موسم میں، بارش کے بعد'),
    symptoms: _L(
      'Eye-shaped grey spots with brown edges on leaves.',
      'پتوں پر آنکھ نما سرمئی دھبے جن کے کنارے بھورے ہوں۔',
    ),
    prevention: _L(
      'Avoid excess nitrogen. Report early spots to your agriculture office.',
      'زیادہ نائٹروجن سے بچیں۔ شروع کے دھبے محکمہ زراعت کو بتائیں۔',
    ),
    riskAfterRain: true,
  ),
  // Cotton
  PestGuide(
    id: 'c_whitefly',
    cropTypeId: 'cotton',
    kind: PestKind.pest,
    emoji: '🪰',
    name: _L('Whitefly', 'سفید مکھی'),
    watchWindow: _L('Vegetative to boll formation', 'بڑھوتری سے ٹینڈے بننے تک'),
    symptoms: _L(
      'Tiny white insects fly up when leaves are shaken; leaves turn sticky and black.',
      'پتے ہلانے پر چھوٹے سفید کیڑے اڑتے ہیں؛ پتے چپچپے اور کالے ہو جاتے ہیں۔',
    ),
    prevention: _L(
      'Scout twice a week. Keep field and borders weed-free. Get advice before spraying.',
      'ہفتے میں دو بار معائنہ کریں۔ کھیت اور کنارے صاف رکھیں۔ اسپرے سے پہلے مشورہ لیں۔',
    ),
  ),
  PestGuide(
    id: 'c_pbw',
    cropTypeId: 'cotton',
    kind: PestKind.pest,
    emoji: '🐛',
    name: _L('Pink bollworm', 'گلابی سنڈی'),
    watchWindow: _L('Flowering to boll opening', 'پھول سے ٹینڈے کھلنے تک'),
    symptoms: _L('Rosette (twisted) flowers; pink larvae inside bolls.', 'مڑے ہوئے پھول؛ ٹینڈوں کے اندر گلابی سنڈی۔'),
    prevention: _L(
      'Remove and destroy rosette flowers. Use pheromone traps if available.',
      'مڑے ہوئے پھول توڑ کر تلف کریں۔ دستیاب ہوں تو فیرومون ٹریپ لگائیں۔',
    ),
  ),
  // Maize
  PestGuide(
    id: 'm_faw',
    cropTypeId: 'maize',
    kind: PestKind.pest,
    emoji: '🐛',
    name: _L('Fall armyworm', 'لشکری سنڈی'),
    watchWindow: _L('Early vegetative stage', 'بڑھوتری کے شروع میں'),
    symptoms: _L(
      'Ragged holes in leaves; sawdust-like waste in the whorl.',
      'پتوں میں بے ترتیب سوراخ؛ گوبھ میں برادہ نما فضلہ۔',
    ),
    prevention: _L(
      'Check 20 plants weekly. Report to your agriculture office if many are damaged.',
      'ہر ہفتے 20 پودے دیکھیں۔ زیادہ نقصان ہو تو محکمہ زراعت کو بتائیں۔',
    ),
  ),
  // Sugarcane
  PestGuide(
    id: 's_borer',
    cropTypeId: 'sugarcane',
    kind: PestKind.pest,
    emoji: '🐛',
    name: _L('Shoot borer', 'گوبھ کی سنڈی'),
    watchWindow: _L('Germination to tillering', 'اگاؤ سے شاخیں نکلنے تک'),
    symptoms: _L(
      'Central shoot dries (dead heart) and pulls out easily.',
      'درمیانی گوبھ سوکھ جاتی ہے اور آسانی سے نکل آتی ہے۔',
    ),
    prevention: _L(
      'Cut and destroy dead hearts. Keep irrigation regular.',
      'سوکھی گوبھ کاٹ کر تلف کریں۔ پانی باقاعدگی سے دیں۔',
    ),
  ),
  // Potato
  PestGuide(
    id: 'p_blight',
    cropTypeId: 'potato',
    kind: PestKind.disease,
    emoji: '🍂',
    name: _L('Late blight', 'پچھیتا جھلساؤ'),
    watchWindow: _L('Foggy, cool and wet weather', 'دھند، ٹھنڈا اور نم موسم'),
    symptoms: _L(
      'Dark wet patches on leaves; white growth under leaves in the morning.',
      'پتوں پر گہرے گیلے دھبے؛ صبح پتوں کے نیچے سفید پھپھوندی۔',
    ),
    prevention: _L(
      'Avoid evening irrigation in fog. Contact your agriculture office at first signs.',
      'دھند میں شام کو پانی نہ دیں۔ پہلی علامت پر محکمہ زراعت سے رابطہ کریں۔',
    ),
    riskAfterRain: true,
  ),
];

const _ppe = _L(
  'Wear gloves, mask and full sleeves while spraying.',
  'اسپرے کرتے وقت دستانے، ماسک اور پوری آستین پہنیں۔',
);
const _noWindSpray = _L('Spray in calm weather, morning or evening.', 'پرسکون موسم میں، صبح یا شام اسپرے کریں۔');
const _keepAway = _L(
  'Keep children and animals away. Do not eat or smoke while spraying.',
  'بچوں اور جانوروں کو دور رکھیں۔ اسپرے کے دوران کچھ نہ کھائیں اور سگریٹ نہ پئیں۔',
);
const _phi = _L(
  'Respect the waiting time before harvest written on the label.',
  'لیبل پر لکھا کٹائی سے پہلے انتظار کا وقت ضرور پورا کریں۔',
);
const _registered = _L(
  'Use only government-registered products from licensed dealers.',
  'صرف حکومت سے رجسٹرڈ دوا، لائسنس یافتہ ڈیلر سے لیں۔',
);
const _noMix = _L(
  'Never mix products unless an agriculture officer advises it.',
  'زراعت افسر کے مشورے کے بغیر دوائیں آپس میں نہ ملائیں۔',
);

const List<PesticideGuide> kPesticideGuides = [
  PesticideGuide(
    id: 'w_p_aphid',
    cropTypeId: 'wheat',
    problem: _L('Aphids (Tela)', 'سست تیلہ'),
    category: _L('Insecticide for sucking pests', 'رس چوسنے والے کیڑوں کی دوا'),
    purpose: _L('Only when aphid numbers are high on many plants.', 'صرف جب بہت سے پودوں پر تیلے کی تعداد زیادہ ہو۔'),
    timing: _L('After an agriculture officer confirms the need.', 'زراعت افسر کی تصدیق کے بعد۔'),
    safety: [_ppe, _noWindSpray, _keepAway],
    warnings: [_registered, _phi, _noMix],
  ),
  PesticideGuide(
    id: 'w_p_rust',
    cropTypeId: 'wheat',
    problem: _L('Yellow rust', 'پیلی کنگی'),
    category: _L('Fungicide', 'پھپھوندی کش دوا'),
    purpose: _L(
      'To stop rust from spreading when it is found early.',
      'شروع میں ملنے پر کنگی کو پھیلنے سے روکنے کے لیے۔',
    ),
    timing: _L('At first signs, as advised by your agriculture office.', 'پہلی علامت پر، محکمہ زراعت کے مشورے سے۔'),
    safety: [_ppe, _noWindSpray, _keepAway],
    warnings: [_registered, _phi],
  ),
  PesticideGuide(
    id: 'r_p_borer',
    cropTypeId: 'rice',
    problem: _L('Stem borer', 'تنے کی سنڈی'),
    category: _L('Insecticide (granules or spray)', 'کیڑے مار دوا (دانے دار یا اسپرے)'),
    purpose: _L('When dead hearts are spreading.', 'جب سوکھی گوبھ بڑھ رہی ہو۔'),
    timing: _L('As advised after field inspection.', 'کھیت کے معائنے کے بعد مشورے سے۔'),
    safety: [_ppe, _keepAway],
    warnings: [_registered, _phi, _noMix],
  ),
  PesticideGuide(
    id: 'c_p_whitefly',
    cropTypeId: 'cotton',
    problem: _L('Whitefly / Jassid', 'سفید مکھی / سبز تیلہ'),
    category: _L('Insecticide for sucking pests', 'رس چوسنے والے کیڑوں کی دوا'),
    purpose: _L(
      'Only above the economic threshold confirmed by scouting.',
      'صرف معائنے سے تصدیق شدہ نقصان کی حد سے اوپر۔',
    ),
    timing: _L('Morning or evening, after advice.', 'مشورے کے بعد، صبح یا شام۔'),
    safety: [_ppe, _noWindSpray, _keepAway],
    warnings: [_registered, _noMix],
  ),
  PesticideGuide(
    id: 'm_p_faw',
    cropTypeId: 'maize',
    problem: _L('Fall armyworm', 'لشکری سنڈی'),
    category: _L('Insecticide applied into the whorl', 'گوبھ میں ڈالی جانے والی دوا'),
    purpose: _L('When many young plants are damaged.', 'جب بہت سے چھوٹے پودے متاثر ہوں۔'),
    timing: _L('Early stage, as advised.', 'شروع کے مرحلے میں، مشورے سے۔'),
    safety: [_ppe, _keepAway],
    warnings: [_registered, _phi],
  ),
  PesticideGuide(
    id: 'p_p_blight',
    cropTypeId: 'potato',
    problem: _L('Late blight', 'پچھیتا جھلساؤ'),
    category: _L('Fungicide', 'پھپھوندی کش دوا'),
    purpose: _L('Protect leaves in foggy weather.', 'دھند کے موسم میں پتوں کی حفاظت۔'),
    timing: _L('Before or at first signs, as advised.', 'علامت سے پہلے یا پہلی علامت پر، مشورے سے۔'),
    safety: [_ppe, _noWindSpray, _keepAway],
    warnings: [_registered, _phi],
  ),
];

const _soil = _L(
  'Check soil moisture before irrigation: squeeze soil from 10 cm deep — if it holds shape, wait.',
  'پانی سے پہلے نمی چیک کریں: 10 سینٹی میٹر گہری مٹی مٹھی میں دبائیں — اگر گولا بن جائے تو انتظار کریں۔',
);
const _rainCheck = _L(
  'Rain is expected? Review your irrigation plan.',
  'بارش متوقع ہے؟ آبپاشی کا منصوبہ دوبارہ دیکھیں۔',
);
const _windCheck = _L(
  'Avoid irrigating before strong wind — the crop may fall.',
  'تیز ہوا سے پہلے پانی نہ دیں — فصل گر سکتی ہے۔',
);
const _morning = _L(
  'Irrigate in the morning or evening to lose less water.',
  'صبح یا شام پانی دیں تاکہ پانی کم ضائع ہو۔',
);

const List<IrrigationGuide> kIrrigationGuides = [
  IrrigationGuide(
    cropTypeId: 'wheat',
    criticalStages: [
      _L('Crown root (about 3 weeks)', 'تاج جڑ (تقریباً 3 ہفتے)'),
      _L('Jointing', 'گانٹھ بننا'),
      _L('Heading', 'سٹے نکلنا'),
      _L('Grain filling', 'دانہ بننا'),
    ],
    tips: [_soil, _rainCheck, _windCheck],
  ),
  IrrigationGuide(
    cropTypeId: 'rice',
    criticalStages: [
      _L('After transplanting', 'منتقلی کے بعد'),
      _L('Panicle start', 'بالی بننا'),
      _L('Flowering', 'پھول آنا'),
    ],
    tips: [
      _L(
        'Keep 2–3 cm water; avoid deep flooding of young plants.',
        '2–3 سینٹی میٹر پانی رکھیں؛ چھوٹے پودوں پر گہرا پانی نہ رکھیں۔',
      ),
      _rainCheck,
    ],
  ),
  IrrigationGuide(
    cropTypeId: 'cotton',
    criticalStages: [_L('Squaring', 'ڈوڈی بننا'), _L('Flowering', 'پھول آنا'), _L('Boll formation', 'ٹینڈے بننا')],
    tips: [_soil, _rainCheck, _morning],
  ),
  IrrigationGuide(
    cropTypeId: 'maize',
    criticalStages: [_L('Knee-high', 'گھٹنے تک'), _L('Tasseling', 'دُمبی نکلنا'), _L('Silking', 'بال نکلنا')],
    tips: [_soil, _rainCheck, _windCheck],
  ),
  IrrigationGuide(
    cropTypeId: 'sugarcane',
    criticalStages: [
      _L('Germination', 'اگاؤ'),
      _L('Tillering', 'شاخیں نکلنا'),
      _L('Grand growth (summer)', 'تیز بڑھوتری (گرمیوں میں)'),
    ],
    tips: [_soil, _rainCheck, _morning],
  ),
  IrrigationGuide(
    cropTypeId: 'potato',
    criticalStages: [_L('Tuber start', 'آلو بننا'), _L('Bulking', 'آلو موٹا ہونا')],
    tips: [
      _soil,
      _L('Water lightly and often; do not flood ridges.', 'ہلکا اور باقاعدہ پانی دیں؛ پٹڑیاں نہ ڈوبیں۔'),
      _rainCheck,
    ],
  ),
];
