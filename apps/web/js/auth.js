import{sb,S,loadMe,loadCfg,upload}from"./core.js";
import{$,esc,say,errText,sess,uuid}from"./util.js";
import{TIERS}from"./public.js";
const flash=()=>{const m=sess.get("flash");sess.del("flash");return m?`<div class="note warn">${esc(m)}</div>`:""};
const lg=(t,body,foot)=>`<main class="narrow"><h1>${t}</h1>${flash()}${body}<p class="small" style="margin-top:14px">${foot}</p></main>`;
async function signIn(f){const d=Object.fromEntries(new FormData(f));const{error}=await sb.auth.signInWithPassword({email:d.email.trim(),password:d.password});if(error)throw error;return loadMe()}
async function out(){await sb.auth.signOut();S.me=null;S.partner=null}
// ---------- customer ----------
export function customerLogin(el){
  el.innerHTML=lg("Customer Login",`<form id="lf"><label>Email</label><input type="email" name="email" required><label>Password</label><input type="password" name="password" required><p><button class="btn gold" style="width:100%">Login</button></p><div class="msg"></div></form>`,
    `New here? <a href="#/signup">Sign Up</a> &middot; <a href="#/partner-login">Partner Login</a>`);
  $("#lf",el).onsubmit=async e=>{e.preventDefault();const msg=$(".msg",e.target);say(msg,"Signing in...",true);
    try{const me=await signIn(e.target);
      if(!me||me.role==="admin"){await out();return say(msg,"This account cannot sign in on this site.")}
      if(me.role!=="customer"){await out();return say(msg,"This is a partner account. Please use Partner Login.")}
      location.hash="#/my"}catch(x){say(msg,errText(x))}}}
export function signup(el){
  loadCfg().then(c=>{el.innerHTML=lg("Customer Sign Up",`<form id="sf"><label>Full name</label><input name="name" required><label>Mobile number (10 digits)</label><input name="mobile" inputmode="numeric" maxlength="10" required>
<label>Email</label><input type="email" name="email" required><label>Password (min. 8 characters)</label><input type="password" name="password" minlength="8" required>
<label>City</label><select name="city">${c.cities.filter(x=>x.active).map(x=>`<option>${esc(x.name)}</option>`).join("")}</select>
<div class="chk"><input type="checkbox" name="consent" id="c1"><label for="c1">I agree to be contacted by AquaShield about my requests and to the use of my details for service.</label></div>
<p><button class="btn gold" style="width:100%">Sign Up</button></p><div class="msg"></div></form>`,`Already have an account? <a href="#/login">Customer Login</a>`);
  $("#sf",el).onsubmit=async e=>{e.preventDefault();const f=e.target,msg=$(".msg",f),d=Object.fromEntries(new FormData(f));
    if(!/^[0-9]{10}$/.test(d.mobile))return say(msg,"Enter a valid 10-digit mobile number.");if(!f.consent.checked)return say(msg,"Consent is required.");
    say(msg,"Creating account...",true);
    const{data,error}=await sb.auth.signUp({email:d.email.trim(),password:d.password,options:{data:{name:d.name.trim(),mobile:d.mobile,city:d.city}}});
    if(error)return say(msg,errText(error));
    if(!data.session)return say(msg,"Account created. Please confirm your email, then log in from Customer Login.",true);
    await loadMe();location.hash="#/my"}})}
// ---------- partner ----------
export function partnerLogin(el){
  el.innerHTML=lg("Partner Login",`<form id="lf"><label>Email</label><input type="email" name="email" required><label>Password</label><input type="password" name="password" required><p><button class="btn gold" style="width:100%">Login</button></p><div class="msg"></div></form>`,
    `Not a partner yet? <a href="#/partner-apply">Apply as a partner</a> &middot; <a href="#/login">Customer Login</a>`);
  $("#lf",el).onsubmit=async e=>{e.preventDefault();const msg=$(".msg",e.target);say(msg,"Signing in...",true);
    try{const me=await signIn(e.target);if(!me||me.role==="admin"){await out();return say(msg,"This account cannot sign in on this site.")}
      if(me.role==="partner"&&S.partner?.status==="approved"){location.hash="#/partner";return}
      const{data:pa}=await sb.from("partners").select("status,reject_reason").eq("user_id",me.id).maybeSingle();await out();
      msg.className="msg err";
      if(pa?.status==="pending")msg.innerHTML=`Your partner application is pending review. You can log in once it is approved. <a href="#/partner-apply">View application</a>`;
      else if(pa?.status==="rejected")msg.innerHTML=`Your partner application was not approved${pa.reject_reason?": "+esc(pa.reject_reason):""}. <a href="#/partner-apply">Apply again</a>`;
      else msg.innerHTML=`This is a customer account. Please use Customer Login, or <a href="#/partner-apply">apply as a partner</a>.`}
    catch(x){say(msg,errText(x))}}}
