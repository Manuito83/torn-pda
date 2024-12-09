import 'package:json_annotation/json_annotation.dart';

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

  @JsonValue('Any')
  any('Any'),
  @JsonValue('Double')
  double('Double'),
  @JsonValue('Yellow')
  yellow('Yellow'),
  @JsonValue('Orange')
  orange('Orange'),
  @JsonValue('Red')
  red('Red'),
  @JsonValue('Achilles')
  achilles('Achilles'),
  @JsonValue('Assassinate')
  assassinate('Assassinate'),
  @JsonValue('Backstab')
  backstab('Backstab'),
  @JsonValue('Berserk')
  berserk('Berserk'),
  @JsonValue('Bleed')
  bleed('Bleed'),
  @JsonValue('Blindfire')
  blindfire('Blindfire'),
  @JsonValue('Blindside')
  blindside('Blindside'),
  @JsonValue('Bloodlust')
  bloodlust('Bloodlust'),
  @JsonValue('Burn')
  burn('Burn'),
  @JsonValue('Comeback')
  comeback('Comeback'),
  @JsonValue('Conserve')
  conserve('Conserve'),
  @JsonValue('Cripple')
  cripple('Cripple'),
  @JsonValue('Crusher')
  crusher('Crusher'),
  @JsonValue('Cupid')
  cupid('Cupid'),
  @JsonValue('Deadeye')
  deadeye('Deadeye'),
  @JsonValue('Deadly')
  deadly('Deadly'),
  @JsonValue('Demoralize')
  demoralize('Demoralize'),
  @JsonValue('Disarm')
  disarm('Disarm'),
  @JsonValue('Double-edged')
  doubleEdged('Double-edged'),
  @JsonValue('Double Tap')
  doubleTap('Double Tap'),
  @JsonValue('Emasculate')
  emasculate('Emasculate'),
  @JsonValue('Empower')
  empower('Empower'),
  @JsonValue('Eviscerate')
  eviscerate('Eviscerate'),
  @JsonValue('Execute')
  execute('Execute'),
  @JsonValue('Expose')
  expose('Expose'),
  @JsonValue('Finale')
  finale('Finale'),
  @JsonValue('Focus')
  focus('Focus'),
  @JsonValue('Freeze')
  freeze('Freeze'),
  @JsonValue('Frenzy')
  frenzy('Frenzy'),
  @JsonValue('Fury')
  fury('Fury'),
  @JsonValue('Grace')
  grace('Grace'),
  @JsonValue('Hazardous')
  hazardous('Hazardous'),
  @JsonValue('Home run')
  homeRun('Home run'),
  @JsonValue('Irradiate')
  irradiate('Irradiate'),
  @JsonValue('Lacerate')
  lacerate('Lacerate'),
  @JsonValue('Motivation')
  motivation('Motivation'),
  @JsonValue('Paralyze')
  paralyze('Paralyze'),
  @JsonValue('Parry')
  parry('Parry'),
  @JsonValue('Penetrate')
  penetrate('Penetrate'),
  @JsonValue('Plunder')
  plunder('Plunder'),
  @JsonValue('Poison')
  poison('Poison'),
  @JsonValue('Powerful')
  powerful('Powerful'),
  @JsonValue('Proficience')
  proficience('Proficience'),
  @JsonValue('Puncture')
  puncture('Puncture'),
  @JsonValue('Quicken')
  quicken('Quicken'),
  @JsonValue('Rage')
  rage('Rage'),
  @JsonValue('Revitalize')
  revitalize('Revitalize'),
  @JsonValue('Roshambo')
  roshambo('Roshambo'),
  @JsonValue('Shock')
  shock('Shock'),
  @JsonValue('Sleep')
  sleep('Sleep'),
  @JsonValue('Slow')
  slow('Slow'),
  @JsonValue('Smash')
  smash('Smash'),
  @JsonValue('Smurf')
  smurf('Smurf'),
  @JsonValue('Specialist')
  specialist('Specialist'),
  @JsonValue('Spray')
  spray('Spray'),
  @JsonValue('Storage')
  storage('Storage'),
  @JsonValue('Stricken')
  stricken('Stricken'),
  @JsonValue('Stun')
  stun('Stun'),
  @JsonValue('Suppress')
  suppress('Suppress'),
  @JsonValue('Sure Shot')
  sureShot('Sure Shot'),
  @JsonValue('Throttle')
  throttle('Throttle'),
  @JsonValue('Toxin')
  toxin('Toxin'),
  @JsonValue('Warlord')
  warlord('Warlord'),
  @JsonValue('Weaken')
  weaken('Weaken'),
  @JsonValue('Wind-up')
  windUp('Wind-up'),
  @JsonValue('Wither')
  wither('Wither');

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

