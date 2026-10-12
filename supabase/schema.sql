-- ============================================================================
-- AquaShield Waterproofing Platform - run this WHOLE file once in
-- Supabase > SQL Editor (new project). Security is enforced here, not in the browser.
-- If you ran an older version of this file first, run supabase/reset.sql before this.
-- ============================================================================

-- ---------- sequences (human friendly IDs) ----------
create sequence lead_seq; create sequence quote_seq; create sequence receipt_seq; create sequence invoice_seq;
create sequence partner_seq; create sequence commission_seq; create sequence warranty_seq; create sequence complaint_seq;
create sequence ticket_seq; create sequence tech_seq;

-- ---------- tables ----------
create table profiles(id uuid primary key references auth.users on delete cascade, name text, mobile text, city text,
  role text not null default 'customer' check(role in('customer','partner','admin')), created_at timestamptz default now());
create table settings(key text primary key, value jsonb not null);
create table rate_card(key text primary key, name text not null, rate numeric check(rate>=0), unit text default 'sq ft',
  warranty_years int default 3 check(warranty_years between 1 and 15), sort int default 0);
create table cities(name text primary key, active boolean not null default false, rates jsonb not null default '{}');
create table technicians(id uuid primary key default gen_random_uuid(), code text unique default ('WP-T-'||lpad(nextval('tech_seq')::text,3,'0')),
  name text not null, mobile text, city text, areas text, active boolean not null default true);
create table partners(id uuid primary key default gen_random_uuid(), user_id uuid unique references auth.users on delete cascade,
  code text unique, tier text not null check(tier in('referral','authorized','area')), name text not null, mobile text, email text, city text,
  id_last4 text check(id_last4 ~ '^[A-Za-z0-9]{4}$'), kyc_note text, kyc_doc text, kyc_status text not null default 'pending' check(kyc_status in('pending','verified','rejected')),
  status text not null default 'pending' check(status in('pending','approved','rejected')), reject_reason text,
  agreement_at timestamptz, fee_status text not null default 'not_applicable' check(fee_status in('not_applicable','due','paid')),
  pincodes text[] not null default '{}', created_at timestamptz default now(), approved_at timestamptz);
create table leads(id uuid primary key default gen_random_uuid(), code text unique default ('WP-L-'||lpad(nextval('lead_seq')::text,4,'0')),
  customer_id uuid references auth.users on delete set null, partner_id uuid references partners, job_partner_id uuid references partners,
  technician_id uuid references technicians, inspection_at timestamptz, follow_up_at date, follow_up_note text,
  name text not null, mobile text not null check(mobile ~ '^[0-9]{10}$'), city text, pincode text, address text, service text not null,
  leakage_type text, property_type text, preferred_date date, photos text[] not null default '{}', source text not null default 'direct',
  status text not null default 'new' check(status in('new','assigned','inspected','quoted','follow_up','approved','in_progress','completed','paid','warranty_active','lost')),
  lost_reason text, quote_total numeric not null default 0, created_at timestamptz default now());
create table lead_log(id bigserial primary key, lead_id uuid not null references leads on delete cascade, by_user uuid, kind text not null default 'status',
  from_status text, to_status text, note text, at timestamptz default now());
create table inspections(lead_id uuid primary key references leads on delete cascade, findings text, area_sqft numeric, recommended_service text,
  photos text[] not null default '{}', technician_id uuid, at timestamptz default now());
create table quotes(id uuid primary key default gen_random_uuid(), code text unique default ('WP-Q-'||lpad(nextval('quote_seq')::text,4,'0')),
  lead_id uuid not null unique references leads on delete cascade, items jsonb not null, subtotal numeric not null, discount numeric not null default 0,
  taxable numeric not null, gst_pct numeric not null, gst numeric not null, total numeric not null check(total>0), adv_pct numeric not null,
  valid_until date not null, treatment_plan text, warranty_years int not null default 3,
  status text not null default 'sent' check(status in('sent','approved','declined')), rev int not null default 1,
  created_at timestamptz default now(), updated_at timestamptz default now());
create table quote_revisions(id bigserial primary key, quote_id uuid references quotes on delete cascade, rev int, snapshot jsonb, reason text, by_user uuid, at timestamptz default now());
create table payments(id uuid primary key default gen_random_uuid(), receipt_no text unique default ('WP-R-'||lpad(nextval('receipt_seq')::text,4,'0')),
  lead_id uuid not null references leads on delete cascade, type text not null check(type in('advance','final','refund')),
  amount numeric not null check(amount>0), mode text, ref text, paid_on date not null default current_date, at timestamptz default now());
create table invoices(no text primary key default ('WP-INV-'||to_char(now(),'YYYY')||'-'||lpad(nextval('invoice_seq')::text,4,'0')),
  lead_id uuid not null unique references leads on delete cascade, items jsonb, subtotal numeric, discount numeric, taxable numeric, gst_pct numeric, gst numeric,
  total numeric, receipts jsonb, issued_at timestamptz default now());
create table work_orders(lead_id uuid primary key references leads on delete cascade, start_date date, crew uuid[] not null default '{}',
  materials jsonb not null default '[]', labour_days int, qc jsonb, completed_at timestamptz);
create table progress_updates(id uuid primary key default gen_random_uuid(), lead_id uuid not null references leads on delete cascade, note text not null,
  photos text[] not null default '{}', by_user uuid, at timestamptz default now());
create table warranties(id uuid primary key default gen_random_uuid(), code text unique default ('WP-W-'||lpad(nextval('warranty_seq')::text,4,'0')),
  lead_id uuid not null unique references leads on delete cascade, service text, years int not null, start_date date not null, end_date date not null, issued_at timestamptz default now());
