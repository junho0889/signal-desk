import 'package:flutter/material.dart';

import 'premium_tokens.dart';

class SignalDeskRiskCallout extends StatelessWidget {
  const SignalDeskRiskCallout({
    super.key,
    required this.riskFlags,
  });

  final List<String> riskFlags;

  @override
  Widget build(BuildContext context) {
    if (riskFlags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: SignalDeskSpacing.s8),
      padding: const EdgeInsets.all(SignalDeskSpacing.s12),
      decoration: BoxDecoration(
        color: SignalDeskPalette.risk.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SignalDeskPalette.risk, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.report_problem_outlined, size: 18),
          ),
          const SizedBox(width: SignalDeskSpacing.s8),
          Expanded(
            child: Text(
              riskFlags.join(', '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: SignalDeskPalette.risk,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
