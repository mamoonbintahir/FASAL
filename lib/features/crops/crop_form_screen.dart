import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/districts.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/basics.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/feedback.dart';
import '../../data/models/crop.dart';
import '../../data/models/user_profile.dart';
import '../../providers/core_providers.dart';
import '../../providers/farm_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_provider.dart';
import '../settings/district_picker.dart';
import '../settings/profile_screen.dart' show pickAreaUnit;

enum CropFormMode { setup, add, edit }

/// Add crop (from app or as setup step 2) and edit crop.
class CropFormScreen extends ConsumerStatefulWidget {
  const CropFormScreen.add({super.key}) : mode = CropFormMode.add, cropId = null;
  const CropFormScreen.setup({super.key}) : mode = CropFormMode.setup, cropId = null;
  const CropFormScreen.edit({super.key, required String this.cropId}) : mode = CropFormMode.edit;

  final CropFormMode mode;
  final String? cropId;

  @override
  ConsumerState<CropFormScreen> createState() => _CropFormScreenState();
}

class _CropFormScreenState extends ConsumerState<CropFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _area = TextEditingController();
  final _seed = TextEditingController();
  final _field = TextEditingController();
  String? _cropTypeId;
  String _variety = '';
  DateTime? _sowingDate;
  AreaUnit _unit = AreaUnit.acre;
  String _locationEn = '';
  bool _submitted = false;
  bool _saving = false;
  Crop? _editing;

  @override
  void initState() {
    super.initState();
    _unit = ref.read(settingsProvider).areaUnit;
    if (widget.mode == CropFormMode.edit) {
      final c = ref.read(cropViewProvider(widget.cropId!))?.crop;
      if (c != null) {
        _editing = c;
        _cropTypeId = c.cropTypeId;
        _variety = c.variety;
        _sowingDate = c.sowingDate;
        _unit = c.areaUnit;
        _area.text = Fmt.area(c.area);
        _seed.text = c.seedKg == null ? '' : Fmt.area(c.seedKg!);
        _field.text = c.fieldName;
        _locationEn = c.location;
      }
    } else {
      // Pre-fill area/location from the farmer profile.
      final p = ref.read(profileProvider).value;
      if (p != null) {
        if (p.farmArea > 0) _area.text = Fmt.area(p.farmArea);
        _unit = p.areaUnit;
        _locationEn = p.district;
      }
    }
  }

  @override
  void dispose() {
    _area.dispose();
    _seed.dispose();
    _field.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = ref.read(clockProvider)();
    final picked = await showDatePicker(
      context: context,
      initialDate: _sowingDate ?? today,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today.add(const Duration(days: 60)),
      helpText: context.s.sowingDate,
    );
    if (picked != null) setState(() => _sowingDate = picked);
  }

  Future<void> _save() async {
    final s = context.s;
    setState(() => _submitted = true);
    final today = ref.read(clockProvider)();
    final formOk = _formKey.currentState?.validate() ?? false;
    final dateErr = Validators(s).sowingDate(_sowingDate, AppDates.dateOnly(today));
    if (!formOk || _cropTypeId == null || dateErr != null) return;

    setState(() => _saving = true);
    final notifier = ref.read(cropsProvider.notifier);
    final area = double.parse(_area.text.trim());
    final seed = double.tryParse(_seed.text.trim());
    try {
      if (_editing != null) {
        await notifier.updateCrop(
          _editing!.copyWith(
            cropTypeId: _cropTypeId,
            variety: _variety,
            sowingDate: _sowingDate,
            area: area,
            areaUnit: _unit,
            fieldName: _field.text.trim(),
            seedKg: seed,
            clearSeed: seed == null,
            location: _locationEn,
          ),
        );
      } else {
        await notifier.add(
          Crop(
            id: newId('crop'),
            cropTypeId: _cropTypeId!,
            variety: _variety,
            sowingDate: AppDates.dateOnly(_sowingDate!),
            area: area,
            areaUnit: _unit,
            fieldName: _field.text.trim(),
            seedKg: seed,
            location: _locationEn,
            createdAt: DateTime.now(),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showSnack(context, s.genericErrorTitle);
      }
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    switch (widget.mode) {
      case CropFormMode.setup:
        ref.read(settingsProvider.notifier).completeSetup();
        context.go('/home');
      case CropFormMode.add:
        showSnack(context, s.cropAdded);
        context.pop();
      case CropFormMode.edit:
        showSnack(context, s.cropUpdated);
        context.pop();
    }
  }

  void _skipForNow() {
    ref.read(settingsProvider.notifier).completeSetup();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = context.lang;
    final t = Theme.of(context).textTheme;
    final v = Validators(s);
    final catalog = ref.watch(cropCatalogProvider).all();
    final selectedDef = _cropTypeId == null ? null : ref.read(cropCatalogProvider).byId(_cropTypeId!);
    final today = AppDates.dateOnly(ref.watch(clockProvider)());
    final dateError = _submitted ? v.sowingDate(_sowingDate, today) : null;
    final district = _locationEn.isEmpty ? null : findDistrict(_locationEn);

    if (widget.mode == CropFormMode.edit && _editing == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: s.editCrop, showBack: true, backTooltip: s.back),
              Expanded(
                child: EmptyState(emoji: '🔍', title: s.cropNotFound),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ScreenHeader(
                title: widget.mode == CropFormMode.edit ? s.editCrop : s.addYourCrop,
                showBack: true,
                backTooltip: s.back,
                onBack: widget.mode == CropFormMode.setup ? () => context.go('/setup') : null,
              ),
              if (widget.mode == CropFormMode.setup)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: StageSegments(count: 2, current: 1, onDark: false),
                ),
              Expanded(
                child: PageBody(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    Text(s.whichCrop, style: t.labelMedium),
                    const Gap(8),
                    TileGrid(
                      children: [
                        for (final def in catalog)
                          ChoiceTile(
                            key: Key('crop_${def.id}'),
                            emoji: def.emoji,
                            label: def.name.of(lang),
                            selected: _cropTypeId == def.id,
                            onTap: () => setState(() {
                              if (_cropTypeId != def.id) _variety = '';
                              _cropTypeId = def.id;
                            }),
                          ),
                      ],
                    ),
                    if (_submitted && _cropTypeId == null)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 12, top: 6),
                        child: Text(s.errSelectCrop, style: t.bodySmall?.copyWith(color: AppColors.error)),
                      ),
                    if (selectedDef != null && selectedDef.varieties.isNotEmpty) ...[
                      const Gap(18),
                      Text('${s.variety} (${s.optional})', style: t.labelMedium),
                      const Gap(8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final name in selectedDef.varieties)
                            ChoiceChip(
                              label: Text(name),
                              selected: _variety == name,
                              showCheckmark: false,
                              selectedColor: AppColors.primaryContainer,
                              backgroundColor: Colors.white,
                              side: BorderSide(color: _variety == name ? AppColors.primary : AppColors.border),
                              labelStyle: t.labelMedium?.copyWith(color: AppColors.textPrimary),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              onSelected: (sel) => setState(() => _variety = sel ? name : ''),
                            ),
                        ],
                      ),
                    ],
                    const Gap(18),
                    PickerField(
                      label: s.sowingDate,
                      value: _sowingDate == null ? null : s.fullDate(_sowingDate!),
                      placeholder: s.selectDate,
                      trailing: Icons.calendar_month_rounded,
                      errorText: dateError,
                      onTap: _pickDate,
                    ),
                    const Gap(18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: FasalTextField(
                            fieldKey: const Key('crop_area'),
                            label: s.farmArea,
                            hint: '5',
                            controller: _area,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                            validator: v.area,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: PickerField(
                            label: s.unit,
                            value: s.areaUnitLabel(_unit),
                            placeholder: s.unit,
                            onTap: () async {
                              final u = await pickAreaUnit(context, _unit);
                              if (u != null) setState(() => _unit = u);
                            },
                          ),
                        ),
                      ],
                    ),
                    const Gap(18),
                    FasalTextField(
                      label: '${s.seedUsedKg} (${s.optional})',
                      hint: '50',
                      controller: _seed,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      validator: v.optionalPositiveNumber,
                    ),
                    const Gap(18),
                    FasalTextField(
                      label: '${s.fieldName} (${s.optional})',
                      hint: s.fieldNameHint,
                      controller: _field,
                      validator: v.optionalName,
                    ),
                    const Gap(18),
                    PickerField(
                      label: '${s.location} (${s.optional})',
                      value: district == null
                          ? (_locationEn.isEmpty ? null : _locationEn)
                          : '${district.name.of(lang)}, ${district.province.of(lang)}',
                      placeholder: s.chooseDistrict,
                      trailing: Icons.place_outlined,
                      onTap: () async {
                        final d = await pickDistrict(context);
                        if (d != null) setState(() => _locationEn = d.name.en);
                      },
                    ),
                    const Gap(28),
                    PrimaryButton(
                      key: const Key('crop_save'),
                      label: widget.mode == CropFormMode.setup ? s.startFasal : s.saveCrop,
                      loading: _saving,
                      onPressed: _save,
                    ),
                    if (widget.mode == CropFormMode.setup) ...[
                      const Gap(8),
                      Center(
                        child: TextButton(
                          key: const Key('crop_skip'),
                          onPressed: _skipForNow,
                          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                          child: Text(s.addLater, style: t.titleSmall?.copyWith(color: AppColors.textSecondary)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
