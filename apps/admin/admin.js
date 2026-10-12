import{sb,A,loadAll,D,stBadge,ALL,idx}from"./js/core.js";
import{$,$$,esc,inr,fmtD,say,errText,today,pretty}from"./js/util.js";
import{leadsView,leadDetail}from"./js/leads.js";
import{techsView,partnersView,commView}from"./js/people.js";
import{warrantyView,reportsView,settingsView,guideView}from"./js/ops.js";
const TABS=[["dash","Dashboard"],["leads","Leads"],["techs","Technicians"],["partners","Partners"],["comm","Commissions"],["warranty","Warranty"],["reports","Reports"],["settings","Settings"],["guide","Guide"]];
const app=$("#app");
function login(msg=""){
  document.title="Admin sign in";
  app.innerHTML=`<main class="narrow"><h1>Admin sign in</h1><form id="lf"><label>Email</label><input type="email" name="email" autocomplete="username" required><label>Password</label><input type="password" name="password" autocomplete="current-password" required><p><button class="btn gold" style="width:100%">Sign in</button></p><div class="msg err">${esc(msg)}</div></form></main>`;
  $("#lf").onsubmit=async e=>{e.preventDefault();const d=Object.fromEntries(new FormData(e.target)),m=$(".msg",e.target);say(m,"Signing in...",true);
    const{error}=await sb.auth.signInWithPassword({email:d.email.trim(),password:d.password});if(error)return say(m,errText(error));start()}}
async function start(){
  const{data:{session}}=await sb.auth.getSession();if(!session)return login();
  const{data:p}=await sb.from("profiles").select("*").eq("id",session.user.id).maybeSingle();
  if(p?.role!=="admin"){await sb.auth.signOut();return login("Access denied. This area is for administrators only.")}
  A.me={...p,email:session.user.email};
  try{await loadAll()}catch(e){app.innerHTML=`<main><div class="note bad">Could not load data: ${esc(errText(e))}. Check config.js and that schema.sql was run.</div></main>`;return}
  route()}
export async function refresh(){await loadAll();route()}
function dash(el){
  const L=D("leads"),t=today(),cnt=s=>L.filter(l=>l.status===s).length,due=L.filter(l=>l.follow_up_at&&l.follow_up_at<=t&&!["lost","paid","warranty_active"].includes(l.status)),un=L.filter(l=>l.status==="new"&&!l.technician_id);
  const rows=a=>a.map(l=>`<a class="row2" href="#/leads?lead=${l.code}" style="text-decoration:none"><span><b>${l.code}</b> ${esc(l.name)}<br><span class="muted">${esc(l.service)} &middot; ${esc(l.mobile)}${l.follow_up_at?" &middot; follow-up "+fmtD(l.follow_up_at):""}</span></span>${stBadge(l.status)}</a>`).join("")||`<p class="muted">Nothing here.</p>`;
  const k=(n,v)=>`<div class="kpi"><b>${v}</b><span>${n}</span></div>`;
  el.innerHTML=`<h2>Dashboard</h2><div class="kpis">${k("New leads today",L.filter(l=>String(l.created_at).slice(0,10)===t).length)}${k("Follow-ups due",due.length)}${k("Unassigned",un.length)}${k("Total leads",L.length)}${k("Pending partners",D("partners").filter(p=>p.status==="pending").length)}${k("Open complaints",D("complaints").filter(c=>c.status!=="resolved").length)}</div>
<h3>Leads by status</h3><div class="kpis">${ALL.map(s=>`<a class="kpi" href="#/leads?status=${s}" style="text-decoration:none"><b>${cnt(s)}</b><span>${pretty(s)}</span></a>`).join("")}</div>
<h3>Follow-ups due today</h3>${rows(due)}<h3>Unassigned leads</h3>${rows(un)}`}
function route(){
  if(!A.me)return;
  const[h,qs]=location.hash.replace(/^#\/?/,"").split("?"),r=h||"dash",q=new URLSearchParams(qs||"");
  document.title="AquaShield Admin";
  app.innerHTML=`<header><span class="logo">AquaShield Admin</span><div class="right"><button class="btn out sm" id="rf">Refresh</button><button class="btn sm" id="lo">Logout</button></div></header><main><nav class="tabs">${TABS.map(([k,l])=>`<a class="btn ${k===(r==="lead"?"leads":r)?"on":""}" href="#/${k}">${l}</a>`).join("")}</nav><div id="v"></div></main>`;
  $("#lo").onclick=async()=>{await sb.auth.signOut();A.me=null;location.hash="";login()};$("#rf").onclick=refresh;
  const el=$("#v");
  try{({dash,leads:e=>q.get("lead")?leadDetail(e,q.get("lead")):leadsView(e,q),techs:techsView,partners:partnersView,comm:commView,warranty:warrantyView,reports:reportsView,settings:settingsView,guide:guideView}[r]||dash)(el,q)}
  catch(e){el.innerHTML=`<div class="note bad">${esc(errText(e))}</div>`;console.error(e)}}
document.addEventListener("click",e=>{const d=e.target.closest("details.dd");document.querySelectorAll("details.dd[open]").forEach(x=>{if(x!==d)x.removeAttribute("open")})});
window.addEventListener("hashchange",route);
export{route};
start();
