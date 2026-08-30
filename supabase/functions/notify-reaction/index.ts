// notify-reaction — data-only FCM when someone reacts to your moment.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.47.10";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FIREBASE_SERVICE_ACCOUNT = Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!;

const REACTION_EMOJI: Record<string, string> = {
  heart: "❤️",
  laugh: "😂",
  fire: "🔥",
  love: "😍",
  wow: "😮",
};

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
    const { moment_id, reactor_id, reaction } = await request.json();
    if (!moment_id || !reactor_id) {
      return new Response(JSON.stringify({ error: "missing ids" }), {
        status: 400,
      });
    }

    const account: ServiceAccount = JSON.parse(FIREBASE_SERVICE_ACCOUNT);
    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    const { data: moment } = await supabase
      .from("moments")
      .select("id, sender_id")
      .eq("id", moment_id)
      .single();

    if (!moment) {
      return new Response(JSON.stringify({ error: "moment not found" }), {
        status: 404,
      });
    }

    const recipientId = moment.sender_id as string;
    if (!recipientId || recipientId === reactor_id) {
      return new Response(JSON.stringify({ skipped: "self reaction" }), {
        status: 200,
      });
    }

    const { data: tokenRows } = await supabase
      .from("device_tokens")
      .select("token")
      .eq("user_id", recipientId);

    const tokens = (tokenRows ?? []).map((row) => row.token as string);
    if (tokens.length === 0) {
      return new Response(JSON.stringify({ skipped: "no devices" }), {
        status: 200,
      });
    }

    const { data: reactor } = await supabase
      .from("profiles")
      .select("display_name")
      .eq("id", reactor_id)
      .single();

    const accessToken = await getAccessToken(account);
    const reactorName = reactor?.display_name ?? "Someone";
    const emoji = REACTION_EMOJI[reaction as string] ?? "❤️";

    const data: Record<string, string> = {
      type: "reaction",
      momentId: moment.id,
      reactorId: reactor_id,
      reactorName,
      reaction: reaction ?? "heart",
      reactionEmoji: emoji,
      notificationTitle: reactorName,
      notificationBody: `reacted ${emoji} to your moment`,
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
