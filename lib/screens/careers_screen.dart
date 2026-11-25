import 'package:flutter/material.dart';
import '../sample_data.dart';
import '../services/ai_service.dart';
import '../services/profile_service.dart';
import '../theme.dart';

class CareersScreen extends StatefulWidget {
  const CareersScreen({super.key});

  @override
  State<CareersScreen> createState() => _CareersScreenState();
}

class _CareersScreenState extends State<CareersScreen> {
  final _profileService = ProfileService();
  final _ai = AiService();

  List<Career> _careers = [];
  bool _loading = true;
  String? _errorText;
  String? _details;
  int _goalIndex = 0; // which career the user picked as goal

  @override
  void initState() {
    super.initState();
    _load();
  }

  int _pct(dynamic v) {
    final n = (v as num).toInt();
    if (n < 0) return 0;
    if (n > 100) return 100;
    return n;
  }

  // AI ya Firestore ka ek career (Map) ko Career object banata hai.
  Career? _parse(dynamic raw) {
    try {
      final m = Map<String, dynamic>.from(raw as Map);
      final skills = (m['skills'] as List).map((s) {
        final sm = Map<String, dynamic>.from(s as Map);
        return Skill(
          sm['name'].toString(),
          _pct(sm['current']),
          _pct(sm['required']),
          sm['tested'] == true,
        );
      }).toList();
      final roles = (m['roles'] as List).map((r) => r.toString()).toList();
      return Career(
        m['title'].toString(),
        _pct(m['match']),
        m['why'].toString(),
        skills,
        roles,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _errorText = null;
      _details = null;
    });

    final profile = await _profileService.loadProfile();
    List<dynamic>? raw;
    bool fromAi = false;

    final saved = profile?['careers'];
    if (!refresh && saved is List && saved.isNotEmpty) {
      raw = saved; // pehle se save kiye hue careers
    } else {
      raw = await _ai.getCareers();
      fromAi = true;
    }
    if (!mounted) return;

    final careers = <Career>[];
    for (final item in raw ?? []) {
      final c = _parse(item);
      if (c != null) careers.add(c);
    }

    if (careers.isEmpty) {
      setState(() {
        _loading = false;
        _errorText =
        'Could not get career matches. Check your internet and try again.';
        _details = _ai.lastError ??
            (raw == null
                ? 'No reply from AI.'
                : 'AI reply had an unexpected format.');
      });
      return;
    }

    if (fromAi) {
      await _profileService.saveProfile({'careers': raw});
    }

    int goal = 0;
    final goalTitle = profile?['goalCareer'];
    if (goalTitle != null) {
      final i = careers.indexWhere((c) => c.title == goalTitle);
      if (i >= 0) goal = i;
    }

    setState(() {
      _careers = careers;
      _goalIndex = goal;
      _loading = false;
    });
  }

  Future<void> _setGoal(int i) async {
    setState(() => _goalIndex = i);
    await _profileService.saveProfile({'goalCareer': _careers[i].title});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text('Finding careers that fit you...',
                style: TextStyle(color: kMuted)),
          ],
        ),
      );
    }

    if (_errorText != null) {
      return ListView(
        padding: const EdgeInsets.all(18),
        children: [
          AppCard(
            child: Column(
              children: [
                Text(_errorText!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center),
                if (_details != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_details!,
                        style: const TextStyle(color: kMuted, fontSize: 12),
                        textAlign: TextAlign.center),
                  ),
                const SizedBox(height: 12),
                BigButton(
                    text: 'Try again',
                    onPressed: () => _load(refresh: true)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        for (int i = 0; i < _careers.length; i++) _careerCard(i),
        const Text(
          'Matches are estimates based on your profile and quiz.',
          style: TextStyle(color: kMuted, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        TextButton.icon(
          onPressed: () => _load(refresh: true),
          icon: const Icon(Icons.refresh),
          label: const Text('Update my matches'),
        ),
      ],
    );
  }

  Widget _careerCard(int i) {
    final c = _careers[i];
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
            onPressed: isGoal ? null : () => _setGoal(i),
          ),
        ],
      ),
    );
  }
}