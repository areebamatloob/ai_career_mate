import 'package:flutter/material.dart';
import '../sample_data.dart';
import '../services/ai_service.dart';
import '../services/profile_service.dart';
import '../theme.dart';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  final _profileService = ProfileService();
  final _ai = AiService();

  List<RoadmapStep> _steps = [];
  final Set<int> _done = {}; // numbers of the steps that are ticked
  String _goalTitle = '';
  bool _loading = true;
  String? _errorText;
  String? _details;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Goal career ka naam (user ne chuna ho, warna pehli career).
  String? _currentGoal(Map<String, dynamic>? p) {
    if (p == null) return null;
    final careers = p['careers'];
    if (careers is! List || careers.isEmpty) return null;
    final g = p['goalCareer'];
    for (final c in careers) {
      if (c is Map && c['title'] == g) return g.toString();
    }
    final first = careers.first;
    return first is Map ? first['title']?.toString() : null;
  }

  RoadmapStep? _parse(dynamic raw) {
    try {
      final m = Map<String, dynamic>.from(raw as Map);
      int weeks = (m['weeks'] as num).toInt();
      if (weeks < 1) weeks = 1;
      return RoadmapStep(
        m['title'].toString(),
        m['why'].toString(),
        weeks,
        m['resource'].toString(),
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

    final p = await _profileService.loadProfile();
    final goal = _currentGoal(p);
    if (goal == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = 'Open the Careers tab first to get your career matches.';
      });
      return;
    }

    List<dynamic>? raw;
    bool fromAi = false;
    final saved = p?['roadmap'];
    if (!refresh &&
        saved is List &&
        saved.isNotEmpty &&
        p?['roadmapFor'] == goal) {
      raw = saved; // pehle se save kiya hua roadmap
    } else {
      raw = await _ai.getRoadmap();
      fromAi = true;
    }
    if (!mounted) return;

    final steps = <RoadmapStep>[];
    for (final item in raw ?? []) {
      final s = _parse(item);
      if (s != null) steps.add(s);
    }

    if (steps.isEmpty) {
      setState(() {
        _loading = false;
        _errorText = 'Could not make your roadmap. Please try again.';
        _details = _ai.lastError ??
            (raw == null
                ? 'No reply from AI.'
                : 'AI reply had an unexpected format.');
      });
      return;
    }

    final done = <int>{};
    if (fromAi) {
      // Naya roadmap: purani ticks khatam, naya save.
      await _profileService.saveProfile({
        'roadmap': raw,
        'roadmapFor': goal,
        'roadmapDone': <int>[],
      });
    } else {
      final d = p?['roadmapDone'];
      if (d is List) {
        for (final x in d) {
          if (x is num && x.toInt() >= 0 && x.toInt() < steps.length) {
            done.add(x.toInt());
          }
        }
      }
    }

    setState(() {
      _steps = steps;
      _goalTitle = goal;
      _done
        ..clear()
        ..addAll(done);
      _loading = false;
    });
  }

  Future<void> _toggle(int i, bool checked) async {
    setState(() {
      if (checked) {
        _done.add(i);
      } else {
        _done.remove(i);
      }
    });
    final list = _done.toList()..sort();
    await _profileService.saveProfile({'roadmapDone': list});
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
            Text('Making your roadmap...', style: TextStyle(color: kMuted)),
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

    final progress = _done.length / _steps.length;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        AppCard(
          child: Row(
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 9,
                        backgroundColor: kLine,
                        color: kPrimary,
                      ),
                    ),
                    Text('${(progress * 100).round()}%',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_goalTitle,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    Text('${_done.length} of ${_steps.length} steps done',
                        style: const TextStyle(color: kMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        for (int i = 0; i < _steps.length; i++)
          AppCard(
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: kPrimary,
              value: _done.contains(i),
              onChanged: (checked) => _toggle(i, checked == true),
              title: Text(_steps[i].title,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_steps[i].why} · about ${_steps[i].weeks} weeks'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const SmallTag('Resource'),
                        Text(_steps[i].resource),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        const Text(
          'This roadmap is made for your goal career. Updating it clears your ticks.',
          style: TextStyle(color: kMuted, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        TextButton.icon(
          onPressed: () => _load(refresh: true),
          icon: const Icon(Icons.refresh),
          label: const Text('Update my roadmap'),
        ),
      ],
    );
  }
}