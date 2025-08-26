import fetch from 'node-fetch';
import { ForumsApiResponse } from './interfaces/forums_interface';

export async function getUsersStat(apiKey: string) {
  const response = await fetch(`https://api.torn.com/user/?selections=profile,bars,travel,icons,cooldowns,newmessages,newevents&key=${apiKey}&comment=PDA-Alerts`);
  const data = await response.json();
  return data;

}

export async function getUsersRefills(apiKey: string) {
  const response = await fetch(`https://api.torn.com/user/?selections=refills&key=${apiKey}&comment=PDA-Alerts`);
  const data = await response.json();
  return data;
}

export async function getUsersForums(apiKey: string): Promise<ForumsApiResponse> {
  const response = await fetch("https://api.torn.com/v2/user/forumsubscribedthreads", {
    method: "GET",
    headers: {
      Authorization: `ApiKey ${apiKey}`,
    },
  });

  if (!response.ok) {
    throw new Error(`API request failed with status ${response.status}: ${response.statusText}`);
  }

  return await response.json();
}


export async function checkUserIdKey(apiKey: string, userId: number) {
  const response = await fetch(`https://api.torn.com/user/?selections=profile&key=${apiKey}`);
  const data = await response.json() as any;

  if (data.error) {
    return false;
  }

  if (data.player_id !== userId) {
    return false;
  }

  return true;
}
