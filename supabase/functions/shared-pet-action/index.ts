// Shared pet actions — validates JWT and delegates to Postgres RPCs (no direct stat writes).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.47.10";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

type PetAction =
  | "create"
  | "feed"
  | "play"
  | "pet"
  | "drink"
  | "sleep"
  | "wake"
  | "get"
  | "list_actions";

interface RequestBody {
  action: PetAction;
  friend_id?: string;
  pet_id?: string;
  pet_type?: string;
  pet_name?: string;
  idempotency_key?: string;
  limit?: number;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
    });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
    });
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
    });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData.user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
    });
  }

  try {
    switch (body.action) {
      case "get": {
        if (!body.friend_id) {
          return new Response(JSON.stringify({ error: "friend_id required" }), {
            status: 400,
          });
        }
        const { data, error } = await supabase.rpc("get_shared_pet_for_friend", {
          p_friend_id: body.friend_id,
        });
        if (error) throw error;
        return new Response(JSON.stringify({ data }), { status: 200 });
      }
      case "create": {
        if (!body.friend_id || !body.pet_type || !body.pet_name) {
          return new Response(
            JSON.stringify({ error: "friend_id, pet_type, pet_name required" }),
            { status: 400 },
          );
        }
        const { data, error } = await supabase.rpc("create_shared_pet", {
          p_friend_id: body.friend_id,
          p_pet_type: body.pet_type,
          p_pet_name: body.pet_name,
        });
        if (error) throw error;
        return new Response(JSON.stringify({ data }), { status: 200 });
      }
      case "list_actions": {
        if (!body.pet_id) {
          return new Response(JSON.stringify({ error: "pet_id required" }), {
            status: 400,
          });
        }
        const { data, error } = await supabase.rpc("list_pet_actions", {
          p_pet_id: body.pet_id,
          p_limit: body.limit ?? 30,
        });
        if (error) throw error;
        return new Response(JSON.stringify({ data }), { status: 200 });
      }
      case "feed":
      case "play":
      case "pet":
      case "drink":
      case "sleep":
      case "wake": {
        if (!body.pet_id) {
          return new Response(JSON.stringify({ error: "pet_id required" }), {
            status: 400,
          });
        }
        const { data, error } = await supabase.rpc("perform_pet_action", {
          p_pet_id: body.pet_id,
          p_action_type: body.action,
          p_idempotency_key: body.idempotency_key ?? null,
        });
        if (error) throw error;
        return new Response(JSON.stringify({ data }), { status: 200 });
      }
      default:
        return new Response(JSON.stringify({ error: "Unknown action" }), {
          status: 400,
        });
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: message }), { status: 400 });
  }
});
