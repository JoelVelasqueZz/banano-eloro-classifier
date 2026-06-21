import 'package:flutter/material.dart';

/// Horizontal bar chart showing every class probability, sorted from
/// highest to lowest — similar to the matplotlib bar plots used in the
/// training notebook.
class ProbabilityBars extends StatelessWidget {
  final List<String> classes;
  final List<double> probabilities;

  const ProbabilityBars({
    super.key,
    required this.classes,
    required this.probabilities,
  });

  @override
  Widget build(BuildContext context) {
    final entries = List.generate(
      classes.length,
      (i) => (label: classes[i], prob: probabilities[i]),
    )..sort((a, b) => b.prob.compareTo(a.prob));

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  entry.label,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: entry.prob.clamp(0.0, 1.0),
                    minHeight: 14,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  '${(entry.prob * 100).toStringAsFixed(1)}%',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
