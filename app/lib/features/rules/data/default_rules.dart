import '../models/rule_model.dart';

GameRuleset getGameRuleset(String program, String? season) {
  final cleanProg = program.toUpperCase();
  if (cleanProg == 'VIQRC' || cleanProg == 'VIQC') {
    return _viqrcRuleset;
  } else if (cleanProg == 'VEX U' || cleanProg == 'VURC') {
    return _vexuRuleset;
  } else if (cleanProg == 'VEX AI' || cleanProg == 'VAIRC' || cleanProg == 'VAIC') {
    return _vexaiRuleset;
  }
  return _v5rcRuleset;
}

const List<RuleModel> _v5rcRules = [
  // General Rules
  RuleModel(
    code: '<G1>',
    title: 'Treat everyone with respect',
    description: 'All Teams are expected to conduct themselves in a respectful and positive manner. Severe or repeated violations can lead to Disqualification from current matches or event-wide.',
    group: 'General Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#g1',
  ),
  RuleModel(
    code: '<G2>',
    title: 'RoboRef & Head Referee rulings are final',
    description: 'Head Referees have the ultimate authority on all match rulings and scoring decisions. Questions must be raised by student Drive Team Members immediately after the match.',
    group: 'General Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#g2',
  ),
  RuleModel(
    code: '<G3>',
    title: 'Use common sense',
    description: 'When reading and applying rules, common sense is expected. If an action violates the spirit of a rule even if not explicitly forbidden, it may be subject to referee ruling.',
    group: 'General Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#g3',
  ),
  RuleModel(
    code: '<G4>',
    title: 'Drive Team Members only at the field',
    description: 'Only Drive Team Members (max 3 students) are permitted in the Alliance Station during a match. Adults, coaches, and spectators may not enter or coach directly from field perimeter.',
    group: 'General Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#g4',
  ),
  RuleModel(
    code: '<G7>',
    title: 'Keep Robots in the Alliance Station / Field',
    description: 'Drive Team Members may not touch or interact with Robots during the match except as permitted during Autonomous resets or human loading.',
    group: 'General Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#g7',
  ),
  RuleModel(
    code: '<G12>',
    title: "Don't destroy other Robots (Entanglement / Damage)",
    description: 'Robots may not intentionally entangle, tip over, damage, or disable opponent Robots. Incidental contact during normal gameplay is expected, but destructive or reckless play is a Major Infraction / DQ.',
    group: 'General Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#g12',
  ),
  RuleModel(
    code: '<G13>',
    title: "Don't cause opponents to violate rules",
    description: 'A Robot that forces an opponent to commit a rule infraction will be penalized, while the forced opponent will not receive a penalty.',
    group: 'General Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#g13',
  ),
  RuleModel(
    code: '<G14>',
    title: 'Pinning is limited to 5 seconds',
    description: 'A Robot may not Pin (trap or inhibit movement of) an opponent Robot for more than 5 seconds. The pinning Robot must retreat at least 2 feet and wait 5 seconds before attempting another pin.',
    group: 'General Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#g14',
  ),
  RuleModel(
    code: '<G15>',
    title: "Don't trap opponent Robots",
    description: 'A Robot may not trap an opponent Robot in a corner or goal area with no escape path for longer than the pinning count allows.',
    group: 'General Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#g15',
  ),
  RuleModel(
    code: '<G16>',
    title: "Don't clamp onto field perimeter or elements",
    description: 'Robots may not grasp, grapple, attach to, or hang from the field perimeter, foam tiles, or field elements unless explicitly allowed by specific game rules.',
    group: 'General Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#g16',
  ),

  // Specific Game Rules
  RuleModel(
    code: '<SG1>',
    title: 'Starting a Match & Pre-Match Placement',
    description: 'Robots must be placed completely within their designated Alliance Starting Tile, contacting the perimeter wall, and sizing within starting dimensions before the match begins.',
    group: 'Specific Game Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#sg1',
  ),
  RuleModel(
    code: '<SG2>',
    title: 'Horizontal expansion limit',
    description: 'Robots may not expand horizontally beyond the specified maximum dimensions during any point in the match.',
    group: 'Specific Game Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#sg2',
  ),
  RuleModel(
    code: '<SG3>',
    title: 'Vertical expansion limit',
    description: 'Vertical expansion is constrained according to the active game specification. Exceeding vertical limit during gameplay results in a warning or Disqualification if Match Affecting.',
    group: 'Specific Game Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#sg3',
  ),
  RuleModel(
    code: '<SG4>',
    title: 'Keep Scoring Objects in the field',
    description: 'Robots may not intentionally eject, throw, or launch scoring objects outside the field perimeter boundaries.',
    group: 'Specific Game Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#sg4',
  ),
  RuleModel(
    code: '<SG5>',
    title: 'Match preloads and starting objects',
    description: 'All designated match preloads must be placed according to pre-match rules and inspected by field referees before match start.',
    group: 'Specific Game Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#sg5',
  ),
  RuleModel(
    code: '<SG6>',
    title: 'Possession & Handling Limits',
    description: 'Robots are restricted to holding, containing, or controlling maximum designated quantities of scoring objects and field elements simultaneously.',
    group: 'Specific Game Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#sg6',
  ),
  RuleModel(
    code: '<SG7>',
    title: 'Autonomous Line & Midfield Restrictions',
    description: 'During the Autonomous Period, Robots may not cross the Autonomous Line or contact opponent tiles/elements on the opposing side of the field.',
    group: 'Specific Game Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#sg7',
  ),
  RuleModel(
    code: '<SG8>',
    title: 'Midfield interaction at your own risk',
    description: 'Interacting with scoring elements near the midfield line during Autonomous carries risk of penalty if contact crosses boundary lines.',
    group: 'Specific Game Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#sg8',
  ),

  // Safety Rules
  RuleModel(
    code: '<S1>',
    title: 'Safety is the top priority',
    description: 'If at any time a Robot or Team action creates a potential safety hazard (flying parts, loose sharp metal, smoking electronics), the Head Referee will immediately disable the Robot.',
    group: 'Safety Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#s1',
  ),
  RuleModel(
    code: '<S2>',
    title: 'Safety glasses required',
    description: 'All Drive Team Members, referees, and field staff must wear eye protection (safety glasses) at all times while in the Alliance Station and field perimeter.',
    group: 'Safety Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#s2',
  ),

  // Robot Inspection Rules
  RuleModel(
    code: '<R1>',
    title: 'One Robot per Team',
    description: 'Each registered team may enter only one Robot into the tournament. Passing sub-assemblies or complete robots between teams is strictly prohibited.',
    group: 'Robot Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#r1',
  ),
  RuleModel(
    code: '<R4>',
    title: 'Robot sizing inspection',
    description: 'Robots must fit within starting sizing box constraints (18 in x 18 in x 18 in) without external compression prior to starting match play.',
    group: 'Robot Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#r4',
  ),
  RuleModel(
    code: '<R12>',
    title: 'Motors and power limits',
    description: 'Only official VEX V5 smart motors and legal battery/pneumatic components within the maximum allowable wattage and pressure ratings are legal.',
    group: 'Robot Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#r12',
  ),

  // Tournament Rules
  RuleModel(
    code: '<T1>',
    title: 'The Head Referee has ultimate authority',
    description: 'The Head Referee carries final ruling authority on all scores and rule interpretations. Video or photo evidence from spectators will not be reviewed.',
    group: 'Tournament Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#t1',
  ),
  RuleModel(
    code: '<T2>',
    title: 'Match replays are rare',
    description: 'Matches will only be replayed in the event of documented field faults or Tournament Manager system errors that directly affect the outcome of the match.',
    group: 'Tournament Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#t2',
  ),

  // Scoring Rules
  RuleModel(
    code: '<SC1>',
    title: 'Scoring is evaluated at match end',
    description: 'All scoring elements are scored and assessed after the match clock reaches zero and all field motion has fully ceased.',
    group: 'Scoring Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#sc1',
  ),
  RuleModel(
    code: '<SC2>',
    title: 'Autonomous Bonus Award',
    description: 'The Autonomous Win Point and Autonomous Bonus points are awarded to the Alliance with the higher autonomous score following referee evaluation.',
    group: 'Scoring Rules',
    link: 'https://www.vexrobotics.com/v5rc-manual#sc2',
  ),
];

