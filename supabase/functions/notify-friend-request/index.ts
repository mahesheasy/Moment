// notify-friend-request — data-only FCM when someone sends a friend request.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.47.10";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FIREBASE_SERVICE_ACCOUNT = Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!;

const SIGNED_URL_TTL_SECONDS = 3600;

interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
}

let cachedToken: { value: string; expiresAt: number } | null = null;

function base64Url(input: ArrayBuffer | string): string {
  const bytes = typeof input === "string"
    ? new TextEncoder().encode(input)
    : new Uint8Array(input);
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToPkcs8(pem: string): ArrayBuffer {
  const body = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");
  const binary = atob(body);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

async function getAccessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt > now + 60) return cachedToken.value;

  const header = base64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = base64Url(JSON.stringify({
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToPkcs8(account.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(`${header}.${claim}`),
  );
  const assertion = `${header}.${claim}.${base64Url(signature)}`;

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });

  if (!response.ok) {
    throw new Error(`Token exchange failed: ${await response.text()}`);
  }

  const payload = await response.json();
  cachedToken = {
    value: payload.access_token,
    expiresAt: now + (payload.expires_in ?? 3600),
  };
  return cachedToken.value;
}

Deno.serve(async (request) => {
  try {
    const { request_id, recipient_id, sender_id } = await request.json();
    if (!request_id || !recipient_id || !sender_id) {
      return new Response(JSON.stringify({ error: "missing ids" }), {
        status: 400,
      });
    }

    const account: ServiceAccount = JSON.parse(FIREBASE_SERVICE_ACCOUNT);
    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    const { data: friendRequest } = await supabase
      .from("friend_requests")
      .select("id, status")
      .eq("id", request_id)
      .single();

    if (!friendRequest || friendRequest.status !== "pending") {
      return new Response(JSON.stringify({ skipped: "not pending" }), {
        status: 200,
      });
    }

    const { data: tokenRows } = await supabase
      .from("device_tokens")
      .select("token")
      .eq("user_id", recipient_id);

    const tokens = (tokenRows ?? []).map((row) => row.token as string);
    if (tokens.length === 0) {
      return new Response(JSON.stringify({ skipped: "no devices" }), {
        status: 200,
      });
    }

    const { data: sender } = await supabase
      .from("profiles")
      .select("display_name, avatar_url")
      .eq("id", sender_id)
      .single();

    let avatarUrl = "";
    if (sender?.avatar_url) {
      const { data: signedAvatar } = await supabase.storage
        .from("avatars")
        .createSignedUrl(sender.avatar_url, SIGNED_URL_TTL_SECONDS);
      avatarUrl = signedAvatar?.signedUrl ?? "";
    }

    const accessToken = await getAccessToken(account);
    const senderName = sender?.display_name ?? "Someone";

    const data: Record<string, string> = {
      type: "friend_request",
      requestId: request_id,
      senderId: sender_id,
      senderName,
      avatarUrl,
      notificationTitle: senderName,
      notificationBody: "sent you a friend request",
    };

    const stale: string[] = [];
    await Promise.all(tokens.map(async (token) => {
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token,
              data,
              android: { priority: "HIGH", ttl: "600s" },
            },
          }),
        },
      );

      if (!response.ok) {
        const body = await response.text();
        if (response.status === 404 || body.includes("UNREGISTERED")) {
          stale.push(token);
        } else {
          console.error(`FCM send failed (${response.status}): ${body}`);
        }
      }
    }));

    if (stale.length > 0) {
      await supabase.from("device_tokens").delete().in("token", stale);
    }

    return new Response(
      JSON.stringify({ sent: tokens.length - stale.length }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
    });
  }
});
