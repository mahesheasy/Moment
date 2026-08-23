-- Fix infinite RLS recursion between moments and moment_recipients.

create or replace function public.user_is_moment_sender(p_moment_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.moments m
    where m.id = p_moment_id
      and m.sender_id = auth.uid()
  );
$$;

create or replace function public.user_is_moment_recipient(p_moment_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.moment_recipients mr
    where mr.moment_id = p_moment_id
      and mr.recipient_id = auth.uid()
  );
$$;

create or replace function public.user_can_access_moment(p_moment_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select public.user_is_moment_sender(p_moment_id)
      or public.user_is_moment_recipient(p_moment_id);
$$;

drop policy if exists "Users can view sent or received moments" on public.moments;
create policy "Users can view sent or received moments"
on public.moments for select
to authenticated
using (
  auth.uid() = sender_id
  or public.user_is_moment_recipient(id)
);

drop policy if exists "Senders can insert recipients" on public.moment_recipients;
create policy "Senders can insert recipients"
on public.moment_recipients for insert
to authenticated
with check (public.user_is_moment_sender(moment_id));

drop policy if exists "Recipients can view own delivery rows" on public.moment_recipients;
create policy "Recipients can view own delivery rows"
on public.moment_recipients for select
to authenticated
using (
  auth.uid() = recipient_id
  or public.user_is_moment_sender(moment_id)
);

drop policy if exists "Senders can update delivery status" on public.moment_recipients;
create policy "Senders can update delivery status"
on public.moment_recipients for update
to authenticated
using (public.user_is_moment_sender(moment_id));

drop policy if exists "Users can view reactions on accessible moments" on public.moment_reactions;
create policy "Users can view reactions on accessible moments"
on public.moment_reactions for select
to authenticated
using (public.user_can_access_moment(moment_id));

drop policy if exists "Users can react to accessible moments" on public.moment_reactions;
create policy "Users can react to accessible moments"
on public.moment_reactions for insert
to authenticated
with check (
  auth.uid() = user_id
  and public.user_can_access_moment(moment_id)
);

drop policy if exists "Users can read accessible moments" on storage.objects;
create policy "Users can read accessible moments"
on storage.objects for select
to authenticated
using (
  bucket_id = 'moments'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or exists (
      select 1
      from public.moments m
      where m.storage_path = name
        and public.user_is_moment_recipient(m.id)
    )
  )
);

revoke all on function public.user_is_moment_sender(uuid) from public;
revoke all on function public.user_is_moment_recipient(uuid) from public;
revoke all on function public.user_can_access_moment(uuid) from public;
revoke all on function public.user_is_moment_sender(uuid) from anon;
revoke all on function public.user_is_moment_recipient(uuid) from anon;
revoke all on function public.user_can_access_moment(uuid) from anon;
grant execute on function public.user_is_moment_sender(uuid) to authenticated;
grant execute on function public.user_is_moment_recipient(uuid) to authenticated;
grant execute on function public.user_can_access_moment(uuid) to authenticated;
