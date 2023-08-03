// To parse this JSON data, do
//
//     final ownPersonalStatsModel = ownPersonalStatsModelFromJson(jsonString);

import 'dart:convert';

OwnPersonalStatsModel ownPersonalStatsModelFromJson(String str) => OwnPersonalStatsModel.fromJson(json.decode(str));

String ownPersonalStatsModelToJson(OwnPersonalStatsModel data) => json.encode(data.toJson());

class OwnPersonalStatsModel {
  OwnPersonalStatsModel({
    this.personalstats,
  });

  Personalstats? personalstats;

  factory OwnPersonalStatsModel.fromJson(Map<String, dynamic> json) => OwnPersonalStatsModel(
        personalstats: json["personalstats"] == null ? null : Personalstats.fromJson(json["personalstats"]),
      );

  Map<String, dynamic> toJson() => {
        "personalstats": personalstats == null ? null : personalstats!.toJson(),
      };
}

class Personalstats {
  Personalstats({
    this.bazaarcustomers,
    this.bazaarsales,
    this.bazaarprofit,
    this.useractivity,
    this.activestreak,
    this.bestactivestreak,
    this.itemsbought,
    this.pointsbought,
    this.itemsboughtabroad,
    this.moneyinvested,
    this.investedprofit,
    this.weaponsbought,
    this.trades,
    this.itemssent,
    this.auctionswon,
    this.auctionsells,
    this.pointssold,
    this.attackswon,
    this.attackslost,
    this.attacksdraw,
    this.bestkillstreak,
    this.killstreak,
    this.moneymugged,
    this.attacksstealthed,
    this.attackhits,
    this.attackmisses,
    this.attackdamage,
    this.attackcriticalhits,
    this.respectforfaction,
    this.onehitkills,
    this.defendswon,
    this.defendslost,
    this.defendsstalemated,
    this.bestdamage,
    this.roundsfired,
    this.yourunaway,
    this.theyrunaway,
    this.highestbeaten,
    this.peoplebusted,
    this.failedbusts,
    this.peoplebought,
    this.peopleboughtspent,
    this.virusescoded,
    this.cityfinds,
    this.traveltimes,
    this.bountiesplaced,
    this.bountiesreceived,
    this.bountiescollected,
    this.totalbountyreward,
    this.revives,
    this.revivesreceived,
    this.medicalitemsused,
    this.statenhancersused,
    this.trainsreceived,
    this.totalbountyspent,
    this.drugsused,
    this.overdosed,
    this.meritsbought,
    this.personalsplaced,
    this.classifiedadsplaced,
    this.mailssent,
    this.friendmailssent,
    this.factionmailssent,
    this.companymailssent,
    this.spousemailssent,
    this.largestmug,
    this.cantaken,
    this.exttaken,
    this.kettaken,
    this.lsdtaken,
    this.opitaken,
    this.shrtaken,
    this.spetaken,
    this.pcptaken,
    this.xantaken,
    this.victaken,
    this.chahits,
    this.heahits,
    this.axehits,
    this.grehits,
    this.machits,
    this.pishits,
    this.rifhits,
    this.shohits,
    this.smghits,
    this.piehits,
    this.slahits,
    this.argtravel,
    this.mextravel,
    this.dubtravel,
    this.hawtravel,
    this.japtravel,
    this.lontravel,
    this.soutravel,
    this.switravel,
    this.chitravel,
    this.cantravel,
    this.dumpfinds,
    this.dumpsearches,
    this.itemsdumped,
    this.daysbeendonator,
    this.caytravel,
    this.jailed,
    this.hospital,
    this.attacksassisted,
    this.bloodwithdrawn,
    this.networth,
    this.missionscompleted,
    this.contractscompleted,
    this.dukecontractscompleted,
    this.missioncreditsearned,
    this.consumablesused,
    this.candyused,
    this.alcoholused,
    this.energydrinkused,
    this.nerverefills,
    this.unarmoredwon,
    this.h2Hhits,
    this.organisedcrimes,
    this.territorytime,
    this.territoryjoins,
    this.stockpayouts,
    this.stockprofits,
    this.stocklosses,
    this.stockfees,
    this.arrestsmade,
    this.tokenrefills,
    this.booksread,
    this.traveltime,
    this.boostersused,
    this.rehabs,
    this.rehabcost,
    this.awards,
    this.receivedbountyvalue,
    this.networthpending,
    this.networthwallet,
    this.networthbank,
    this.networthpoints,
    this.networthcayman,
    this.networthvault,
    this.networthpiggybank,
    this.networthitems,
    this.networthdisplaycase,
    this.networthbazaar,
    this.networthproperties,
    this.networthstockmarket,
    this.networthitemmarket,
    this.networthauctionhouse,
    this.networthcompany,
    this.networthbookie,
    this.networthenlistedcars,
    this.networthloan,
    this.networthunpaidfees,
    this.racingskill,
    this.raceswon,
    this.racesentered,
    this.racingpointsearned,
    this.specialammoused,
    this.cityitemsbought,
    this.hollowammoused,
    this.tracerammoused,
    this.piercingammoused,
    this.incendiaryammoused,
    this.attackswonabroad,
    this.defendslostabroad,
    this.retals,
    this.elo,
    this.strength,
    this.defense,
    this.speed,
    this.dexterity,
    this.totalstats,
    this.manuallabor,
    this.intelligence,
    this.endurance,
    this.totalworkingstats,
    this.jobpointsused,
    this.reviveskill,
    this.itemslooted,
    this.refills,
  });