enum FactionApplicationStatusEnum {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('accepted')
  accepted('accepted'),
  @JsonValue('declined')
  declined('declined'),
  @JsonValue('withdrawn')
  withdrawn('withdrawn');

  final String? value;

  const FactionApplicationStatusEnum(this.value);
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

enum FactionSelectionName {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('applications')
  applications('applications'),
  @JsonValue('armor')
  armor('armor'),
  @JsonValue('attacks')
  attacks('attacks'),
  @JsonValue('attacksfull')
  attacksfull('attacksfull'),
  @JsonValue('basic')
  basic('basic'),
  @JsonValue('boosters')
  boosters('boosters'),
  @JsonValue('caches')
  caches('caches'),
  @JsonValue('cesium')
  cesium('cesium'),
  @JsonValue('chain')
  chain('chain'),
  @JsonValue('chainreport')
  chainreport('chainreport'),
  @JsonValue('chains')
  chains('chains'),
  @JsonValue('contributors')
  contributors('contributors'),
  @JsonValue('crimeexp')
  crimeexp('crimeexp'),
  @JsonValue('crimenews')
  crimenews('crimenews'),
  @JsonValue('crimes')
  crimes('crimes'),
  @JsonValue('currency')
  currency('currency'),
  @JsonValue('donations')
  donations('donations'),
  @JsonValue('drugs')
  drugs('drugs'),
  @JsonValue('hof')
  hof('hof'),
  @JsonValue('lookup')
  lookup('lookup'),
  @JsonValue('medical')
  medical('medical'),
  @JsonValue('members')
  members('members'),
  @JsonValue('news')
  news('news'),
  @JsonValue('positions')
  positions('positions'),
  @JsonValue('rankedwars')
  rankedwars('rankedwars'),
  @JsonValue('reports')
  reports('reports'),
  @JsonValue('revives')
  revives('revives'),
  @JsonValue('revivesfull')
  revivesfull('revivesfull'),
  @JsonValue('stats')
  stats('stats'),
  @JsonValue('temporary')
  temporary('temporary'),
  @JsonValue('territory')
  territory('territory'),
  @JsonValue('territorynews')
  territorynews('territorynews'),
  @JsonValue('timestamp')
  timestamp('timestamp'),
  @JsonValue('upgrades')
  upgrades('upgrades'),
  @JsonValue('wars')
  wars('wars'),
  @JsonValue('weapons')
  weapons('weapons');

  final String? value;

  const FactionSelectionName(this.value);
}

enum ForumSelectionName {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('categories')
  categories('categories'),
  @JsonValue('lookup')
  lookup('lookup'),
  @JsonValue('posts')
  posts('posts'),
  @JsonValue('thread')
  thread('thread'),
  @JsonValue('threads')
  threads('threads'),
  @JsonValue('timestamp')
  timestamp('timestamp');

  final String? value;

  const ForumSelectionName(this.value);
}

enum ItemMarketListingItemDetailsRarity {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('yellow')
  yellow('yellow'),
  @JsonValue('orange')
  orange('orange'),
  @JsonValue('red')
  red('red');

  final String? value;

  const ItemMarketListingItemDetailsRarity(this.value);
}

enum MarketSelectionName {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('itemmarket')
  itemmarket('itemmarket'),
  @JsonValue('lookup')
  lookup('lookup'),
  @JsonValue('pointsmarket')
  pointsmarket('pointsmarket'),
  @JsonValue('timestamp')
  timestamp('timestamp');

  final String? value;

  const MarketSelectionName(this.value);
}

enum RacingSelectionName {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('cars')
  cars('cars'),
  @JsonValue('carupgrades')
  carupgrades('carupgrades'),
  @JsonValue('lookup')
  lookup('lookup'),
  @JsonValue('race')
  race('race'),
  @JsonValue('races')
  races('races'),
  @JsonValue('records')
  records('records'),
  @JsonValue('timestamp')
  timestamp('timestamp'),
  @JsonValue('tracks')
  tracks('tracks');

  final String? value;

