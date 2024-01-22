import fetch from 'node-fetch';

export async function getUsersStat(apiKey: string) {
  const response = await fetch('https://api.torn.com/user/?selections=profile,bars,travel,icons,cooldowns,newmessages,newevents&key=${apiKey}&comment=PDA-Alerts');
  const data = await response.json();
  return data;

}

export async function getUsersRefills(apiKey: string) {
  const response = await fetch(`https://api.torn.com/user/?selections=refills&key=${apiKey}&comment=PDA-Alerts`);
  const data = await response.json();
  return data;
}

export async function checkUserIdKey(apiKey: string, userId: number) {
  const response = await fetch(`https://api.torn.com/user/?selections=basic&key=${apiKey}`);
  const data = await response.json();

  if (data.error) {
    return false;
  }

  if (data.player_id !== userId) {
    return false;
  }

  return true;
}
