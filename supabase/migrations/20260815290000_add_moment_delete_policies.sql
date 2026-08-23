-- Allow recipients to remove moments from their daily feed and senders to delete sent moments.

drop policy if exists "Recipients can remove from feed" on public.moment_recipients;
create policy "Recipients can remove from feed"
on public.moment_recipients for delete
to authenticated
using (auth.uid() = recipient_id);

drop policy if exists "Senders can delete own moments" on public.moments;
create policy "Senders can delete own moments"
on public.moments for delete
to authenticated
using (auth.uid() = sender_id);

drop policy if exists "Senders can delete own moment files" on storage.objects;
create policy "Senders can delete own moment files"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'moments'
  and (storage.foldername(name))[1] = auth.uid()::text
);