const _v5rcRuleset = GameRuleset(
  gameTitle: 'V5RC Competition Manual',
  season: '2026-2027',
  program: 'V5RC',
  manualUrl: 'https://www.vexrobotics.com/v5rc-manual',
  qaUrl: 'https://events.vex.com/V5RC/2026-2027/QA',
  rules: _v5rcRules,
);

const List<RuleModel> _viqrcRules = [
  RuleModel(
    code: '<G1>',
    title: 'Treat everyone with respect',
    description: 'All Teams are expected to conduct themselves in a respectful, collaborative manner. Violations may result in match Disqualification.',
    group: 'General Rules',
    link: 'https://www.vexrobotics.com/viqrc-manual#g1',
  ),
  RuleModel(
    code: '<G2>',
    title: 'Student-centered team work',
    description: 'Students must be the primary designers, builders, and programmers of their robot. Adult coaching during matches is prohibited.',
    group: 'General Rules',
    link: 'https://www.vexrobotics.com/viqrc-manual#g2',
  ),
  RuleModel(
    code: '<G4>',
    title: 'Two drivers per Team',
    description: 'Two student Drive Team Members operate the Robot during the match, passing the controller at the halfway driver switch point.',
    group: 'General Rules',
    link: 'https://www.vexrobotics.com/viqrc-manual#g4',
  ),
  RuleModel(
    code: '<G8>',
    title: 'Driver switch requirement',
    description: 'Drivers must hand off the controller between the 35-second and 25-second remaining mark during Teamwork matches.',
    group: 'General Rules',
    link: 'https://www.vexrobotics.com/viqrc-manual#g8',
  ),
  RuleModel(
    code: '<G12>',
    title: 'Handling & reset rules',
    description: 'Drivers may only contact or reset their Robot if it is stuck, disabled, or tipped over in accordance with specific field handling rules.',
    group: 'General Rules',
    link: 'https://www.vexrobotics.com/viqrc-manual#g12',
  ),
  RuleModel(
    code: '<SG1>',
    title: 'Starting positions',
    description: 'Robots must begin the match placed within starting zones without exceeding starting sizing constraints.',
    group: 'Specific Game Rules',
    link: 'https://www.vexrobotics.com/viqrc-manual#sg1',
  ),
  RuleModel(
    code: '<S1>',
    title: 'Safety first',
    description: 'Robots that pose safety risks to participants or arena will be disabled immediately by the Head Referee.',
    group: 'Safety Rules',
    link: 'https://www.vexrobotics.com/viqrc-manual#s1',
  ),
  RuleModel(
    code: '<R1>',
    title: 'One Robot per Team',
    description: 'Teams may only enter a single inspected robot built with legal VEX IQ components.',
    group: 'Robot Rules',
    link: 'https://www.vexrobotics.com/viqrc-manual#r1',
  ),
  RuleModel(
    code: '<SC1>',
    title: 'Final score determination',
    description: 'Scores are tallied when all field elements and robots have come to a complete rest at the conclusion of the 60-second match.',
    group: 'Scoring Rules',
    link: 'https://www.vexrobotics.com/viqrc-manual#sc1',
  ),
];

