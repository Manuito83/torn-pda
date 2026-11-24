import * as admin from "firebase-admin";

const BUCKET = "torn-pda-manuito.appspot.com";
const ROOT = "feedback_attachments";
const HEAD_BYTES = 16;

export interface StoredObject {
  size: number;
  contentType: string;
  head: Buffer;
}

const bucket = () => admin.storage().bucket(BUCKET);
const fileOf = (feedbackId: string, attachmentId: string) => bucket().file(`${ROOT}/${feedbackId}/${attachmentId}`);

// One upload, fixed type and size
export async function signUpload(feedbackId: string, attachmentId: string, contentType: string, size: number,
  validMs: number): Promise<{ url: string; headers: Record<string, string> }> {
  const extensionHeaders = { "x-goog-content-length-range": `${size},${size}`, "x-goog-if-generation-match": "0" };
  const [url] = await fileOf(feedbackId, attachmentId).getSignedUrl({
    version: "v4",
    action: "write",
    expires: Date.now() + validMs,
    contentType,
    extensionHeaders,
  });
  return { url, headers: { "Content-Type": contentType, ...extensionHeaders } };
}

export async function signDownload(feedbackId: string, attachmentId: string, validMs: number): Promise<string> {
  const [url] = await fileOf(feedbackId, attachmentId).getSignedUrl({
    version: "v4",
    action: "read",
    expires: Date.now() + validMs,
  });
  return url;
}

export async function statObject(feedbackId: string, attachmentId: string): Promise<StoredObject | undefined> {
  const file = fileOf(feedbackId, attachmentId);
  if (!(await file.exists())[0]) return undefined;
  const [metadata] = await file.getMetadata();
  const [head] = await file.download({ start: 0, end: HEAD_BYTES - 1 });
  return { size: Number(metadata.size), contentType: `${metadata.contentType ?? ""}`, head };
}

// Objects with upload time in ms
export async function listObjects(): Promise<{ feedbackId: string; attachmentId: string; createdAt: number }[]> {
  const [files] = await bucket().getFiles({ prefix: `${ROOT}/` });
  return files.flatMap((file) => {
    const [, feedbackId, attachmentId] = file.name.split("/");
    return attachmentId === undefined || attachmentId === "" ? []
      : [{ feedbackId, attachmentId, createdAt: Date.parse(`${file.metadata.timeCreated}`) }];
  });
}

// Without ids, everything of the item
export async function deleteObjects(feedbackId: string, attachmentIds?: string[]) {
  if (attachmentIds === undefined) {
    await bucket().deleteFiles({ prefix: `${ROOT}/${feedbackId}/`, force: true });
    return;
  }
  await Promise.all(attachmentIds.map((id) => fileOf(feedbackId, id).delete({ ignoreNotFound: true })));
}
