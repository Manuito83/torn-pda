import { createHash, createHmac } from "crypto";

const TIMEOUT_MS = 10000;

export interface R2Config {
  r2AccountId: string;
  r2AccessKeyId: string;
  r2SecretAccessKey: string;
  r2Bucket: string;
  publicBaseUrl: string;
  mapHeader: string;
}

export type R2Files = Pick<R2Client, "put" | "get" | "headPublic">;

function sha256Hex(data: string | Buffer): string {
  return createHash("sha256").update(data).digest("hex");
}

function hmac(key: Buffer | string, msg: string): Buffer {
  return createHmac("sha256", key).update(msg).digest();
}

// Lowercase headers, all of them signed
export function sigV4Authorization(method: string, path: string, query: string, headers: Record<string, string>,
  payloadHash: string, accessKey: string, secret: string, region: string, service: string): string {
  const amzDate = headers["x-amz-date"];
  const day = amzDate.slice(0, 8);
  const scope = `${day}/${region}/${service}/aws4_request`;
  const names = Object.keys(headers).sort();
  const canonical = [method, path, query, names.map((n) => `${n}:${headers[n].trim()}\n`).join(""),
    names.join(";"), payloadHash].join("\n");
  const toSign = ["AWS4-HMAC-SHA256", amzDate, scope, sha256Hex(canonical)].join("\n");
  let key: Buffer = hmac(`AWS4${secret}`, day);
  for (const part of [region, service, "aws4_request"]) key = hmac(key, part);
  const signature = createHmac("sha256", key).update(toSign).digest("hex");
  return `AWS4-HMAC-SHA256 Credential=${accessKey}/${scope}, SignedHeaders=${names.join(";")}, Signature=${signature}`;
}

function amzDate(ms: number): string {
  return new Date(ms).toISOString().replace(/[-:]/g, "").replace(/\.\d{3}/, "");
}

export class R2Client {
  private readonly host: string;

  constructor(
    private readonly config: R2Config,
    private readonly clockMs: () => number = Date.now,
    private readonly fetcher: typeof fetch = fetch,
  ) {
    this.host = `${config.r2AccountId}.r2.cloudflarestorage.com`;
  }

  private async send(method: "GET" | "PUT", key: string, body: Buffer | null,
    extra: Record<string, string>): Promise<Response> {
    const path = "/" + `${this.config.r2Bucket}/${key}`.split("/").map(encodeURIComponent).join("/");
    const payloadHash = sha256Hex(body ?? "");
    const sent: Record<string, string> = {
      "x-amz-date": amzDate(this.clockMs()),
      "x-amz-content-sha256": payloadHash,
      ...extra,
    };
    const auth = sigV4Authorization(method, path, "", { ...sent, host: this.host }, payloadHash,
      this.config.r2AccessKeyId, this.config.r2SecretAccessKey, "auto", "s3");
    return this.fetcher(`https://${this.host}${path}`, {
      method,
      headers: { ...sent, Authorization: auth },
      body: body ? new Uint8Array(body) : undefined,
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
  }

  private async fail(key: string, response: Response): Promise<never> {
    const code = /<Code>([A-Za-z]{1,60})<\/Code>/.exec(await response.text())?.[1];
    throw new Error(`R2 ${key}: HTTP ${response.status}${code ? ` ${code}` : ""}`);
  }

  async put(key: string, body: Buffer, contentType: string, cacheControl: string): Promise<void> {
    const response = await this.send("PUT", key, body, { "content-type": contentType, "cache-control": cacheControl });
    if (!response.ok) await this.fail(key, response);
  }

  // Bucket, not CDN; null if missing
  async get(key: string): Promise<Buffer | null> {
    const response = await this.send("GET", key, null, {});
    if (response.status === 404) return null;
    if (!response.ok) await this.fail(key, response);
    return Buffer.from(await response.arrayBuffer());
  }

  // Public file status, with header
  async headPublic(path: string): Promise<number> {
    const response = await this.fetcher(`${this.config.publicBaseUrl}/${path}`, {
      method: "HEAD",
      headers: { "x-pda-map": this.config.mapHeader },
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
    return response.status;
  }
}