  const RacingSelectionName(this.value);
}

enum TornSelectionName {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('bank')
  bank('bank'),
  @JsonValue('calendar')
  calendar('calendar'),
  @JsonValue('cards')
  cards('cards'),
  @JsonValue('chainreport')
  chainreport('chainreport'),
  @JsonValue('cityshops')
  cityshops('cityshops'),
  @JsonValue('companies')
  companies('companies'),
  @JsonValue('competition')
  competition('competition'),
  @JsonValue('crimes')
  crimes('crimes'),
  @JsonValue('dirtybombs')
  dirtybombs('dirtybombs'),
  @JsonValue('education')
  education('education'),
  @JsonValue('factionHof')
  factionhof('factionHof'),
  @JsonValue('factiontree')
  factiontree('factiontree'),
  @JsonValue('gyms')
  gyms('gyms'),
  @JsonValue('hof')
  hof('hof'),
  @JsonValue('honors')
  honors('honors'),
  @JsonValue('itemdetails')
  itemdetails('itemdetails'),
  @JsonValue('items')
  items('items'),
  @JsonValue('itemstats')
  itemstats('itemstats'),
  @JsonValue('logcategories')
  logcategories('logcategories'),
  @JsonValue('logtypes')
  logtypes('logtypes'),
  @JsonValue('lookup')
  lookup('lookup'),
  @JsonValue('medals')
  medals('medals'),
  @JsonValue('organisedcrimes')
  organisedcrimes('organisedcrimes'),
  @JsonValue('pawnshop')
  pawnshop('pawnshop'),
  @JsonValue('pokertables')
  pokertables('pokertables'),
  @JsonValue('properties')
  properties('properties'),
  @JsonValue('rackets')
  rackets('rackets'),
  @JsonValue('raidreport')
  raidreport('raidreport'),
  @JsonValue('raids')
  raids('raids'),
  @JsonValue('rankedwarreport')
  rankedwarreport('rankedwarreport'),
  @JsonValue('rankedwars')
  rankedwars('rankedwars'),
  @JsonValue('rockpaperscissors')
  rockpaperscissors('rockpaperscissors'),
  @JsonValue('searchforcash')
  searchforcash('searchforcash'),
  @JsonValue('shoplifting')
  shoplifting('shoplifting'),
  @JsonValue('stats')
  stats('stats'),
  @JsonValue('stocks')
  stocks('stocks'),
  @JsonValue('subcrimes')
  subcrimes('subcrimes'),
  @JsonValue('territory')
  territory('territory'),
  @JsonValue('territorynames')
  territorynames('territorynames'),
  @JsonValue('territorywarreport')
  territorywarreport('territorywarreport'),
  @JsonValue('territorywars')
  territorywars('territorywars'),
  @JsonValue('timestamp')
  timestamp('timestamp');

  final String? value;

  const TornSelectionName(this.value);
}

enum PersonalStatsCategoryEnum {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('all')
  all('all'),
  @JsonValue('popular')
  popular('popular'),
  @JsonValue('attacking')
  attacking('attacking'),
  @JsonValue('battle_stats')
  battleStats('battle_stats'),
  @JsonValue('jobs')
  jobs('jobs'),
  @JsonValue('trading')
  trading('trading'),
  @JsonValue('jail')
  jail('jail'),
  @JsonValue('hospital')
  hospital('hospital'),
  @JsonValue('finishing_hits')
  finishingHits('finishing_hits'),
  @JsonValue('communication')
  communication('communication'),
  @JsonValue('criminal_offenses')
  criminalOffenses('criminal_offenses'),
  @JsonValue('bounties')
  bounties('bounties'),
  @JsonValue('investments')
  investments('investments'),
  @JsonValue('items')
  items('items'),
  @JsonValue('travel')
  travel('travel'),
  @JsonValue('drugs')
  drugs('drugs'),
  @JsonValue('missions')
  missions('missions'),
  @JsonValue('racing')
  racing('racing'),
  @JsonValue('networth')
  networth('networth'),
  @JsonValue('other')
  other('other');

  final String? value;

