import{createClient}from"https://esm.sh/@supabase/supabase-js@2.45.4";
import{SUPABASE_URL,SUPABASE_ANON_KEY,PHONE}from"../config.js";
import{$$,esc,uuid,compress}from"./util.js";
export{PHONE};
export const sb=createClient(SUPABASE_URL,SUPABASE_ANON_KEY);
export const S={me:null,partner:null,cfg:null};
export async function loadMe(){
  S.me=null;S.partner=null;
  const{data:{session}}=await sb.auth.getSession();if(!session)return null;
  const{data:p}=await sb.from("profiles").select("*").eq("id",session.user.id).maybeSingle();
  if(!p)return null;S.me={...p,email:session.user.email};
  if(p.role==="partner"){const{data}=await sb.from("partners").select("*").eq("user_id",session.user.id).maybeSingle();S.partner=data}
  return S.me}
export async function loadCfg(force){
  if(S.cfg&&!force)return S.cfg;
  const[a,b,c]=await Promise.all([sb.from("rate_card").select("*").order("sort"),sb.from("cities").select("*").order("name"),sb.from("settings").select("*")]);
  const set={};(c.data||[]).forEach(r=>set[r.key]=r.value);
  S.cfg={rates:a.data||[],cities:b.data||[],company_name:set.company_name||"AquaShield Waterproofing (DEMO)",phone:set.phone||"",whatsapp:set.whatsapp||PHONE,
    warranty_terms:set.warranty_terms||"",gst_pct:Number(set.gst_pct??18),advance_pct:Number(set.advance_pct??40)};
  return S.cfg}
export const basis=r=>Number(r.rate)>0?`Rs. ${Number(r.rate).toLocaleString("en-IN")} per ${r.unit}`:"Custom quotation after inspection";
export async function upload(bucket,files,prefix){
  const out=[];
  for(const f of[...files].slice(0,4)){const b=await compress(f),ext=(b.type==="image/jpeg"?"jpg":(f.name.split(".").pop()||"jpg")).toLowerCase().replace(/[^a-z0-9]/g,"").slice(0,5)||"jpg";
    const path=`${prefix}/${uuid()}.${ext}`,{error}=await sb.storage.from(bucket).upload(path,b,{contentType:b.type||f.type,upsert:false});if(!error)out.push(path)}
  return out}
export async function showPhotos(root=document){
  for(const im of $$("img[data-path]",root)){const{data}=await sb.storage.from(im.dataset.bucket||"lead-photos").createSignedUrl(im.dataset.path,3600);
    if(data?.signedUrl){im.src=data.signedUrl;const a=im.closest("a");if(a){a.href=data.signedUrl;a.target="_blank";a.rel="noopener"}}}}
export const photoHtml=(paths=[])=>paths.length?`<div class="pgal">${paths.map(p=>`<a><img data-path="${esc(p)}" alt="photo"></a>`).join("")}</div>`:"";
export const PIPE=["new","assigned","inspected","quoted","approved","in_progress","completed","paid","warranty_active"];
export const stBadge=s=>`<span class="st" style="background:${({new:"#456",assigned:"#1f6fb2",inspected:"#6a4bb5",quoted:"#b26a00",follow_up:"#b26a00",approved:"#1a7f4b",in_progress:"#0b7a8a",completed:"#1a7f4b",paid:"#146c3f",warranty_active:"#0B2545",lost:"#b3261e"})[s]||"#456"}">${esc(String(s).replace(/_/g," "))}</span>`;
