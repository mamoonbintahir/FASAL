import 'package:material_ui/material_ui.dart';

import 'package:fasal_core/catalog.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/feedback.dart';

/// Searchable district list in a bottom sheet. Returns the chosen [District].
Future<District?> pickDistrict(BuildContext context) {
  return showFasalSheet<District>(context, builder: (_) => const _DistrictSheet());
}

class _DistrictSheet extends StatefulWidget {
  const _DistrictSheet();

  @override
  State<_DistrictSheet> createState() => _DistrictSheetState();
}

class _DistrictSheetState extends State<_DistrictSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = context.lang;
    final t = Theme.of(context).textTheme;
    final q = _query.trim().toLowerCase();
    final items = kDistricts
        .where((d) => q.isEmpty || d.name.en.toLowerCase().contains(q) || d.name.ur.contains(q))
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(s.chooseDistrict, style: t.headlineSmall),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            autofocus: false,
            onChanged: (v) => setState(() => _query = v),
            style: t.bodyLarge,
            decoration: InputDecoration(
              hintText: s.searchDistrict,
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: AppRadius.mdAll,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.mdAll,
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: items.isEmpty
              ? EmptyState(emoji: '🔎', title: s.noResults, compact: true)
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, i) {
                    final d = items[i];
                    return ListTile(
                      minVerticalPadding: 12,
                      leading: const Text('📍', style: TextStyle(fontSize: 20)),
                      title: Text(d.name.of(lang), style: t.titleSmall),
                      subtitle: Text(d.province.of(lang), style: t.bodySmall),
                      onTap: () => Navigator.of(context).pop(d),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
