import 'package:flutter/material.dart';
import '../sample_data.dart';
import '../theme.dart';

class CareersScreen extends StatefulWidget {
  const CareersScreen({super.key});

  @override
  State<CareersScreen> createState() => _CareersScreenState();
}

class _CareersScreenState extends State<CareersScreen> {
  int _goalIndex = 0; // which career the user picked as goal

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        for (int i = 0; i < sampleCareers.length; i++) _careerCard(i),
      ],
    );
  }

  Widget _careerCard(int i) {
    final c = sampleCareers[i];
    final isGoal = i == _goalIndex;

    // This removes the thin lines that ExpansionTile draws by default.
    final noLines = Theme.of(context).copyWith(dividerColor: Colors.transparent);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(c.title,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800)),
                        if (isGoal) const SmallTag('Your goal'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(c.why, style: const TextStyle(color: kMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text('${c.match}%',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: kPrimary)),
            ],
          ),
          Theme(
            data: noLines,
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: const Text('Skill gap',
                  style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
              children: [
                for (final s in c.skills)
                  SkillBar(
                      name: s.name,
                      current: s.current,
                      required: s.required,
                      tested: s.tested),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Green is your level. Yellow is what the role needs.',
                    style: TextStyle(color: kMuted, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Theme(
            data: noLines,
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: const Text('Roles to search for',
                  style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
              children: [
                for (final r in c.roles)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $r'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          BigButton(
            text: isGoal ? 'This is your goal' : 'Set as my goal',
            soft: true,
            onPressed: isGoal ? null : () => setState(() => _goalIndex = i),
          ),
        ],
      ),
    );
  }
}