  int? bazaarcustomers;
  int? bazaarsales;
  int? bazaarprofit;
  int? useractivity;
  int? activestreak;
  int? bestactivestreak;
  int? itemsbought;
  int? pointsbought;
  int? itemsboughtabroad;
  int? moneyinvested;
  int? investedprofit;
  int? weaponsbought;
  int? trades;
  int? itemssent;
  int? auctionswon;
  int? auctionsells;
  int? pointssold;
  int? attackswon;
  int? attackslost;
  int? attacksdraw;
  int? bestkillstreak;
  int? killstreak;
  int? moneymugged;
  int? attacksstealthed;
  int? attackhits;
  int? attackmisses;
  int? attackdamage;
  int? attackcriticalhits;
  int? respectforfaction;
  int? onehitkills;
  int? defendswon;
  int? defendslost;
  int? defendsstalemated;
  int? bestdamage;
  int? roundsfired;
  int? yourunaway;
  int? theyrunaway;
  int? highestbeaten;
  int? peoplebusted;
  int? failedbusts;
  int? peoplebought;
  int? peopleboughtspent;
  int? virusescoded;
  int? cityfinds;
  int? traveltimes;
  int? bountiesplaced;
  int? bountiesreceived;
  int? bountiescollected;
  int? totalbountyreward;
  int? revives;
  int? revivesreceived;
  int? medicalitemsused;
  int? statenhancersused;
  int? trainsreceived;
  int? totalbountyspent;
  int? drugsused;
  int? overdosed;
  int? meritsbought;
  int? personalsplaced;
  int? classifiedadsplaced;
  int? mailssent;
  int? friendmailssent;
  int? factionmailssent;
  int? companymailssent;
  int? spousemailssent;
  int? largestmug;
  int? cantaken;
  int? exttaken;
  int? kettaken;
  int? lsdtaken;
  int? opitaken;
  int? shrtaken;
  int? spetaken;
  int? pcptaken;
  int? xantaken;
  int? victaken;
  int? chahits;
  int? heahits;
  int? axehits;
  int? grehits;
  int? machits;
  int? pishits;
  int? rifhits;
  int? shohits;
  int? smghits;
  int? piehits;
  int? slahits;
  int? argtravel;
  int? mextravel;
  int? dubtravel;
  int? hawtravel;
  int? japtravel;
  int? lontravel;
  int? soutravel;
  int? switravel;
  int? chitravel;
  int? cantravel;
  int? dumpfinds;
  int? dumpsearches;
  int? itemsdumped;
  int? daysbeendonator;
  int? caytravel;
  int? jailed;
  int? hospital;
  int? attacksassisted;
  int? bloodwithdrawn;
  int? networth;
  int? missionscompleted;
  int? contractscompleted;
  int? dukecontractscompleted;
  int? missioncreditsearned;
  int? consumablesused;
  int? candyused;
  int? alcoholused;
  int? energydrinkused;
  int? nerverefills;
  int? unarmoredwon;
  int? h2Hhits;
  int? organisedcrimes;
  int? territorytime;
  int? territoryjoins;
  int? stockpayouts;
  int? stockprofits;
  int? stocklosses;
  int? stockfees;
  int? arrestsmade;
  int? tokenrefills;
  int? booksread;
  int? traveltime;
  int? boostersused;
  int? rehabs;
  int? rehabcost;
  int? awards;
  int? receivedbountyvalue;
  int? networthpending;
  int? networthwallet;
  int? networthbank;
  int? networthpoints;
  int? networthcayman;
  int? networthvault;
  int? networthpiggybank;
  int? networthitems;
  int? networthdisplaycase;
  int? networthbazaar;
  int? networthproperties;
  int? networthstockmarket;
  int? networthitemmarket;
  int? networthauctionhouse;
  int? networthcompany;
  int? networthbookie;
  int? networthenlistedcars;
  int? networthloan;
  int? networthunpaidfees;
  int? racingskill;
  int? raceswon;
  int? racesentered;
  int? racingpointsearned;
  int? specialammoused;
  int? cityitemsbought;
  int? hollowammoused;
  int? tracerammoused;
  int? piercingammoused;
  int? incendiaryammoused;
  int? attackswonabroad;
  int? defendslostabroad;
  int? retals;
  int? elo;
  int? strength;
  int? defense;
  int? speed;
  int? dexterity;
  int? totalstats;
  int? manuallabor;
  int? intelligence;
  int? endurance;
  int? totalworkingstats;
  int? jobpointsused;
  int? reviveskill;
  int? itemslooted;
  int? refills;

