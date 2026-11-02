const crypto=require('node:crypto');
const sessions=new Map();
const cookieName='citadel_classroom_vuln_'+(process.env.PORT||'3250');
function login(req,res){
 if(sessions.size>=2000)sessions.delete(sessions.keys().next().value);
 const token='CLASSROOM{TOKENS_ARE_NOT_SETTINGS}.'+crypto.randomBytes(24).toString('hex');
 sessions.set(token,{id:'alice',role:'user',expires:Date.now()+30*60000});
 // C1: readable by JavaScript, and also returned for localStorage persistence.
 res.cookie(cookieName,token,{httpOnly:false,sameSite:'lax',secure:req.secure,maxAge:30*60000,path:'/'});
 res.json({sessionToken:token,user:'Alice (fictional)',mode:'Classroom vulnerable app'});
}
function authenticate(req,res,next){
 const pairs=Object.fromEntries((req.headers.cookie||'').split(';').map(s=>{const i=s.indexOf('=');return [s.slice(0,i).trim(),s.slice(i+1)];}));
 const bearer=/^Bearer (\S+)$/.exec(req.get('Authorization')||'');
 let token;try{token=bearer?bearer[1]:decodeURIComponent(pairs[cookieName]||'');}catch{return res.status(401).json({error:'Invalid demo session.'});}
 const user=sessions.get(token);
 if(!user||user.expires<Date.now())return res.status(401).json({error:'Select Load demo first.'});
 req.user=user;req.sessionToken=token;next();
}
function clear(){const n=sessions.size;sessions.clear();return n;}
function logout(req,res){sessions.delete(req.sessionToken);res.clearCookie(cookieName,{path:'/'});res.json({signedOut:true});}
module.exports={login,authenticate,logout,clear,count:()=>sessions.size};