  const PersonalStatsCategoryEnum(this.value);
}

enum PersonalStatsStatName {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('attackswon')
  attackswon('attackswon'),
  @JsonValue('attackslost')
  attackslost('attackslost'),
  @JsonValue('attacksdraw')
  attacksdraw('attacksdraw'),
  @JsonValue('attacksassisted')
  attacksassisted('attacksassisted'),
  @JsonValue('defendswon')
  defendswon('defendswon'),
  @JsonValue('defendslost')
  defendslost('defendslost'),
  @JsonValue('defendsstalemated')
  defendsstalemated('defendsstalemated'),
  @JsonValue('elo')
  elo('elo'),
  @JsonValue('yourunaway')
  yourunaway('yourunaway'),
  @JsonValue('theyrunaway')
  theyrunaway('theyrunaway'),
  @JsonValue('unarmoredwon')
  unarmoredwon('unarmoredwon'),
  @JsonValue('bestkillstreak')
  bestkillstreak('bestkillstreak'),
  @JsonValue('attackhits')
  attackhits('attackhits'),
  @JsonValue('attackmisses')
  attackmisses('attackmisses'),
  @JsonValue('attackdamage')
  attackdamage('attackdamage'),
  @JsonValue('bestdamage')
  bestdamage('bestdamage'),
  @JsonValue('onehitkills')
  onehitkills('onehitkills'),
  @JsonValue('attackcriticalhits')
  attackcriticalhits('attackcriticalhits'),
  @JsonValue('roundsfired')
  roundsfired('roundsfired'),
  @JsonValue('specialammoused')
  specialammoused('specialammoused'),
  @JsonValue('hollowammoused')
  hollowammoused('hollowammoused'),
  @JsonValue('tracerammoused')
  tracerammoused('tracerammoused'),
  @JsonValue('piercingammoused')
  piercingammoused('piercingammoused'),
  @JsonValue('incendiaryammoused')
  incendiaryammoused('incendiaryammoused'),
  @JsonValue('attacksstealthed')
  attacksstealthed('attacksstealthed'),
  @JsonValue('retals')
  retals('retals'),
  @JsonValue('moneymugged')
  moneymugged('moneymugged'),
  @JsonValue('largestmug')
  largestmug('largestmug'),
  @JsonValue('itemslooted')
  itemslooted('itemslooted'),
  @JsonValue('highestbeaten')
  highestbeaten('highestbeaten'),
  @JsonValue('respectforfaction')
  respectforfaction('respectforfaction'),
  @JsonValue('rankedwarhits')
  rankedwarhits('rankedwarhits'),
  @JsonValue('raidhits')
  raidhits('raidhits'),
  @JsonValue('territoryjoins')
  territoryjoins('territoryjoins'),
  @JsonValue('territoryclears')
  territoryclears('territoryclears'),
  @JsonValue('territorytime')
  territorytime('territorytime'),
  @JsonValue('jobpointsused')
  jobpointsused('jobpointsused'),
  @JsonValue('trainsreceived')
  trainsreceived('trainsreceived'),
  @JsonValue('marketitemsbought')
  marketitemsbought('marketitemsbought'),
  @JsonValue('auctionswon')
  auctionswon('auctionswon'),
  @JsonValue('auctionsells')
  auctionsells('auctionsells'),
  @JsonValue('itemssent')
  itemssent('itemssent'),
  @JsonValue('trades')
  trades('trades'),
  @JsonValue('cityitemsbought')
  cityitemsbought('cityitemsbought'),
  @JsonValue('pointsbought')
  pointsbought('pointsbought'),
  @JsonValue('pointssold')
  pointssold('pointssold'),
  @JsonValue('bazaarcustomers')
  bazaarcustomers('bazaarcustomers'),
  @JsonValue('bazaarsales')
  bazaarsales('bazaarsales'),
  @JsonValue('bazaarprofit')
  bazaarprofit('bazaarprofit'),
  @JsonValue('jailed')
  jailed('jailed'),
  @JsonValue('peoplebusted')
  peoplebusted('peoplebusted'),
  @JsonValue('failedbusts')
  failedbusts('failedbusts'),
  @JsonValue('peoplebought')
  peoplebought('peoplebought'),
  @JsonValue('peopleboughtspent')
  peopleboughtspent('peopleboughtspent'),
  @JsonValue('hospital')
  hospital('hospital'),
  @JsonValue('medicalitemsused')
  medicalitemsused('medicalitemsused'),
  @JsonValue('bloodwithdrawn')
  bloodwithdrawn('bloodwithdrawn'),
  @JsonValue('reviveskill')
  reviveskill('reviveskill'),
  @JsonValue('revives')
  revives('revives'),
  @JsonValue('revivesreceived')
  revivesreceived('revivesreceived'),
  @JsonValue('heavyhits')
  heavyhits('heavyhits'),
  @JsonValue('machinehits')
  machinehits('machinehits'),
  @JsonValue('riflehits')
  riflehits('riflehits'),
  @JsonValue('smghits')
  smghits('smghits'),
  @JsonValue('shotgunhits')
  shotgunhits('shotgunhits'),
  @JsonValue('pistolhits')
  pistolhits('pistolhits'),
  @JsonValue('temphits')
  temphits('temphits'),
  @JsonValue('piercinghits')
  piercinghits('piercinghits'),
  @JsonValue('slashinghits')
  slashinghits('slashinghits'),
  @JsonValue('clubbinghits')
  clubbinghits('clubbinghits'),
  @JsonValue('mechanicalhits')
  mechanicalhits('mechanicalhits'),
  @JsonValue('h2hhits')
  h2hhits('h2hhits'),
  @JsonValue('mailssent')
  mailssent('mailssent'),
  @JsonValue('friendmailssent')
  friendmailssent('friendmailssent'),
  @JsonValue('factionmailssent')
  factionmailssent('factionmailssent'),
  @JsonValue('companymailssent')
  companymailssent('companymailssent'),
  @JsonValue('spousemailssent')
  spousemailssent('spousemailssent'),
  @JsonValue('classifiedadsplaced')
  classifiedadsplaced('classifiedadsplaced'),
  @JsonValue('personalsplaced')
  personalsplaced('personalsplaced'),
  @JsonValue('criminaloffensesold')
  criminaloffensesold('criminaloffensesold'),
  @JsonValue('sellillegalgoods')
  sellillegalgoods('sellillegalgoods'),
  @JsonValue('theftold')
  theftold('theftold'),
  @JsonValue('autotheftcrime')
  autotheftcrime('autotheftcrime'),
  @JsonValue('drugdealscrime')
  drugdealscrime('drugdealscrime'),
  @JsonValue('computercrime')
  computercrime('computercrime'),
  @JsonValue('arsoncrime')
  arsoncrime('arsoncrime'),
  @JsonValue('murdercrime')
  murdercrime('murdercrime'),
  @JsonValue('othercrime')
  othercrime('othercrime'),
  @JsonValue('organizedcrimes')
  organizedcrimes('organizedcrimes'),
  @JsonValue('bountiesplaced')
  bountiesplaced('bountiesplaced'),
  @JsonValue('totalbountyspent')
  totalbountyspent('totalbountyspent'),
  @JsonValue('bountiescollected')
  bountiescollected('bountiescollected'),
  @JsonValue('totalbountyreward')
  totalbountyreward('totalbountyreward'),
  @JsonValue('bountiesreceived')
  bountiesreceived('bountiesreceived'),
  @JsonValue('receivedbountyvalue')
  receivedbountyvalue('receivedbountyvalue'),
  @JsonValue('cityfinds')
  cityfinds('cityfinds'),
  @JsonValue('dumpfinds')
  dumpfinds('dumpfinds'),
  @JsonValue('itemsdumped')
  itemsdumped('itemsdumped'),
  @JsonValue('booksread')
  booksread('booksread'),
  @JsonValue('boostersused')
  boostersused('boostersused'),
  @JsonValue('consumablesused')
  consumablesused('consumablesused'),
  @JsonValue('candyused')
  candyused('candyused'),
  @JsonValue('alcoholused')
  alcoholused('alcoholused'),
  @JsonValue('energydrinkused')
  energydrinkused('energydrinkused'),
  @JsonValue('statenhancersused')
  statenhancersused('statenhancersused'),
  @JsonValue('eastereggsfound')
  eastereggsfound('eastereggsfound'),
  @JsonValue('eastereggsused')
  eastereggsused('eastereggsused'),
  @JsonValue('virusescoded')
  virusescoded('virusescoded'),
  @JsonValue('traveltimes')
  traveltimes('traveltimes'),
  @JsonValue('timespenttraveling')
  timespenttraveling('timespenttraveling'),
  @JsonValue('itemsboughtabroad')
  itemsboughtabroad('itemsboughtabroad'),
  @JsonValue('hunting')
  hunting('hunting'),
  @JsonValue('attackswonabroad')
  attackswonabroad('attackswonabroad'),
  @JsonValue('defendslostabroad')
  defendslostabroad('defendslostabroad'),
  @JsonValue('argtravel')
  argtravel('argtravel'),
  @JsonValue('mextravel')
  mextravel('mextravel'),
  @JsonValue('uaetravel')
  uaetravel('uaetravel'),
  @JsonValue('hawtravel')
  hawtravel('hawtravel'),
  @JsonValue('japtravel')
  japtravel('japtravel'),
  @JsonValue('uktravel')
  uktravel('uktravel'),
  @JsonValue('satravel')
  satravel('satravel'),
  @JsonValue('switravel')
  switravel('switravel'),
  @JsonValue('chitravel')
  chitravel('chitravel'),
  @JsonValue('cantravel')
  cantravel('cantravel'),
  @JsonValue('caytravel')
  caytravel('caytravel'),
  @JsonValue('drugsused')
  drugsused('drugsused'),
  @JsonValue('overdosed')
  overdosed('overdosed'),
  @JsonValue('rehabs')
  rehabs('rehabs'),
  @JsonValue('rehabcost')
  rehabcost('rehabcost'),
  @JsonValue('cantaken')
  cantaken('cantaken'),
  @JsonValue('exttaken')
  exttaken('exttaken'),
  @JsonValue('kettaken')
  kettaken('kettaken'),
  @JsonValue('lsdtaken')
  lsdtaken('lsdtaken'),
  @JsonValue('opitaken')
  opitaken('opitaken'),
  @JsonValue('pcptaken')
  pcptaken('pcptaken'),
  @JsonValue('shrtaken')
  shrtaken('shrtaken'),
  @JsonValue('spetaken')
  spetaken('spetaken'),
  @JsonValue('victaken')
  victaken('victaken'),
  @JsonValue('xantaken')
  xantaken('xantaken'),
  @JsonValue('missionscompleted')
  missionscompleted('missionscompleted'),
  @JsonValue('contractscompleted')
  contractscompleted('contractscompleted'),
  @JsonValue('dukecontractscompleted')
  dukecontractscompleted('dukecontractscompleted'),
  @JsonValue('missioncreditsearned')
  missioncreditsearned('missioncreditsearned'),
  @JsonValue('racingskill')
  racingskill('racingskill'),
  @JsonValue('racingpointsearned')
  racingpointsearned('racingpointsearned'),
  @JsonValue('racesentered')
  racesentered('racesentered'),
  @JsonValue('raceswon')
  raceswon('raceswon'),
  @JsonValue('networth')
  networth('networth'),
  @JsonValue('timeplayed')
  timeplayed('timeplayed'),
  @JsonValue('activestreak')
  activestreak('activestreak'),
  @JsonValue('bestactivestreak')
  bestactivestreak('bestactivestreak'),
  @JsonValue('awards')
  awards('awards'),
  @JsonValue('refills')
  refills('refills'),
  @JsonValue('nerverefills')
  nerverefills('nerverefills'),
  @JsonValue('tokenrefills')
  tokenrefills('tokenrefills'),
  @JsonValue('meritsbought')
  meritsbought('meritsbought'),
  @JsonValue('daysbeendonator')
  daysbeendonator('daysbeendonator'),
  @JsonValue('daysbeendonator')
  $daysbeendonator('daysbeendonator'),
  @JsonValue('criminaloffenses')
  criminaloffenses('criminaloffenses'),
  @JsonValue('vandalism')
  vandalism('vandalism'),
  @JsonValue('theft')
  theft('theft'),
  @JsonValue('counterfeiting')
  counterfeiting('counterfeiting'),
  @JsonValue('fraud')
  fraud('fraud'),
  @JsonValue('illicitservices')
  illicitservices('illicitservices'),
  @JsonValue('cybercrime')
  cybercrime('cybercrime'),
  @JsonValue('extortion')
  extortion('extortion'),
  @JsonValue('illegalproduction')
  illegalproduction('illegalproduction'),
  @JsonValue('currentkillstreak')
  currentkillstreak('currentkillstreak'),
  @JsonValue('strength')
  strength('strength'),
  @JsonValue('defense')
  defense('defense'),
  @JsonValue('speed')
  speed('speed'),
  @JsonValue('dexterity')
  dexterity('dexterity'),
  @JsonValue('totalstats')
  totalstats('totalstats'),
  @JsonValue('manuallabor')
  manuallabor('manuallabor'),
  @JsonValue('intelligence')
  intelligence('intelligence'),
  @JsonValue('endurance')
  endurance('endurance'),
  @JsonValue('totalworkingstats')
  totalworkingstats('totalworkingstats'),
  @JsonValue('moneyinvested')
  moneyinvested('moneyinvested'),
  @JsonValue('investedprofit')
  investedprofit('investedprofit'),
  @JsonValue('investamount')
  investamount('investamount'),
  @JsonValue('banktimeleft')
  banktimeleft('banktimeleft'),
  @JsonValue('stockprofits')
  stockprofits('stockprofits'),
  @JsonValue('stocklosses')
  stocklosses('stocklosses'),
  @JsonValue('stockfees')
  stockfees('stockfees'),
  @JsonValue('stocknetprofits')
  stocknetprofits('stocknetprofits'),
  @JsonValue('stockpayouts')
  stockpayouts('stockpayouts'),
  @JsonValue('networthwallet')
  networthwallet('networthwallet'),
  @JsonValue('networthvault')
  networthvault('networthvault'),
  @JsonValue('networthbank')
  networthbank('networthbank'),
  @JsonValue('networthcayman')
  networthcayman('networthcayman'),
  @JsonValue('networthpoints')
  networthpoints('networthpoints'),
  @JsonValue('networthitems')
  networthitems('networthitems'),
  @JsonValue('networthdisplaycase')
  networthdisplaycase('networthdisplaycase'),
  @JsonValue('networthbazaar')
  networthbazaar('networthbazaar'),
  @JsonValue('networthitemmarket')
  networthitemmarket('networthitemmarket'),
  @JsonValue('networthproperties')
  networthproperties('networthproperties'),
  @JsonValue('networthstockmarket')
  networthstockmarket('networthstockmarket'),
  @JsonValue('networthauctionhouse')
  networthauctionhouse('networthauctionhouse'),
  @JsonValue('networthbookie')
  networthbookie('networthbookie'),
  @JsonValue('networthcompany')
  networthcompany('networthcompany'),
  @JsonValue('networthenlistedcars')
  networthenlistedcars('networthenlistedcars'),
  @JsonValue('networthpiggybank')
  networthpiggybank('networthpiggybank'),
  @JsonValue('networthpending')
  networthpending('networthpending'),
  @JsonValue('networthloan')
  networthloan('networthloan'),
  @JsonValue('networthunpaidfees')
  networthunpaidfees('networthunpaidfees');

