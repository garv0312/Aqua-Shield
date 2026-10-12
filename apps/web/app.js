import{sb,S,loadMe}from"./js/core.js";
import{$,sess}from"./js/util.js";
import{header,footer,home,services,partnerProgram,contact}from"./js/public.js";
import{bookView}from"./js/book.js";
import{customerLogin,signup,partnerLogin,partnerApply,profile}from"./js/auth.js";
import{customerPage}from"./js/customer.js";
import{partnerPage}from"./js/partner.js";
import{applyLang,toggleLang}from"./js/i18n.js";
const need={my:"customer",profile:"any",partner:"partner"};
const PUBLIC={home,services,"partner-program":partnerProgram,contact,login:customerLogin,signup,"partner-login":partnerLogin,"partner-apply":partnerApply};
async function route(){
  const[h,qs]=location.hash.replace(/^#\/?/,"").split("?"),r=h||"home",q=new URLSearchParams(qs||"");
  const ref=q.get("ref")||new URLSearchParams(location.search).get("ref");if(ref&&/^WP-P-\d{3,}$/i.test(ref))sess.set("ref",ref.toUpperCase());
  if(r==="logout"){await sb.auth.signOut();S.me=null;S.partner=null;location.hash="#/home";return}
  await loadMe();
  if(S.me?.role==="admin"){await sb.auth.signOut();S.me=null;S.partner=null;sess.set("flash","This account cannot be used on this site.")}
  const n=need[r];
  if(n&&(!S.me||(n!=="any"&&S.me.role!==n))){const to=n==="partner"?"partner-login":"login";sess.set("flash",`Please sign in with a ${n==="any"?"customer or partner":n} account to continue.`);if(location.hash!==`#/${to}`){location.hash=`#/${to}`;return}}
  if(r==="partner"&&S.partner?.status!=="approved"){location.hash="#/partner-login";return}
  document.title=({home:"AquaShield Waterproofing | Terrace, Bathroom & Basement Waterproofing in Bhopal (DEMO)"})[r]||"AquaShield Waterproofing (DEMO)";
  $("#hdr").innerHTML=header();const el=$("#app");el.innerHTML="<main>Loading...</main>";
  try{
    if(PUBLIC[r])await PUBLIC[r](el);
    else if(r==="book"){el.innerHTML="<main></main>";await bookView($("main",el),{preService:q.get("service")||""})}
    else if(r==="my")await customerPage(el,q);
    else if(r==="profile")profile(el);
    else if(r==="partner")await partnerPage(el,q);
    else await home(el);
  }catch(e){el.innerHTML=`<main><div class="note bad">Something went wrong. Please refresh the page. If this continues, check that config.js has your Supabase URL and anon key.</div></main>`;console.error(e)}
  $("#ftr").innerHTML=footer();applyLang();window.scrollTo(0,0)}
document.addEventListener("click",async e=>{
  if(e.target.closest("[data-logout]")){e.preventDefault();location.hash="#/logout";return}
  if(e.target.closest("#lang")){toggleLang();applyLang();return}
  const open=e.target.closest("details.dd");document.querySelectorAll("details.dd[open]").forEach(d=>{if(d!==open||e.target.closest("a,button"))d.removeAttribute("open")})});
document.addEventListener("keydown",e=>{if(e.key==="Escape")document.querySelectorAll("details.dd[open]").forEach(d=>d.removeAttribute("open"))});
window.addEventListener("hashchange",route);route();
