# AquaShield Waterproofing Platform: two sites + one secure backend

```
wp-platform/
  apps/web/            Customer + partner site (static, no build step)  -> Vercel project #1
  apps/admin/          Admin panel (separate static app, noindex)       -> Vercel project #2
  supabase/schema.sql  Database, security rules, business rules          -> run once in Supabase
  supabase/demo_data.sql  Optional demo technicians and leads
  supabase/reset.sql   Only if you must start over (deletes data)
```
Both sites talk to the same Supabase project. **Security is enforced by the database** (Row Level Security, triggers and SQL functions), so customers and partners can never read admin data, even if someone edits the page in their browser. The web site contains no admin code, no admin links and no admin routes.

## What is included
**Web (customers and partners):** home, services (prices come from the rate card), partner program, book inspection with photo upload, customer sign up / login, customer dashboard (timeline, inspection report, quotation approve/decline, payments, GST invoice, progress photos, warranty certificate, complaints, feedback), partner apply / login / dashboard (referral link, lead form with duplicate protection, leads, commission statement, payouts, support tickets, training), Hindi / English toggle. Header: logo, Book Inspection, Login dropdown (Customer / Partner), Sign Up, menu (Home, Services, Partner Program, Contact); on phones Login and Sign Up move into the menu.

**Admin:** dashboard, lead CRM (search, filters, all statuses with warnings and a required reason), technicians, inspection reports, quotation builder (editable rate card, line items, GST, revisions), payments (advance / final / refund), work orders, progress photos, QC checklist, printable GST invoice, partner approval and KYC, commission ledger and payouts, warranty and complaints, feedback approval, reports with CSV export, expenses, cities with rate overrides, WhatsApp message links, admin guide.

**Rules in the database:** Paid needs the full payment recorded; Warranty Active only after Paid; final payment only after Completed; commission is created only after Paid (Referral 5% with Rs. 10,000 minimum project, Authorized 8%, Area 10%, job payout 25%, Area territory override 3%); **no commission for recruiting partners**; refunds reverse commissions; a partner owns a lead for 90 days (duplicates are rejected and shown to admin only); users can never change their own role; only the last 4 characters of PAN/Aadhaar are stored; photos and KYC are in private storage buckets served with short-lived signed links.

## Step by step (0 to 100)

### 1. Install the tools (once)
1. Install **Git**: https://git-scm.com/downloads
2. Install **VS Code**: https://code.visualstudio.com
3. Install **Node.js (LTS)**: https://nodejs.org (only needed to test locally with `npx serve`).
4. Create free accounts on **GitHub**, **Supabase** and **Vercel**.

### 2. Open the project
Unzip `wp-platform.zip`, open the `wp-platform` folder in VS Code (File > Open Folder).

### 3. Create the Supabase project
1. In Supabase click **New project**, choose a name, a strong database password and the region nearest to you.
2. Wait until it is ready.
3. Go to **SQL Editor > New query**, open `supabase/schema.sql` in VS Code, copy everything, paste it in the editor and click **Run**. It must finish with "Success". (If you ran an older version of this file earlier, run `supabase/reset.sql` first.)
4. Optional: run `supabase/demo_data.sql` the same way to get demo technicians and leads.

### 4. Demo settings in Supabase
1. **Authentication > Providers > Email**: switch **off** "Confirm email" (demo only; for real use keep it on and set up SMTP).
2. **Authentication > URL Configuration**: set Site URL to your web address later (step 8); for local tests add `http://localhost:3000` and `http://localhost:3001` under Redirect URLs.

### 5. Paste your keys into BOTH config files
In Supabase open **Project Settings > API**. Copy the **Project URL** and the **anon public** key. Paste them into:
- `apps/web/config.js`
- `apps/admin/config.js`

Also set `WEB_URL` in `apps/admin/config.js` to the address of the web site (used for partner referral links; you can set it after step 8). **Never put the `service_role` key anywhere in this project.**

### 6. Create the admin user
1. In Supabase: **Authentication > Users > Add user > Create new user**. Enter an email and a strong password and tick "Auto Confirm User".
2. Open **SQL Editor** and run this line with that email (the **owner only** can do this; there is no way to become admin from the website):
```sql
update profiles set role='admin' where id=(select id from auth.users where email='YOUR-ADMIN-EMAIL');
```

