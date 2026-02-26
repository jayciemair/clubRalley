// send-push-notification — Supabase Edge Function
//
// Triggered by a Database Webhook on INSERT into the `notifications` table.
// Sends an APNs push notification to all active devices for the target user,
// respecting their per-category notification_settings.
//
// Required secrets (set via `supabase secrets set`):
//   APNS_KEY_ID      — Apple APNs Key ID
//   APNS_TEAM_ID     — Apple Developer Team ID
//   APNS_KEY_P8      — Contents of the .p8 private key file (base64-encoded)
//   APNS_TOPIC       — Bundle ID (e.g. com.clubralley.app)
//   SUPABASE_URL     — Auto-provided by Supabase
//   SUPABASE_SERVICE_ROLE_KEY — Auto-provided by Supabase

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ── Helpers ──────────────────────────────────────────────────────────────────

/** Base64url-encode a string (no padding). */
function base64url(input: string): string {
  return btoa(input)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

/** Import the PKCS#8 .p8 key for ES256 signing. */
async function importP8Key(base64Key: string): Promise<CryptoKey> {
  const pem = atob(base64Key);
  // Strip PEM header/footer if present
  const stripped = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s/g, "");
  const binaryDer = Uint8Array.from(atob(stripped), (c) => c.charCodeAt(0));

  return crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"]
  );
}

/** Generate an APNs JWT valid for ~55 minutes. */
async function generateAPNsJWT(
  keyId: string,
  teamId: string,
  privateKey: CryptoKey
): Promise<string> {
  const header = base64url(JSON.stringify({ alg: "ES256", kid: keyId }));
  const now = Math.floor(Date.now() / 1000);
  const payload = base64url(JSON.stringify({ iss: teamId, iat: now }));
  const signingInput = new TextEncoder().encode(`${header}.${payload}`);

  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    privateKey,
    signingInput
  );

  // Convert DER signature to raw r||s (64 bytes) for JWT
  const sig = new Uint8Array(signature);
  let r: Uint8Array, s: Uint8Array;

  if (sig[0] === 0x30) {
    // DER-encoded
    const rLen = sig[3];
    const rStart = 4;
    r = sig.slice(rStart, rStart + rLen);
    const sLen = sig[rStart + rLen + 1];
    const sStart = rStart + rLen + 2;
    s = sig.slice(sStart, sStart + sLen);
  } else {
    // Already raw
    r = sig.slice(0, 32);
    s = sig.slice(32, 64);
  }

  // Pad/trim to exactly 32 bytes each
  const pad = (arr: Uint8Array): Uint8Array => {
    if (arr.length === 32) return arr;
    if (arr.length > 32) return arr.slice(arr.length - 32);
    const padded = new Uint8Array(32);
    padded.set(arr, 32 - arr.length);
    return padded;
  };

  const rawSig = new Uint8Array(64);
  rawSig.set(pad(r), 0);
  rawSig.set(pad(s), 32);

  const sigB64 = base64url(String.fromCharCode(...rawSig));
  return `${header}.${payload}.${sigB64}`;
}

// ── Notification type → settings column mapping ──────────────────────────────

const TYPE_TO_SETTING: Record<string, string> = {
  ralley_invite: "ralley_invites",
  ralley_reminder: "ralley_updates",
  ralley_join: "ralley_updates",
  follow: "new_followers",
  like: "comments_likes",
  comment: "comments_likes",
  mention: "comments_likes",
};

// ── Main handler ─────────────────────────────────────────────────────────────