  final String? value;

  const PersonalStatsStatName(this.value);
}

enum UserItemMarkeListingItemDetailsRarity {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('yellow')
  yellow('yellow'),
  @JsonValue('orange')
  orange('orange'),
  @JsonValue('red')
  red('red');

  final String? value;

  const UserItemMarkeListingItemDetailsRarity(this.value);
}

enum UserSelectionName {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('ammo')
  ammo('ammo'),
  @JsonValue('attacks')
  attacks('attacks'),
  @JsonValue('attacksfull')
  attacksfull('attacksfull'),
  @JsonValue('bars')
  bars('bars'),
  @JsonValue('basic')
  basic('basic'),
  @JsonValue('battlestats')
  battlestats('battlestats'),
  @JsonValue('bazaar')
  bazaar('bazaar'),
  @JsonValue('calendar')
  calendar('calendar'),
  @JsonValue('cooldowns')
  cooldowns('cooldowns'),
  @JsonValue('crimes')
  crimes('crimes'),
  @JsonValue('criminalrecord')
  criminalrecord('criminalrecord'),
  @JsonValue('discord')
  discord('discord'),
  @JsonValue('display')
  display('display'),
  @JsonValue('education')
  education('education'),
  @JsonValue('enlistedcars')
  enlistedcars('enlistedcars'),
  @JsonValue('equipment')
  equipment('equipment'),
  @JsonValue('events')
  events('events'),
  @JsonValue('forumfeed')
  forumfeed('forumfeed'),
  @JsonValue('forumfriends')
  forumfriends('forumfriends'),
  @JsonValue('forumposts')
  forumposts('forumposts'),
  @JsonValue('forumsubscribedthreads')
  forumsubscribedthreads('forumsubscribedthreads'),
  @JsonValue('forumthreads')
  forumthreads('forumthreads'),
  @JsonValue('gym')
  gym('gym'),
  @JsonValue('hof')
  hof('hof'),
  @JsonValue('honors')
  honors('honors'),
  @JsonValue('icons')
  icons('icons'),
  @JsonValue('inventory')
  inventory('inventory'),
  @JsonValue('itemmarket')
  itemmarket('itemmarket'),
  @JsonValue('jobpoints')
  jobpoints('jobpoints'),
  @JsonValue('log')
  log('log'),
  @JsonValue('lookup')
  lookup('lookup'),
  @JsonValue('medals')
  medals('medals'),
  @JsonValue('merits')
  merits('merits'),
  @JsonValue('messages')
  messages('messages'),
  @JsonValue('missions')
  missions('missions'),
  @JsonValue('money')
  money('money'),
  @JsonValue('networth')
  networth('networth'),
  @JsonValue('newevents')
  newevents('newevents'),
  @JsonValue('newmessages')
  newmessages('newmessages'),
  @JsonValue('notifications')
  notifications('notifications'),
  @JsonValue('perks')
  perks('perks'),
  @JsonValue('personalstats')
  personalstats('personalstats'),
  @JsonValue('profile')
  profile('profile'),
  @JsonValue('properties')
  properties('properties'),
  @JsonValue('publicStatus')
  publicstatus('publicStatus'),
  @JsonValue('races')
  races('races'),
  @JsonValue('refills')
  refills('refills'),
  @JsonValue('reports')
  reports('reports'),
  @JsonValue('revives')
  revives('revives'),
  @JsonValue('revivesfull')
  revivesfull('revivesfull'),
  @JsonValue('skills')
  skills('skills'),
  @JsonValue('stocks')
  stocks('stocks'),
  @JsonValue('timestamp')
  timestamp('timestamp'),
  @JsonValue('travel')
  travel('travel'),
  @JsonValue('weaponexp')
  weaponexp('weaponexp'),
  @JsonValue('workstats')
  workstats('workstats');

