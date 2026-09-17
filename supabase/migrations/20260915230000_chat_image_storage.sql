-- Chat images live under {user_id}/chat/{conversation_id}/ in the moments bucket.
-- Upload is allowed by the existing "Users can upload own moments" policy (first folder = uid).
-- Add read access for conversation participants.

drop policy if exists "Chat participants can read chat images" on storage.objects;
create policy "Chat participants can read chat images"
on storage.objects for select
to authenticated
using (
  bucket_id = 'moments'
  and (storage.foldername(name))[2] = 'chat'
  and exists (
    select 1
    from public.chat_conversations c
    where c.id::text = (storage.foldername(name))[3]
      and (c.participant_low = auth.uid() or c.participant_high = auth.uid())
  )
);
