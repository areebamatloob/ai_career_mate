import 'package:flutter/material.dart';
import '../sample_data.dart';
import '../theme.dart';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  final Set<int> _done = {}; // numbers of the steps that are ticked

  @override
  Widget build(BuildContext context) {
    final progress = _done.length / sampleRoadmap.length;

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
                    Text(sampleCareers.first.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    Text('${_done.length} of ${sampleRoadmap.length} steps done',
                        style: const TextStyle(color: kMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        for (int i = 0; i < sampleRoadmap.length; i++)
          AppCard(
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: kPrimary,
              value: _done.contains(i),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _done.add(i);
                  } else {
                    _done.remove(i);
                  }
                });
              },
              title: Text(sampleRoadmap[i].title,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${sampleRoadmap[i].why} · about ${sampleRoadmap[i].weeks} weeks'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const SmallTag('Resource'),
                        Text(sampleRoadmap[i].resource),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
