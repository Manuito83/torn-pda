const rp = require("request-promise");

export async function getUsersStat(apiKey: string) {
  return rp({
    uri: `https://api.torn.com/user/?selections=profile,bars,travel,icons,cooldowns,messages&key=${apiKey}`,
    json: true,
  });
}
