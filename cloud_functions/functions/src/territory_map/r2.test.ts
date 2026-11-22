import { test } from "node:test";
import * as assert from "node:assert/strict";
import { createHash } from "crypto";
import { sigV4Authorization } from "./r2";

// Examples from the AWS documentation
const AK = "AKIAIOSFODNN7EXAMPLE";
const SK = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY";
const sha = (text: string) => createHash("sha256").update(text).digest("hex");

test("SigV4: GET with range", () => {
  const headers = { "host": "examplebucket.s3.amazonaws.com", "range": "bytes=0-9",
    "x-amz-content-sha256": sha(""), "x-amz-date": "20130524T000000Z" };
  const auth = sigV4Authorization("GET", "/test.txt", "", headers, sha(""), AK, SK, "us-east-1", "s3");
  assert.ok(auth.endsWith("Signature=f0e8bdb87c964420e857bd35b5d6ed310bd44f0170aba48dd91039c6036bdb41"));
});

test("SigV4: PUT with a body", () => {
  const payload = sha("Welcome to Amazon S3.");
  const headers = { "date": "Fri, 24 May 2013 00:00:00 GMT", "host": "examplebucket.s3.amazonaws.com",
    "x-amz-content-sha256": payload, "x-amz-date": "20130524T000000Z", "x-amz-storage-class": "REDUCED_REDUNDANCY" };
  const auth = sigV4Authorization("PUT", "/test%24file.text", "", headers, payload, AK, SK, "us-east-1", "s3");
  assert.equal(auth, "AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20130524/us-east-1/s3/aws4_request, " +
    "SignedHeaders=date;host;x-amz-content-sha256;x-amz-date;x-amz-storage-class, " +
    "Signature=98ad721746da40c64f1a55b78f14c238d841ea1380cd77a1b5971af0ece108bd");
});
