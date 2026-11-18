import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/basics.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/feedback.dart';

import 'package:fasal_core/models.dart';

import '../../providers/farm_providers.dart';

class _Event {
  const _Event(this.date, this.emoji, this.title, this.subtitle, {this.amount});
  final DateTime date;
  final String emoji;
  final String title;
  final String? subtitle;
  final int? amount;
}

/// Timeline of everything that happened on one crop.
class CropHistoryScreen extends ConsumerWidget {
  const CropHistoryScreen({super.key, required this.cropId});
  final String cropId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = context.lang;
    final view = ref.watch(cropViewProvider(cropId));
    final activities = ref.watch(activitiesProvider);
    final expenses = ref.watch(expensesProvider).value ?? const <ExpenseRecord>[];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: s.cropHistory,
              subtitle: view == null ? null : '${view.def.emoji} ${view.def.name.of(lang)}',
              showBack: true,
              backTooltip: s.back,
            ),
            Expanded(
              child: view == null
                  ? EmptyState(emoji: '🔍', title: s.cropNotFound)
                  : AsyncView(
                      value: activities,
                      onRetry: () => ref.invalidate(activitiesProvider),
                      data: (acts) {
                        final events = <_Event>[
                          _Event(view.crop.createdAt, '➕', s.cropAddedEvent, null),
                          _Event(
                            view.crop.sowingDate,
                            '🌱',
                            s.sowingEvent,
                            view.crop.variety.isEmpty ? null : view.crop.variety,
                          ),
                          for (final a in acts.where((a) => a.cropId == cropId))
                            _Event(
                              a.date,
                              a.type.emoji,
                              a.title?.of(lang) ?? s.activityType(a.type),
                              a.note.isEmpty ? (a.title == null ? null : s.activityType(a.type)) : a.note,
                            ),
                          for (final e in expenses.where((e) => e.cropId == cropId))
                            _Event(
                              e.date,
                              e.category.emoji,
                              s.expenseCategory(e.category),
                              e.note.isEmpty ? null : e.note,
                              amount: e.amount,
                            ),
                        ]..sort((a, b) => b.date.compareTo(a.date));

                        return PageBody(
                          children: [
                            SecondaryButton(label: s.addNote, emoji: '📝', onPressed: () => _addNote(context, ref)),
                            const Gap(16),
                            FasalCard(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Column(
                                children: [
                                  for (var i = 0; i < events.length; i++)
                                    _TimelineRow(event: events[i], isLast: i == events.length - 1),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final s = context.s;
    final text = await showFasalSheet<String>(context, builder: (_) => const NoteSheet());
    if (text == null || text.isEmpty) return;
    await ref
        .read(activitiesProvider.notifier)
        .add(
          ActivityRecord(id: newId('note'), cropId: cropId, type: ActivityType.note, date: DateTime.now(), note: text),
        );
    if (context.mounted) showSnack(context, s.noteSaved);
  }
}

/// Sheet with a single note field; pops with the entered text.
class NoteSheet extends StatefulWidget {
  const NoteSheet({super.key});

  @override
  State<NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<NoteSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return SheetBody(
      title: s.addNote,
      footer: PrimaryButton(
        label: s.save,
        onPressed: () {
          final v = _controller.text.trim();
          if (v.isNotEmpty) Navigator.of(context).pop(v);
        },
      ),
      children: [
        FasalTextField(
          label: s.note,
          hint: s.writeNote,
          controller: _controller,
          maxLines: 4,
          maxLength: 300,
          autofocus: true,
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event, required this.isLast});
  final _Event event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              EmojiIcon(event.emoji, size: 18, background: AppColors.tintGreen, boxSize: 40),
              if (!isLast) Expanded(child: Container(width: 2, color: AppColors.divider)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(event.title, style: t.titleSmall)),
                      if (event.amount != null) Text(s.rs(event.amount!), style: t.titleSmall),
                    ],
                  ),
                  Text(s.fullDate(event.date), style: t.labelSmall),
                  if (event.subtitle != null) Text(event.subtitle!, style: t.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