create table complaints(id uuid primary key default gen_random_uuid(), code text unique default ('WP-CP-'||lpad(nextval('complaint_seq')::text,4,'0')),
  lead_id uuid not null references leads on delete cascade, customer_id uuid, warranty_id uuid references warranties, issue text not null,
  photos text[] not null default '{}', status text not null default 'open' check(status in('open','re_inspection','resolved')),
  log jsonb not null default '[]', created_at timestamptz default now());
create table feedback(lead_id uuid primary key references leads on delete cascade, customer_id uuid, by_name text, rating int not null check(rating between 1 and 5),
  text text, status text not null default 'pending' check(status in('pending','approved','hidden')), demo boolean not null default false, created_at timestamptz default now());
-- Commission types are ONLY referral / job / override. There is deliberately NO type for recruiting or adding partners,
-- and no multi-level payout: a commission always belongs to a customer lead.
create table commissions(id uuid primary key default gen_random_uuid(), code text unique default ('WP-C-'||lpad(nextval('commission_seq')::text,4,'0')),
  partner_id uuid not null references partners, lead_id uuid not null references leads on delete cascade, type text not null check(type in('referral','job','override')),
  base numeric not null, pct numeric not null, amount numeric not null, status text not null default 'approved' check(status in('approved','paid','reversed')),
  payout_ref text, paid_at timestamptz, approved_at timestamptz default now(), note text, clawback boolean not null default false, unique(lead_id,type,partner_id));
create table tickets(id uuid primary key default gen_random_uuid(), code text unique default ('WP-S-'||lpad(nextval('ticket_seq')::text,4,'0')),
  partner_id uuid not null references partners, lead_code text, issue text not null, status text not null default 'open' check(status in('open','in_progress','resolved')),
  log jsonb not null default '[]', created_at timestamptz default now());
create table expenses(id uuid primary key default gen_random_uuid(), on_date date not null default current_date, category text, amount numeric not null check(amount>0), note text, created_at timestamptz default now());
create table duplicate_attempts(id uuid primary key default gen_random_uuid(), partner_id uuid, mobile text, address text, name text, original_lead_code text, at timestamptz default now());

