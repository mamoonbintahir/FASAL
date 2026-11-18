import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fasal_core/catalog.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/basics.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/feedback.dart';

import 'package:fasal_core/models.dart';

import '../../data/repositories/repositories.dart';
import '../../providers/farm_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_provider.dart';
import 'district_picker.dart';

/// "Tell us about you" — first-run setup (step 1 of 2) and later profile editing.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.isSetup = false});

  final bool isSetup;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _farmName = TextEditingController();
  final _area = TextEditingController();
  String? _districtEn;
  String _provinceEn = '';
  AreaUnit _unit = AreaUnit.acre;
  bool _locating = false;
  bool _saving = false;
  bool _submitted = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _unit = ref.read(settingsProvider).areaUnit;
    ref.read(profileProvider.future).then((p) {
      if (!mounted || p == null || _loaded) return;
      setState(() {
        _loaded = true;
        _name.text = p.name;
        _farmName.text = p.farmName;
        _area.text = p.farmArea > 0 ? Fmt.area(p.farmArea) : '';
        _districtEn = p.district.isEmpty ? null : p.district;
        _provinceEn = p.province;
        _unit = p.areaUnit;
      });
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _farmName.dispose();
    _area.dispose();
    super.dispose();
  }

  String? get _districtLabel {
    if (_districtEn == null) return null;
    final d = findDistrict(_districtEn!);
    final lang = context.lang;
    if (d == null) return _provinceEn.isEmpty ? _districtEn : '$_districtEn, $_provinceEn';
    return '${d.name.of(lang)}, ${d.province.of(lang)}';
  }

  Future<void> _useLocation() async {
    final s = context.s;
    setState(() => _locating = true);
    final result = await ref.read(locationServiceProvider).detectDistrict();
    if (!mounted) return;
    setState(() => _locating = false);
    if (result.outcome == LocationOutcome.found && result.districtEn != null) {
      setState(() {
        _districtEn = result.districtEn;
        _provinceEn = result.provinceEn ?? '';
      });
      showSnack(context, s.locationDemoSet(_districtLabel ?? result.districtEn!));
    } else {
      // Permission denied / unavailable → fall back to manual choice.
      showSnack(context, s.locationDenied);
      await _pickDistrict();
    }
  }

  Future<void> _pickDistrict() async {
    final d = await pickDistrict(context);
    if (d != null && mounted) {
      setState(() {
        _districtEn = d.name.en;
        _provinceEn = d.province.en;
      });
    }
  }

  Future<void> _save() async {
    final s = context.s;
    setState(() => _submitted = true);
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _districtEn == null) return;
    setState(() => _saving = true);
    final profile = UserProfile(
      name: _name.text.trim(),
      district: _districtEn!,
      province: _provinceEn,
      farmName: _farmName.text.trim(),
      farmArea: double.parse(_area.text.trim()),
      areaUnit: _unit,
    );
    await ref.read(profileProvider.notifier).save(profile);
    ref.read(settingsProvider.notifier).setAreaUnit(_unit);
    if (!mounted) return;
    setState(() => _saving = false);
    if (widget.isSetup) {
      context.go('/setup/crop');
    } else {
      showSnack(context, s.profileSaved);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final v = Validators(s);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ScreenHeader(
                title: widget.isSetup ? s.tellUsAboutYou : s.profile,
                showBack: true,
                backTooltip: s.back,
                onBack: widget.isSetup ? () => context.go('/onboarding') : null,
              ),
              if (widget.isSetup)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: StageSegments(count: 2, current: 0, onDark: false),
                ),
              Expanded(
                child: PageBody(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    FasalTextField(
                      fieldKey: const Key('profile_name'),
                      label: '${s.yourName} (${s.optional})',
                      hint: s.yourNameHint,
                      controller: _name,
                      validator: v.optionalName,
                      textInputAction: TextInputAction.next,
                    ),
                    const Gap(18),
                    PickerField(
                      label: s.villageDistrict,
                      value: _districtLabel,
                      placeholder: s.chooseDistrict,
                      trailing: Icons.search_rounded,
                      errorText: _submitted && _districtEn == null ? s.errDistrictRequired : null,
                      onTap: _pickDistrict,
                    ),
                    const Gap(10),
                    Material(
                      color: AppColors.infoContainer,
                      borderRadius: AppRadius.lgAll,
                      child: InkWell(
                        borderRadius: AppRadius.lgAll,
                        onTap: _locating ? null : _useLocation,
                        child: SizedBox(
                          height: 50,
                          child: Center(
                            child: _locating
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Text(
                                          s.detectingLocation,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: t.titleSmall?.copyWith(color: AppColors.info),
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const EmojiIcon('📍', size: 18),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          s.useMyLocation,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: t.titleSmall?.copyWith(color: AppColors.info),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const Gap(18),
                    FasalTextField(
                      label: '${s.farmName} (${s.optional})',
                      hint: s.farmNameHint,
                      controller: _farmName,
                      validator: v.optionalName,
                      textInputAction: TextInputAction.next,
                    ),
                    const Gap(18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: FasalTextField(
                            fieldKey: const Key('profile_area'),
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
                    const Gap(32),
                    PrimaryButton(
                      key: const Key('profile_continue'),
                      label: widget.isSetup ? s.continueLabel : s.save,
                      loading: _saving,
                      onPressed: _save,
                    ),
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

/// Bottom sheet to choose an area unit.
Future<AreaUnit?> pickAreaUnit(BuildContext context, AreaUnit current) {
  final s = context.s;
  return showFasalSheet<AreaUnit>(
    context,
    builder: (ctx) => SheetBody(
      title: s.unit,
      children: [
        for (final u in AreaUnit.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ChoiceTile(
              label: s.areaUnitLabel(u),
              selected: u == current,
              height: 56,
              onTap: () => Navigator.of(ctx).pop(u),
            ),
          ),
      ],
    ),
  );
}
