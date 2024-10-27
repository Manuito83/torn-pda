import 'package:json_annotation/json_annotation.dart';
import 'package:collection/collection.dart';

enum RaceClassEnum {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('A')
  a('A'),
  @JsonValue('B')
  b('B'),
  @JsonValue('C')
  c('C'),
  @JsonValue('D')
  d('D'),
  @JsonValue('E')
  e('E');

  final String? value;

  const RaceClassEnum(this.value);
}

enum FactionNewsCategory {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('main')
  main('main'),
  @JsonValue('attack')
  attack('attack'),
  @JsonValue('armoryDeposit')
  armorydeposit('armoryDeposit'),
  @JsonValue('armoryAction')
  armoryaction('armoryAction'),
  @JsonValue('territoryWar')
  territorywar('territoryWar'),
  @JsonValue('rankedWar')
  rankedwar('rankedWar'),
  @JsonValue('territoryGain')
  territorygain('territoryGain'),
  @JsonValue('chain')
  chain('chain'),
  @JsonValue('crime')
  crime('crime'),
  @JsonValue('membership')
  membership('membership'),
  @JsonValue('depositFunds')
  depositfunds('depositFunds'),
  @JsonValue('giveFunds')
  givefunds('giveFunds');

  final String? value;

  const FactionNewsCategory(this.value);
}

enum FactionRankEnum {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('Unranked')
  unranked('Unranked'),
  @JsonValue('Bronze')
  bronze('Bronze'),
  @JsonValue('Silver')
  silver('Silver'),
  @JsonValue('Gold')
  gold('Gold'),
  @JsonValue('Platinum')
  platinum('Platinum'),
  @JsonValue('Diamond')
  diamond('Diamond');

  final String? value;

  const FactionRankEnum(this.value);
}

enum UserCrimeUniquesRewardAmmoEnum {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('standard')
  standard('standard'),
  @JsonValue('special')
  special('special');

  final String? value;

  const UserCrimeUniquesRewardAmmoEnum(this.value);
}

enum RaceStatusEnum {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('open')
  open('open'),
  @JsonValue('in_progress')
  inProgress('in_progress'),
  @JsonValue('finished')
  finished('finished');

  final String? value;

  const RaceStatusEnum(this.value);
}

enum TornHofCategory {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('level')
  level('level'),
  @JsonValue('busts')
  busts('busts'),
  @JsonValue('rank')
  rank('rank'),
  @JsonValue('traveltime')
  traveltime('traveltime'),
  @JsonValue('workstats')
  workstats('workstats'),
  @JsonValue('networth')
  networth('networth'),
  @JsonValue('revives')
  revives('revives'),
  @JsonValue('defends')
  defends('defends'),
  @JsonValue('offences')
  offences('offences'),
  @JsonValue('attacks')
  attacks('attacks'),
  @JsonValue('awards')
  awards('awards'),
  @JsonValue('racingwins')
  racingwins('racingwins'),
  @JsonValue('racingpoints')
  racingpoints('racingpoints'),
  @JsonValue('racingskill')
  racingskill('racingskill');

  final String? value;

  const TornHofCategory(this.value);
}

enum TornFactionHofCategory {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('respect')
  respect('respect'),
  @JsonValue('chains')
  chains('chains'),
  @JsonValue('rank')
  rank('rank');

  final String? value;

  const TornFactionHofCategory(this.value);
}

enum FactionAttackResult {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('None')
  none('None'),
  @JsonValue('Attacked')
  attacked('Attacked'),
  @JsonValue('Mugged')
  mugged('Mugged'),
  @JsonValue('Hospitalized')
  hospitalized('Hospitalized'),
  @JsonValue('Arrested')
  arrested('Arrested'),
  @JsonValue('Looted')
  looted('Looted'),
  @JsonValue('Lost')
  lost('Lost'),
  @JsonValue('Stalemate')
  stalemate('Stalemate'),
  @JsonValue('Assist')
  assist('Assist'),
  @JsonValue('Escape')
  escape('Escape'),
  @JsonValue('Timeout')
  timeout('Timeout'),
  @JsonValue('Special')
  special('Special'),
  @JsonValue('Bounty')
  bounty('Bounty'),
  @JsonValue('Interrupted')
  interrupted('Interrupted');

