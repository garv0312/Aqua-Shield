// Hindi / English label toggle (labels only). The choice is stored per viewer in localStorage.
import{store}from"./util.js";
let LANG=store.get("wp_lang")==="hi"?"hi":"en";
export const lang=()=>LANG;
export function toggleLang(){LANG=LANG==="hi"?"en":"hi";store.set("wp_lang",LANG)}
const HI={"Home":"होम","Services":"सेवाएँ","Partner Program":"पार्टनर प्रोग्राम","Contact":"संपर्क","Book Inspection":"निरीक्षण बुक करें","Login":"लॉगिन","Sign Up":"साइन अप","Customer Login":"ग्राहक लॉगिन","Partner Login":"पार्टनर लॉगिन","Logout":"लॉगआउट","Dashboard":"डैशबोर्ड","My Profile":"मेरी प्रोफ़ाइल","Call":"कॉल","WhatsApp":"व्हाट्सऐप",
"Leakage problem? Get a free inspection in Bhopal.":"लीकेज की समस्या? भोपाल में मुफ़्त निरीक्षण पाएँ।","Our services":"हमारी सेवाएँ","How it works":"यह कैसे काम करता है","Customer reviews":"ग्राहक समीक्षाएँ","Service locations":"सेवा क्षेत्र","Before and after":"पहले और बाद में",
"Free site visit":"मुफ़्त साइट विज़िट","Quotation":"कोटेशन","Warranty":"वारंटी","Waterproofing services":"वॉटरप्रूफिंग सेवाएँ","Apply":"आवेदन करें","Full name":"पूरा नाम","Mobile number (10 digits)":"मोबाइल नंबर (10 अंक)","City":"शहर","Pincode":"पिनकोड","Address":"पता","Service":"सेवा","Leakage type":"लीकेज का प्रकार","Property type":"प्रॉपर्टी का प्रकार","Preferred inspection date":"पसंदीदा निरीक्षण तिथि","Photos (optional, up to 4)":"फ़ोटो (वैकल्पिक, अधिकतम 4)","Email":"ईमेल","Password":"पासवर्ड","Contact us":"हमसे संपर्क करें","Customer Sign Up":"ग्राहक साइन अप","Partner application":"पार्टनर आवेदन","Submit":"जमा करें","My projects":"मेरे प्रोजेक्ट","Progress timeline":"प्रगति टाइमलाइन","Payments and receipts":"भुगतान और रसीदें","Terrace Waterproofing":"छत वॉटरप्रूफिंग","Bathroom Leakage":"बाथरूम लीकेज","Basement Waterproofing":"बेसमेंट वॉटरप्रूफिंग","Water Tank Waterproofing":"पानी की टंकी वॉटरप्रूफिंग","PU Injection Grouting":"पीयू इंजेक्शन ग्राउटिंग","Wall Dampness Treatment":"दीवार सीलन उपचार","Commercial and Industrial":"कमर्शियल और इंडस्ट्रियल"};
export function applyLang(root=document.body){
  const on=LANG==="hi",w=document.createTreeWalker(root,NodeFilter.SHOW_TEXT);let n;
  while((n=w.nextNode())){const p=n.parentNode;if(!p||/^(SCRIPT|STYLE|TEXTAREA)$/.test(p.tagName))continue;
    if(n.__en!==undefined&&(!on||!HI[n.__en.trim()])){n.nodeValue=n.__en;delete n.__en;continue}
    if(on){const t=n.nodeValue.trim();if(t&&HI[t]){if(n.__en===undefined)n.__en=n.nodeValue;n.nodeValue=n.__en.replace(t,HI[t])}}}
  const b=document.getElementById("lang");if(b)b.textContent=on?"EN (English)":"हिंदी"}