serve(async (req: Request) => {
  try {
    // 1. Parse the webhook payload
    const { record } = await req.json();
    if (!record) {
      return new Response(JSON.stringify({ error: "No record in payload" }), {
        status: 400,
      });
    }

    const {
      id: notificationId,
      user_id: userId,
      type,
      title,
      body,
      from_user_id: actorId,
      ralley_id: ralleyId,
      post_id: postId,
    } = record;

    console.log(
      `Processing push for notification ${notificationId} (type: ${type}) to user ${userId}`
    );

    // 2. Check APNs secrets are configured
    const apnsKeyId = Deno.env.get("APNS_KEY_ID");
    const apnsTeamId = Deno.env.get("APNS_TEAM_ID");
    const apnsKeyP8 = Deno.env.get("APNS_KEY_P8");
    const apnsTopic = Deno.env.get("APNS_TOPIC");

    if (!apnsKeyId || !apnsTeamId || !apnsKeyP8 || !apnsTopic) {
      console.log("APNs secrets not configured, skipping push");
      return new Response(JSON.stringify({ skipped: "apns_not_configured" }), {
        status: 200,
      });
    }

    // 3. Initialize Supabase client with service_role to bypass RLS
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // 4. Check user's notification settings
    const settingsColumn = TYPE_TO_SETTING[type];
    if (settingsColumn) {
      const { data: settings } = await supabase
        .from("notification_settings")
        .select("push_enabled, " + settingsColumn)
        .eq("user_id", userId)
        .maybeSingle();

      if (settings) {
        if (
          !settings.push_enabled ||
          !settings[settingsColumn as keyof typeof settings]
        ) {
          console.log(
            `Push disabled for type "${type}" by user settings, skipping`
          );
          return new Response(
            JSON.stringify({ skipped: "disabled_by_settings" }),
            { status: 200 }
          );
        }
      }
      // If no settings row exists, defaults are all enabled — proceed
    }

    // 5. Load active device tokens
    const { data: tokens, error: tokensError } = await supabase
      .from("device_tokens")
      .select("id, token")
      .eq("user_id", userId)
      .eq("is_active", true);

    if (tokensError) {
      console.error("Failed to load device tokens:", tokensError.message);
      return new Response(
        JSON.stringify({ error: "Failed to load tokens" }),
        { status: 500 }
      );
    }

    if (!tokens || tokens.length === 0) {
      console.log("No active device tokens for user, skipping");
      return new Response(JSON.stringify({ skipped: "no_tokens" }), {
        status: 200,
      });
    }

    // 6. Generate APNs JWT
    const privateKey = await importP8Key(apnsKeyP8);
    const jwt = await generateAPNsJWT(apnsKeyId, apnsTeamId, privateKey);

    // 7. Build APNs payload
    const apnsPayload = {
      aps: {
        alert: {
          title: title || "Club Ralley",
          body: body || "",
        },
        sound: "default",
        "mutable-content": 1,
      },
      // Custom data for client-side deep linking
      type,
      notification_id: notificationId,
      ...(ralleyId && { ralley_id: ralleyId }),
      ...(postId && { post_id: postId }),
      ...(actorId && { actor_id: actorId }),
    };

    // 8. Send to each device token
    const useProduction = Deno.env.get("APNS_PRODUCTION") === "true";
    const apnsHost = useProduction
      ? "https://api.push.apple.com"
      : "https://api.sandbox.push.apple.com";

    const tokensToDeactivate: string[] = [];
    let successCount = 0;

    for (const { id: tokenRowId, token } of tokens) {
      try {
        const response = await fetch(`${apnsHost}/3/device/${token}`, {
          method: "POST",
          headers: {
            authorization: `bearer ${jwt}`,
            "apns-topic": apnsTopic,
            "apns-push-type": "alert",
            "apns-priority": "10",
            "content-type": "application/json",
          },
          body: JSON.stringify(apnsPayload),
        });

        if (response.ok) {
          successCount++;
        } else {
          const errorBody = await response.text();
          console.error(
            `APNs error for token ${token.substring(0, 8)}...: ${response.status} ${errorBody}`
          );

          // Deactivate invalid tokens
          if (
            response.status === 410 ||
            errorBody.includes("BadDeviceToken") ||
            errorBody.includes("Unregistered")
          ) {
            tokensToDeactivate.push(tokenRowId);
          }
        }
      } catch (err) {
        console.error(
          `Failed to send to token ${token.substring(0, 8)}...:`,
          err
        );
      }
    }

    // 9. Deactivate stale tokens
    if (tokensToDeactivate.length > 0) {
      await supabase
        .from("device_tokens")
        .update({ is_active: false })
        .in("id", tokensToDeactivate);

      console.log(`Deactivated ${tokensToDeactivate.length} stale token(s)`);
    }

    console.log(
      `Push sent: ${successCount}/${tokens.length} succeeded for notification ${notificationId}`
    );

    return new Response(
      JSON.stringify({
        sent: successCount,
        total: tokens.length,
        deactivated: tokensToDeactivate.length,
      }),
      { status: 200 }
    );
  } catch (err) {
    console.error("Unhandled error in send-push-notification:", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
    });
  }
});