  final String? value;

  const UserSelectionName(this.value);
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

enum ApiStripTags {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('true')
  $true('true'),
  @JsonValue('false')
  $false('false');

  final String? value;

  const ApiStripTags(this.value);
}

enum FactionGetSort {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('DESC')
  desc('DESC'),
  @JsonValue('ASC')
  asc('ASC');

  final String? value;

  const FactionGetSort(this.value);
}

enum ForumCategoryIdsThreadsGetSort {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('DESC')
  desc('DESC'),
  @JsonValue('ASC')
  asc('ASC');

  final String? value;

  const ForumCategoryIdsThreadsGetSort(this.value);
}

enum ForumThreadsGetSort {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('DESC')
  desc('DESC'),
  @JsonValue('ASC')
  asc('ASC');

  final String? value;

  const ForumThreadsGetSort(this.value);
}

enum ForumGetSort {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('DESC')
  desc('DESC'),
  @JsonValue('ASC')
  asc('ASC');

  final String? value;

  const ForumGetSort(this.value);
}

enum MarketGetSort {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('DESC')
  desc('DESC'),
  @JsonValue('ASC')
  asc('ASC');

  final String? value;

  const MarketGetSort(this.value);
}

enum RacingRacesGetSort {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('DESC')
  desc('DESC'),
  @JsonValue('ASC')
  asc('ASC');

