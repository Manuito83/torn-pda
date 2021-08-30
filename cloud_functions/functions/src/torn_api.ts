const rp = require("request-promise");

export async function getUsersStat(apiKey: string) {
  return rp({
    uri: `https://api.torn.com/user/?selections=profile,bars,travel,icons,cooldowns,newmessages,newevents&key=${apiKey}&comment=PDA-Alerts`,
    json: true,
  });
}

export async function getUsersRefills(apiKey: string) {
  return rp({
    uri: `https://api.torn.com/user/?selections=refills&key=${apiKey}&comment=PDA-Alerts`,
    json: true,
  });
}