  final String? value;

  const FactionAttackResult(this.value);
}

enum RaceCarUpgradeCategory {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('Aerodynamics')
  aerodynamics('Aerodynamics'),
  @JsonValue('Brakes')
  brakes('Brakes'),
  @JsonValue('Engine')
  engine('Engine'),
  @JsonValue('Exhaust and Induction')
  exhaustAndInduction('Exhaust and Induction'),
  @JsonValue('Fuel')
  fuel('Fuel'),
  @JsonValue('Safety')
  safety('Safety'),
  @JsonValue('Suspension')
  suspension('Suspension'),
  @JsonValue('Transmission')
  transmission('Transmission'),
  @JsonValue('Weight Reduction')
  weightReduction('Weight Reduction'),
  @JsonValue('Wheels and Tyres')
  wheelsAndTyres('Wheels and Tyres');

  final String? value;

  const RaceCarUpgradeCategory(this.value);
}

enum JobPositionArmyEnum {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('Private')
  private('Private'),
  @JsonValue('Corporal')
  corporal('Corporal'),
  @JsonValue('Sergeant')
  sergeant('Sergeant'),
  @JsonValue('Master Sergeant')
  masterSergeant('Master Sergeant'),
  @JsonValue('Warrant Officer')
  warrantOfficer('Warrant Officer'),
  @JsonValue('Lieutenant')
  lieutenant('Lieutenant'),
  @JsonValue('Major')
  major('Major'),
  @JsonValue('Colonel')
  colonel('Colonel'),
  @JsonValue('Brigadier')
  brigadier('Brigadier'),
  @JsonValue('General')
  general('General');

  final String? value;

  const JobPositionArmyEnum(this.value);
}

enum JobPositionGrocerEnum {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('Bagboy')
  bagboy('Bagboy'),
  @JsonValue('Price Labeler')
  priceLabeler('Price Labeler'),
  @JsonValue('Cashier')
  cashier('Cashier'),
  @JsonValue('Food Delivery')
  foodDelivery('Food Delivery'),
  @JsonValue('Manager')
  manager('Manager');

  final String? value;

  const JobPositionGrocerEnum(this.value);
}

