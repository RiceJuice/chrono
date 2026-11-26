-- Profile photos are private and can only be accessed by their account owner.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('profile_avatars', 'profile_avatars', false, 2097152, array['image/jpeg'])
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "profile_avatars_select_own"
on storage.objects for select to authenticated
using (bucket_id = 'profile_avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "profile_avatars_insert_own"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'profile_avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and array_length(storage.foldername(name), 1) = 1
  and storage.extension(name) = 'jpg'
);

create policy "profile_avatars_delete_own"
on storage.objects for delete to authenticated
using (bucket_id = 'profile_avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
