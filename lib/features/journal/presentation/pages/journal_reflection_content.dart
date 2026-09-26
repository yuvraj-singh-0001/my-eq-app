import 'package:flutter/material.dart';

import 'self_regulation_content.dart';

const _everydayExperience = <String>[
  'Something about this felt good to me.',
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

const _everydayPeople = <String>[
  'I feel comfortable sharing my thoughts with someone I trust.',
  'I feel listened to when I explain what is on my mind.',
  'I sometimes find it hard to say what I need.',
  'I can ask someone to give me a little time or space.',
  'I feel included when people invite me to join in.',
  'I try to notice when someone else wants to join in.',
  'I can talk to a trusted adult when something does not feel right.',
  'I am learning how to speak up in a kind and clear way.',
];

const _everydayHardMoments = <String>[
  'I made a mistake and felt able to try again.',
  'I felt left out or not understood.',
  'I found it hard when something changed.',
  'I worried about what other people might think.',
  'I felt proud of how I handled a tricky moment.',
  'I needed help but was not sure how to ask.',
  'I had a hard moment, but it did not last all day.',
  'I am still working out what I think about it.',
];

const _everydayVoice = <String>[
  'I would like to share more about what happened.',
  'I am not ready to talk about every part yet.',
  'I know one small thing I would like someone to understand.',
  'I have a question I would like to ask.',
  'I would like someone to listen without trying to fix it right away.',
  'I want to remember something that went well.',
  'I am still finding the words for what I feel.',
  'Writing a little about it helps me sort out my thoughts.',
];

const _extraChoices = <String>[
  'I can take my time and share only what feels okay.',
  'One small step can be enough for today.',
];

List<String> _withTenChoices(List<String> choices) => [
  ...choices,
  ..._extraChoices.take((10 - choices.length).clamp(0, 2).toInt()),
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
      statements: _withTenChoices(
        index < promptSets.length ? promptSets[index] : _everydayVoice,
      ),
    ),
];

const _topicIcons = <IconData>[
  Icons.explore_rounded,
  Icons.favorite_outline_rounded,
  Icons.lightbulb_outline_rounded,
  Icons.chat_bubble_outline_rounded,
  Icons.edit_note_rounded,
  Icons.edit_note_rounded,
];

const _topicColors = <Color>[
  Color(0xFF1689E8),
  Color(0xFFEF4B5B),
  Color(0xFF149B78),
  Color(0xFF8C4DDA),
  Color(0xFFF1A000),
  Color(0xFF65728E),
];

