# Grave Care Services — Netlify + Supabase Setup Guide

This folder is ready for a GitHub → Netlify deployment.

## Files in this project

```text
graveyard-care/
├── netlify.toml
├── netlify-deploy/
│   ├── index.html
│   └── _headers
├── supabase-setup.sql
└── FINAL_GO_LIVE_SETUP.md
```

## 1. GitHub location

Upload this whole folder to GitHub as:

```text
your-repo/graveyard-care/
```

## 2. Netlify settings

Create a Netlify site from the same GitHub repo.

Use:

```text
Base directory: graveyard-care
Build command: leave empty
Publish directory: netlify-deploy
```

Netlify will publish:

```text
graveyard-care/netlify-deploy/index.html
```

## 3. Supabase setup

Open the Grave Care Supabase project.

Go to:

```text
SQL Editor
```

Paste and run:

```text
graveyard-care/supabase-setup.sql
```

The admin email is already configured as:

```text
tawfeeqahmadsofi13@gmail.com
```

## 4. Create Supabase admin user

In the Grave Care Supabase project:

```text
Authentication → Users → Add user
```

Create/confirm this user:

```text
tawfeeqahmadsofi13@gmail.com
```

Set a strong password.

## 5. Verify Supabase config in HTML

Open:

```text
graveyard-care/netlify-deploy/index.html
```

Find:

```js
const SUPABASE_URL = "...";
const SUPABASE_ANON_KEY = "...";
```

Make sure these belong to the **Grave Care** Supabase project, not Kashmir Weaves.

## 6. Update Supabase Auth URL settings

In the Grave Care Supabase project:

```text
Authentication → URL Configuration
```

Set Site URL to your Grave Care Netlify URL:

```text
https://YOUR-GRAVE-CARE-SITE.netlify.app
```

Add redirect URL:

```text
https://YOUR-GRAVE-CARE-SITE.netlify.app/**
```

If using a custom domain, add that too.

## 7. Test after deployment

Open the live Grave Care site.

Test:

- Public page loads
- Services section loads
- Instagram links/gallery load
- WhatsApp button opens correctly
- Hidden admin panel opens
- Supabase admin login works
- Settings save to Supabase
- Instagram work links can be added/deleted

## Important

Do not put the Kashmir Weaves Supabase URL/key in this HTML file.
Do not put the Grave Care Supabase URL/key in Kashmir Weaves.
Never expose the Supabase `service_role` key in frontend code.


## Supabase config status

The Grave Care Services Supabase project URL and anon public key have already been added to the live HTML file.

Project URL:

```text
https://oggyndaynrkcwnmxmusp.supabase.co
```

Admin email:

```text
tawfeeqahmadsofi13@gmail.com
```
