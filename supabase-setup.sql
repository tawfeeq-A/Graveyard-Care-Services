-- Secure Supabase setup for Grave Care Services landing page
-- Social-link version: media is hosted on Instagram/Facebook; database stores only links/captions.
-- Admin email configured: tawfeeqahmadsofi13@gmail.com

-- =========================================================
-- 0) ADMIN EMAIL CONFIGURATION
-- =========================================================

create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  email text primary key,
  created_at timestamptz default now()
);

insert into public.admin_users (email)
values ('tawfeeqahmadsofi13@gmail.com')
on conflict (email) do nothing;

create or replace function public.is_site_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admin_users
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

alter table public.admin_users enable row level security;

drop policy if exists "Admins can read admin users" on public.admin_users;
drop policy if exists "Admins can manage admin users" on public.admin_users;

create policy "Admins can read admin users"
on public.admin_users
for select
to authenticated
using (public.is_site_admin());

create policy "Admins can manage admin users"
on public.admin_users
for all
to authenticated
using (public.is_site_admin())
with check (public.is_site_admin());

-- =========================================================
-- 0B) RECOVERY PIN CONFIGURATION
-- =========================================================
-- The recovery PIN only opens the hidden admin UI.
-- Supabase Auth + RLS still protect saving database changes.

create table if not exists public.site_private_settings (
  id text primary key default 'main',
  recovery_pin_hash text not null,
  updated_at timestamptz default now()
);

insert into public.site_private_settings (id, recovery_pin_hash)
values ('main', md5('gravecare-recovery-pin:' || '1234'))
on conflict (id) do nothing;

alter table public.site_private_settings enable row level security;

drop policy if exists "Only site admins can read private settings" on public.site_private_settings;
drop policy if exists "Only site admins can manage private settings" on public.site_private_settings;

create policy "Only site admins can read private settings"
on public.site_private_settings
for select
to authenticated
using (public.is_site_admin());

create policy "Only site admins can manage private settings"
on public.site_private_settings
for all
to authenticated
using (public.is_site_admin())
with check (public.is_site_admin());

create or replace function public.verify_recovery_pin(pin text)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.site_private_settings
    where id = 'main'
      and recovery_pin_hash = md5('gravecare-recovery-pin:' || coalesce(pin, ''))
  );
$$;

grant execute on function public.verify_recovery_pin(text) to anon, authenticated;

create or replace function public.set_recovery_pin(pin text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_site_admin() then
    raise exception 'Only site admins can change the recovery PIN';
  end if;

  if pin is null or length(pin) < 4 then
    raise exception 'PIN must be at least 4 characters';
  end if;

  update public.site_private_settings
  set recovery_pin_hash = md5('gravecare-recovery-pin:' || pin),
      updated_at = now()
  where id = 'main';
end;
$$;

grant execute on function public.set_recovery_pin(text) to authenticated;

-- =========================================================
-- 1) DEFAULT COPY JSON
-- =========================================================