enum WeaponBonusEnum {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('Proficience')
  proficience('Proficience'),
  @JsonValue('Expose')
  expose('Expose'),
  @JsonValue('Stricken')
  stricken('Stricken'),
  @JsonValue('Plunder')
  plunder('Plunder'),
  @JsonValue('Burn')
  burn('Burn'),
  @JsonValue('Emasculate')
  emasculate('Emasculate'),
  @JsonValue('Poison')
  poison('Poison'),
  @JsonValue('Blindfire')
  blindfire('Blindfire'),
  @JsonValue('Hazardous')
  hazardous('Hazardous'),
  @JsonValue('Spray')
  spray('Spray'),
  @JsonValue('Demoralize')
  demoralize('Demoralize'),
  @JsonValue('Storage')
  storage('Storage'),
  @JsonValue('Freeze')
  freeze('Freeze'),
  @JsonValue('Sleep')
  sleep('Sleep'),
  @JsonValue('Revitalize')
  revitalize('Revitalize'),
  @JsonValue('Wither')
  wither('Wither'),
  @JsonValue('Roshambo')
  roshambo('Roshambo'),
  @JsonValue('Slow')
  slow('Slow'),
  @JsonValue('Cripple')
  cripple('Cripple'),
  @JsonValue('Weaken')
  weaken('Weaken'),
  @JsonValue('Cupid')
  cupid('Cupid'),
  @JsonValue('Throttle')
  throttle('Throttle'),
  @JsonValue('Crusher')
  crusher('Crusher'),
  @JsonValue('Achilles')
  achilles('Achilles'),
  @JsonValue('Blindside')
  blindside('Blindside'),
  @JsonValue('Backstab')
  backstab('Backstab'),
  @JsonValue('Grace')
  grace('Grace'),
  @JsonValue('Berserk')
  berserk('Berserk'),
  @JsonValue('Conserve')
  conserve('Conserve'),
  @JsonValue('Eviscerate')
  eviscerate('Eviscerate'),
  @JsonValue('Bleed')
  bleed('Bleed'),
  @JsonValue('Stun')
  stun('Stun'),
  @JsonValue('Paralyze')
  paralyze('Paralyze'),
  @JsonValue('Suppress')
  suppress('Suppress'),
  @JsonValue('Motivation')
  motivation('Motivation'),
  @JsonValue('Deadly')
  deadly('Deadly'),
  @JsonValue('Deadeye')
  deadeye('Deadeye'),
  @JsonValue('Fury')
  fury('Fury'),
  @JsonValue('Rage')
  rage('Rage'),
  @JsonValue('Puncture')
  puncture('Puncture'),
  @JsonValue('Comeback')
  comeback('Comeback'),
  @JsonValue('Powerful')
  powerful('Powerful'),
  @JsonValue('Specialist')
  specialist('Specialist'),
  @JsonValue('Assassinate')
  assassinate('Assassinate'),
  @JsonValue('Smurf')
  smurf('Smurf'),
  @JsonValue('Double-edged')
  doubleEdged('Double-edged'),
  @JsonValue('Execute')
  execute('Execute'),
  @JsonValue('Shock')
  shock('Shock'),
  @JsonValue('Wind-up')
  windUp('Wind-up'),
  @JsonValue('Sure Shot')
  sureShot('Sure Shot'),
  @JsonValue('Focus')
  focus('Focus'),
  @JsonValue('Frenzy')
  frenzy('Frenzy'),
  @JsonValue('Warlord')
  warlord('Warlord'),
  @JsonValue('Finale')
  finale('Finale'),
  @JsonValue('Home run')
  homeRun('Home run'),
  @JsonValue('Parry')
  parry('Parry'),
  @JsonValue('Bloodlust')
  bloodlust('Bloodlust'),
  @JsonValue('Disarm')
  disarm('Disarm'),
  @JsonValue('Empower')
  empower('Empower'),
  @JsonValue('Quicken')
  quicken('Quicken'),
  @JsonValue('Lacerate')
  lacerate('Lacerate'),
  @JsonValue('Penetrate')
  penetrate('Penetrate'),
  @JsonValue('Irradiate')
  irradiate('Irradiate'),
  @JsonValue('Toxin')
  toxin('Toxin'),
  @JsonValue('Smash')
  smash('Smash'),
  @JsonValue('Double Tap')
  doubleTap('Double Tap');

  final String? value;

  const WeaponBonusEnum(this.value);
}

enum JobPositionCasinoEnum {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('Gaming Consultant')
  gamingConsultant('Gaming Consultant'),
  @JsonValue('Marketing Manager')
  marketingManager('Marketing Manager'),
  @JsonValue('Revenue Manager')
  revenueManager('Revenue Manager'),
  @JsonValue('Casino Manager')
  casinoManager('Casino Manager'),
  @JsonValue('Casino President')
  casinoPresident('Casino President');

  final String? value;

  const JobPositionCasinoEnum(this.value);
}

enum JobPositionMedicalEnum {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('Medical Student')
  medicalStudent('Medical Student'),
  @JsonValue('Houseman')
  houseman('Houseman'),
  @JsonValue('Senior Houseman')
  seniorHouseman('Senior Houseman'),
  @JsonValue('GP')
  gp('GP'),
  @JsonValue('Consultant')
  consultant('Consultant'),
  @JsonValue('Surgeon')
  surgeon('Surgeon'),
  @JsonValue('Brain Surgeon')
  brainSurgeon('Brain Surgeon');

  final String? value;

  const JobPositionMedicalEnum(this.value);
}

enum JobPositionLawEnum {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('Law Student')
  lawStudent('Law Student'),
  @JsonValue('Paralegal')
  paralegal('Paralegal'),
  @JsonValue('Probate Lawyer')
  probateLawyer('Probate Lawyer'),
  @JsonValue('Trial Lawyer')
  trialLawyer('Trial Lawyer'),
  @JsonValue('Circuit Court Judge')
  circuitCourtJudge('Circuit Court Judge'),
  @JsonValue('Federal Judge')
  federalJudge('Federal Judge');

