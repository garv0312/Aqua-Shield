import{createClient}from"https://esm.sh/@supabase/supabase-js@2.45.4";
import{SUPABASE_URL,SUPABASE_ANON_KEY,PHONE}from"../config.js";
import{$$,esc,uuid,compress}from"./util.js";
export{PHONE};
export const sb=createClient(SUPABASE_URL,SUPABASE_ANON_KEY);
export const A={me:null,cfg:null,d:{}};
export const ALL=["new","assigned","inspected","quoted","follow_up","approved","in_progress","completed","paid","warranty_active","lost"];
export const idx=s=>ALL.indexOf(s);
export const COL={new:"#456",assigned:"#1f6fb2",inspected:"#6a4bb5",quoted:"#b26a00",follow_up:"#b26a00",approved:"#1a7f4b",in_progress:"#0b7a8a",completed:"#1a7f4b",paid:"#146c3f",warranty_active:"#0B2545",lost:"#b3261e",
  sent:"#b26a00",declined:"#b3261e",open:"#b26a00",re_inspection:"#6a4bb5",resolved:"#1a7f4b",pending:"#b26a00",hidden:"#888",verified:"#1a7f4b",rejected:"#b3261e"};
export const stBadge=s=>`<span class="st" style="background:${COL[s]||"#456"}">${esc(String(s).replace(/_/g," "))}</span>`;
export async function loadCfg(){
  const[a,b,c]=await Promise.all([sb.from("rate_card").select("*").order("sort"),sb.from("cities").select("*").order("name"),sb.from("settings").select("*")]);
  const set={};(c.data||[]).forEach(r=>set[r.key]=r.value);
  A.cfg={rates:a.data||[],cities:b.data||[],company_name:set.company_name||"AquaShield Waterproofing (DEMO)",phone:set.phone||"",whatsapp:set.whatsapp||PHONE,warranty_terms:set.warranty_terms||"",gst_pct:Number(set.gst_pct??18),advance_pct:Number(set.advance_pct??40)};
  return A.cfg}
const TBL=["leads","technicians","partners","quotes","payments","invoices","warranties","commissions","inspections","work_orders","complaints","feedback","expenses","duplicate_attempts","tickets"];
export async function loadAll(){
  await loadCfg();
  const res=await Promise.all(TBL.map(t=>sb.from(t).select("*").limit(5000)));
  res.forEach((r,i)=>{if(r.error)throw r.error;A.d[TBL[i]]=r.data||[]});
  A.d.leads.sort((a,b)=>String(b.created_at).localeCompare(String(a.created_at)))}
export const D=t=>A.d[t]||[];
export const byLead=(t,id)=>D(t).filter(x=>x.lead_id===id);
export const oneLead=(t,id)=>D(t).find(x=>x.lead_id===id);
export const leadOf=id=>D("leads").find(l=>l.id===id);
export const techName=id=>D("technicians").find(t=>t.id===id)?.name||"-";
export const partnerName=id=>{const p=D("partners").find(x=>x.id===id);return p?`${p.name} (${p.code||"pending"})`:"-"};
export const netPaid=id=>byLead("payments",id).reduce((s,p)=>s+(p.type==="refund"?-1:1)*Number(p.amount),0);
export const rateFor=(key,city)=>{const ci=D("cities").find(c=>c.name===city),o=ci?.rates?.[key],r=A.cfg.rates.find(x=>x.key===key);return Number(o)||Number(r?.rate)||0};
export const rcOf=key=>A.cfg.rates.find(x=>x.key===key)||{};
export async function upload(files,prefix){
  const out=[];for(const f of[...files].slice(0,6)){const b=await compress(f),path=`${prefix}/${uuid()}.jpg`,{error}=await sb.storage.from("lead-photos").upload(path,b,{contentType:"image/jpeg"});if(!error)out.push(path)}return out}
export async function showPhotos(root=document){
  for(const im of $$("img[data-path]",root)){const{data}=await sb.storage.from(im.dataset.bucket||"lead-photos").createSignedUrl(im.dataset.path,3600);
    if(data?.signedUrl){im.src=data.signedUrl;const a=im.closest("a");if(a){a.href=data.signedUrl;a.target="_blank";a.rel="noopener"}}}}
export const photoHtml=(paths=[],bucket="lead-photos")=>paths?.length?`<div class="pgal">${paths.map(p=>`<a><img data-path="${esc(p)}" data-bucket="${bucket}" alt="photo"></a>`).join("")}</div>`:"";