  factory Personalstats.fromJson(Map<String, dynamic> json) => Personalstats(
        bazaarcustomers: json["bazaarcustomers"] == null ? null : json["bazaarcustomers"],
        bazaarsales: json["bazaarsales"] == null ? null : json["bazaarsales"],
        bazaarprofit: json["bazaarprofit"] == null ? null : json["bazaarprofit"],
        useractivity: json["useractivity"] == null ? null : json["useractivity"],
        activestreak: json["activestreak"] == null ? null : json["activestreak"],
        bestactivestreak: json["bestactivestreak"] == null ? null : json["bestactivestreak"],
        itemsbought: json["itemsbought"] == null ? null : json["itemsbought"],
        pointsbought: json["pointsbought"] == null ? null : json["pointsbought"],
        itemsboughtabroad: json["itemsboughtabroad"] == null ? null : json["itemsboughtabroad"],
        moneyinvested: json["moneyinvested"] == null ? null : json["moneyinvested"],
        investedprofit: json["investedprofit"] == null ? null : json["investedprofit"],
        weaponsbought: json["weaponsbought"] == null ? null : json["weaponsbought"],
        trades: json["trades"] == null ? null : json["trades"],
        itemssent: json["itemssent"] == null ? null : json["itemssent"],
        auctionswon: json["auctionswon"] == null ? null : json["auctionswon"],
        auctionsells: json["auctionsells"] == null ? null : json["auctionsells"],
        pointssold: json["pointssold"] == null ? null : json["pointssold"],
        attackswon: json["attackswon"] == null ? null : json["attackswon"],
        attackslost: json["attackslost"] == null ? null : json["attackslost"],
        attacksdraw: json["attacksdraw"] == null ? null : json["attacksdraw"],
        bestkillstreak: json["bestkillstreak"] == null ? null : json["bestkillstreak"],
        killstreak: json["killstreak"] == null ? null : json["killstreak"],
        moneymugged: json["moneymugged"] == null ? null : json["moneymugged"],
        attacksstealthed: json["attacksstealthed"] == null ? null : json["attacksstealthed"],
        attackhits: json["attackhits"] == null ? null : json["attackhits"],
        attackmisses: json["attackmisses"] == null ? null : json["attackmisses"],
        attackdamage: json["attackdamage"] == null ? null : json["attackdamage"],
        attackcriticalhits: json["attackcriticalhits"] == null ? null : json["attackcriticalhits"],
        respectforfaction: json["respectforfaction"] == null ? null : json["respectforfaction"],
        onehitkills: json["onehitkills"] == null ? null : json["onehitkills"],
        defendswon: json["defendswon"] == null ? null : json["defendswon"],
        defendslost: json["defendslost"] == null ? null : json["defendslost"],
        defendsstalemated: json["defendsstalemated"] == null ? null : json["defendsstalemated"],
        bestdamage: json["bestdamage"] == null ? null : json["bestdamage"],
        roundsfired: json["roundsfired"] == null ? null : json["roundsfired"],
        yourunaway: json["yourunaway"] == null ? null : json["yourunaway"],
        theyrunaway: json["theyrunaway"] == null ? null : json["theyrunaway"],
        highestbeaten: json["highestbeaten"] == null ? null : json["highestbeaten"],
        peoplebusted: json["peoplebusted"] == null ? null : json["peoplebusted"],
        failedbusts: json["failedbusts"] == null ? null : json["failedbusts"],
        peoplebought: json["peoplebought"] == null ? null : json["peoplebought"],
        peopleboughtspent: json["peopleboughtspent"] == null ? null : json["peopleboughtspent"],
        virusescoded: json["virusescoded"] == null ? null : json["virusescoded"],
        cityfinds: json["cityfinds"] == null ? null : json["cityfinds"],
        traveltimes: json["traveltimes"] == null ? null : json["traveltimes"],
        bountiesplaced: json["bountiesplaced"] == null ? null : json["bountiesplaced"],
        bountiesreceived: json["bountiesreceived"] == null ? null : json["bountiesreceived"],
        bountiescollected: json["bountiescollected"] == null ? null : json["bountiescollected"],
        totalbountyreward: json["totalbountyreward"] == null ? null : json["totalbountyreward"],
        revives: json["revives"] == null ? null : json["revives"],
        revivesreceived: json["revivesreceived"] == null ? null : json["revivesreceived"],
        medicalitemsused: json["medicalitemsused"] == null ? null : json["medicalitemsused"],
        statenhancersused: json["statenhancersused"] == null ? null : json["statenhancersused"],
        trainsreceived: json["trainsreceived"] == null ? null : json["trainsreceived"],
        totalbountyspent: json["totalbountyspent"] == null ? null : json["totalbountyspent"],
        drugsused: json["drugsused"] == null ? null : json["drugsused"],
        overdosed: json["overdosed"] == null ? null : json["overdosed"],
        meritsbought: json["meritsbought"] == null ? null : json["meritsbought"],
        personalsplaced: json["personalsplaced"] == null ? null : json["personalsplaced"],
        classifiedadsplaced: json["classifiedadsplaced"] == null ? null : json["classifiedadsplaced"],
        mailssent: json["mailssent"] == null ? null : json["mailssent"],
        friendmailssent: json["friendmailssent"] == null ? null : json["friendmailssent"],
        factionmailssent: json["factionmailssent"] == null ? null : json["factionmailssent"],
        companymailssent: json["companymailssent"] == null ? null : json["companymailssent"],
        spousemailssent: json["spousemailssent"] == null ? null : json["spousemailssent"],
        largestmug: json["largestmug"] == null ? null : json["largestmug"],
        cantaken: json["cantaken"] == null ? null : json["cantaken"],
        exttaken: json["exttaken"] == null ? null : json["exttaken"],
        kettaken: json["kettaken"] == null ? null : json["kettaken"],
        lsdtaken: json["lsdtaken"] == null ? null : json["lsdtaken"],
        opitaken: json["opitaken"] == null ? null : json["opitaken"],
        shrtaken: json["shrtaken"] == null ? null : json["shrtaken"],
        spetaken: json["spetaken"] == null ? null : json["spetaken"],
        pcptaken: json["pcptaken"] == null ? null : json["pcptaken"],
        xantaken: json["xantaken"] == null ? null : json["xantaken"],
        victaken: json["victaken"] == null ? null : json["victaken"],
        chahits: json["chahits"] == null ? null : json["chahits"],
        heahits: json["heahits"] == null ? null : json["heahits"],
        axehits: json["axehits"] == null ? null : json["axehits"],
        grehits: json["grehits"] == null ? null : json["grehits"],
        machits: json["machits"] == null ? null : json["machits"],
        pishits: json["pishits"] == null ? null : json["pishits"],
        rifhits: json["rifhits"] == null ? null : json["rifhits"],
        shohits: json["shohits"] == null ? null : json["shohits"],
        smghits: json["smghits"] == null ? null : json["smghits"],
        piehits: json["piehits"] == null ? null : json["piehits"],
        slahits: json["slahits"] == null ? null : json["slahits"],
        argtravel: json["argtravel"] == null ? null : json["argtravel"],
        mextravel: json["mextravel"] == null ? null : json["mextravel"],
        dubtravel: json["dubtravel"] == null ? null : json["dubtravel"],
        hawtravel: json["hawtravel"] == null ? null : json["hawtravel"],
        japtravel: json["japtravel"] == null ? null : json["japtravel"],
        lontravel: json["lontravel"] == null ? null : json["lontravel"],
        soutravel: json["soutravel"] == null ? null : json["soutravel"],
        switravel: json["switravel"] == null ? null : json["switravel"],
        chitravel: json["chitravel"] == null ? null : json["chitravel"],
        cantravel: json["cantravel"] == null ? null : json["cantravel"],
        dumpfinds: json["dumpfinds"] == null ? null : json["dumpfinds"],
        dumpsearches: json["dumpsearches"] == null ? null : json["dumpsearches"],
        itemsdumped: json["itemsdumped"] == null ? null : json["itemsdumped"],
        daysbeendonator: json["daysbeendonator"] == null ? null : json["daysbeendonator"],
        caytravel: json["caytravel"] == null ? null : json["caytravel"],
        jailed: json["jailed"] == null ? null : json["jailed"],
        hospital: json["hospital"] == null ? null : json["hospital"],
        attacksassisted: json["attacksassisted"] == null ? null : json["attacksassisted"],
        bloodwithdrawn: json["bloodwithdrawn"] == null ? null : json["bloodwithdrawn"],
        networth: json["networth"] == null ? null : json["networth"],
        missionscompleted: json["missionscompleted"] == null ? null : json["missionscompleted"],
        contractscompleted: json["contractscompleted"] == null ? null : json["contractscompleted"],
        dukecontractscompleted: json["dukecontractscompleted"] == null ? null : json["dukecontractscompleted"],
        missioncreditsearned: json["missioncreditsearned"] == null ? null : json["missioncreditsearned"],
        consumablesused: json["consumablesused"] == null ? null : json["consumablesused"],
        candyused: json["candyused"] == null ? null : json["candyused"],
        alcoholused: json["alcoholused"] == null ? null : json["alcoholused"],
        energydrinkused: json["energydrinkused"] == null ? null : json["energydrinkused"],
        nerverefills: json["nerverefills"] == null ? null : json["nerverefills"],
        unarmoredwon: json["unarmoredwon"] == null ? null : json["unarmoredwon"],
        h2Hhits: json["h2hhits"] == null ? null : json["h2hhits"],
        organisedcrimes: json["organisedcrimes"] == null ? null : json["organisedcrimes"],
        territorytime: json["territorytime"] == null ? null : json["territorytime"],
        territoryjoins: json["territoryjoins"] == null ? null : json["territoryjoins"],
        stockpayouts: json["stockpayouts"] == null ? null : json["stockpayouts"],
        stockprofits: json["stockprofits"] == null ? null : json["stockprofits"],
        stocklosses: json["stocklosses"] == null ? null : json["stocklosses"],
        stockfees: json["stockfees"] == null ? null : json["stockfees"],
        arrestsmade: json["arrestsmade"] == null ? null : json["arrestsmade"],
        tokenrefills: json["tokenrefills"] == null ? null : json["tokenrefills"],
        booksread: json["booksread"] == null ? null : json["booksread"],
        traveltime: json["traveltime"] == null ? null : json["traveltime"],
        boostersused: json["boostersused"] == null ? null : json["boostersused"],
        rehabs: json["rehabs"] == null ? null : json["rehabs"],
        rehabcost: json["rehabcost"] == null ? null : json["rehabcost"],
        awards: json["awards"] == null ? null : json["awards"],
        receivedbountyvalue: json["receivedbountyvalue"] == null ? null : json["receivedbountyvalue"],
        networthpending: json["networthpending"] == null ? null : json["networthpending"],
        networthwallet: json["networthwallet"] == null ? null : json["networthwallet"],
        networthbank: json["networthbank"] == null ? null : json["networthbank"],
        networthpoints: json["networthpoints"] == null ? null : json["networthpoints"],
        networthcayman: json["networthcayman"] == null ? null : json["networthcayman"],
        networthvault: json["networthvault"] == null ? null : json["networthvault"],
        networthpiggybank: json["networthpiggybank"] == null ? null : json["networthpiggybank"],
        networthitems: json["networthitems"] == null ? null : json["networthitems"],
        networthdisplaycase: json["networthdisplaycase"] == null ? null : json["networthdisplaycase"],
        networthbazaar: json["networthbazaar"] == null ? null : json["networthbazaar"],
        networthproperties: json["networthproperties"] == null ? null : json["networthproperties"],
        networthstockmarket: json["networthstockmarket"] == null ? null : json["networthstockmarket"],
        networthitemmarket: json["networthitemmarket"] == null ? null : json["networthitemmarket"],
        networthauctionhouse: json["networthauctionhouse"] == null ? null : json["networthauctionhouse"],
        networthcompany: json["networthcompany"] == null ? null : json["networthcompany"],
        networthbookie: json["networthbookie"] == null ? null : json["networthbookie"],
        networthenlistedcars: json["networthenlistedcars"] == null ? null : json["networthenlistedcars"],
        networthloan: json["networthloan"] == null ? null : json["networthloan"],
        networthunpaidfees: json["networthunpaidfees"] == null ? null : json["networthunpaidfees"],
        racingskill: json["racingskill"] == null ? null : json["racingskill"],
        raceswon: json["raceswon"] == null ? null : json["raceswon"],
        racesentered: json["racesentered"] == null ? null : json["racesentered"],
        racingpointsearned: json["racingpointsearned"] == null ? null : json["racingpointsearned"],
        specialammoused: json["specialammoused"] == null ? null : json["specialammoused"],
        cityitemsbought: json["cityitemsbought"] == null ? null : json["cityitemsbought"],
        hollowammoused: json["hollowammoused"] == null ? null : json["hollowammoused"],
        tracerammoused: json["tracerammoused"] == null ? null : json["tracerammoused"],
        piercingammoused: json["piercingammoused"] == null ? null : json["piercingammoused"],
        incendiaryammoused: json["incendiaryammoused"] == null ? null : json["incendiaryammoused"],
        attackswonabroad: json["attackswonabroad"] == null ? null : json["attackswonabroad"],
        defendslostabroad: json["defendslostabroad"] == null ? null : json["defendslostabroad"],
        retals: json["retals"] == null ? null : json["retals"],
        elo: json["elo"] == null ? null : json["elo"],
        strength: json["strength"] == null ? null : json["strength"],
        defense: json["defense"] == null ? null : json["defense"],
        speed: json["speed"] == null ? null : json["speed"],
        dexterity: json["dexterity"] == null ? null : json["dexterity"],
        totalstats: json["totalstats"] == null ? null : json["totalstats"],
        manuallabor: json["manuallabor"] == null ? null : json["manuallabor"],
        intelligence: json["intelligence"] == null ? null : json["intelligence"],
        endurance: json["endurance"] == null ? null : json["endurance"],
        totalworkingstats: json["totalworkingstats"] == null ? null : json["totalworkingstats"],
        jobpointsused: json["jobpointsused"] == null ? null : json["jobpointsused"],
        reviveskill: json["reviveskill"] == null ? null : json["reviveskill"],
        itemslooted: json["itemslooted"] == null ? null : json["itemslooted"],
        refills: json["refills"] == null ? null : json["refills"],
      );