  final String? value;

  const JobPositionLawEnum(this.value);
}

enum JobPositionEducationEnum {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('Recess Supervisor')
  recessSupervisor('Recess Supervisor'),
  @JsonValue('Substitute Teacher')
  substituteTeacher('Substitute Teacher'),
  @JsonValue('Elementary Teacher')
  elementaryTeacher('Elementary Teacher'),
  @JsonValue('Secondary Teacher')
  secondaryTeacher('Secondary Teacher'),
  @JsonValue('Professor')
  professor('Professor'),
  @JsonValue('Vice-Principal')
  vicePrincipal('Vice-Principal'),
  @JsonValue('Principal')
  principal('Principal');

  final String? value;

  const JobPositionEducationEnum(this.value);
}

enum RaceCarUpgradeSubCategory {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('Engine Cooling')
  engineCooling('Engine Cooling'),
  @JsonValue('Front Diffuser')
  frontDiffuser('Front Diffuser'),
  @JsonValue('Rear Diffuser')
  rearDiffuser('Rear Diffuser'),
  @JsonValue('Spoiler')
  spoiler('Spoiler'),
  @JsonValue('Brake Accessory')
  brakeAccessory('Brake Accessory'),
  @JsonValue('Brake Control')
  brakeControl('Brake Control'),
  @JsonValue('Callipers')
  callipers('Callipers'),
  @JsonValue('Discs')
  discs('Discs'),
  @JsonValue('Brake Cooling')
  brakeCooling('Brake Cooling'),
  @JsonValue('Fluid')
  fluid('Fluid'),
  @JsonValue('Rear Control Arms')
  rearControlArms('Rear Control Arms'),
  @JsonValue('Springs')
  springs('Springs'),
  @JsonValue('Upper Front Brace')
  upperFrontBrace('Upper Front Brace'),
  @JsonValue('Clutch')
  clutch('Clutch'),
  @JsonValue('Differential')
  differential('Differential'),
  @JsonValue('Flywheel')
  flywheel('Flywheel'),
  @JsonValue('Gearbox')
  gearbox('Gearbox'),
  @JsonValue('Shifting')
  shifting('Shifting'),
  @JsonValue('Boot')
  boot('Boot'),
  @JsonValue('Hood')
  hood('Hood'),
  @JsonValue('Interior')
  interior('Interior'),
  @JsonValue('Roof')
  roof('Roof'),
  @JsonValue('Steering wheel')
  steeringWheel('Steering wheel'),
  @JsonValue('Strip out')
  stripOut('Strip out'),
  @JsonValue('Windows')
  windows('Windows'),
  @JsonValue('Tyres')
  tyres('Tyres'),
  @JsonValue('Wheels')
  wheels('Wheels'),
  @JsonValue('Rear Bushes')
  rearBushes('Rear Bushes'),
  @JsonValue('Rear Brace')
  rearBrace('Rear Brace'),
  @JsonValue('Lower Front Brace')
  lowerFrontBrace('Lower Front Brace'),
  @JsonValue('Front Tie Rods')
  frontTieRods('Front Tie Rods'),
  @JsonValue('Front Bushes')
  frontBushes('Front Bushes'),
  @JsonValue('Seat')
  seat('Seat'),
  @JsonValue('Safety Accessory')
  safetyAccessory('Safety Accessory'),
  @JsonValue('Roll cage')
  rollCage('Roll cage'),
  @JsonValue('Overalls')
  overalls('Overalls'),
  @JsonValue('Helmet')
  helmet('Helmet'),
  @JsonValue('Fire Extinguisher')
  fireExtinguisher('Fire Extinguisher'),
  @JsonValue('Cut-off')
  cutOff('Cut-off'),
  @JsonValue('Fuel')
  fuel('Fuel'),
  @JsonValue('Manifold')
  manifold('Manifold'),
  @JsonValue('Exhaust')
  exhaust('Exhaust'),
  @JsonValue('Air Filter')
  airFilter('Air Filter'),
  @JsonValue('Turbo')
  turbo('Turbo'),
  @JsonValue('Pistons')
  pistons('Pistons'),
  @JsonValue('Intercooler')
  intercooler('Intercooler'),
  @JsonValue('Gasket')
  gasket('Gasket'),
  @JsonValue('Fuel Pump')
  fuelPump('Fuel Pump'),
  @JsonValue('Engine Porting')
  enginePorting('Engine Porting'),
  @JsonValue('Engine Cleaning')
  engineCleaning('Engine Cleaning'),
  @JsonValue('Computer')
  computer('Computer'),
  @JsonValue('Camshaft')
  camshaft('Camshaft'),
  @JsonValue('Pads')
  pads('Pads'),
  @JsonValue('Fluid')
  $fluid('Fluid');

