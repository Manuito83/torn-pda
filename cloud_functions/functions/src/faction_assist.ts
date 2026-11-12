import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { sendNotificationToUser } from "./notification";
import { isDiscreetNow } from "./discreet";
import { getUserSelections, INVALID_KEY_ERRORS, isApiKey } from "./torn_api";
import { takeRateLimitSlot } from "./rate_limit";
import { MAX_RECHECK_MS, RECIPIENT_FACTION_FIELD } from "./verified_players";

const ASSISTS_PER_HOUR = 60;
const TORN_TIMEOUT_MS = 6 * 1000;

const FACTION_NOT_FOUND = -1;
const INVALID_API_KEY = -2;
const TORN_API_UNAVAILABLE = -3;
const ASSIST_LIMIT_REACHED = -4;
const TORN_KEY_RATE_LIMITED = -5;
const TOO_MANY_REQUESTS_ERROR = 5;

const statsNumber = "-?[\\d.,]{1,12}[KMBkmb]?";
const updatedTime = "(\\d{1,2}:\\d{2}( TCT)?|\\d{1,4} (day|days|week|weeks|month|months|year|years) ago)";
const personalStat = "(Xanax|Refills \\(E\\)|Drinks \\(E\\))";
const estimatedLine = `(- ${personalStat}: ([\\d,]{1,12}|\\?|null)` +
    `|>> ${personalStat}: \\d{1,12} (LESS|MORE) than you` +
    `|\\(tap to get a comparison with you\\))`;

// Formats sent by every app version
const fieldFormats: { [field: string]: RegExp } = {
    attackName: /^[A-Za-z0-9_-]{1,16}$/,
    attackLevel: /^\d{1,4}$/,
    attackAge: /^\d{1,5}$/,
    attackLife: /^[\d?,]{1,9} ?\/ ?[\d?,]{1,9}$/,
    estimatedStats: new RegExp(`^(unk|[<>]? ?${statsNumber}( - ${statsNumber})?)(\\n${estimatedLine}){0,8}$`),
    exactStats: new RegExp(`^${statsNumber} \\(STR ${statsNumber}, SPD ${statsNumber}, DEF ${statsNumber}, ` +
        `DEX ${statsNumber}\\), updated ${updatedTime}$`),
    ffsStats: /^([\d.,]{1,12} ?[A-Za-z]{0,2}|N\/A)$/,
    fairFight: /^\d{1,4}(\.\d{1,2})?x$/,
    xanax: /^(\d{1,12}|\?|unk|null)$/,
    refills: /^(\d{1,12}|\?|unk|null)$/,
    drinks: /^(\d{1,12}|\?|unk|null)$/,
};

// Empty when missing or malformed
function assistField(data: any, field: string): string {
    const value = data?.[field];
    if (typeof value !== "string" && typeof value !== "number") return "";
    const text = `${value}`;
    return fieldFormats[field].test(text) ? text : "";
}

interface Requester {
    name: string;
    level: string;
    faction: number;
    playerId: number;
}

// Saved verification, only if recent
function verifiedRequester(player: any, now: number): Requester | undefined {
    const name = assistField({ attackName: player.name }, "attackName");
    if (typeof player.verifiedAt !== "number" || now - player.verifiedAt >= MAX_RECHECK_MS) return undefined;
    if (name === "" || !Number.isSafeInteger(player.verifiedFaction)) return undefined;
    return {
        name,
        level: assistField({ attackLevel: player.level }, "attackLevel"),
        faction: player.verifiedFaction,
        playerId: player.verifiedPlayerId,
    };
}

// Error code when there is no requester
async function findRequester(uid: string, player: any): Promise<Requester | number> {
    let profile: any;
    try {
        profile = await getUserSelections(player.apiKey, "profile", "PDA-Assist", TORN_TIMEOUT_MS);
    } catch (e) {
        profile = { error: { error: `${e}` } };
    }
    const code = profile.error?.code;
    if (INVALID_KEY_ERRORS.includes(code)) {
        logger.info(`Call from uid ${uid}: Torn API error ${code} ${profile.error.error}`);
        return INVALID_API_KEY;
    }
    if (code === TOO_MANY_REQUESTS_ERROR) {
        logger.info(`Call from uid ${uid}: Torn API error ${code} ${profile.error.error}`);
        return TORN_KEY_RATE_LIMITED;
    }
    if (!profile.error && typeof profile.name === "string" && profile.name !== "") {
        return { name: profile.name, level: `${profile.level}`, faction: profile.faction?.faction_id, playerId: profile.player_id };
    }

    const saved = verifiedRequester(player, Date.now());
    logger.warn(`Call from uid ${uid}: Torn API unavailable (${profile.error?.error ?? "unexpected profile"}), ` +
        `${saved ? "using saved verification" : "no recent verification"}`);
    return saved ?? TORN_API_UNAVAILABLE;
}

