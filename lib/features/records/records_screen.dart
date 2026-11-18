import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/basics.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/feedback.dart';

import 'package:fasal_core/models.dart';

import '../../providers/core_providers.dart';
import '../../providers/farm_providers.dart';

/// Farm records: activities log and expense tracking.
class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final expenses = ref.watch(expensesProvider);
    final total = (expenses.value ?? const <ExpenseRecord>[]).fold<int>(0, (sum, e) => sum + e.amount);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: s.records),
            Expanded(
              child: PageBody(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  FasalCard(
                    color: AppColors.secondary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.totalSpentSeason,
                          style: t.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                        ),
                        Text(
                          s.rs(total),
                          style: t.displaySmall?.copyWith(color: Colors.white, fontFamily: 'Manrope'),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                  SegmentedTabs(
                    labels: [s.activities, s.expenses],
                    selected: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                  const Gap(16),
                  if (_tab == 0) const _ActivitiesList() else const _ExpensesList(),
                  const Gap(16),
                  PrimaryButton(
                    key: Key(_tab == 0 ? 'add_activity' : 'add_expense'),
                    label: _tab == 0 ? s.addActivity : s.addExpense,
                    onPressed: () => showFasalSheet<void>(
                      context,
                      builder: (_) => _tab == 0 ? const _AddActivitySheet() : const _AddExpenseSheet(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _cropLabel(WidgetRef ref, BuildContext context, String? cropId) {
  if (cropId == null) return context.s.wholeFarm;
  final v = ref.watch(cropViewProvider(cropId));
  return v == null ? context.s.wholeFarm : '${v.def.emoji} ${v.def.name.of(context.lang)}';
}

class _ActivitiesList extends ConsumerWidget {
  const _ActivitiesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = context.lang;
    return AsyncView(
      value: ref.watch(activitiesProvider),
      onRetry: () => ref.invalidate(activitiesProvider),
      data: (list) {
        if (list.isEmpty) {
          return FasalCard(
            child: EmptyState(emoji: '📒', title: s.noActivities, compact: true),
          );
        }
        return FasalCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < list.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _RecordRow(
                  emoji: list[i].type.emoji,
                  title: list[i].title?.of(lang) ?? s.activityType(list[i].type),
                  subtitle: [
                    s.shortDate(list[i].date),
                    _cropLabel(ref, context, list[i].cropId),
                    if (list[i].note.isNotEmpty) list[i].note,
                  ].join(' · '),
                  onDelete: () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: s.deleteRecordTitle,
                      body: list[i].title?.of(lang) ?? s.activityType(list[i].type),
                      confirmLabel: s.delete,
                      destructive: true,
                    );
                    if (!ok) return;
                    await ref.read(activitiesProvider.notifier).delete(list[i]);
                    if (context.mounted) showSnack(context, s.recordDeleted);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ExpensesList extends ConsumerWidget {
  const _ExpensesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    return AsyncView(
      value: ref.watch(expensesProvider),
      onRetry: () => ref.invalidate(expensesProvider),
      data: (list) {
        if (list.isEmpty) {
          return FasalCard(
            child: EmptyState(emoji: '💰', title: s.noExpenses, compact: true),
          );
        }
        return FasalCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < list.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _RecordRow(
                  emoji: list[i].category.emoji,
                  title: s.expenseCategory(list[i].category),
                  subtitle: [
                    s.shortDate(list[i].date),
                    _cropLabel(ref, context, list[i].cropId),
                    if (list[i].note.isNotEmpty) list[i].note,
                  ].join(' · '),
                  trailing: s.rs(list[i].amount),
                  onDelete: () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: s.deleteRecordTitle,
                      body: '${s.expenseCategory(list[i].category)} · ${s.rs(list[i].amount)}',
                      confirmLabel: s.delete,
                      destructive: true,
                    );
                    if (!ok) return;
                    await ref.read(expensesProvider.notifier).delete(list[i]);
                    if (context.mounted) showSnack(context, s.recordDeleted);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onDelete,
    this.trailing,
  });
  final String emoji;
  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      onLongPress: onDelete,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            EmojiIcon(emoji, size: 20, background: AppColors.tintGrey, boxSize: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.titleSmall),
                  Text(subtitle, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (trailing != null) Text(trailing!, style: t.titleSmall),
            IconButton(
              tooltip: context.s.delete,
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Add sheets ─────────────────────────

class _CropChooser extends ConsumerWidget {
  const _CropChooser({required this.selected, required this.onChanged});
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = context.lang;
    final views = ref.watch(cropViewsProvider).value ?? const <CropView>[];
    final t = Theme.of(context).textTheme;
    Widget chip(String label, String? id) => ChoiceChip(
      label: Text(label),
      selected: selected == id,
      showCheckmark: false,
      selectedColor: AppColors.primaryContainer,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected == id ? AppColors.primary : AppColors.border),
      labelStyle: t.labelMedium?.copyWith(color: AppColors.textPrimary),
      onSelected: (_) => onChanged(id),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.crop, style: t.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            chip('🏡 ${s.wholeFarm}', null),
            for (final v in views) chip('${v.def.emoji} ${v.def.name.of(lang)}', v.crop.id),
          ],
        ),
      ],
    );
  }
}

class _DateField extends ConsumerWidget {
  const _DateField({required this.date, required this.onChanged});
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final today = ref.watch(clockProvider)();
    return PickerField(
      label: s.date,
      value: s.fullDate(date),
      placeholder: s.selectDate,
      trailing: Icons.calendar_month_rounded,
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: today.subtract(const Duration(days: 400)),
          lastDate: today,
        );
        if (d != null) onChanged(d);
      },
    );
  }
}

class _AddActivitySheet extends ConsumerStatefulWidget {
  const _AddActivitySheet();

  @override
  ConsumerState<_AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends ConsumerState<_AddActivitySheet> {
  ActivityType? _type;
  String? _cropId;
  DateTime _date = DateTime.now();
  final _note = TextEditingController();
  bool _submitted = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final views = ref.read(cropViewsProvider).value ?? const <CropView>[];
    if (views.length == 1) _cropId = views.first.crop.id;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = context.s;
    setState(() => _submitted = true);
    if (_type == null) return;
    setState(() => _saving = true);
    await ref
        .read(activitiesProvider.notifier)
        .add(ActivityRecord(id: newId('act'), cropId: _cropId, type: _type!, date: _date, note: _note.text.trim()));
    if (!mounted) return;
    showSnack(context, s.recordAdded);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    return SheetBody(
      title: s.addActivityTitle,
      footer: PrimaryButton(key: const Key('save_activity'), label: s.save, loading: _saving, onPressed: _save),
      children: [
        TileGrid(
          minTileWidth: 90,
          children: [
            for (final type in ActivityType.values.where((x) => x != ActivityType.other))
              ChoiceTile(
                emoji: type.emoji,
                label: s.activityType(type),
                selected: _type == type,
                height: 84,
                onTap: () => setState(() => _type = type),
              ),
          ],
        ),
        if (_submitted && _type == null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(s.errCategory, style: t.bodySmall?.copyWith(color: AppColors.error)),
          ),
        const Gap(AppSpacing.md),
        _CropChooser(selected: _cropId, onChanged: (v) => setState(() => _cropId = v)),
        const Gap(AppSpacing.md),
        _DateField(date: _date, onChanged: (d) => setState(() => _date = d)),
        const Gap(AppSpacing.md),
        FasalTextField(label: '${s.note} (${s.optional})', hint: s.noteHint, controller: _note, maxLength: 200),
      ],
    );
  }
}

class _AddExpenseSheet extends ConsumerStatefulWidget {
  const _AddExpenseSheet();

  @override
  ConsumerState<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<_AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  ExpenseCategory? _category;
  String? _cropId;
  DateTime _date = DateTime.now();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  bool _submitted = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final views = ref.read(cropViewsProvider).value ?? const <CropView>[];
    if (views.length == 1) _cropId = views.first.crop.id;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = context.s;
    setState(() => _submitted = true);
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok || _category == null) return;
    setState(() => _saving = true);
    await ref
        .read(expensesProvider.notifier)
        .add(
          ExpenseRecord(
            id: newId('exp'),
            cropId: _cropId,
            category: _category!,
            amount: int.parse(_amount.text.trim().replaceAll(',', '')),
            date: _date,
            note: _note.text.trim(),
          ),
        );
    if (!mounted) return;
    showSnack(context, s.recordAdded);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    return Form(
      key: _formKey,
      child: SheetBody(
        title: s.addExpenseTitle,
        footer: PrimaryButton(key: const Key('save_expense'), label: s.save, loading: _saving, onPressed: _save),
        children: [
          TileGrid(
            minTileWidth: 90,
            children: [
              for (final c in ExpenseCategory.values)
                ChoiceTile(
                  key: Key('exp_${c.name}'),
                  emoji: c.emoji,
                  label: s.expenseCategory(c),
                  selected: _category == c,
                  height: 84,
                  onTap: () => setState(() => _category = c),
                ),
            ],
          ),
          if (_submitted && _category == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(s.errCategory, style: t.bodySmall?.copyWith(color: AppColors.error)),
            ),
          const Gap(AppSpacing.md),
          FasalTextField(
            fieldKey: const Key('expense_amount'),
            label: s.amountRs,
            hint: '5000',
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: Validators(s).amount,
          ),
          const Gap(AppSpacing.md),
          _CropChooser(selected: _cropId, onChanged: (v) => setState(() => _cropId = v)),
          const Gap(AppSpacing.md),
          _DateField(date: _date, onChanged: (d) => setState(() => _date = d)),
          const Gap(AppSpacing.md),
          FasalTextField(label: '${s.note} (${s.optional})', hint: s.noteHint, controller: _note, maxLength: 200),
        ],
      ),
    );
  }
}
