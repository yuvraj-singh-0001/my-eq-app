import 'package:flutter/material.dart';

import 'self_regulation_content.dart';

const _everydayExperience = <String>[
  'Something in this area went well for me.',
  'One part of this felt difficult for me.',
  'It went differently from what I expected.',
  'I tried something new or unfamiliar.',
  'Someone helped me or made it easier.',
  'I kept going even when it felt hard.',
  'I learned something about myself.',
  'I am still thinking about what happened.',
];

const _everydayFeelings = <String>[
  'I felt happy or excited.',
  'I felt calm and comfortable.',
  'I felt proud of myself.',
  'I felt worried or unsure.',
  'I felt sad or disappointed.',
  'I felt annoyed or frustrated.',
  'I had more than one feeling at the same time.',
  'I am still figuring out how I feel.',
];

const _everydayNextSteps = <String>[
  'I would like to try again in my own time.',
  'I could ask someone I trust for help.',
  'I want to talk about how this felt for me.',
  'I can take one small step at a time.',
  'I would like to notice what is already going well.',
  'A short break could help me feel ready again.',
  'I want to understand what might help next time.',
  'I am not sure what I need yet, and that is okay.',
];

List<SelfRegulationTopic> _topics(
  String category,
  List<(String, String)> details,
  List<List<String>> promptSets,
) => [
  for (var index = 0; index < details.length; index++)
    SelfRegulationTopic(
      id: '${category.toLowerCase().replaceAll(' ', '_')}_$index',
      title: details[index].$1,
      description: details[index].$2,
      icon: _topicIcons[index],
      color: _topicColors[index],
      statements: promptSets[index],
    ),
];

const _topicIcons = <IconData>[
  Icons.explore_rounded,
  Icons.favorite_outline_rounded,
  Icons.lightbulb_outline_rounded,
];

const _topicColors = <Color>[
  Color(0xFF1689E8),
  Color(0xFFEF4B5B),
  Color(0xFF149B78),
];

