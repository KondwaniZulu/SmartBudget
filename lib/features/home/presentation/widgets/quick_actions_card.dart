import 'package:flutter/material.dart';
import 'package:smartbudget_app/features/home/domain/quick_action.dart';
import 'package:smartbudget_app/features/home/presentation/widgets/section_card.dart';

class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({
    super.key,
    required this.actions,
    required this.onActionTap,
  });

  final List<QuickAction> actions;
  final ValueChanged<QuickAction> onActionTap;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      borderRadius: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool compact = constraints.maxWidth < 420;

              if (compact) {
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: actions
                      .map(
                        (action) => SizedBox(
                          width: (constraints.maxWidth - 10) / 2,
                          child: _ActionButton(
                            action: action,
                            onTap: () => onActionTap(action),
                          ),
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                children: List.generate(actions.length, (index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index == actions.length - 1 ? 0 : 8,
                      ),
                      child: _ActionButton(
                        action: actions[index],
                        onTap: () => onActionTap(actions[index]),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.onTap});

  final QuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 94,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: action.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(action.icon, color: action.color),
              Text(
                action.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