  Map<String, dynamic> toJson() => {
        "bazaarcustomers": bazaarcustomers == null ? null : bazaarcustomers,
        "bazaarsales": bazaarsales == null ? null : bazaarsales,
        "bazaarprofit": bazaarprofit == null ? null : bazaarprofit,
        "useractivity": useractivity == null ? null : useractivity,
        "activestreak": activestreak == null ? null : activestreak,
        "bestactivestreak": bestactivestreak == null ? null : bestactivestreak,
        "itemsbought": itemsbought == null ? null : itemsbought,
        "pointsbought": pointsbought == null ? null : pointsbought,
        "itemsboughtabroad": itemsboughtabroad == null ? null : itemsboughtabroad,
        "moneyinvested": moneyinvested == null ? null : moneyinvested,
        "investedprofit": investedprofit == null ? null : investedprofit,
        "weaponsbought": weaponsbought == null ? null : weaponsbought,
        "trades": trades == null ? null : trades,
        "itemssent": itemssent == null ? null : itemssent,
        "auctionswon": auctionswon == null ? null : auctionswon,
        "auctionsells": auctionsells == null ? null : auctionsells,
        "pointssold": pointssold == null ? null : pointssold,
        "attackswon": attackswon == null ? null : attackswon,
        "attackslost": attackslost == null ? null : attackslost,
        "attacksdraw": attacksdraw == null ? null : attacksdraw,
        "bestkillstreak": bestkillstreak == null ? null : bestkillstreak,
        "killstreak": killstreak == null ? null : killstreak,
        "moneymugged": moneymugged == null ? null : moneymugged,
        "attacksstealthed": attacksstealthed == null ? null : attacksstealthed,
        "attackhits": attackhits == null ? null : attackhits,
        "attackmisses": attackmisses == null ? null : attackmisses,
        "attackdamage": attackdamage == null ? null : attackdamage,
        "attackcriticalhits": attackcriticalhits == null ? null : attackcriticalhits,
        "respectforfaction": respectforfaction == null ? null : respectforfaction,
        "onehitkills": onehitkills == null ? null : onehitkills,
        "defendswon": defendswon == null ? null : defendswon,
        "defendslost": defendslost == null ? null : defendslost,
        "defendsstalemated": defendsstalemated == null ? null : defendsstalemated,
        "bestdamage": bestdamage == null ? null : bestdamage,
        "roundsfired": roundsfired == null ? null : roundsfired,
        "yourunaway": yourunaway == null ? null : yourunaway,
        "theyrunaway": theyrunaway == null ? null : theyrunaway,
        "highestbeaten": highestbeaten == null ? null : highestbeaten,
        "peoplebusted": peoplebusted == null ? null : peoplebusted,
        "failedbusts": failedbusts == null ? null : failedbusts,
        "peoplebought": peoplebought == null ? null : peoplebought,
        "peopleboughtspent": peopleboughtspent == null ? null : peopleboughtspent,
        "virusescoded": virusescoded == null ? null : virusescoded,
        "cityfinds": cityfinds == null ? null : cityfinds,
        "traveltimes": traveltimes == null ? null : traveltimes,
        "bountiesplaced": bountiesplaced == null ? null : bountiesplaced,
        "bountiesreceived": bountiesreceived == null ? null : bountiesreceived,
        "bountiescollected": bountiescollected == null ? null : bountiescollected,
        "totalbountyreward": totalbountyreward == null ? null : totalbountyreward,
        "revives": revives == null ? null : revives,
        "revivesreceived": revivesreceived == null ? null : revivesreceived,
        "medicalitemsused": medicalitemsused == null ? null : medicalitemsused,
        "statenhancersused": statenhancersused == null ? null : statenhancersused,
        "trainsreceived": trainsreceived == null ? null : trainsreceived,
        "totalbountyspent": totalbountyspent == null ? null : totalbountyspent,
        "drugsused": drugsused == null ? null : drugsused,
        "overdosed": overdosed == null ? null : overdosed,
        "meritsbought": meritsbought == null ? null : meritsbought,
        "personalsplaced": personalsplaced == null ? null : personalsplaced,
        "classifiedadsplaced": classifiedadsplaced == null ? null : classifiedadsplaced,
        "mailssent": mailssent == null ? null : mailssent,
        "friendmailssent": friendmailssent == null ? null : friendmailssent,
        "factionmailssent": factionmailssent == null ? null : factionmailssent,
        "companymailssent": companymailssent == null ? null : companymailssent,
        "spousemailssent": spousemailssent == null ? null : spousemailssent,
        "largestmug": largestmug == null ? null : largestmug,
        "cantaken": cantaken == null ? null : cantaken,
        "exttaken": exttaken == null ? null : exttaken,
        "kettaken": kettaken == null ? null : kettaken,
        "lsdtaken": lsdtaken == null ? null : lsdtaken,
        "opitaken": opitaken == null ? null : opitaken,
        "shrtaken": shrtaken == null ? null : shrtaken,
        "spetaken": spetaken == null ? null : spetaken,
        "pcptaken": pcptaken == null ? null : pcptaken,
        "xantaken": xantaken == null ? null : xantaken,
        "victaken": victaken == null ? null : victaken,
        "chahits": chahits == null ? null : chahits,
        "heahits": heahits == null ? null : heahits,
        "axehits": axehits == null ? null : axehits,
        "grehits": grehits == null ? null : grehits,
        "machits": machits == null ? null : machits,
        "pishits": pishits == null ? null : pishits,
        "rifhits": rifhits == null ? null : rifhits,
        "shohits": shohits == null ? null : shohits,
        "smghits": smghits == null ? null : smghits,
        "piehits": piehits == null ? null : piehits,
        "slahits": slahits == null ? null : slahits,
        "argtravel": argtravel == null ? null : argtravel,
        "mextravel": mextravel == null ? null : mextravel,
        "dubtravel": dubtravel == null ? null : dubtravel,
        "hawtravel": hawtravel == null ? null : hawtravel,
        "japtravel": japtravel == null ? null : japtravel,
        "lontravel": lontravel == null ? null : lontravel,
        "soutravel": soutravel == null ? null : soutravel,
        "switravel": switravel == null ? null : switravel,
        "chitravel": chitravel == null ? null : chitravel,
        "cantravel": cantravel == null ? null : cantravel,
        "dumpfinds": dumpfinds == null ? null : dumpfinds,
        "dumpsearches": dumpsearches == null ? null : dumpsearches,
        "itemsdumped": itemsdumped == null ? null : itemsdumped,
        "daysbeendonator": daysbeendonator == null ? null : daysbeendonator,
        "caytravel": caytravel == null ? null : caytravel,
        "jailed": jailed == null ? null : jailed,
        "hospital": hospital == null ? null : hospital,
        "attacksassisted": attacksassisted == null ? null : attacksassisted,
        "bloodwithdrawn": bloodwithdrawn == null ? null : bloodwithdrawn,
        "networth": networth == null ? null : networth,
        "missionscompleted": missionscompleted == null ? null : missionscompleted,
        "contractscompleted": contractscompleted == null ? null : contractscompleted,
        "dukecontractscompleted": dukecontractscompleted == null ? null : dukecontractscompleted,
        "missioncreditsearned": missioncreditsearned == null ? null : missioncreditsearned,
        "consumablesused": consumablesused == null ? null : consumablesused,
        "candyused": candyused == null ? null : candyused,
        "alcoholused": alcoholused == null ? null : alcoholused,
        "energydrinkused": energydrinkused == null ? null : energydrinkused,
        "nerverefills": nerverefills == null ? null : nerverefills,
        "unarmoredwon": unarmoredwon == null ? null : unarmoredwon,
        "h2hhits": h2Hhits == null ? null : h2Hhits,
        "organisedcrimes": organisedcrimes == null ? null : organisedcrimes,
        "territorytime": territorytime == null ? null : territorytime,
        "territoryjoins": territoryjoins == null ? null : territoryjoins,
        "stockpayouts": stockpayouts == null ? null : stockpayouts,
        "stockprofits": stockprofits == null ? null : stockprofits,
        "stocklosses": stocklosses == null ? null : stocklosses,
        "stockfees": stockfees == null ? null : stockfees,
        "arrestsmade": arrestsmade == null ? null : arrestsmade,
        "tokenrefills": tokenrefills == null ? null : tokenrefills,
        "booksread": booksread == null ? null : booksread,
        "traveltime": traveltime == null ? null : traveltime,
        "boostersused": boostersused == null ? null : boostersused,
        "rehabs": rehabs == null ? null : rehabs,
        "rehabcost": rehabcost == null ? null : rehabcost,
        "awards": awards == null ? null : awards,
        "receivedbountyvalue": receivedbountyvalue == null ? null : receivedbountyvalue,
        "networthpending": networthpending == null ? null : networthpending,
        "networthwallet": networthwallet == null ? null : networthwallet,
        "networthbank": networthbank == null ? null : networthbank,
        "networthpoints": networthpoints == null ? null : networthpoints,
        "networthcayman": networthcayman == null ? null : networthcayman,
        "networthvault": networthvault == null ? null : networthvault,
        "networthpiggybank": networthpiggybank == null ? null : networthpiggybank,
        "networthitems": networthitems == null ? null : networthitems,
        "networthdisplaycase": networthdisplaycase == null ? null : networthdisplaycase,
        "networthbazaar": networthbazaar == null ? null : networthbazaar,
        "networthproperties": networthproperties == null ? null : networthproperties,
        "networthstockmarket": networthstockmarket == null ? null : networthstockmarket,
        "networthitemmarket": networthitemmarket == null ? null : networthitemmarket,
        "networthauctionhouse": networthauctionhouse == null ? null : networthauctionhouse,
        "networthcompany": networthcompany == null ? null : networthcompany,
        "networthbookie": networthbookie == null ? null : networthbookie,
        "networthenlistedcars": networthenlistedcars == null ? null : networthenlistedcars,
        "networthloan": networthloan == null ? null : networthloan,
        "networthunpaidfees": networthunpaidfees == null ? null : networthunpaidfees,
        "racingskill": racingskill == null ? null : racingskill,
        "raceswon": raceswon == null ? null : raceswon,
        "racesentered": racesentered == null ? null : racesentered,
        "racingpointsearned": racingpointsearned == null ? null : racingpointsearned,
        "specialammoused": specialammoused == null ? null : specialammoused,
        "cityitemsbought": cityitemsbought == null ? null : cityitemsbought,
        "hollowammoused": hollowammoused == null ? null : hollowammoused,
        "tracerammoused": tracerammoused == null ? null : tracerammoused,
        "piercingammoused": piercingammoused == null ? null : piercingammoused,
        "incendiaryammoused": incendiaryammoused == null ? null : incendiaryammoused,
        "attackswonabroad": attackswonabroad == null ? null : attackswonabroad,
        "defendslostabroad": defendslostabroad == null ? null : defendslostabroad,
        "retals": retals == null ? null : retals,
        "elo": elo == null ? null : elo,
        "strength": strength == null ? null : strength,
        "defense": defense == null ? null : defense,
        "speed": speed == null ? null : speed,
        "dexterity": dexterity == null ? null : dexterity,
        "totalstats": totalstats == null ? null : totalstats,
        "manuallabor": manuallabor == null ? null : manuallabor,
        "intelligence": intelligence == null ? null : intelligence,
        "endurance": endurance == null ? null : endurance,
        "totalworkingstats": totalworkingstats == null ? null : totalworkingstats,
        "jobpointsused": jobpointsused == null ? null : jobpointsused,
        "reviveskill": reviveskill == null ? null : reviveskill,
        "itemslooted": itemslooted == null ? null : itemslooted,
        "refills": refills == null ? null : refills,
      };
}