export async function partnerApply(el){
  await loadMe();const me=S.me;
  el.innerHTML=lg("Partner application",`<p class="muted">Choose a tier. Fees and benefits are shown before you apply. Our team reviews every application.</p>
<form id="pf"><label>Tier</label><select name="tier"><option value="referral">${TIERS[0][0]} (${TIERS[0][1]})</option><option value="authorized">${TIERS[1][0]} (${TIERS[1][1]})</option><option value="area">${TIERS[2][0]} (${TIERS[2][1]})</option></select><div class="note" id="ti"></div>
<label>Full name</label><input name="name" value="${esc(me?.name||"")}" required><div class="two"><div><label>Mobile (10 digits)</label><input name="mobile" inputmode="numeric" maxlength="10" value="${esc(me?.mobile||"")}" required></div><div><label>Email</label><input type="email" name="email" value="${esc(me?.email||"")}" ${me?"readonly":""} required></div></div>
${me?"":`<label>Password (min. 8 characters)</label><input type="password" name="password" minlength="8" required>`}
<div class="two"><div><label>City</label><input name="city" value="Bhopal" required></div><div><label>PAN / Aadhaar last 4 characters only</label><input name="id_last4" maxlength="4" required></div></div>
<label>KYC note (optional)</label><textarea name="kyc_note" rows="2" placeholder="Example: available for video KYC. Do not type full PAN, Aadhaar or bank numbers."></textarea>
<label>KYC document (optional, private. Mask all but the last 4 digits of any ID number)</label><input type="file" name="kyc" accept="image/*,application/pdf">
<div class="chk"><input type="checkbox" name="agree" id="ag"><label for="ag">I accept the Partner Agreement (DEMO): commission is earned only on real customer business and paid after full payment; no commission is paid for recruiting partners; the first partner to submit a unique lead owns it for 90 days.</label></div>
<p><button class="btn gold" style="width:100%">Submit application</button></p><div class="msg"></div></form>`,`Already approved? <a href="#/partner-login">Partner Login</a>`);
  const f=$("#pf",el),info=()=>{const t=TIERS[["referral","authorized","area"].indexOf(f.tier.value)];$("#ti",el).innerHTML=`<b>${t[0]}</b><br>Joining fee: <b>${t[1]}</b> (collected after approval)<br>Benefits: ${t[2]}<br>Commission: ${t[3]}<br><span class="muted">All figures DEMO.</span>`};
  f.tier.onchange=info;info();
  f.onsubmit=async e=>{e.preventDefault();const msg=$(".msg",f),d=Object.fromEntries(new FormData(f));
    if(!/^[0-9]{10}$/.test(d.mobile))return say(msg,"Enter a valid 10-digit mobile number.");if(!/^[A-Za-z0-9]{4}$/.test(d.id_last4))return say(msg,"Enter exactly 4 characters.");if(!f.agree.checked)return say(msg,"You must accept the agreement.");
    if(/[0-9]{9,}|[A-Za-z]{5}[0-9]{4}[A-Za-z]/.test((d.kyc_note||"").replace(/\s/g,"")))return say(msg,"Please do not enter full PAN, Aadhaar or bank numbers.");
    say(msg,"Submitting...",true);
    try{let uid=me?.id;
      if(!me){const{data,error}=await sb.auth.signUp({email:d.email.trim(),password:d.password,options:{data:{name:d.name.trim(),mobile:d.mobile,city:d.city}}});if(error)throw error;
        if(!data.session)return say(msg,"Account created. Please confirm your email, then return here and submit again.",true);uid=data.user.id}
      let kyc_doc="";if(f.kyc.files[0]){const p=await upload("kyc",[f.kyc.files[0]],uid);kyc_doc=p[0]||""}
      const{error}=await sb.rpc("apply_partner",{p:{tier:d.tier,name:d.name.trim(),mobile:d.mobile,email:d.email.trim(),city:d.city,id_last4:d.id_last4,kyc_note:d.kyc_note||"",kyc_doc,agree:"true"}});if(error)throw error;
      await out();el.innerHTML=lg("Application received",`<div class="note ok">Our team will verify your KYC and approve your application. Your Partner ID (WP-P-xxx) is assigned on approval. You can then log in from Partner Login.</div>`,`<a href="#/home">Back to home</a>`)}
    catch(x){say(msg,errText(x))}}}
// ---------- profile ----------
export function profile(el){
  const m=S.me,isC=m.role==="customer";
  el.innerHTML=`<main class="narrow"><h1>My Profile</h1><form id="pf" class="card"><label>Full name</label><input name="name" value="${esc(m.name||"")}" ${isC?"":"readonly"}><label>Mobile</label><input name="mobile" inputmode="numeric" maxlength="10" value="${esc(m.mobile||"")}" ${isC?"":"readonly"}>
<label>Email</label><input value="${esc(m.email)}" readonly><label>City</label><input name="city" value="${esc(m.city||"")}" ${isC?"":"readonly"}>${S.partner?`<label>Partner ID / tier</label><input value="${esc(S.partner.code)} / ${esc(S.partner.tier)}" readonly>`:""}
${isC?`<p><button class="btn gold">Save changes</button></p>`:`<p class="muted">To change your details, raise a support ticket from the dashboard.</p>`}<div class="msg"></div></form></main>`;
  if(isC)$("#pf",el).onsubmit=async e=>{e.preventDefault();const f=e.target,msg=$(".msg",f);
    if(!/^[0-9]{10}$/.test(f.mobile.value))return say(msg,"Enter a valid 10-digit mobile number.");
    const{error}=await sb.from("profiles").update({name:f.name.value.trim(),mobile:f.mobile.value,city:f.city.value.trim()}).eq("id",m.id);
    if(error)return say(msg,errText(error));await loadMe();say(msg,"Saved.",true)}}