final journalReflectionTopics = <String, List<SelfRegulationTopic>>{
  'Empathy': _topics('Empathy', const [
    ('Noticing Feelings', 'What feelings do you notice in others?'),
    ('Seeing Another View', 'What might someone else be thinking?'),
    ('Showing Care', 'How do you show someone you care?'),
  ], const [
    [
      'I notice when someone seems happy or excited.',
      'I notice when someone seems worried or left out.',
      'I try to listen when someone shares a feeling.',
      'Sometimes I am not sure how another person feels.',
      'I ask someone how they are feeling.',
      'I can tell when someone may need some space.',
      'I notice that people can feel differently about the same thing.',
      'I am learning to understand feelings in myself and others.',
    ],
    [
      'I try to imagine how the situation looks to someone else.',
      'I remember that another person may have a different experience.',
      'I can disagree and still try to understand their view.',
      'I sometimes find it hard to see another point of view.',
      'I ask questions before deciding what someone meant.',
      'I try to hear the whole story before I respond.',
      'I notice that people may need different kinds of help.',
      'I am open to learning more about what someone thinks.',
    ],
    [
      'I check in when someone seems to need support.',
      'I use kind words when someone is having a hard day.',
      'I offer help and let the person choose what they need.',
      'I try to include people in a kind way.',
      'Sometimes I do not know what to say, so I stay nearby.',
      'I respect it when someone wants time alone.',
      'I can ask a trusted adult how to help.',
      'Small kind actions can help someone feel welcome.',
    ],
  ]),
  'Social Skills': _topics('Social Skills', const [
    ('Talking & Listening', 'How do you share and listen in a conversation?'),
    ('Working Together', 'What is it like to do things with others?'),
    ('Solving Disagreements', 'What helps when people do not agree?'),
  ], const [
    [
      'I can share my ideas with other people.',
      'I try to listen without interrupting.',
      'I can ask someone to explain more.',
      'I sometimes need time before I speak.',
      'I find it easier to talk with some people than others.',
      'I notice when someone wants a turn to speak.',
      'I can tell someone when I did not understand.',
      'I am learning what makes a conversation feel comfortable.',
    ],
    [
      'I enjoy sharing a task with other people.',
      'I can offer an idea and listen to other ideas too.',
      'I try to do my part when we work as a team.',
      'It can be hard when a group has different ideas.',
      'I can ask the group how I can help.',
      'I notice when someone is being left out.',
      'I can take turns leading and following.',
      'Working together gets easier when we make a plan.',
    ],
    [
      'I try to explain what is bothering me calmly.',
      'I can listen to another person’s side.',
      'I ask for a little time when I need to cool down.',
      'I sometimes need help finding the right words.',
      'I can look for a solution that feels fair.',
      'I can say sorry when my actions hurt someone.',
      'I can ask a trusted adult to help us talk.',
      'A disagreement does not always have to end a friendship.',
    ],
  ]),
  'Self-Awareness': _topics('Self-Awareness', const [
    ('Knowing My Feelings', 'What helps you understand how you feel?'),
    ('My Strengths & Growth', 'What do you notice about yourself?'),
    ('What I Need', 'What helps you feel supported and understood?'),
  ], const [
    [
      'I can name some feelings I have during the day.',
      'Sometimes I feel more than one thing at once.',
      'I notice that my body gives me clues about my feelings.',
      'I need time to work out what I am feeling.',
      'I can tell someone when I feel worried or upset.',
      'I notice what helps me feel calm again.',
      'My feelings can change as a situation changes.',
      'I am learning that all my feelings can tell me something.',
    ],
    [
      'I can think of something I am good at.',
      'I feel proud when I keep trying.',
      'I am still learning some things that matter to me.',
      'I can learn from a mistake without calling myself bad.',
      'I notice small ways I have improved.',
      'I sometimes compare myself with other people.',
      'I have qualities that make me who I am.',
      'I can ask someone I trust what they appreciate about me.',
    ],
    [
      'I can ask for help when I need it.',
      'Quiet time helps me feel more settled.',
      'I feel better when someone listens without rushing me.',
      'I can let someone know when I need a break.',
      'I am still learning what kind of support works for me.',
      'I can tell people when something does not feel okay.',
      'I feel supported when people give me time to explain.',
      'It is okay for me to have needs and ask for support.',
    ],
  ]),
  'Relationships': _generalTopics('Relationships', const [
    ('Feeling Connected', 'When do you feel close to people?'),
    ('Trust & Boundaries', 'What helps you feel safe and respected?'),
    ('Working Through Problems', 'What helps when a relationship feels hard?'),
  ]),
  'Exam Fears': _generalTopics('Exam Fears', const [
    ('Getting Ready', 'What is exam preparation like for you?'),
    ('During an Exam', 'How do you feel while taking an exam?'),
    ('After an Exam', 'What do you think about after an exam?'),
  ]),
  'Someone Misbehaves': _generalTopics('Someone Misbehaves', const [
    ('What Happened', 'What would you like to share about the situation?'),
    ('How It Affected Me', 'How did the situation feel for you?'),
    ('What Could Help', 'What would help you feel supported now?'),
  ]),
  'Bad Habits': _generalTopics('Bad Habits', const [
    ('Noticing My Habits', 'What patterns have you noticed?'),
    ('What Makes It Hard', 'What can make a change difficult?'),
    ('Small Changes', 'What small change might help you?'),
  ]),
  'Sports': _generalTopics('Sports', const [
    ('Practice & Effort', 'What is practice like for you?'),
    ('Teamwork', 'How do you feel when you play with others?'),
    ('Wins & Setbacks', 'What do you learn from results and mistakes?'),
  ]),
  'School': _generalTopics('School', const [
    ('Learning in Class', 'What has learning been like for you?'),
    ('People at School', 'How do you feel around people at school?'),
    ('My School Day', 'What stands out from your school day?'),
  ]),
  'Presentation': _generalTopics('Presentation', const [
    ('Getting Ready', 'What helps you prepare to share?'),
    ('Speaking Up', 'How does it feel to speak in front of others?'),
    ('After I Share', 'What do you notice after your presentation?'),
  ]),
  'Competition': _generalTopics('Competition', const [
    ('Preparing', 'What is preparing for a competition like?'),
    ('During Competition', 'What goes through your mind while competing?'),
    ('Results & Feelings', 'How do you feel about the result?'),
  ]),
  'Family': _generalTopics('Family', const [
    ('Time Together', 'What do you enjoy or find hard at home?'),
    ('Talking & Listening', 'How do people share their thoughts at home?'),
    ('What I Need', 'What helps you feel supported by family?'),
  ]),
  'Friends': _generalTopics('Friends', const [
    ('Feeling Connected', 'What makes friendship feel good to you?'),
    ('Friendship Challenges', 'What can feel hard with friends?'),
    ('Being a Good Friend', 'How do you want to show up for friends?'),
  ]),
  'Screen Time': _generalTopics('Screen Time', const [
    ('My Screen Habits', 'When and why do you use screens?'),
    ('How Screens Affect Me', 'How do you feel during and after screen time?'),
    ('Balance & Choices', 'What balance would feel good for you?'),
  ]),
  'Other': _generalTopics('Other', const [
    ('What Is on My Mind', 'What would you like to talk about?'),
    ('How I Feel', 'What feelings are coming up for you?'),
    ('What Might Help', 'What could help you feel supported?'),
  ]),
};

List<SelfRegulationTopic> _generalTopics(
  String category,
  List<(String, String)> details,
) => _topics(category, details, const [
  _everydayExperience,
  _everydayFeelings,
  _everydayNextSteps,
]);
