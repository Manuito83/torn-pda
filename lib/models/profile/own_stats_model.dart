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
        bazaarcustomers: json["bazaarcustomers"],
        bazaarsales: json["bazaarsales"],
        bazaarprofit: json["bazaarprofit"],
        useractivity: json["useractivity"],
        activestreak: json["activestreak"],
        bestactivestreak: json["bestactivestreak"],
        itemsbought: json["itemsbought"],
        pointsbought: json["pointsbought"],
        itemsboughtabroad: json["itemsboughtabroad"],
        moneyinvested: json["moneyinvested"],
        investedprofit: json["investedprofit"],
        weaponsbought: json["weaponsbought"],
        trades: json["trades"],
        itemssent: json["itemssent"],
        auctionswon: json["auctionswon"],
        auctionsells: json["auctionsells"],
        pointssold: json["pointssold"],
        attackswon: json["attackswon"],
        attackslost: json["attackslost"],
        attacksdraw: json["attacksdraw"],
        bestkillstreak: json["bestkillstreak"],
        killstreak: json["killstreak"],
        moneymugged: json["moneymugged"],
        attacksstealthed: json["attacksstealthed"],
        attackhits: json["attackhits"],
        attackmisses: json["attackmisses"],
        attackdamage: json["attackdamage"],
        attackcriticalhits: json["attackcriticalhits"],
        respectforfaction: json["respectforfaction"],
        onehitkills: json["onehitkills"],
        defendswon: json["defendswon"],
        defendslost: json["defendslost"],
        defendsstalemated: json["defendsstalemated"],
        bestdamage: json["bestdamage"],
        roundsfired: json["roundsfired"],
        yourunaway: json["yourunaway"],
        theyrunaway: json["theyrunaway"],
        highestbeaten: json["highestbeaten"],
        peoplebusted: json["peoplebusted"],
        failedbusts: json["failedbusts"],
        peoplebought: json["peoplebought"],
        peopleboughtspent: json["peopleboughtspent"],
        virusescoded: json["virusescoded"],
        cityfinds: json["cityfinds"],
        traveltimes: json["traveltimes"],
        bountiesplaced: json["bountiesplaced"],
        bountiesreceived: json["bountiesreceived"],
        bountiescollected: json["bountiescollected"],
        totalbountyreward: json["totalbountyreward"],
        revives: json["revives"],
        revivesreceived: json["revivesreceived"],
        medicalitemsused: json["medicalitemsused"],
        statenhancersused: json["statenhancersused"],
        trainsreceived: json["trainsreceived"],
        totalbountyspent: json["totalbountyspent"],
        drugsused: json["drugsused"],
        overdosed: json["overdosed"],
        meritsbought: json["meritsbought"],
        personalsplaced: json["personalsplaced"],
        classifiedadsplaced: json["classifiedadsplaced"],
        mailssent: json["mailssent"],
        friendmailssent: json["friendmailssent"],
        factionmailssent: json["factionmailssent"],
        companymailssent: json["companymailssent"],
        spousemailssent: json["spousemailssent"],
        largestmug: json["largestmug"],
        cantaken: json["cantaken"],
        exttaken: json["exttaken"],
        kettaken: json["kettaken"],
        lsdtaken: json["lsdtaken"],
        opitaken: json["opitaken"],
        shrtaken: json["shrtaken"],
        spetaken: json["spetaken"],
        pcptaken: json["pcptaken"],
        xantaken: json["xantaken"],
        victaken: json["victaken"],
        chahits: json["chahits"],
        heahits: json["heahits"],
        axehits: json["axehits"],
        grehits: json["grehits"],
        machits: json["machits"],
        pishits: json["pishits"],
        rifhits: json["rifhits"],
        shohits: json["shohits"],
        smghits: json["smghits"],
        piehits: json["piehits"],
        slahits: json["slahits"],
        argtravel: json["argtravel"],
        mextravel: json["mextravel"],
        dubtravel: json["dubtravel"],
        hawtravel: json["hawtravel"],
        japtravel: json["japtravel"],
        lontravel: json["lontravel"],
        soutravel: json["soutravel"],
        switravel: json["switravel"],
        chitravel: json["chitravel"],
        cantravel: json["cantravel"],
        dumpfinds: json["dumpfinds"],
        dumpsearches: json["dumpsearches"],
        itemsdumped: json["itemsdumped"],
        daysbeendonator: json["daysbeendonator"],
        caytravel: json["caytravel"],
        jailed: json["jailed"],
        hospital: json["hospital"],
        attacksassisted: json["attacksassisted"],
        bloodwithdrawn: json["bloodwithdrawn"],
        networth: json["networth"],
        missionscompleted: json["missionscompleted"],
        contractscompleted: json["contractscompleted"],
        dukecontractscompleted: json["dukecontractscompleted"],
        missioncreditsearned: json["missioncreditsearned"],
        consumablesused: json["consumablesused"],
        candyused: json["candyused"],
        alcoholused: json["alcoholused"],
        energydrinkused: json["energydrinkused"],
        nerverefills: json["nerverefills"],
        unarmoredwon: json["unarmoredwon"],
        h2Hhits: json["h2hhits"],
        organisedcrimes: json["organisedcrimes"],
        territorytime: json["territorytime"],
        territoryjoins: json["territoryjoins"],
        stockpayouts: json["stockpayouts"],
        stockprofits: json["stockprofits"],
        stocklosses: json["stocklosses"],
        stockfees: json["stockfees"],
        arrestsmade: json["arrestsmade"],
        tokenrefills: json["tokenrefills"],
        booksread: json["booksread"],
        traveltime: json["traveltime"],
        boostersused: json["boostersused"],
        rehabs: json["rehabs"],
        rehabcost: json["rehabcost"],
        awards: json["awards"],
        receivedbountyvalue: json["receivedbountyvalue"],
        networthpending: json["networthpending"],
        networthwallet: json["networthwallet"],
        networthbank: json["networthbank"],
        networthpoints: json["networthpoints"],
        networthcayman: json["networthcayman"],
        networthvault: json["networthvault"],
        networthpiggybank: json["networthpiggybank"],
        networthitems: json["networthitems"],
        networthdisplaycase: json["networthdisplaycase"],
        networthbazaar: json["networthbazaar"],
        networthproperties: json["networthproperties"],
        networthstockmarket: json["networthstockmarket"],
        networthitemmarket: json["networthitemmarket"],
        networthauctionhouse: json["networthauctionhouse"],
        networthcompany: json["networthcompany"],
        networthbookie: json["networthbookie"],
        networthenlistedcars: json["networthenlistedcars"],
        networthloan: json["networthloan"],
        networthunpaidfees: json["networthunpaidfees"],
        racingskill: json["racingskill"],
        raceswon: json["raceswon"],
        racesentered: json["racesentered"],
        racingpointsearned: json["racingpointsearned"],
        specialammoused: json["specialammoused"],
        cityitemsbought: json["cityitemsbought"],
        hollowammoused: json["hollowammoused"],
        tracerammoused: json["tracerammoused"],
        piercingammoused: json["piercingammoused"],
        incendiaryammoused: json["incendiaryammoused"],
        attackswonabroad: json["attackswonabroad"],
        defendslostabroad: json["defendslostabroad"],
        retals: json["retals"],
        elo: json["elo"],
        strength: json["strength"],
        defense: json["defense"],
        speed: json["speed"],
        dexterity: json["dexterity"],
        totalstats: json["totalstats"],
        manuallabor: json["manuallabor"],
        intelligence: json["intelligence"],
        endurance: json["endurance"],
        totalworkingstats: json["totalworkingstats"],
        jobpointsused: json["jobpointsused"],
        reviveskill: json["reviveskill"],
        itemslooted: json["itemslooted"],
        refills: json["refills"],
      );

  Map<String, dynamic> toJson() => {
        "bazaarcustomers": bazaarcustomers,
        "bazaarsales": bazaarsales,
        "bazaarprofit": bazaarprofit,
        "useractivity": useractivity,
        "activestreak": activestreak,
        "bestactivestreak": bestactivestreak,
        "itemsbought": itemsbought,
        "pointsbought": pointsbought,
        "itemsboughtabroad": itemsboughtabroad,
        "moneyinvested": moneyinvested,
        "investedprofit": investedprofit,
        "weaponsbought": weaponsbought,
        "trades": trades,
        "itemssent": itemssent,
        "auctionswon": auctionswon,
        "auctionsells": auctionsells,
        "pointssold": pointssold,
        "attackswon": attackswon,
        "attackslost": attackslost,
        "attacksdraw": attacksdraw,
        "bestkillstreak": bestkillstreak,
        "killstreak": killstreak,
        "moneymugged": moneymugged,
        "attacksstealthed": attacksstealthed,
        "attackhits": attackhits,
        "attackmisses": attackmisses,
        "attackdamage": attackdamage,
        "attackcriticalhits": attackcriticalhits,
        "respectforfaction": respectforfaction,
        "onehitkills": onehitkills,
        "defendswon": defendswon,
        "defendslost": defendslost,
        "defendsstalemated": defendsstalemated,
        "bestdamage": bestdamage,
        "roundsfired": roundsfired,
        "yourunaway": yourunaway,
        "theyrunaway": theyrunaway,
        "highestbeaten": highestbeaten,
        "peoplebusted": peoplebusted,
        "failedbusts": failedbusts,
        "peoplebought": peoplebought,
        "peopleboughtspent": peopleboughtspent,
        "virusescoded": virusescoded,
        "cityfinds": cityfinds,
        "traveltimes": traveltimes,
        "bountiesplaced": bountiesplaced,
        "bountiesreceived": bountiesreceived,
        "bountiescollected": bountiescollected,
        "totalbountyreward": totalbountyreward,
        "revives": revives,
        "revivesreceived": revivesreceived,
        "medicalitemsused": medicalitemsused,
        "statenhancersused": statenhancersused,
        "trainsreceived": trainsreceived,
        "totalbountyspent": totalbountyspent,
        "drugsused": drugsused,
        "overdosed": overdosed,
        "meritsbought": meritsbought,
        "personalsplaced": personalsplaced,
        "classifiedadsplaced": classifiedadsplaced,
        "mailssent": mailssent,
        "friendmailssent": friendmailssent,
        "factionmailssent": factionmailssent,
        "companymailssent": companymailssent,
        "spousemailssent": spousemailssent,
        "largestmug": largestmug,
        "cantaken": cantaken,
        "exttaken": exttaken,
        "kettaken": kettaken,
        "lsdtaken": lsdtaken,
        "opitaken": opitaken,
        "shrtaken": shrtaken,
        "spetaken": spetaken,
        "pcptaken": pcptaken,
        "xantaken": xantaken,
        "victaken": victaken,
        "chahits": chahits,
        "heahits": heahits,
        "axehits": axehits,
        "grehits": grehits,
        "machits": machits,
        "pishits": pishits,
        "rifhits": rifhits,
        "shohits": shohits,
        "smghits": smghits,
        "piehits": piehits,
        "slahits": slahits,
        "argtravel": argtravel,
        "mextravel": mextravel,
        "dubtravel": dubtravel,
        "hawtravel": hawtravel,
        "japtravel": japtravel,
        "lontravel": lontravel,
        "soutravel": soutravel,
        "switravel": switravel,
        "chitravel": chitravel,
        "cantravel": cantravel,
        "dumpfinds": dumpfinds,
        "dumpsearches": dumpsearches,
        "itemsdumped": itemsdumped,
        "daysbeendonator": daysbeendonator,
        "caytravel": caytravel,
        "jailed": jailed,
        "hospital": hospital,
        "attacksassisted": attacksassisted,
        "bloodwithdrawn": bloodwithdrawn,
        "networth": networth,
        "missionscompleted": missionscompleted,
        "contractscompleted": contractscompleted,
        "dukecontractscompleted": dukecontractscompleted,
        "missioncreditsearned": missioncreditsearned,
        "consumablesused": consumablesused,
        "candyused": candyused,
        "alcoholused": alcoholused,
        "energydrinkused": energydrinkused,
        "nerverefills": nerverefills,
        "unarmoredwon": unarmoredwon,
        "h2hhits": h2Hhits,
        "organisedcrimes": organisedcrimes,
        "territorytime": territorytime,
        "territoryjoins": territoryjoins,
        "stockpayouts": stockpayouts,
        "stockprofits": stockprofits,
        "stocklosses": stocklosses,
        "stockfees": stockfees,
        "arrestsmade": arrestsmade,
        "tokenrefills": tokenrefills,
        "booksread": booksread,
        "traveltime": traveltime,
        "boostersused": boostersused,
        "rehabs": rehabs,
        "rehabcost": rehabcost,
        "awards": awards,
        "receivedbountyvalue": receivedbountyvalue,
        "networthpending": networthpending,
        "networthwallet": networthwallet,
        "networthbank": networthbank,
        "networthpoints": networthpoints,
        "networthcayman": networthcayman,
        "networthvault": networthvault,
        "networthpiggybank": networthpiggybank,
        "networthitems": networthitems,
        "networthdisplaycase": networthdisplaycase,
        "networthbazaar": networthbazaar,
        "networthproperties": networthproperties,
        "networthstockmarket": networthstockmarket,
        "networthitemmarket": networthitemmarket,
        "networthauctionhouse": networthauctionhouse,
        "networthcompany": networthcompany,
        "networthbookie": networthbookie,
        "networthenlistedcars": networthenlistedcars,
        "networthloan": networthloan,
        "networthunpaidfees": networthunpaidfees,
        "racingskill": racingskill,
        "raceswon": raceswon,
        "racesentered": racesentered,
        "racingpointsearned": racingpointsearned,
        "specialammoused": specialammoused,
        "cityitemsbought": cityitemsbought,
        "hollowammoused": hollowammoused,
        "tracerammoused": tracerammoused,
        "piercingammoused": piercingammoused,
        "incendiaryammoused": incendiaryammoused,
        "attackswonabroad": attackswonabroad,
        "defendslostabroad": defendslostabroad,
        "retals": retals,
        "elo": elo,
        "strength": strength,
        "defense": defense,
        "speed": speed,
        "dexterity": dexterity,
        "totalstats": totalstats,
        "manuallabor": manuallabor,
        "intelligence": intelligence,
        "endurance": endurance,
        "totalworkingstats": totalworkingstats,
        "jobpointsused": jobpointsused,
        "reviveskill": reviveskill,
        "itemslooted": itemslooted,
        "refills": refills,
      };
}
