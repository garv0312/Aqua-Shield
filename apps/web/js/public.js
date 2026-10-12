import{sb,S,PHONE,loadCfg,basis}from"./core.js";
import{$,esc,inr}from"./util.js";
import{lang}from"./i18n.js";
const DESC={terrace:"Roof and terrace seepage, cracks and ponding. Surface cleaning, crack repair and waterproof coating.",bathroom:"Leaks through bathroom floors, walls and pipe joints, fixed without breaking the whole bathroom where possible.",basement:"Seepage and dampness in basements and below-ground walls and floors.",tank:"Internal waterproofing for overhead and underground tanks with safe coating.",pu:"Crack and joint sealing by injecting polyurethane grout under pressure.",wall:"Damp patches, peeling paint and salt marks on interior and exterior walls.",commercial:"Large roofs, factories, parking decks and multi-floor buildings, planned after site inspection."};
export const TIERS=[["Referral Partner","Rs. 0","Submit leads, dashboard, marketing material","5% of net project value (excluding GST); minimum project Rs. 10,000"],
 ["Authorized Service Partner","Rs. 10,000 per year","Referral benefits + eligible to be assigned jobs in own area, training, priority support","8% on referred leads; job payout 25% of net project value when assigned a job"],
 ["Area Partner","Rs. 50,000 per year","Exclusive pincode territory, all benefits above, area lead sharing","10% on referred leads + 3% override on company-generated projects completed in own territory"]];
