# CSDP Tracker

A shared tracker for schools, tasks, the yearly checklist, email follow-ups, and issues & concerns.

## One-time setup (already done if you're reading this after initial setup)
1. Supabase project created, `supabase/schema.sql` and `supabase/seed.sql` run — see those files.
2. `config.js` filled in with your Supabase Project URL and anon key.
3. Deployed on Cloudflare Pages, connected to this repo — pushes to `main` auto-deploy.

## Team password
Set in `supabase/schema.sql`'s RLS policies. To change it, update the policy in Supabase's SQL editor (no app code change needed) and tell the team the new password.
