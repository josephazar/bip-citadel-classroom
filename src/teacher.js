// Teacher-only controls for the hosted classroom copy: clear every demo session so the class starts fresh.
// Disabled until TEACHER_PASSWORD is set in the server environment. The password is read only from the
// environment, compared in constant time, and never logged or returned.
const crypto=require('node:crypto');
const session=require('./session');
const fails=new Map(),WINDOW=10*60*1000,MAX_FAILS=5;
let lastReset=null;
const digest=v=>crypto.createHash('sha256').update(String(v)).digest();
const same=(a,b)=>crypto.timingSafeEqual(digest(a),digest(b));
function guard(req,res,next){
 const expected=process.env.TEACHER_PASSWORD;
 if(!expected)return res.status(503).json({error:'Teacher controls are disabled: set TEACHER_PASSWORD on the server.'});
 const key=req.ip||'unknown',now=Date.now();
 let rec=fails.get(key);
 if(rec&&now-rec.first>=WINDOW){fails.delete(key);rec=undefined;}
 if(rec&&rec.n>=MAX_FAILS)return res.status(429).json({error:'Too many wrong passwords. Wait a few minutes.'});
 if(!same((req.body&&req.body.password)||'',expected)){
  if(fails.size>1000)fails.clear();
  rec=rec||{n:0,first:now};rec.n++;fails.set(key,rec);
  return res.status(401).json({error:'Wrong password.'});
 }
 fails.delete(key);next();
}
const status=(_req,res)=>res.json({sessions:session.count(),lastReset});
const reset=(_req,res)=>{const cleared=session.clear();lastReset=new Date().toISOString();res.json({cleared,lastReset});};
module.exports={guard,status,reset};