create or replace function public.default_site_copy()
returns jsonb
language sql
immutable
as $$
  select $json$
{
  "seoTitle": "Grave Care Services | Professional Grave Maintenance in Srinagar",
  "seoDescription": "Professional grave maintenance in Srinagar. We clean, align, restore and maintain graves with care. Contact us on WhatsApp to start.",
  "navServicesLabel": "Services",
  "navWorkLabel": "Our work",
  "navInstagramLabel": "Social",
  "navContactLabel": "Contact",
  "eyebrow": "Grave maintenance done with care and precision.",
  "heroWhatsappButton": "💬 Chat on WhatsApp",
  "heroWorkButton": "See our work",
  "heroInstagramButton": "Social",
  "floatOneTitle": "🌿 Deweeding",
  "floatOneText": "Remove grass, weeds and unwanted growth.",
  "floatTwoTitle": "📐 Alignment",
  "floatTwoText": "Make graves sit neat with the floor.",
  "floatThreeTitle": "🧱 DPC / Custom",
  "floatThreeText": "Discuss protection, repairs and special work.",
  "servicesTag": "Our services",
  "servicesHeading": "What we do.",
  "servicesSubtext": "Every job starts with a WhatsApp message. We confirm details by call before any work begins.",
  "service1Title": "Deweeding",
  "service1Text": "We clear weeds, grass, and unwanted growth from around the grave. The area is left clean and fully visible.",
  "service2Title": "Bush removal",
  "service2Text": "We remove bushes and shrubs that cover or damage the grave. Overgrowth is cut back fully.",
  "service3Title": "Grave alignment",
  "service3Text": "We correct graves that have shifted or sit uneven with the floor. The result is a straight, properly aligned grave.",
  "service4Title": "Floor leveling",
  "service4Text": "We level uneven grave surfaces. Work is confirmed after we assess the site condition with you.",
  "service5Title": "DPC work",
  "service5Text": "Send us photos of the grave. We assess what DPC or protective work is needed, then arrange a call to confirm.",
  "service6Title": "Custom requests",
  "service6Text": "Send us your request on WhatsApp. We discuss what is needed and plan the work with you directly.",
  "workTag": "Our work",
  "workHeading": "Browse our work on Instagram and Facebook.",
  "workSubtext": "Browse before-and-after photos of our cleaning, alignment, and restoration work. Latest jobs can be shared from Instagram or Facebook.",
  "workInstagramButton": "Visit Social Page",
  "instagramCardTitle": "Work Sample",
  "instagramCardButton": "View Post / Reel →",
  "galleryPlaceholder1": "Add an Instagram or Facebook reel showing before/after deweeding.",
  "galleryPlaceholder2": "Add an Instagram or Facebook post showing bush removal work.",
  "galleryPlaceholder3": "Add an Instagram or Facebook reel showing alignment or DPC work.",
  "galleryPlaceholderCaption": "Social portfolio placeholder",
  "processTag": "Process",
  "processHeading": "How it works.",
  "step1Title": "Message us",
  "step1Text": "Send a WhatsApp message and describe the grave condition and what needs doing.",
  "step2Title": "Share details",
  "step2Text": "Send the cemetery location, grave photos, and any specific instructions.",
  "step3Title": "Confirm by call",
  "step3Text": "We discuss timing, pricing, and exact scope before any work starts.",
  "step4Title": "Work completed",
  "step4Text": "We carry out the job and send you photos or video as confirmation.",
  "ctaWhatsappButton": "Start WhatsApp Chat",
  "ctaInstagramButton": "View Social",
  "footerSecretWord": "admin",
  "footerMainText": "grave maintenance for families across Srinagar and local qabristans."
}
$json$::jsonb;
$$;

-- =========================================================
-- 2) SITE SETTINGS TABLE
-- =========================================================

create table if not exists public.site_settings (
  id text primary key default 'main',
  brand_name text default 'Grave Care Services',
  whatsapp_number text default '',
  instagram_profile_url text default 'https://www.instagram.com/',
  hero_title text default 'Your family''s resting place, maintained with dignity.',
  hero_subtitle text default 'We clean, align, and restore graves for families who want to keep resting places in proper condition. Send us a WhatsApp message to start.',
  whatsapp_message text default 'Hello, I need graveyard maintenance service. I would like to discuss deweeding, bush removal, grave alignment, DPC or custom work.',
  cta_title text default 'Ready to restore the grave?',
  cta_text text default 'Send us a WhatsApp message. We review your request and confirm all details by call before starting.',
  content_json jsonb default public.default_site_copy(),
  updated_at timestamptz default now()
);

alter table public.site_settings add column if not exists instagram_profile_url text default 'https://www.instagram.com/';
alter table public.site_settings add column if not exists content_json jsonb default public.default_site_copy();

insert into public.site_settings (
  id,
  brand_name,
  whatsapp_number,
  instagram_profile_url,
  hero_title,
  hero_subtitle,
  whatsapp_message,
  cta_title,
  cta_text,
  content_json
)
values (
  'main',
  'Grave Care Services',
  '',
  'https://www.instagram.com/',
  'Your family''s resting place, maintained with dignity.',
  'We clean, align, and restore graves for families who want to keep resting places in proper condition. Send us a WhatsApp message to start.',
  'Hello, I need graveyard maintenance service. I would like to discuss deweeding, bush removal, grave alignment, DPC or custom work.',
  'Ready to restore the grave?',
  'Send us a WhatsApp message. We review your request and confirm all details by call before starting.',
  public.default_site_copy()
)
on conflict (id) do nothing;

