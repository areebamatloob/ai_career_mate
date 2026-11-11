// SAMPLE DATA ONLY. These screens are the design stage of the app.
// Later, this data will come from the backend (login, database, AI).

class Skill {
  final String name;
  final int current;
  final int required;
  final bool tested;
  const Skill(this.name, this.current, this.required, this.tested);
}

class Career {
  final String title;
  final int match;
  final String why;
  final List<Skill> skills;
  final List<String> roles;
  const Career(this.title, this.match, this.why, this.skills, this.roles);
}

class RoadmapStep {
  final String title;
  final String why;
  final int weeks;
  final String resource;
  const RoadmapStep(this.title, this.why, this.weeks, this.resource);
}

class QuizQuestion {
  final String skill;
  final String question;
  final List<String> options;
  final int answer; // index of the correct option
  const QuizQuestion(this.skill, this.question, this.options, this.answer);
}

const String sampleName = 'Student';

const List<QuizQuestion> sampleQuiz = [
  QuizQuestion('Web Page Making', 'Which tag makes the biggest heading in HTML?',
      ['<h6>', '<h1>', '<head>', '<p>'], 1),
  QuizQuestion('Graphic Designing',
      'What is the main purpose of white space in a design?',
      ['Improve readability and balance', 'Reduce colors', 'Make files smaller', 'Increase printing cost'], 0),
  QuizQuestion('Basic C++', 'Which symbol ends a statement in C++?',
      [':', '.', ';', ','], 2),
];

const List<Career> sampleCareers = [
  Career(
    'Web Designer',
    78,
    'Your design skills and interest in web pages fit this role.',
    [
      Skill('Graphic Designing', 70, 70, true),
      Skill('HTML/CSS', 60, 75, true),
      Skill('JavaScript', 10, 50, false),
    ],
    ['Junior Web Designer', 'Web Design Intern', 'Frontend Trainee'],
  ),
  Career(
    'UI/UX Designer',
    65,
    'Layout practice helps, but you need UX tools and research skills.',
    [
      Skill('Layout & Typography', 50, 55, false),
      Skill('Figma', 20, 70, false),
      Skill('User Research', 15, 60, false),
    ],
    ['UI Design Intern', 'Junior UX Designer'],
  ),
];

const List<RoadmapStep> sampleRoadmap = [
  RoadmapStep('Learn JavaScript basics',
      'JavaScript is your biggest gap for web design.', 6, 'MDN: JavaScript'),
  RoadmapStep('Build 3 small web pages',
      'Practice makes your HTML and CSS stronger.', 3, 'freeCodeCamp'),
  RoadmapStep('Learn Figma basics',
      'Most design jobs ask for Figma.', 2, 'Figma Learn'),
  RoadmapStep('Make a portfolio page',
      'Employers want to see real work.', 3, 'Search: simple portfolio website'),
];

const List<String> sampleInterviewQuestions = [
  'How do you turn a design mockup into a web page layout?',
  'Tell me about a project you are proud of.',
  'How do you choose colors and fonts for a design?',
  'Why do you want this role?',
];