-- ---------- helper functions ----------
create function is_admin() returns boolean language sql security definer stable set search_path=public as
$$ select exists(select 1 from profiles where id=auth.uid() and role='admin') $$;
create function owns_lead(l uuid) returns boolean language sql security definer stable set search_path=public as
$$ select exists(select 1 from leads where id=l and customer_id=auth.uid()) $$;
create function status_idx(s text) returns int language sql immutable as
$$ select array_position(array['new','assigned','inspected','quoted','follow_up','approved','in_progress','completed','paid','warranty_active','lost'],s) $$;
create function setting_num(k text, d numeric) returns numeric language sql stable security definer set search_path=public as
$$ select coalesce((select (value #>> '{}')::numeric from settings where key=k),d) $$;
create function admin_only() returns void language plpgsql stable security definer set search_path=public as
$$ begin if not is_admin() then raise exception 'Admins only'; end if; end $$;

create function handle_new_user() returns trigger language plpgsql security definer set search_path=public as
$$ begin insert into profiles(id,name,mobile,city) values(new.id,left(new.raw_user_meta_data->>'name',80),
  case when new.raw_user_meta_data->>'mobile' ~ '^[0-9]{10}$' then new.raw_user_meta_data->>'mobile' end,left(new.raw_user_meta_data->>'city',60))
  on conflict do nothing; return new; end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function handle_new_user();

-- ---------- lead status rules ----------
create function lead_before() returns trigger language plpgsql security definer set search_path=public as $$
declare note text := nullif(current_setting('wp.note',true),''); paid numeric; qt numeric;
begin
  if new.status is distinct from old.status then
    if new.status='warranty_active' and old.status<>'paid' then raise exception 'Warranty Active is only allowed after the lead is Paid'; end if;
    if new.status='paid' then
      select total into qt from quotes where lead_id=new.id;
      select coalesce(sum(case when type='refund' then -amount else amount end),0) into paid from payments where lead_id=new.id;
      if qt is null or paid<qt or not exists(select 1 from payments where lead_id=new.id and type='final')
        then raise exception 'Record the full payment (advance and final) before marking Paid'; end if;
    end if;
    if new.status='lost' then
      if coalesce(note,new.lost_reason,'')='' then raise exception 'A reason is required for Lost'; end if;
      new.lost_reason := coalesce(note,new.lost_reason);
    elsif old.status='lost' then new.lost_reason := null; end if;
    insert into lead_log(lead_id,by_user,from_status,to_status,note) values(new.id,auth.uid(),old.status,new.status,note);
  end if;
  return new;
end $$;
create trigger lead_before before update on leads for each row execute function lead_before();

create function finish_paid(p_lead uuid) returns void language plpgsql security definer set search_path=public as $$
declare L leads%rowtype; q quotes%rowtype; fin payments%rowtype; pt partners%rowtype; pc numeric;
begin
  select * into L from leads where id=p_lead; select * into q from quotes where lead_id=p_lead;
  select * into fin from payments where lead_id=p_lead and type='final' order by at desc limit 1;
  if not exists(select 1 from invoices where lead_id=p_lead) then
    insert into invoices(lead_id,items,subtotal,discount,taxable,gst_pct,gst,total,receipts)
    values(p_lead,q.items,q.subtotal,q.discount,q.taxable,q.gst_pct,q.gst,q.total,
      (select coalesce(jsonb_agg(jsonb_build_object('receiptNo',receipt_no,'type',type,'amount',amount) order by at),'[]'::jsonb) from payments where lead_id=p_lead));
  end if;
  if not exists(select 1 from warranties where lead_id=p_lead) then
    insert into warranties(lead_id,service,years,start_date,end_date)
    values(p_lead,L.service,q.warranty_years,fin.paid_on,(fin.paid_on+make_interval(years=>q.warranty_years))::date);
  end if;
  -- commissions: created only now (lead is Paid), on net project value (excluding GST)
  if L.partner_id is not null then
    select * into pt from partners where id=L.partner_id and status='approved';
    if found then
      pc := case pt.tier when 'referral' then 5 when 'authorized' then 8 else 10 end;
      if not (pt.tier='referral' and q.taxable<10000) then   -- Referral tier needs a project of Rs. 10,000 or more
        insert into commissions(partner_id,lead_id,type,base,pct,amount) values(pt.id,p_lead,'referral',q.taxable,pc,round(q.taxable*pc/100,2)) on conflict do nothing;
      end if;
    end if;
  else  -- company generated lead: Area Partner territory override 3%
    select * into pt from partners where status='approved' and tier='area' and L.pincode=any(pincodes) order by created_at limit 1;
    if found then insert into commissions(partner_id,lead_id,type,base,pct,amount) values(pt.id,p_lead,'override',q.taxable,3,round(q.taxable*3/100,2)) on conflict do nothing; end if;
  end if;
  if L.job_partner_id is not null then   -- job payout 25% for Authorized / Area partners assigned the job
    select * into pt from partners where id=L.job_partner_id and status='approved' and tier in('authorized','area');
    if found then insert into commissions(partner_id,lead_id,type,base,pct,amount) values(pt.id,p_lead,'job',q.taxable,25,round(q.taxable*25/100,2)) on conflict do nothing; end if;
  end if;
  perform set_config('wp.note','Warranty issued',true);
  update leads set status='warranty_active' where id=p_lead and status='paid';
end $$;

create function lead_after() returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.status is distinct from old.status then
    if new.status='approved' then update quotes set status='approved',updated_at=now() where lead_id=new.id and status<>'approved';
    elsif new.status<>'lost' and status_idx(new.status)<status_idx('approved') and status_idx(old.status)>=status_idx('approved')
      then update quotes set status='sent',updated_at=now() where lead_id=new.id and status='approved'; end if;
    if new.status='paid' then perform finish_paid(new.id); end if;
  end if;
  return null;
end $$;
create trigger lead_after after update on leads for each row execute function lead_after();

-- refund: reverse the commissions of that lead
create function payment_after() returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.type='refund' then
    update commissions set clawback=(status='paid'), status='reversed', note='Refund '||new.receipt_no where lead_id=new.lead_id and status<>'reversed';
  end if; return null;
end $$;
create trigger payment_after after insert on payments for each row execute function payment_after();

-- ---------- public / customer / partner functions ----------
create function submit_lead(p jsonb) returns text language plpgsql security definer set search_path=public as $$
declare pid uuid; src text:='direct'; self boolean:=false; c text; addr text; orig text; ph text[]:='{}'; x text;
begin
  if length(coalesce(p->>'name',''))<2 or (p->>'mobile') !~ '^[0-9]{10}$' or coalesce(p->>'pincode','') !~ '^[0-9]{6}$' or length(coalesce(p->>'address',''))<5
     or not exists(select 1 from rate_card where key=p->>'service') or coalesce(p->>'consent','')<>'true'
     then raise exception 'Please check the form: name, 10-digit mobile, 6-digit pincode, address, service and consent are required'; end if;
  if auth.uid() is not null then select id into pid from partners where user_id=auth.uid() and status='approved'; self := pid is not null; end if;
  if pid is null and nullif(p->>'ref','') is not null then select id into pid from partners where status='approved' and code=upper(p->>'ref'); end if;
  addr := regexp_replace(lower(coalesce(p->>'address','')),'[^a-z0-9]','','g');
  select code into orig from leads where mobile=p->>'mobile' and regexp_replace(lower(coalesce(address,'')),'[^a-z0-9]','','g')=addr
     and created_at>now()-interval '90 days' and (partner_id is not null or self) order by created_at limit 1;
  if orig is not null and self then   -- 90 day ownership: the first partner owns the lead; duplicates are rejected and shown to admin only
    insert into duplicate_attempts(partner_id,mobile,address,name,original_lead_code) values(pid,p->>'mobile',p->>'address',p->>'name',orig);
    return 'DUPLICATE';
  end if;
  if orig is not null then pid := null; end if;   -- someone else already owns this customer
  if pid is not null then src := case when self then 'partner submitted' else 'partner referral' end; end if;
  for x in select jsonb_array_elements_text(coalesce(p->'photos','[]'::jsonb)) loop
    if x like 'inbox/%' and length(x)<200 and array_length(ph,1) is distinct from 4 then ph := ph||x; end if;
  end loop;
  insert into leads(customer_id,partner_id,name,mobile,city,pincode,address,service,leakage_type,property_type,preferred_date,photos,source)
  values(case when self then null else auth.uid() end,pid,left(p->>'name',80),p->>'mobile',left(p->>'city',60),p->>'pincode',left(p->>'address',300),p->>'service',
    left(p->>'leakage_type',60),left(p->>'property_type',60),nullif(p->>'preferred_date','')::date,ph,src) returning code into c;
  return c;
end $$;

create function claim_lead(p_code text, p_mobile text) returns text language plpgsql security definer set search_path=public as $$
begin
  if auth.uid() is null then raise exception 'Please sign in'; end if;
  update leads set customer_id=auth.uid() where code=upper(trim(p_code)) and mobile=p_mobile and customer_id is null;
  if not found then raise exception 'No unclaimed lead matches that Lead ID and mobile number'; end if;
  return upper(trim(p_code));
end $$;

create function my_timeline(p_lead uuid) returns table(to_status text, at timestamptz) language sql security definer stable set search_path=public as
$$ select to_status,at from lead_log where lead_id=p_lead and kind='status' and (owns_lead(p_lead) or is_admin()) order by id $$;
create function my_technician(p_lead uuid) returns table(name text, mobile text, inspection_at timestamptz) language sql security definer stable set search_path=public as
$$ select t.name,t.mobile,l.inspection_at from leads l join technicians t on t.id=l.technician_id where l.id=p_lead and l.customer_id=auth.uid() $$;

create function customer_respond(p_lead uuid, p_approve boolean) returns void language plpgsql security definer set search_path=public as $$
declare L leads%rowtype; q quotes%rowtype;
begin
  select * into L from leads where id=p_lead and customer_id=auth.uid(); select * into q from quotes where lead_id=p_lead;
  if L.id is null or q.id is null or q.status<>'sent' or L.status not in('quoted','follow_up') then raise exception 'Not allowed'; end if;
  if q.valid_until<current_date then raise exception 'This quotation has expired. Please contact us.'; end if;
  perform set_config('wp.note',case when p_approve then 'Customer approved ' else 'Customer declined ' end||q.code,true);
  if p_approve then update quotes set status='approved',updated_at=now() where id=q.id; update leads set status='approved' where id=L.id;
  else update quotes set status='declined',updated_at=now() where id=q.id; update leads set status='follow_up',follow_up_at=current_date+1 where id=L.id; end if;
end $$;

create function raise_complaint(p_lead uuid, p_issue text, p_photos text[]) returns text language plpgsql security definer set search_path=public as $$
declare w warranties%rowtype; c text; ph text[]:='{}'; x text;
begin
  select * into w from warranties where lead_id=p_lead and owns_lead(p_lead);
  if w.id is null or w.end_date<current_date then raise exception 'Complaints are only accepted while the warranty is active'; end if;
  if length(coalesce(p_issue,''))<5 then raise exception 'Please describe the problem'; end if;
  foreach x in array coalesce(p_photos,'{}') loop if x like 'complaints/'||auth.uid()::text||'/%' and coalesce(array_length(ph,1),0)<3 then ph:=ph||x; end if; end loop;
  insert into complaints(lead_id,customer_id,warranty_id,issue,photos,log) values(p_lead,auth.uid(),w.id,left(p_issue,1000),ph,
    jsonb_build_array(jsonb_build_object('at',now(),'to','open','note','Complaint raised'))) returning code into c;
  return c;
end $$;

create function submit_feedback(p_lead uuid, p_rating int, p_text text) returns void language plpgsql security definer set search_path=public as $$
declare L leads%rowtype;
begin
  select * into L from leads where id=p_lead and customer_id=auth.uid();
  if L.id is null or L.status not in('paid','warranty_active') then raise exception 'Feedback opens after payment'; end if;
  insert into feedback(lead_id,customer_id,by_name,rating,text) values(p_lead,auth.uid(),split_part(L.name,' ',1)||', '||coalesce(L.city,''),p_rating,left(coalesce(nullif(trim(p_text),''),'(no comment)'),500));
end $$;

create function apply_partner(p jsonb) returns text language plpgsql security definer set search_path=public as $$
declare ex partners%rowtype; k text:=coalesce(p->>'kyc_note',''); v_id uuid; fee text;
begin
  if auth.uid() is null then raise exception 'Please sign in first'; end if;
  if p->>'tier' not in('referral','authorized','area') or length(coalesce(p->>'name',''))<2 or (p->>'mobile') !~ '^[0-9]{10}$'
     or (p->>'email') !~ '^\S+@\S+\.\S+$' or (p->>'id_last4') !~ '^[A-Za-z0-9]{4}$' or coalesce(p->>'agree','')<>'true'
     then raise exception 'Please check the form (name, mobile, email, last 4 characters of PAN/Aadhaar, agreement)'; end if;
  if k ~ '[0-9]{9,}' or k ~* '[A-Z]{5}[0-9]{4}[A-Z]' then raise exception 'Do not enter full PAN, Aadhaar or bank numbers. Only the last 4 characters are stored.'; end if;
  if nullif(p->>'kyc_doc','') is not null and (p->>'kyc_doc') not like auth.uid()::text||'/%' then raise exception 'Invalid document path'; end if;
  fee := case when p->>'tier'='referral' then 'not_applicable' else 'due' end;
  select * into ex from partners where user_id=auth.uid();
  if ex.id is not null and ex.status<>'rejected' then raise exception 'You already have a partner application'; end if;
  if ex.id is not null then
    update partners set tier=p->>'tier',name=p->>'name',mobile=p->>'mobile',email=p->>'email',city=p->>'city',id_last4=upper(p->>'id_last4'),kyc_note=left(k,300),
      kyc_doc=nullif(p->>'kyc_doc',''),kyc_status='pending',status='pending',reject_reason=null,agreement_at=now(),fee_status=fee where id=ex.id returning id into v_id;
  else
    insert into partners(user_id,tier,name,mobile,email,city,id_last4,kyc_note,kyc_doc,agreement_at,fee_status)
    values(auth.uid(),p->>'tier',p->>'name',p->>'mobile',p->>'email',p->>'city',upper(p->>'id_last4'),left(k,300),nullif(p->>'kyc_doc',''),now(),fee) returning partners.id into v_id;
  end if;
  return v_id::text;
end $$;

-- ---------- admin functions (each checks is_admin()) ----------
create function admin_set_status(p_lead uuid, p_to text, p_note text) returns void language plpgsql security definer set search_path=public as $$
begin
  perform admin_only();
  perform set_config('wp.note',coalesce(p_note,''),true);
  update leads set status=p_to where id=p_lead;
  if not found then raise exception 'Lead not found'; end if;
end $$;

create function assign_technician(p_lead uuid, p_tech uuid, p_at timestamptz) returns void language plpgsql security definer set search_path=public as $$
declare L leads%rowtype; t technicians%rowtype;
begin
  perform admin_only(); select * into L from leads where id=p_lead; select * into t from technicians where id=p_tech;
  if L.id is null or t.id is null then raise exception 'Lead or technician not found'; end if;
  if p_at is null then raise exception 'Pick the inspection date and time'; end if;
  update leads set technician_id=p_tech,inspection_at=p_at where id=p_lead;
  if L.status in('new','assigned') then perform set_config('wp.note','Technician '||t.name,true); update leads set status='assigned' where id=p_lead; end if;
end $$;

create function save_inspection(p_lead uuid, p_findings text, p_area numeric, p_service text, p_photos text[]) returns void language plpgsql security definer set search_path=public as $$
declare L leads%rowtype;
begin
  perform admin_only(); select * into L from leads where id=p_lead;
  if L.id is null then raise exception 'Lead not found'; end if;
  if length(coalesce(p_findings,''))<3 or coalesce(p_area,0)<=0 then raise exception 'Enter the findings and the area'; end if;
  insert into inspections(lead_id,findings,area_sqft,recommended_service,photos,technician_id) values(p_lead,p_findings,p_area,p_service,coalesce(p_photos,'{}'),L.technician_id)
  on conflict(lead_id) do update set findings=excluded.findings,area_sqft=excluded.area_sqft,recommended_service=excluded.recommended_service,photos=excluded.photos,at=now();
  if L.status='assigned' then perform set_config('wp.note','Inspection report saved',true); update leads set status='inspected' where id=p_lead; end if;
end $$;

create function save_quote(p_lead uuid, p_items jsonb, p_discount numeric, p_years int, p_plan text, p_reason text) returns text language plpgsql security definer set search_path=public as $$
declare L leads%rowtype; q quotes%rowtype; it jsonb; v_items jsonb:='[]'::jsonb; amt numeric; sub numeric:=0; disc numeric; gp numeric; ap numeric; tax numeric; g numeric; tot numeric; v_code text;
begin
  perform admin_only(); select * into L from leads where id=p_lead;
  if L.id is null then raise exception 'Lead not found'; end if;
  if jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items)=0 then raise exception 'Add at least one line'; end if;
  for it in select value from jsonb_array_elements(p_items) loop
    if coalesce((it->>'qty')::numeric,0)<=0 or coalesce((it->>'rate')::numeric,0)<=0 then raise exception 'Every line needs a quantity and a rate above zero'; end if;
    if coalesce((it->>'disc')::numeric,0)<0 or coalesce((it->>'disc')::numeric,0)>(it->>'qty')::numeric*(it->>'rate')::numeric then raise exception 'A line discount cannot exceed the line value'; end if;
    amt := round((it->>'qty')::numeric*(it->>'rate')::numeric-coalesce((it->>'disc')::numeric,0));
    sub := sub+amt; v_items := v_items||jsonb_build_array(it||jsonb_build_object('amount',amt));
  end loop;
  if coalesce(p_discount,0)<0 or coalesce(p_discount,0)>sub then raise exception 'The overall discount cannot exceed the subtotal'; end if;
  if length(coalesce(p_plan,''))<5 or coalesce(p_years,0)<1 then raise exception 'Add a treatment plan and the warranty years'; end if;
  disc := coalesce(p_discount,0); gp := setting_num('gst_pct',18); ap := setting_num('advance_pct',40);
  tax := sub-disc; g := round(tax*gp/100); tot := tax+g;
  select * into q from quotes where lead_id=p_lead;
  if q.id is not null then
    if q.status='approved' then raise exception 'This quote is approved. Use Revise quote first'; end if;
    if length(coalesce(p_reason,''))<2 then raise exception 'Enter the reason for the change'; end if;
    insert into quote_revisions(quote_id,rev,snapshot,reason,by_user) values(q.id,q.rev,to_jsonb(q),p_reason,auth.uid());
    update quotes set items=v_items,subtotal=sub,discount=disc,taxable=tax,gst_pct=gp,gst=g,total=tot,adv_pct=ap,valid_until=current_date+15,treatment_plan=p_plan,
      warranty_years=p_years,status='sent',rev=q.rev+1,updated_at=now() where id=q.id returning code into v_code;
    insert into lead_log(lead_id,by_user,kind,note) values(p_lead,auth.uid(),'quote',v_code||' revised (rev '||(q.rev+1)||'): '||p_reason||', total '||tot);
  else
    insert into quotes(lead_id,items,subtotal,discount,taxable,gst_pct,gst,total,adv_pct,valid_until,treatment_plan,warranty_years)
    values(p_lead,v_items,sub,disc,tax,gp,g,tot,ap,current_date+15,p_plan,p_years) returning code into v_code;
    insert into lead_log(lead_id,by_user,kind,note) values(p_lead,auth.uid(),'quote',v_code||' created, total '||tot);
  end if;
  update leads set quote_total=tot where id=p_lead;
  if L.status='inspected' then perform set_config('wp.note',v_code||' total '||tot,true); update leads set status='quoted' where id=p_lead; end if;
  return v_code;
end $$;

create function revise_quote(p_lead uuid, p_reason text) returns void language plpgsql security definer set search_path=public as $$
declare L leads%rowtype; q quotes%rowtype;
begin
  perform admin_only(); select * into L from leads where id=p_lead; select * into q from quotes where lead_id=p_lead;
  if q.id is null or q.status<>'approved' then raise exception 'Only an approved quote can be revised'; end if;
  if L.status<>'approved' then raise exception 'The quote is locked because work has started'; end if;
  if length(coalesce(p_reason,''))<2 then raise exception 'Enter the reason for revising the quote'; end if;
  insert into quote_revisions(quote_id,rev,snapshot,reason,by_user) values(q.id,q.rev,to_jsonb(q),'Revision requested: '||p_reason,auth.uid());
  perform set_config('wp.note','Quote revision requested: '||p_reason,true);
  update leads set status='quoted' where id=p_lead;
  update quotes set status='sent',updated_at=now() where id=q.id;
end $$;

create function record_payment(p_lead uuid, p_type text, p_amount numeric, p_mode text, p_ref text, p_date date) returns text language plpgsql security definer set search_path=public as $$
declare L leads%rowtype; q quotes%rowtype; adv numeric; due numeric; rn text;
begin
  perform admin_only(); select * into L from leads where id=p_lead; select * into q from quotes where lead_id=p_lead;
  if L.id is null or q.id is null then raise exception 'A quotation is required before payments'; end if;
  if L.status='lost' or status_idx(L.status)<status_idx('approved') then raise exception 'The quotation must be approved first'; end if;
  select coalesce(sum(amount),0) into adv from payments where lead_id=p_lead and type='advance';
  if p_type='advance' then
    if adv>0 then raise exception 'The advance is already recorded'; end if; due := round(q.total*q.adv_pct/100);
  elsif p_type='final' then
    if L.status<>'completed' then raise exception 'Final payment can only be recorded after the job is Completed'; end if;
    if adv=0 then raise exception 'Record the advance first'; end if;
    if exists(select 1 from payments where lead_id=p_lead and type='final') then raise exception 'The final payment is already recorded'; end if;
    due := q.total-adv;
  else raise exception 'Use Refund for refunds'; end if;
  if p_amount is distinct from due then raise exception 'Amount must equal the due amount %', due; end if;
  insert into payments(lead_id,type,amount,mode,ref,paid_on) values(p_lead,p_type,p_amount,p_mode,left(p_ref,80),coalesce(p_date,current_date)) returning receipt_no into rn;
  if p_type='final' then perform set_config('wp.note','Final payment '||rn,true); update leads set status='paid' where id=p_lead; end if;
  return rn;
end $$;

create function record_refund(p_lead uuid, p_amount numeric, p_reason text) returns text language plpgsql security definer set search_path=public as $$
declare net numeric; rn text;
begin
  perform admin_only();
  select coalesce(sum(case when type='refund' then -amount else amount end),0) into net from payments where lead_id=p_lead;
  if p_amount<=0 or p_amount>net then raise exception 'Refund must be between 1 and %', net; end if;
  if length(coalesce(p_reason,''))<2 then raise exception 'Enter a reason for the refund'; end if;
  insert into payments(lead_id,type,amount,mode,ref) values(p_lead,'refund',p_amount,'Bank transfer',left(p_reason,80)) returning receipt_no into rn;
  insert into lead_log(lead_id,by_user,kind,note) values(p_lead,auth.uid(),'refund','Refund '||p_amount||' ('||rn||'): '||p_reason||'. Commissions reversed.');
  return rn;
end $$;

create function save_work_order(p_lead uuid, p_start date, p_crew uuid[], p_materials jsonb, p_labour int) returns void language plpgsql security definer set search_path=public as $$
declare L leads%rowtype;
begin
  perform admin_only(); select * into L from leads where id=p_lead;
  if L.id is null then raise exception 'Lead not found'; end if;
  if p_start is null or coalesce(array_length(p_crew,1),0)=0 or coalesce(p_labour,0)<1 then raise exception 'Enter the start date, crew and labour days'; end if;
  if L.status='approved' and not exists(select 1 from payments where lead_id=p_lead and type='advance') then raise exception 'Record the advance payment before starting work'; end if;
  insert into work_orders(lead_id,start_date,crew,materials,labour_days) values(p_lead,p_start,p_crew,coalesce(p_materials,'[]'::jsonb),p_labour)
  on conflict(lead_id) do update set start_date=excluded.start_date,crew=excluded.crew,materials=excluded.materials,labour_days=excluded.labour_days;
  if L.status='approved' then perform set_config('wp.note','Work order created',true); update leads set status='in_progress' where id=p_lead; end if;
end $$;

create function add_progress(p_lead uuid, p_note text, p_photos text[]) returns void language plpgsql security definer set search_path=public as $$
begin
  perform admin_only();
  if length(coalesce(p_note,''))<3 then raise exception 'Write a short progress note'; end if;
  insert into progress_updates(lead_id,note,photos,by_user) values(p_lead,p_note,coalesce(p_photos,'{}'),auth.uid());
end $$;

create function complete_qc(p_lead uuid, p_qc jsonb) returns void language plpgsql security definer set search_path=public as $$
declare L leads%rowtype;
begin
  perform admin_only(); select * into L from leads where id=p_lead;
  if L.status<>'in_progress' then raise exception 'The job must be In Progress'; end if;
  if not ((p_qc->>'water')::boolean and (p_qc->>'finish')::boolean and (p_qc->>'cleanup')::boolean and (p_qc->>'signoff')::boolean)
    then raise exception 'All four checklist items must pass'; end if;
  if length(coalesce(p_qc->>'by',''))<2 or length(coalesce(p_qc->>'customer',''))<2 then raise exception 'Enter the supervisor and customer names'; end if;
  update work_orders set qc=p_qc||jsonb_build_object('at',now()),completed_at=now() where lead_id=p_lead;
  if not found then raise exception 'Create the work order first'; end if;
  perform set_config('wp.note','Quality check passed',true); update leads set status='completed' where id=p_lead;
end $$;

create function review_partner(p_id uuid, p_approve boolean, p_reason text) returns void language plpgsql security definer set search_path=public as $$
declare P partners%rowtype;
begin
  perform admin_only(); select * into P from partners where id=p_id;
  if P.id is null then raise exception 'Application not found'; end if;
  if p_approve then
    if P.kyc_status<>'verified' then raise exception 'Verify KYC before approving'; end if;
    update partners set status='approved',approved_at=now(),reject_reason=null,code=coalesce(code,'WP-P-'||lpad(nextval('partner_seq')::text,3,'0')) where id=p_id;
    update profiles set role='partner' where id=P.user_id and role='customer';
  else
    if length(coalesce(p_reason,''))<2 then raise exception 'A reason is required'; end if;
    update partners set status='rejected',reject_reason=p_reason where id=p_id;
  end if;
end $$;

create function pay_commission(p_id uuid, p_ref text, p_date date) returns void language plpgsql security definer set search_path=public as $$
begin
  perform admin_only();
  if length(coalesce(p_ref,''))<2 then raise exception 'Enter the payout reference'; end if;
  update commissions set status='paid',payout_ref=left(p_ref,80),paid_at=coalesce(p_date,current_date) where id=p_id and status='approved';
  if not found then raise exception 'Only an approved commission can be paid'; end if;
end $$;

create function update_complaint(p_id uuid, p_to text, p_note text) returns void language plpgsql security definer set search_path=public as $$
declare c complaints%rowtype;
begin
  perform admin_only(); select * into c from complaints where id=p_id;
  if p_to not in('re_inspection','resolved') or not ((c.status='open' and p_to='re_inspection') or (c.status='re_inspection' and p_to='resolved'))
    then raise exception 'Invalid move'; end if;
  if p_to='resolved' and length(coalesce(p_note,''))<2 then raise exception 'A resolution note is required'; end if;
  update complaints set status=p_to,log=log||jsonb_build_array(jsonb_build_object('at',now(),'from',c.status,'to',p_to,'note',coalesce(p_note,''),'by',auth.uid())) where id=p_id;
end $$;

create function update_ticket(p_id uuid, p_to text) returns void language plpgsql security definer set search_path=public as $$
begin
  perform admin_only();
  update tickets set status=p_to,log=log||jsonb_build_array(jsonb_build_object('at',now(),'by',auth.uid(),'note','Status '||p_to)) where id=p_id;
end $$;

-- ---------- Row Level Security ----------
do $$ declare r record; begin
  for r in select tablename from pg_tables where schemaname='public' loop execute format('alter table %I enable row level security',r.tablename); end loop;
end $$;

revoke all on all tables in schema public from anon, authenticated;
revoke all on all functions in schema public from public, anon, authenticated;
grant usage on schema public to anon, authenticated;
grant select on rate_card, cities, settings, feedback to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;
-- users can never change their own role or id
revoke update on profiles from authenticated; grant update(name,mobile,city) on profiles to authenticated;
grant execute on function is_admin(), owns_lead(uuid), status_idx(text), submit_lead(jsonb) to anon, authenticated;
grant execute on function claim_lead(text,text), my_timeline(uuid), my_technician(uuid), customer_respond(uuid,boolean), raise_complaint(uuid,text,text[]),
  submit_feedback(uuid,int,text), apply_partner(jsonb), admin_set_status(uuid,text,text), assign_technician(uuid,uuid,timestamptz),
  save_inspection(uuid,text,numeric,text,text[]), save_quote(uuid,jsonb,numeric,int,text,text), revise_quote(uuid,text), record_payment(uuid,text,numeric,text,text,date),
  record_refund(uuid,numeric,text), save_work_order(uuid,date,uuid[],jsonb,int), add_progress(uuid,text,text[]), complete_qc(uuid,jsonb), review_partner(uuid,boolean,text),
  pay_commission(uuid,text,date), update_complaint(uuid,text,text), update_ticket(uuid,text) to authenticated;

create policy pr_sel on profiles for select using(id=auth.uid() or is_admin());
create policy pr_upd on profiles for update using(id=auth.uid()) with check(id=auth.uid());
create policy set_sel on settings for select using(true);   create policy set_all on settings for all using(is_admin()) with check(is_admin());
create policy rc_sel on rate_card for select using(true);   create policy rc_all on rate_card for all using(is_admin()) with check(is_admin());
create policy ci_sel on cities for select using(true);      create policy ci_all on cities for all using(is_admin()) with check(is_admin());
create policy te_all on technicians for all using(is_admin()) with check(is_admin());
create policy pa_sel on partners for select using(user_id=auth.uid() or is_admin());
create policy pa_upd on partners for update using(is_admin()) with check(is_admin());
create policy pa_del on partners for delete using(is_admin());
create policy le_sel on leads for select using(customer_id=auth.uid() or is_admin() or partner_id in(select id from partners where user_id=auth.uid()));
create policy le_upd on leads for update using(is_admin()) with check(is_admin());
create policy le_del on leads for delete using(is_admin());
create policy lg_sel on lead_log for select using(is_admin());   create policy lg_ins on lead_log for insert with check(is_admin());
create policy in_sel on inspections for select using(owns_lead(lead_id) or is_admin()); create policy in_all on inspections for all using(is_admin()) with check(is_admin());
create policy qu_sel on quotes for select using(owns_lead(lead_id) or is_admin()); create policy qu_all on quotes for all using(is_admin()) with check(is_admin());
create policy qr_all on quote_revisions for all using(is_admin()) with check(is_admin());
create policy pm_sel on payments for select using(owns_lead(lead_id) or is_admin()); create policy pm_all on payments for all using(is_admin()) with check(is_admin());
create policy iv_sel on invoices for select using(owns_lead(lead_id) or is_admin()); create policy iv_all on invoices for all using(is_admin()) with check(is_admin());
create policy wo_sel on work_orders for select using(owns_lead(lead_id) or is_admin()); create policy wo_all on work_orders for all using(is_admin()) with check(is_admin());
create policy pu_sel on progress_updates for select using(owns_lead(lead_id) or is_admin()); create policy pu_all on progress_updates for all using(is_admin()) with check(is_admin());
create policy wa_sel on warranties for select using(owns_lead(lead_id) or is_admin()); create policy wa_all on warranties for all using(is_admin()) with check(is_admin());
create policy cp_sel on complaints for select using(customer_id=auth.uid() or is_admin()); create policy cp_upd on complaints for update using(is_admin()) with check(is_admin());
create policy fb_sel on feedback for select using(status='approved' or customer_id=auth.uid() or is_admin()); create policy fb_upd on feedback for update using(is_admin()) with check(is_admin());
create policy co_sel on commissions for select using(is_admin() or partner_id in(select id from partners where user_id=auth.uid()));
create policy co_upd on commissions for update using(is_admin()) with check(is_admin());
create policy tk_sel on tickets for select using(is_admin() or partner_id in(select id from partners where user_id=auth.uid()));
create policy tk_ins on tickets for insert with check(status='open' and partner_id in(select id from partners where user_id=auth.uid() and status='approved'));
create policy tk_upd on tickets for update using(is_admin()) with check(is_admin());
create policy ex_all on expenses for all using(is_admin()) with check(is_admin());
create policy du_all on duplicate_attempts for all using(is_admin()) with check(is_admin());

-- ---------- private storage buckets (photos and KYC) ----------
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values
  ('lead-photos','lead-photos',false,5242880,array['image/jpeg','image/png','image/webp']),
  ('kyc','kyc',false,5242880,array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict(id) do update set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

create function can_read_photo(n text) returns boolean language sql security definer stable set search_path=public as $$
  select is_admin()
   or exists(select 1 from leads l where (l.customer_id=auth.uid() or l.partner_id in(select id from partners where user_id=auth.uid())) and n=any(l.photos))
   or exists(select 1 from inspections i where owns_lead(i.lead_id) and n=any(i.photos))
   or exists(select 1 from progress_updates u where owns_lead(u.lead_id) and n=any(u.photos))
   or exists(select 1 from complaints c where c.customer_id=auth.uid() and n=any(c.photos)) $$;
grant execute on function can_read_photo(text) to anon, authenticated;

create policy lp_ins on storage.objects for insert to anon, authenticated with check(bucket_id='lead-photos' and (name like 'inbox/%'
  or (auth.uid() is not null and name like 'complaints/'||auth.uid()::text||'/%') or (is_admin() and name like 'work/%')));
create policy lp_sel on storage.objects for select to authenticated using(bucket_id='lead-photos' and can_read_photo(name));
create policy lp_del on storage.objects for delete to authenticated using(bucket_id='lead-photos' and is_admin());
create policy kyc_ins on storage.objects for insert to authenticated with check(bucket_id='kyc' and (storage.foldername(name))[1]=auth.uid()::text);
create policy kyc_sel on storage.objects for select to authenticated using(bucket_id='kyc' and ((storage.foldername(name))[1]=auth.uid()::text or is_admin()));

-- ---------- demo defaults (all DEMO values) ----------
insert into settings(key,value) values ('gst_pct','18'),('advance_pct','40'),('company_name','"AquaShield Waterproofing (DEMO)"'),
  ('phone','"+91 00000 00000"'),('whatsapp','"910000000000"'),
  ('warranty_terms','"Warranty starts on the final payment date; covers recurrence of leakage in the treated area only; void if structural changes, damage or unauthorised repairs occur; complaint response within 48 hours; free re-inspection during warranty."');
insert into rate_card(key,name,rate,unit,warranty_years,sort) values
  ('terrace','Terrace Waterproofing',55,'sq ft',5,1),('bathroom','Bathroom Leakage',9000,'bathroom',3,2),('basement','Basement Waterproofing',85,'sq ft',5,3),
  ('tank','Water Tank Waterproofing',45,'sq ft',3,4),('pu','PU Injection Grouting',1200,'running metre',3,5),('wall','Wall Dampness Treatment',60,'sq ft',2,6),
  ('commercial','Commercial and Industrial',null,'custom',5,7);
insert into cities(name,active,rates) values ('Bhopal',true,'{}'),('Indore',false,'{"terrace":60}'),('Jabalpur',false,'{}'),('Gwalior',false,'{}'),('Ujjain',false,'{}');
