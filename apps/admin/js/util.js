// Small helpers shared by both apps (identical copy lives in apps/admin/js/util.js)
export const $=(s,r=document)=>r.querySelector(s);
export const $$=(s,r=document)=>[...r.querySelectorAll(s)];
export const esc=s=>String(s??"").replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
export const inr=n=>"Rs. "+Number(n||0).toLocaleString("en-IN");
export const fmtD=d=>d?new Date(d).toLocaleDateString("en-IN",{day:"2-digit",month:"short",year:"numeric"}):"-";
export const fmtDT=d=>d?new Date(d).toLocaleString("en-IN",{day:"2-digit",month:"short",year:"numeric",hour:"2-digit",minute:"2-digit"}):"-";
export const pretty=s=>String(s??"").replace(/_/g," ").replace(/^./,c=>c.toUpperCase());
export const today=()=>new Date(Date.now()-new Date().getTimezoneOffset()*60000).toISOString().slice(0,10);
export const addDays=(d,n)=>new Date(new Date(d).getTime()+n*864e5).toISOString().slice(0,10);
export const store={get:k=>{try{return localStorage.getItem(k)}catch{return null}},set:(k,v)=>{try{localStorage.setItem(k,v)}catch{}}};
export const sess={get:k=>{try{return sessionStorage.getItem(k)}catch{return null}},set:(k,v)=>{try{sessionStorage.setItem(k,v)}catch{}},del:k=>{try{sessionStorage.removeItem(k)}catch{}}};
export const say=(el,msg,ok=false)=>{if(el){el.className="msg "+(ok?"ok":"err");el.textContent=msg||""}};
export const errText=e=>String(e?.message||e||"Something went wrong").replace(/^.*?exception:\s*/i,"");
export const uuid=()=>(crypto.randomUUID?crypto.randomUUID():String(Date.now())+Math.random().toString(16).slice(2));
export function csvText(rows,cols){const c=v=>{if(v==null)return"";let s=typeof v==="object"?JSON.stringify(v):String(v);if(/^[=+\-@]/.test(s))s="'"+s;return/[",\n\r]/.test(s)?'"'+s.replace(/"/g,'""')+'"':s};
  return[cols.join(","),...rows.map(r=>cols.map(k=>c(r[k])).join(","))].join("\r\n")}
export function download(name,text){const a=document.createElement("a");a.href=URL.createObjectURL(new Blob(["\ufeff"+text],{type:"text/csv"}));a.download=name;document.body.append(a);a.click();a.remove()}
export function compress(file,max=1280,q=.8){return new Promise(res=>{if(!file.type.startsWith("image/")||file.type==="image/gif")return res(file);
  const r=new FileReader();r.onerror=()=>res(file);r.onload=()=>{const im=new Image();im.onerror=()=>res(file);im.onload=()=>{const k=Math.min(1,max/Math.max(im.width,im.height)),c=document.createElement("canvas");
    c.width=Math.round(im.width*k);c.height=Math.round(im.height*k);c.getContext("2d").drawImage(im,0,0,c.width,c.height);c.toBlob(b=>res(b||file),"image/jpeg",q)};im.src=r.result};r.readAsDataURL(file)})}
