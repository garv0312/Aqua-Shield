import{sb,S,loadCfg,upload}from"./core.js";
import{$,esc,say,errText,uuid,sess,today,addDays}from"./util.js";
const LEAK=["Terrace / roof seepage","Wall dampness","Bathroom leakage","Basement seepage","Water tank leakage","Cracks / joints","Not sure"];
const PROP=["House / Villa","Apartment / Flat","Shop / Office","Industrial / Warehouse","Other"];
// partner=true: partner submits a lead from the dashboard (same fields, duplicate check happens in the database)
export async function bookView(el,{partner=false,preService="",onDone}={}){
  const c=await loadCfg(),me=S.me,ref=sess.get("ref")||"";
  el.innerHTML=`${partner?"<h2>Submit a lead</h2>":"<h1>Book Inspection</h1>"}<p class="muted">Free inside Bhopal city limits. Takes about one minute.</p>
${ref&&!partner?`<div class="note ok">Referred by partner <b>${esc(ref)}</b>.</div>`:""}
<form id="bf" class="narrow" style="max-width:640px"><label>Full name</label><input name="name" value="${esc(partner?"":me?.name||"")}" required>
<label>Mobile number (10 digits)</label><input name="mobile" inputmode="numeric" maxlength="10" value="${esc(partner?"":me?.mobile||"")}" required>
<div class="two"><div><label>City</label><select name="city">${c.cities.filter(x=>x.active).map(x=>`<option>${esc(x.name)}</option>`).join("")||"<option>Bhopal</option>"}</select></div><div><label>Pincode</label><input name="pincode" inputmode="numeric" maxlength="6" required></div></div>
<label>Address</label><textarea name="address" rows="2" required></textarea>
<label>Service</label><select name="service" required><option value="">Select service</option>${c.rates.map(s=>`<option value="${esc(s.key)}" ${s.key===preService?"selected":""}>${esc(s.name)}</option>`).join("")}</select>
<div class="two"><div><label>Leakage type</label><select name="leakage_type">${LEAK.map(x=>`<option>${x}</option>`).join("")}</select></div><div><label>Property type</label><select name="property_type">${PROP.map(x=>`<option>${x}</option>`).join("")}</select></div></div>
<label>Photos (optional, up to 4)</label><input type="file" name="photos" accept="image/*" multiple>
<label>Preferred inspection date</label><input type="date" name="preferred_date" min="${addDays(today(),1)}">
<div class="chk"><input type="checkbox" name="consent" id="cons"><label for="cons">I agree to be contacted by AquaShield on call or WhatsApp about this request.</label></div>
<button class="btn gold" style="width:100%">${partner?"Submit lead":"Book Inspection"}</button><div class="msg"></div></form>`;
  $("#bf",el).onsubmit=async e=>{e.preventDefault();const f=e.target,msg=$(".msg",f),btn=$("button",f),d=Object.fromEntries(new FormData(f));
    if(!/^[0-9]{10}$/.test(d.mobile||""))return say(msg,"Enter a valid 10-digit mobile number.");
    if(!/^[0-9]{6}$/.test(d.pincode||""))return say(msg,"Enter a valid 6-digit pincode.");
    if((d.name||"").trim().length<2||(d.address||"").trim().length<5||!d.service)return say(msg,"Please fill in name, address and service.");
    if(!f.consent.checked)return say(msg,"Consent is required.");
    btn.disabled=true;say(msg,"Submitting...",true);
    try{const files=f.photos.files,photos=files.length?await upload("lead-photos",files,"inbox/"+uuid()):[];
      const{data,error}=await sb.rpc("submit_lead",{p:{name:d.name.trim(),mobile:d.mobile,city:d.city,pincode:d.pincode,address:d.address.trim(),service:d.service,leakage_type:d.leakage_type,property_type:d.property_type,preferred_date:d.preferred_date||"",consent:"true",ref:partner?"":ref,photos}});
      if(error)throw error;
      if(data==="DUPLICATE"){btn.disabled=false;return say(msg,"Duplicate lead rejected: this customer (same mobile and address) is already registered within the 90-day ownership window.")}
      el.innerHTML=`<div class="note ok" style="max-width:640px"><h2>Request received</h2><p>Your Lead ID is</p><div style="font-size:2rem;font-weight:800;color:var(--head)">${esc(data)}</div><p>Save this ID. ${partner?"The customer can track it from their account.":"Our team will confirm your inspection slot."}</p></div>
<p>${partner?`<a class="btn" href="#/partner">Back to dashboard</a>`:S.me?`<a class="btn" href="#/my">Go to my dashboard</a>`:`<a class="btn gold" href="#/signup">Create an account to track this request</a>`}</p>`;
      if(onDone)onDone(data)}
    catch(x){btn.disabled=false;say(msg,errText(x))}}}
