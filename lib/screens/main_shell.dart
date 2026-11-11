import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'careers_screen.dart';
import 'roadmap_screen.dart';
import 'interview_screen.dart';
import 'chat_screen.dart';

/// The main screen with the bottom navigation bar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  final List<String> _titles = [
    'AI Career Mate',
    'Career matches',
    'Your roadmap',
    'Interview prep',
    'Career mate',
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onOpenTab: (i) => setState(() => _tab = i)),
      const CareersScreen(),
      const RoadmapScreen(),
      const InterviewScreen(),
      const ChatScreen(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_tab])),
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.track_changes), label: 'Careers'),
          NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Roadmap'),
          NavigationDestination(
              icon: Icon(Icons.mic_none),
              selectedIcon: Icon(Icons.mic),
              label: 'Practice'),
          NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined),
              selectedIcon: Icon(Icons.smart_toy),
              label: 'Chat'),
        ],
      ),
    );
  }
}