### 7. Test locally
Open two terminals in the project folder:
```
npx serve apps/web -l 3000
npx serve apps/admin -l 3001
```
Open http://localhost:3000 (customer site) and http://localhost:3001 (admin). Sign in to the admin with the user from step 6.

### 8. Put the code on GitHub
Create an empty repository on GitHub (no README), then in the project folder:
```
git init
git add .
git commit -m "AquaShield platform"
git branch -M main
git remote add origin https://github.com/YOUR-NAME/YOUR-REPO.git
git push -u origin main
```

### 9. Deploy on Vercel (the same repo twice)
1. Vercel > **Add New > Project** > import your GitHub repo. Set **Root Directory** to `apps/web`, **Framework Preset** to **Other**, leave the build command and output directory empty, then **Deploy**.
2. Repeat: **Add New > Project** > import the **same repo** again, Root Directory `apps/admin`, Framework **Other**, **Deploy**.
3. You now have two URLs, for example `aquashield.vercel.app` (customers and partners) and `aquashield-admin.vercel.app` (admin). Keep the admin URL private.
4. Put the web URL into `WEB_URL` in `apps/admin/config.js`, commit and push (`git add . && git commit -m "web url" && git push`); Vercel redeploys automatically.

### 10. Supabase Auth URLs
**Authentication > URL Configuration**: Site URL = your web URL; add both Vercel URLs (and the localhost ones) to **Redirect URLs**.

### 11. Final test checklist
- [ ] Web: book an inspection with a photo; you get a Lead ID.
- [ ] Web: sign up as a customer, log in, claim the lead with Lead ID + mobile (Add a request earlier).
- [ ] Admin: log in; the lead appears; assign a technician, save an inspection, create a quotation.
- [ ] Customer: approve the quotation; admin records the advance, creates a work order, posts progress with a photo, passes QC, records the final payment.
- [ ] Customer: sees the invoice, warranty certificate, progress photos; can raise a complaint and leave feedback.
- [ ] Partner: apply at Partner Program > Apply; admin verifies KYC and approves; partner logs in with Partner Login, sees the referral link, submits a lead; after the lead is Paid a commission appears and admin can mark it paid.
- [ ] Wrong role: a partner account on Customer Login, a customer on Partner Login, and a normal user on the admin site are all refused.
- [ ] Edit a price in Admin > Settings; open a new quotation and confirm the new rate is used and totals match everywhere.

## Security notes
- The anon key is public by design. All protection is Row Level Security; every table has RLS enabled and users have no direct write access except where a policy allows it.
- Never commit secrets. `.gitignore` excludes `.env` files. Never use the `service_role` key in a browser app.
- Roles: `customer`, `partner`, `admin`. The role column cannot be edited by users; admin is granted only by the SQL in step 6.
- Customers see only their own leads, quotes, payments, invoices, warranties and complaints; partners see only their own leads and commissions.
- Photos and KYC files are private; links are signed and expire after an hour. Do not upload ID documents with visible full numbers (mask all but the last 4 digits).
- Both apps send `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY` and a strict `Referrer-Policy`; the admin app also sends `X-Robots-Tag: noindex`.

## Known limitations
- Passwords/email login only (no mobile OTP). Customers who booked without an account claim a lead with Lead ID + mobile.
- No payment gateway: payments are recorded manually; WhatsApp messages are links you tap (no automatic sending).
- Email confirmation and password reset emails need Supabase email/SMTP set up for production.
- The admin app loads up to 5,000 rows per table at once; very large data needs paging and server-side filters.
- Public booking has no CAPTCHA or rate limit yet; add one (Supabase Edge Function or Cloudflare Turnstile) before a public launch.
- Hindi covers labels only. Terms, warranty text, prices and rates are DEMO values. Not legal or tax advice; have the agreement and GST invoice format reviewed.
- The web and admin apps load `@supabase/supabase-js` 2.45.4 from esm.sh at run time; self-host it if you need a stricter policy.