  final String? value;

  const RaceCarUpgradeSubCategory(this.value);
}

enum ForumFeedTypeEnum {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue(1)
  value_1(1),
  @JsonValue(2)
  value_2(2),
  @JsonValue(3)
  value_3(3),
  @JsonValue(4)
  value_4(4),
  @JsonValue(5)
  value_5(5),
  @JsonValue(6)
  value_6(6),
  @JsonValue(7)
  value_7(7);

  final int? value;

  const ForumFeedTypeEnum(this.value);
}

enum ReviveSetting {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('Everyone')
  everyone('Everyone'),
  @JsonValue('Friends & faction')
  friendsFaction('Friends & faction'),
  @JsonValue('No one')
  noOne('No one'),
  @JsonValue('Unknown')
  unknown('Unknown');

  final String? value;

  const ReviveSetting(this.value);
}

enum ApiSort {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('DESC')
  desc('DESC'),
  @JsonValue('ASC')
  asc('ASC');

  final String? value;

  const ApiSort(this.value);
}

enum ApiStripTagsTrue {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('true')
  $true('true'),
  @JsonValue('false')
  $false('false');

  final String? value;

  const ApiStripTagsTrue(this.value);
}

enum ApiStripTagsFalse {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('true')
  $true('true'),
  @JsonValue('false')
  $false('false');

  final String? value;

  const ApiStripTagsFalse(this.value);
}

enum FactionSelectionsMembersGetStriptags {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('true')
  $true('true'),
  @JsonValue('false')
  $false('false');

  final String? value;

  const FactionSelectionsMembersGetStriptags(this.value);
}

enum ForumSelectionsThreadsGetSort {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('DESC')
  desc('DESC'),
  @JsonValue('ASC')
  asc('ASC');

  final String? value;

  const ForumSelectionsThreadsGetSort(this.value);
}

enum ForumSelectionsPostsGetCat {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('raw')
  raw('raw'),
  @JsonValue('plain')
  plain('plain');

  final String? value;

  const ForumSelectionsPostsGetCat(this.value);
}

enum RacingSelectionsRacesGetSort {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('DESC')
  desc('DESC'),
  @JsonValue('ASC')
  asc('ASC');

  final String? value;

  const RacingSelectionsRacesGetSort(this.value);
}

enum RacingSelectionsRacesGetCat {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('official')
  official('official'),
  @JsonValue('custom')
  custom('custom');

  final String? value;

  const RacingSelectionsRacesGetCat(this.value);
}

enum UserSelectionsRacesGetSort {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('DESC')
  desc('DESC'),
  @JsonValue('ASC')
  asc('ASC');

  final String? value;

  const UserSelectionsRacesGetSort(this.value);
}

enum UserSelectionsRacesGetCat {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('official')
  official('official'),
  @JsonValue('custom')
  custom('custom');

  final String? value;

  const UserSelectionsRacesGetCat(this.value);
}

enum UserSelectionsForumpostsGetCat {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('raw')
  raw('raw'),
  @JsonValue('plain')
  plain('plain');

  final String? value;

  const UserSelectionsForumpostsGetCat(this.value);
}

enum UserSelectionsForumpostsGetSort {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('DESC')
  desc('DESC'),
  @JsonValue('ASC')
  asc('ASC');

  final String? value;

  const UserSelectionsForumpostsGetSort(this.value);
}

enum UserSelectionsForumthreadsGetSort {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('DESC')
  desc('DESC'),
  @JsonValue('ASC')
  asc('ASC');

  final String? value;

  const UserSelectionsForumthreadsGetSort(this.value);
}