Map<String, List<SelfRegulationTopic>> get journalReflectionTopics => {
  'Empathy': _topics('Empathy', const [
    ('Noticing Feelings', 'What feelings do you notice in others?'),
    ('Seeing Another View', 'What might someone else be thinking?'),
    ('Showing Care', 'How do you show someone you care?'),
    ('Listening with Care', 'How do you make space for someone to talk?'),
    ('Respecting Feelings & Space', 'How can you respect what someone needs?'),
    ('A Moment I Remember', 'What else would you like to share about someone?'),
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
    [
      'I try to listen without rushing to give advice.',
      'I let someone finish before I share my thoughts.',
      'I ask a gentle question if I do not understand.',
      'I can listen even when I do not have the same experience.',
      'Sometimes I get distracted while someone is talking.',
      'I can check that I understood what they meant.',
      'I let people know I am listening in a way that feels natural to me.',
      'Listening can help people feel less alone.',
    ],
    [
      'I understand that people may want different kinds of help.',
      'I ask before touching someone or their belongings.',
      'I respect it when someone says they need space.',
      'I try not to tease someone about how they feel.',
      'I can say what I need while still being kind.',
      'I know it is okay to ask a trusted adult for help.',
      'Sometimes I need reminders to notice another person’s boundaries.',
      'People can care about each other and still need time alone.',
    ],
  ]),
  'Social Skills': _topics('Social Skills', const [
    ('Talking & Listening', 'How do you share and listen in a conversation?'),
    ('Working Together', 'What is it like to do things with others?'),
    ('Solving Disagreements', 'What helps when people do not agree?'),
    ('Joining In & Including Others', 'How do you help everyone feel welcome?'),
    ('Sharing What I Need', 'How do you let others know what works for you?'),
    ('A Moment I Remember', 'What else would you like to share about people?'),
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
    [
      'I feel welcome when someone invites me to join in.',
      'I can invite someone else to join a game or activity.',
      'I notice when a person is being left out.',
      'I sometimes feel shy about joining a group.',
      'I can ask if there is room for me to take part.',
      'I try to make space for different ideas and ways to join.',
      'I feel more comfortable when the group explains the rules.',
      'Small friendly actions can help people feel included.',
    ],
    [
      'I can say what I would like in a calm way.',
      'I can say no when something does not feel right.',
      'I sometimes worry that people will be upset if I speak up.',
      'I can ask someone to stop if their words bother me.',
      'I try to use clear words instead of expecting others to guess.',
      'I can ask for help when a conversation feels too hard.',
      'I listen when someone else tells me what they need.',
      'It takes practice to share needs and respect other people’s needs.',
    ],
  ]),
  'Self-Awareness': _topics('Self-Awareness', const [
    ('Knowing My Feelings', 'What helps you understand how you feel?'),
    ('My Strengths & Growth', 'What do you notice about yourself?'),
    ('What I Need', 'What helps you feel supported and understood?'),
    ('My Choices', 'What matters to you when you make a choice?'),
    ('How I Learn Best', 'What helps you learn and keep going?'),
    ('A Moment I Remember', 'What else would you like to share about yourself?'),
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
    [
      'I try to make choices that feel right for me.',
      'I think about how my choices may affect other people.',
      'Sometimes I need time before I decide what to do.',
      'I can change my mind when I learn something new.',
      'I feel good when my actions match what matters to me.',
      'I sometimes follow others even when I feel unsure.',
      'I can ask a trusted person to help me think through a choice.',
      'I am learning that I can make a new choice after a mistake.',
    ],
    [
      'I learn well when I can take one step at a time.',
      'Seeing an example helps me understand what to do.',
      'I learn by asking questions and trying things out.',
      'I find it harder to learn when I feel rushed.',
      'A short break can help me return to my work.',
      'I feel proud when I keep practising something difficult.',
      'I can let someone know when I need help to understand.',
      'Different ways of learning can work for different people.',
    ],
  ]),
  'Relationships': _generalTopics('Relationships', const [
    ('Feeling Connected', 'When do you feel close to people?'),
    ('Trust & Boundaries', 'What helps you feel safe and respected?'),
    ('Working Through Problems', 'What helps when a relationship feels hard?'),
    ('Good Moments Together', 'What moments make time together feel good?'),
    ('What I Need', 'How can people understand what you need?'),
    ('Something I Want to Share', 'What else would you like people to know?'),
  ]),
  'Exam Fears': _generalTopics('Exam Fears', const [
    ('Getting Ready', 'What is exam preparation like for you?'),
    ('During an Exam', 'How do you feel while taking an exam?'),
    ('After an Exam', 'What do you think about after an exam?'),
    ('When a Question Feels Hard', 'What do you do when you get stuck?'),
    ('Support & Small Steps', 'What helps you feel ready to learn?'),
    ('What I Want to Remember', 'What would you like to remember for next time?'),
  ]),
  'Someone Misbehaves': _generalTopics('Someone Misbehaves', const [
    ('What Happened', 'What would you like to share about the situation?'),
    ('How It Affected Me', 'How did the situation feel for you?'),
    ('What Could Help', 'What would help you feel supported now?'),
    ('Getting Help', 'Who could you talk to about what happened?'),
    ('Feeling Safe Again', 'What could help you feel okay at school?'),
    ('What I Want Adults to Know', 'What would you like a trusted adult to know?'),
  ]),
  'Bad Habits': _generalTopics('Bad Habits', const [
    ('Noticing My Habits', 'What patterns have you noticed?'),
    ('What Makes It Hard', 'What can make a change difficult?'),
    ('Small Changes', 'What small change might help you?'),
    ('Small Wins', 'What has gone a little better lately?'),
    ('Support That Helps', 'What kind of support would feel useful?'),
    ('What I Want to Remember', 'What could you remind yourself next time?'),
  ]),
  'Sports': _generalTopics('Sports', const [
    ('Practice & Effort', 'What is practice like for you?'),
    ('Teamwork', 'How do you feel when you play with others?'),
    ('Wins & Setbacks', 'What do you learn from results and mistakes?'),
    ('Enjoyment & Confidence', 'What parts of sport do you enjoy?'),
    ('Rest & Support', 'What helps your body and mind feel ready?'),
    ('A Moment I Remember', 'What else would you like to share about sport?'),
  ]),
  'School': _generalTopics('School', const [
    ('Learning in Class', 'What has learning been like for you?'),
    ('People at School', 'How do you feel around people at school?'),
    ('My School Day', 'What stands out from your school day?'),
    ('Things I Feel Proud Of', 'What is something you did your best with?'),
    ('Help with Schoolwork', 'What helps when schoolwork feels hard?'),
    ('A Moment I Remember', 'What else would you like to share about school?'),
  ]),
  'Presentation': _generalTopics('Presentation', const [
    ('Getting Ready', 'What helps you prepare to share?'),
    ('Speaking Up', 'How does it feel to speak in front of others?'),
    ('After I Share', 'What do you notice after your presentation?'),
    ('Worries & Brave Moments', 'What felt hard, and what felt brave?'),
    ('Support & Practice', 'What would help you feel ready next time?'),
    ('A Moment I Remember', 'What else would you like others to know?'),
  ]),
  'Competition': _generalTopics('Competition', const [
    ('Preparing', 'What is preparing for a competition like?'),
    ('During Competition', 'What goes through your mind while competing?'),
    ('Results & Feelings', 'How do you feel about the result?'),
    ('Effort & Enjoyment', 'What part of taking part felt good?'),
    ('Learning for Next Time', 'What would you like to remember next time?'),
    ('A Moment I Remember', 'What else would you like to share about competing?'),
  ]),
  'Family': _generalTopics('Family', const [
    ('Time Together', 'What do you enjoy or find hard at home?'),
    ('Talking & Listening', 'How do people share their thoughts at home?'),
    ('What I Need', 'What helps you feel supported by family?'),
    ('Good Moments at Home', 'What small moments make you feel close?'),
    ('When Things Feel Hard', 'What helps when home feels difficult?'),
    ('A Moment I Remember', 'What else would you like to share about home?'),
  ]),
  'Friends': _generalTopics('Friends', const [
    ('Feeling Connected', 'What makes friendship feel good to you?'),
    ('Friendship Challenges', 'What can feel hard with friends?'),
    ('Being a Good Friend', 'How do you want to show up for friends?'),
    ('Including Each Other', 'What helps everyone feel welcome?'),
    ('Talking Things Through', 'What helps after a disagreement?'),
    ('A Moment I Remember', 'What else would you like to share about friends?'),
  ]),
  'Screen Time': _generalTopics('Screen Time', const [
    ('My Screen Habits', 'When and why do you use screens?'),
    ('How Screens Affect Me', 'How do you feel during and after screen time?'),
    ('Balance & Choices', 'What balance would feel good for you?'),
    ('Screens & Sleep', 'How does screen time fit with your rest?'),
    ('Offline Fun', 'What else helps you have a good time?'),
    ('My Own Choice', 'What would you like to change or keep the same?'),
  ]),
  'Other': _generalTopics('Other', const [
    ('What Is on My Mind', 'What would you like to talk about?'),
    ('How I Feel', 'What feelings are coming up for you?'),
    ('What Might Help', 'What could help you feel supported?'),
    ('Something Good', 'What is something you would like to remember?'),
    ('Something Difficult', 'What is something you wish felt easier?'),
    ('Anything Else', 'What else would you like to write about?'),
  ]),
};

List<SelfRegulationTopic> _generalTopics(
  String category,
  List<(String, String)> details,
) => _topics(category, details, const [
  _everydayExperience,
  _everydayFeelings,
  _everydayPeople,
  _everydayHardMoments,
  _everydayNextSteps,
  _everydayVoice,
]);