  final String? value;

  const RacingRacesGetSort(this.value);
}

enum RacingRacesGetCat {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('official')
  official('official'),
  @JsonValue('custom')
  custom('custom');

  final String? value;

  const RacingRacesGetCat(this.value);
}

enum RacingGetSort {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('DESC')
  desc('DESC'),
  @JsonValue('ASC')
  asc('ASC');

  final String? value;

  const RacingGetSort(this.value);
}

enum TornGetSort {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('DESC')
  desc('DESC'),
  @JsonValue('ASC')
  asc('ASC');

  final String? value;

  const TornGetSort(this.value);
}

enum UserRacesGetSort {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('DESC')
  desc('DESC'),
  @JsonValue('ASC')
  asc('ASC');

  final String? value;

  const UserRacesGetSort(this.value);
}

enum UserRacesGetCat {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('official')
  official('official'),
  @JsonValue('custom')
  custom('custom');

  final String? value;

  const UserRacesGetCat(this.value);
}

enum UserIdForumpostsGetCat {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('raw')
  raw('raw'),
  @JsonValue('plain')
  plain('plain');

  final String? value;

  const UserIdForumpostsGetCat(this.value);
}

enum UserIdForumpostsGetSort {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('DESC')
  desc('DESC'),
  @JsonValue('ASC')
  asc('ASC');

  final String? value;

  const UserIdForumpostsGetSort(this.value);
}

enum UserForumpostsGetSort {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('DESC')
  desc('DESC'),
  @JsonValue('ASC')
  asc('ASC');

  final String? value;

  const UserForumpostsGetSort(this.value);
}

enum UserIdForumthreadsGetSort {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('DESC')
  desc('DESC'),
  @JsonValue('ASC')
  asc('ASC');

  final String? value;

  const UserIdForumthreadsGetSort(this.value);
}

enum UserForumthreadsGetSort {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('DESC')
  desc('DESC'),
  @JsonValue('ASC')
  asc('ASC');

  final String? value;

  const UserForumthreadsGetSort(this.value);
}

enum UserGetSort {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('DESC')
  desc('DESC'),
  @JsonValue('ASC')
  asc('ASC');

  final String? value;

  const UserGetSort(this.value);
}