export const sendAssistMessage = onCall({
    region: 'us-east4',
    memory: "512MiB",
    timeoutSeconds: 540
}, async (request) => {

    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'The user is not authenticated');
    }

    // Older versions only understand -1
    const failure = (code: number) => request.data?.errorDetail === true ? code : FACTION_NOT_FOUND;

    // Leading digits only, like older versions
    const attackId = /^\d{1,12}(?!\d)/.exec(`${request.data?.attackId ?? ""}`)?.[0];
    if (attackId === undefined) {
        logger.info(`Call from uid ${request.auth.uid}: invalid attackId`);
        return failure(FACTION_NOT_FOUND);
    }

    const callingUser = await admin
        .firestore()
        .collection("players")
        .doc(request.auth.uid)
        .get();

    if (callingUser.data() === undefined) {
        logger.info(`User not found`);
        return failure(FACTION_NOT_FOUND);
    }
    const apiKey = callingUser.data().apiKey;
    if (!isApiKey(apiKey)) {
        logger.info(`Call from uid ${request.auth.uid}: no API key`);
        return failure(INVALID_API_KEY);
    }

    if (!await takeRateLimitSlot(`assist_${request.auth.uid}`, ASSISTS_PER_HOUR, 60 * 60 * 1000)) {
        logger.info(`Call from uid ${request.auth.uid}: assist limit reached`);
        return failure(ASSIST_LIMIT_REACHED);
    }

    const requester = await findRequester(request.auth.uid, callingUser.data());
    if (typeof requester === "number") return failure(requester);

    const { name, level, faction, playerId } = requester;
    if (!faction) {
        logger.info(`Call from ${name} [${playerId}]: faction not found`);
        return failure(FACTION_NOT_FOUND);
    }

    // Get all faction members that allow messages to be received
    const response = await admin
        .firestore()
        .collection("players")
        .where("active", "==", true)
        .where(RECIPIENT_FACTION_FIELD, "==", faction)
        .where("factionAssistMessage", "==", true)
        //.where("name", "==", `Manuito`)  // DEBUG (change also 'main.dart' to redirect functions)
        .where("name", "!=", name) // Not the requestor's own name
        .get();

    const factionMembers = response.docs.map((d) => d.data());
    if (factionMembers.length === 0) {
        logger.info(`Call from ${name} [${playerId}]: 0 receptors`);
        // No one to notify
        return 0;
    };

    const data = request.data;

    let attackName = assistField(data, "attackName");
    if (attackName === "") {
        attackName = `ID ${attackId}`;
    }

    let attackLevelAge = assistField(data, "attackLevel");
    const attackAge = assistField(data, "attackAge");
    if (attackLevelAge === "" || attackAge === "") {
        attackLevelAge = "";
    } else {
        attackLevelAge = `\n- Level ${attackLevelAge} (${attackAge} days old)`;
    }

    let attackLife = assistField(data, "attackLife");
    if (attackLife !== "") {
        attackLife = `\n- Life ${attackLife}`;
    }

    let estimatedStats = assistField(data, "estimatedStats");
    let exactStats = assistField(data, "exactStats");
    let ffsStats = assistField(data, "ffsStats");
    let fairFight = assistField(data, "fairFight");
    let bulkDetails = "";
    if (exactStats === "") {
        // If exact stats are not available, add estimated
        if (estimatedStats !== "") {
            estimatedStats = `\n- Estimated stats: ${estimatedStats}`;
            const xanax = assistField(data, "xanax") || "unk";
            const refills = assistField(data, "refills") || "unk";
            const drinks = assistField(data, "drinks") || "unk";
            bulkDetails = `xanax:${xanax}#refills:${refills}#drinks:${drinks}`;
        }
    } else {
        estimatedStats = "";
        exactStats = `\n- Spied stats: ${exactStats}`;
    }

    // FFScouter battle score
    if (ffsStats !== "") {
        ffsStats = `\n- FFS Battle Score: ~${ffsStats}`;
    }

    // FFScouter fair fight
    if (fairFight !== "") {
        fairFight = `\n- Fair Fight: ${fairFight}`;
    }

    const promises: Promise<any>[] = [];
    const levelText = level === "" ? "" : ` (level ${level})`;
    let membersNotified = 0;
    for (const key of Array.from(factionMembers.keys())) {
        const thisMember = factionMembers[key];

        let title = `Attack assist request!`;
        let body = `${name}${levelText} needs help attacking ${attackName}!` +
            `${attackLevelAge}${attackLife}${estimatedStats}${exactStats}${ffsStats}${fairFight}`;
        if (isDiscreetNow(thisMember)) {
            title = `Assist`;
            body = `${attackLevelAge}`;
        }

        promises.push(
            sendNotificationToUser({
                token: thisMember.token,
                title: title,
                body: body,
                icon: "notification_assists",
                color: "#FF0000",
                channelId: "Alerts assists",
                assistId: attackId,
                bulkDetails: bulkDetails,
                vibration: thisMember.vibration,
                sound: "sword_clash.aiff",
            })
        );

        membersNotified++;
    }

    logger.info(`Call from ${name} [${playerId}]: ${membersNotified} receptors`);

    await Promise.all(promises);

    return membersNotified;

});