update public.site_settings
set
  instagram_profile_url = coalesce(instagram_profile_url, 'https://www.instagram.com/'),
  hero_title = 'Your family''s resting place, maintained with dignity.',
  hero_subtitle = 'We clean, align, and restore graves for families who want to keep resting places in proper condition. Send us a WhatsApp message to start.',
  cta_title = 'Ready to restore the grave?',
  cta_text = 'Send us a WhatsApp message. We review your request and confirm all details by call before starting.',
  content_json = public.default_site_copy(),
  updated_at = now()
where id = 'main';

-- =========================================================
-- 3) INSTAGRAM WORK LINKS TABLE
-- =========================================================

create table if not exists public.work_media (
  id uuid primary key default gen_random_uuid(),
  file_url text not null,
  storage_path text, -- stores optional thumbnail image URL for social links
  file_type text not null default 'social',
  caption text,
  created_at timestamptz default now()
);

alter table public.work_media alter column file_type set default 'social';

-- =========================================================
-- 4) ENABLE ROW LEVEL SECURITY
-- =========================================================

alter table public.site_settings enable row level security;
alter table public.work_media enable row level security;

-- =========================================================
-- 5) RESET OLD POLICIES
-- =========================================================

drop policy if exists "Public can read site settings" on public.site_settings;
drop policy if exists "Authenticated admins can manage site settings" on public.site_settings;
drop policy if exists "Only admin email can manage site settings" on public.site_settings;
drop policy if exists "Only site admins can manage site settings" on public.site_settings;

drop policy if exists "Public can read work media" on public.work_media;
drop policy if exists "Authenticated admins can manage work media" on public.work_media;
drop policy if exists "Only admin email can manage work media" on public.work_media;
drop policy if exists "Only site admins can manage work media" on public.work_media;

-- Old storage policies removed because this site uses social links instead of Supabase Storage.
drop policy if exists "Public can read work-media files" on storage.objects;
drop policy if exists "Authenticated admins can upload work-media files" on storage.objects;
drop policy if exists "Authenticated admins can update work-media files" on storage.objects;
drop policy if exists "Authenticated admins can delete work-media files" on storage.objects;
drop policy if exists "Only admin email can upload work-media files" on storage.objects;
drop policy if exists "Only admin email can update work-media files" on storage.objects;
drop policy if exists "Only admin email can delete work-media files" on storage.objects;
drop policy if exists "Only site admins can upload work-media files" on storage.objects;
drop policy if exists "Only site admins can update work-media files" on storage.objects;
drop policy if exists "Only site admins can delete work-media files" on storage.objects;

-- =========================================================
-- 6) DATABASE POLICIES
-- =========================================================

create policy "Public can read site settings"
on public.site_settings
for select
to anon, authenticated
using (true);

create policy "Only site admins can manage site settings"
on public.site_settings
for all
to authenticated
using (public.is_site_admin())
with check (public.is_site_admin());

create policy "Public can read work media"
on public.work_media
for select
to anon, authenticated
using (true);

create policy "Only site admins can manage work media"
on public.work_media
for all
to authenticated
using (public.is_site_admin())
with check (public.is_site_admin());

-- =========================================================
-- 7) GRANTS
-- =========================================================

grant select on public.site_settings to anon, authenticated;
grant select on public.work_media to anon, authenticated;
grant select on public.admin_users to authenticated;
grant select on public.site_private_settings to authenticated;

grant insert, update, delete on public.site_settings to authenticated;
grant insert, update, delete on public.work_media to authenticated;
grant insert, update, delete on public.admin_users to authenticated;
grant insert, update, delete on public.site_private_settings to authenticated;

notify pgrst, 'reload schema';

-- Recommended Supabase dashboard settings:
-- 1. Authentication > Providers > Email: disable public signups if you do not need them.
-- 2. Authentication > Users: manually create and confirm your admin user: tawfeeqahmadsofi13@gmail.com
-- 3. Never expose the service_role key in frontend code.