export function header(){
  const m=S.me,home=m?(m.role==="partner"?"#/partner":"#/my"):"";
  return`<a class="logo" href="#/home">AquaShield</a><div class="right"><a class="btn gold" href="#/book">Book Inspection</a>
${m?`<details class="dd hd-wide lg"><summary>${esc((m.name||"Account").split(" ")[0])}</summary><div><a href="${home}">Dashboard</a><a href="#/profile">My Profile</a><button data-logout>Logout</button></div></details>`
:`<details class="dd lg hd-wide"><summary>Login</summary><div><a href="#/login">Customer Login</a><a href="#/partner-login">Partner Login</a></div></details><a class="btn out hd-wide" href="#/signup">Sign Up</a>`}
<details class="dd"><summary aria-label="Menu"><svg width="20" height="20" viewBox="0 0 24 24" aria-hidden="true"><path d="M3 6h18M3 12h18M3 18h18" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/></svg></summary><div>
<a href="#/home">Home</a><a href="#/services">Services</a><a href="#/partner-program">Partner Program</a><a href="#/contact">Contact</a>
${m?`<a class="m-only" href="${home}">Dashboard</a><a class="m-only" href="#/profile">My Profile</a><button class="m-only" data-logout>Logout</button>`:`<a class="m-only" href="#/login">Customer Login</a><a class="m-only" href="#/partner-login">Partner Login</a><a class="m-only" href="#/signup">Sign Up</a>`}
<button id="lang" aria-label="Switch language (Hindi / English)">${lang()==="hi"?"EN (English)":"हिंदी"}</button></div></details></div>`}
export const footer=()=>`<footer><b>AquaShield Waterproofing</b> <span class="demo">DEMO</span> &middot; Bhopal, Madhya Pradesh<br>All reviews, photos, phone numbers and rates on this site are DEMO placeholders.</footer>
<div class="fab"><a class="btn gold" href="tel:+${PHONE}">Call</a><a class="btn" href="https://wa.me/${PHONE}" target="_blank" rel="noopener">WhatsApp</a></div>`;
const svcCards=c=>c.rates.map(s=>`<article class="card"><h3>${esc(s.name)}</h3><p class="muted">${esc(basis(s))} <span class="demo">DEMO</span></p><p>${esc(DESC[s.key]||"")}</p><span class="badge">${s.warranty_years} year warranty</span></article>`).join("");
export async function home(el){
  const c=await loadCfg(),{data:rv}=await sb.from("feedback").select("*").eq("status","approved").order("created_at",{ascending:false}).limit(6);
  const reviews=(rv&&rv.length?rv.map(f=>[f.text,f.by_name,f.rating,f.demo]):[["Terrace stayed dry in the whole monsoon.","Sample customer, Arera Colony",5,true],["Bathroom leak fixed without breaking the tiles.","Sample customer, Kolar Road",5,true],["Clear quotation and on-time work.","Sample customer, MP Nagar",4,true]]);
  el.innerHTML=`<div class="hero"><h1>Leakage problem? Get a free inspection in Bhopal.</h1><p>Expert waterproofing for terrace, bathroom, basement, tank and walls, with written warranty.</p><div class="row"><a class="btn gold" href="#/book">Book Inspection</a> <a class="btn out" href="#/services">See Services</a></div></div>
<main><h2>Our services</h2><div class="grid">${svcCards(c)}</div>
<h2>How it works</h2><div class="grid">${[["Book Inspection","Fill a short form. You get a Lead ID."],["Free site visit","A technician checks the leakage. Free inside Bhopal city limits."],["Quotation","Clear plan and price, GST shown separately. Valid 15 days."],["Approve and work starts",`${c.advance_pct}% advance on approval, ${100-c.advance_pct}% after quality inspection.`],["Warranty","Certificate issued after final payment, with free re-inspection."]].map((s,i)=>`<div class="card"><b>${i+1}. ${s[0]}</b><br><span class="muted">${s[1]}</span></div>`).join("")}</div>
<h2>Before and after <span class="demo">DEMO</span></h2><div class="grid">${[1,2].map(i=>`<div class="card muted">Before / after photo placeholder ${i} (DEMO)</div>`).join("")}</div>
<h2>Customer reviews</h2><div class="grid">${reviews.map(r=>`<div class="card"><p class="muted">${"★".repeat(r[2])}${"☆".repeat(5-r[2])}</p><p>"${esc(r[0])}"</p><p class="muted">${esc(r[1])} ${r[3]?'<span class="demo">DEMO</span>':""}</p></div>`).join("")}</div>
<h2>Service locations</h2><p>We serve: ${c.cities.filter(x=>x.active).map(x=>esc(x.name)).join(", ")||"Bhopal"}. More cities coming soon.</p></main>`}
export async function services(el){
  const c=await loadCfg();
  el.innerHTML=`<main><h1>Waterproofing services</h1><p class="muted">Typical pricing basis (DEMO). The final price is in your quotation after inspection.</p>${c.rates.map(s=>`<section class="card"><h2>${esc(s.name)}</h2><p>${esc(DESC[s.key]||"")}</p><p><b>Typical pricing basis:</b> ${esc(basis(s))} <span class="demo">DEMO</span><br><b>Warranty:</b> ${s.warranty_years} years <span class="demo">DEMO</span></p><a class="btn sm" href="#/book?service=${encodeURIComponent(s.key)}">Book Inspection</a></section>`).join("")}
<div class="note"><b>Warranty terms (DEMO):</b> ${esc(c.warranty_terms)}</div></main>`}
export function partnerProgram(el){
  el.innerHTML=`<main><h1>Partner Program</h1><p>Earn by referring real customers to AquaShield, or join as a service partner. Fees and benefits are shown before you apply.</p>
<div class="tw"><table><tr><th>Tier</th><th>Joining fee</th><th>Benefits</th><th>Commission</th></tr>${TIERS.map(t=>`<tr><td><b>${t[0]}</b></td><td>${t[1]}</td><td>${t[2]}</td><td>${t[3]}</td></tr>`).join("")}</table></div><p class="muted">All figures are DEMO placeholders.</p>
<div class="note"><b>Important:</b> No commission is paid for recruiting or adding partners, and there are no multi-level payouts. Commission is earned only on real customer business and is paid after the project is fully paid. Payout is within 15 days. The first partner to submit a unique lead owns it for 90 days. You must accept the partner agreement when applying.</div>
<a class="btn gold" href="#/partner-apply">Apply</a></main>`}
export async function contact(el){
  const c=await loadCfg();
  el.innerHTML=`<main><h1>Contact us</h1><div class="card"><p><b>Phone:</b> ${esc(c.phone)} <span class="demo">DEMO</span></p><p><b>WhatsApp:</b> <a href="https://wa.me/${esc(String(c.whatsapp).replace(/\D/g,""))}" target="_blank" rel="noopener">Chat now</a> <span class="demo">DEMO</span></p><p><b>City:</b> Bhopal, Madhya Pradesh</p><p><b>Hours:</b> 9 AM to 7 PM, Monday to Saturday (DEMO)</p><a class="btn gold" href="#/book">Book Inspection</a></div></main>`}