const _viqrcRuleset = GameRuleset(
  gameTitle: 'VIQRC Game Manual',
  season: '2026-2027',
  program: 'VIQRC',
  manualUrl: 'https://www.vexrobotics.com/viqrc-manual',
  qaUrl: 'https://events.vex.com/VIQRC/2026-2027/QA',
  rules: _viqrcRules,
);

const List<RuleModel> _vexuRules = [
  RuleModel(
    code: '<VUG1>',
    title: 'Two Robots per Team',
    description: 'Each VEX U team constructs and deploys two distinct robots (one small robot, one large robot) on the field for each match.',
    group: 'VEX U Specific Rules',
    link: 'https://www.vexrobotics.com/vexu-manual#vug1',
  ),
  RuleModel(
    code: '<VUG2>',
    title: 'Extended Autonomous Period',
    description: 'VEX U matches feature an extended 45-second Autonomous Period followed by a 75-second Driver Controlled Period.',
    group: 'VEX U Specific Rules',
    link: 'https://www.vexrobotics.com/vexu-manual#vug2',
  ),
  RuleModel(
    code: '<VUR1>',
    title: 'Fabrication & Custom Parts',
    description: 'VEX U teams may utilize 3D printed components, CNC machined parts, and custom electronics within the allowable power and safety bounds.',
    group: 'VEX U Specific Rules',
    link: 'https://www.vexrobotics.com/vexu-manual#vur1',
  ),
  ..._v5rcRules,
];

const _vexuRuleset = GameRuleset(
  gameTitle: 'VEX U College Competition Manual',
  season: '2026-2027',
  program: 'VEX U',
  manualUrl: 'https://www.vexrobotics.com/vexu-manual',
  qaUrl: 'https://events.vex.com/VEXU/2026-2027/QA',
  rules: _vexuRules,
);

const List<RuleModel> _vexaiRules = [
  RuleModel(
    code: '<VAIC1>',
    title: 'Fully Autonomous Match Operation',
    description: 'VAIRC matches are conducted 100% autonomously without human driver interaction using onboard sensors, Jetson processors, and VEX GPS.',
    group: 'VEX AI Specific Rules',
    link: 'https://www.vexrobotics.com/vexai-manual#vaic1',
  ),
  RuleModel(
    code: '<VAIC2>',
    title: 'Vehicle-to-Vehicle (V2V) Communication',
    description: 'Partner robots communicate state and navigation targets over Wi-Fi / V2V mesh protocols during match execution.',
    group: 'VEX AI Specific Rules',
    link: 'https://www.vexrobotics.com/vexai-manual#vaic2',
  ),
  ..._v5rcRules,
];

const _vexaiRuleset = GameRuleset(
  gameTitle: 'VEX AI Robotics Competition Manual',
  season: '2026-2027',
  program: 'VEX AI',
  manualUrl: 'https://www.vexrobotics.com/vexai-manual',
  qaUrl: 'https://events.vex.com/VAIRC/2026-2027/QA',
  rules: _vexaiRules,
);
