// notify-moment
//
// Invoked by the `moment_recipients_notify` trigger for every delivered moment.
// Sends a DATA-ONLY, high priority FCM message. Data-only matters: if the
// payload carried a `notification` block, Android would hand it to the system
// tray and never start our service while the app is killed, so the home-screen
// widget would stay stale until the user opened the app.

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
    const { moment_id, recipient_id } = await request.json();
    if (!moment_id || !recipient_id) {
      return new Response(JSON.stringify({ error: "missing ids" }), {
        status: 400,
      });
    }

    const account: ServiceAccount = JSON.parse(FIREBASE_SERVICE_ACCOUNT);
    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

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

    const { data: moment } = await supabase
      .from("moments")
      .select("id, sender_id, storage_path, caption, created_at")
      .eq("id", moment_id)
      .single();

    if (!moment) {
      return new Response(JSON.stringify({ error: "moment not found" }), {
        status: 404,
      });
    }

    const { data: sender } = await supabase
      .from("profiles")
      .select("display_name, avatar_url")
      .eq("id", moment.sender_id)
      .single();

    const { data: prefs } = await supabase
      .from("widget_preferences")
      .select("widget_mode, selected_person_id, selected_circle_id")
      .eq("user_id", recipient_id)
      .maybeSingle();

    const mode = prefs?.widget_mode ?? "latest";
    let widgetEligible = mode === "latest";
    let headerTitle = sender?.display_name ?? "Moment";
    let headerEmoji = "";

    if (mode === "person") {
      widgetEligible = prefs?.selected_person_id === moment.sender_id;
    } else if (mode === "circle" && prefs?.selected_circle_id) {
      const { data: membership } = await supabase
        .from("circle_members")
        .select("user_id")
        .eq("circle_id", prefs.selected_circle_id)
        .eq("user_id", moment.sender_id)
        .maybeSingle();
      widgetEligible = membership != null;

      if (widgetEligible) {
        const { data: circle } = await supabase
          .from("circles")
          .select("name, emoji")
          .eq("id", prefs.selected_circle_id)
          .single();
        if (circle) {
          headerTitle = circle.name;
          headerEmoji = circle.emoji ?? "";
        }
      }
    }

    // Buckets are private, so the device cannot fetch storage paths directly.
    const { data: signedImage } = await supabase.storage
      .from("moments")
      .createSignedUrl(moment.storage_path, SIGNED_URL_TTL_SECONDS);

    let avatarUrl = "";
    if (sender?.avatar_url) {
      const { data: signedAvatar } = await supabase.storage
        .from("avatars")
        .createSignedUrl(sender.avatar_url, SIGNED_URL_TTL_SECONDS);
      avatarUrl = signedAvatar?.signedUrl ?? "";
    }

    const accessToken = await getAccessToken(account);
    const senderName = sender?.display_name ?? "A friend";

    const data: Record<string, string> = {
      type: "new_moment",
      momentId: moment.id,
      moment_id: moment.id,
      recipientId: recipient_id,
      recipient_id: recipient_id,
      senderId: moment.sender_id,
      sender_id: moment.sender_id,
      senderName,
      title: headerTitle,
      headerTitle,
      headerEmoji,
      caption: moment.caption ?? "",
      relativeTime: "now",
      createdAt: moment.created_at,
      created_at: moment.created_at,
      createdAtMillis: String(Date.parse(moment.created_at) || Date.now()),
      imageUrl: signedImage?.signedUrl ?? "",
      image_url: signedImage?.signedUrl ?? "",
      avatarUrl,
      avatar_url: avatarUrl,
      widgetEligible: widgetEligible ? "true" : "false",
      notificationTitle: senderName,
      notificationBody: moment.caption?.trim()
        ? moment.caption
        : "sent you a moment",
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
      JSON.stringify({ sent: tokens.length - stale.length, widgetEligible }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
    });
  }
});
