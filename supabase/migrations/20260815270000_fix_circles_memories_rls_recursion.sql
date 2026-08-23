-- Fix infinite RLS recursion on circles, circle_members, memories, and related tables.

create or replace function public.user_is_circle_member(p_circle_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.circle_members cm
    where cm.circle_id = p_circle_id
      and cm.user_id = auth.uid()
  );
$$;

create or replace function public.user_is_circle_owner(p_circle_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.circles c
    where c.id = p_circle_id
      and c.owner_id = auth.uid()
  );
$$;

create or replace function public.user_can_access_memory(p_memory_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.memories m
    where m.id = p_memory_id
      and (
        m.owner_id = auth.uid()
        or exists (
          select 1
          from public.memory_participants mp
          where mp.memory_id = m.id
            and mp.user_id = auth.uid()
        )
        or (
          m.circle_id is not null
          and exists (
            select 1
            from public.circle_members cm
            where cm.circle_id = m.circle_id
              and cm.user_id = auth.uid()
          )
        )
      )
  );
$$;

drop policy if exists "Members can view circles" on public.circles;
create policy "Members can view circles"
on public.circles for select
to authenticated
using (
  public.user_is_circle_member(id)
  or (select auth.uid()) = owner_id
);

drop policy if exists "Members can view circle membership" on public.circle_members;
create policy "Members can view circle membership"
on public.circle_members for select
to authenticated
using (public.user_is_circle_member(circle_id));

drop policy if exists "Owners can add circle members" on public.circle_members;
create policy "Owners can add circle members"
on public.circle_members for insert
to authenticated
with check (
  public.user_is_circle_owner(circle_id)
  or (
    (select auth.uid()) = user_id
    and role = 'owner'
    and public.user_is_circle_owner(circle_id)
  )
);

drop policy if exists "Owners can remove circle members" on public.circle_members;
create policy "Owners can remove circle members"
on public.circle_members for delete
to authenticated
using (
  public.user_is_circle_owner(circle_id)
  or (select auth.uid()) = user_id
);

drop policy if exists "Users can view accessible memories" on public.memories;
create policy "Users can view accessible memories"
on public.memories for select
to authenticated
using (public.user_can_access_memory(id));

drop policy if exists "Users can view memory items" on public.memory_items;
create policy "Users can view memory items"
on public.memory_items for select
to authenticated
using (public.user_can_access_memory(memory_id));

drop policy if exists "Users can view memory participants" on public.memory_participants;
create policy "Users can view memory participants"
on public.memory_participants for select
to authenticated
using (public.user_can_access_memory(memory_id));

drop policy if exists "Users can view memory chapters" on public.memory_chapters;
create policy "Users can view memory chapters"
on public.memory_chapters for select
to authenticated
using (public.user_can_access_memory(memory_id));

drop policy if exists "Circle members can view prompt responses" on public.prompt_responses;
create policy "Circle members can view prompt responses"
on public.prompt_responses for select
to authenticated
using (public.user_is_circle_member(circle_id));

drop policy if exists "Members can submit prompt responses" on public.prompt_responses;
create policy "Members can submit prompt responses"
on public.prompt_responses for insert
to authenticated
with check (
  (select auth.uid()) = user_id
  and public.user_is_circle_member(circle_id)
  and exists (
    select 1
    from public.moments m
    where m.id = moment_id
      and m.sender_id = auth.uid()
  )
);

revoke all on function public.user_is_circle_member(uuid) from public;
revoke all on function public.user_is_circle_owner(uuid) from public;
revoke all on function public.user_can_access_memory(uuid) from public;
revoke all on function public.user_is_circle_member(uuid) from anon;
revoke all on function public.user_is_circle_owner(uuid) from anon;
revoke all on function public.user_can_access_memory(uuid) from anon;
grant execute on function public.user_is_circle_member(uuid) to authenticated;
grant execute on function public.user_is_circle_owner(uuid) to authenticated;
grant execute on function public.user_can_access_memory(uuid) to authenticated;
