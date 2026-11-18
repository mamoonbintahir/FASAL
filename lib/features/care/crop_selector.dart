import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/farm_providers.dart';
import '../../providers/repository_providers.dart';

/// What a guidance screen is showing: a farmer's crop, or just a crop type
/// (when the farmer has no crops yet and is browsing).
class CropTarget {
  const CropTarget({required this.cropTypeId, this.view});
  final String cropTypeId;
  final CropView? view;
  String get key => view?.crop.id ?? 'type:$cropTypeId';
}

/// Horizontal chips to choose which crop the guidance is for.
class CropSelector extends ConsumerWidget {
  const CropSelector({super.key, required this.selectedKey, required this.onChanged});

  final String? selectedKey;
  final ValueChanged<CropTarget> onChanged;

  static List<CropTarget> targets(WidgetRef ref) {
    final views = ref.watch(cropViewsProvider).value ?? const <CropView>[];
    if (views.isNotEmpty) return [for (final v in views) CropTarget(cropTypeId: v.def.id, view: v)];
    return [for (final d in ref.watch(cropCatalogProvider).all()) CropTarget(cropTypeId: d.id)];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = context.lang;
    final catalog = ref.watch(cropCatalogProvider);
    final list = targets(ref);
    if (list.length <= 1) return const SizedBox.shrink();
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        children: [
          for (final tgt in list)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Builder(
                builder: (context) {
                  final def = catalog.byId(tgt.cropTypeId);
                  final field = tgt.view?.crop.fieldName ?? '';
                  final selected = tgt.key == selectedKey;
                  return ChoiceChip(
                    label: Text('${def?.emoji ?? ''} ${def?.name.of(lang) ?? ''}${field.isEmpty ? '' : ' · $field'}'),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: AppColors.primaryContainer,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                    labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
                    onSelected: (_) => onChanged(tgt),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Picks the initial target: the requested crop, else the first one.
CropTarget? initialTarget(WidgetRef ref, String? cropId) {
  final list = CropSelector.targets(ref);
  if (list.isEmpty) return null;
  for (final t in list) {
    if (t.view?.crop.id == cropId) return t;
  }
  return list.first;
}
