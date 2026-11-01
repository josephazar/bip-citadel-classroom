const {test}=require('node:test'),assert=require('node:assert/strict');
const {app}=require('../src/server');
test('guided classroom vulnerabilities are reproducible on fictional fixtures',async()=>{
 const server=app.listen(0,'127.0.0.1');await new Promise(r=>server.once('listening',r));const base=`http://127.0.0.1:${server.address().port}`;
 try{
 const login=await fetch(base+'/demo/login',{method:'POST'}),data=await login.json(),cookie=login.headers.getSetCookie()[0];
 assert(data.sessionToken.includes('CLASSROOM{TOKENS_ARE_NOT_SETTINGS}'));assert(!cookie.includes('HttpOnly'));
 const get=async(p,h={})=>{const r=await fetch(base+p,{headers:{cookie:cookie.split(';')[0],...h}});return {status:r.status,data:await r.json()};};
 assert((await get('/lab-api/logs')).data.logs.join(' ').includes(data.sessionToken));
 assert.equal((await get('/lab-api/notes/102')).data.owner,'bob');
 assert.equal((await get('/lab-api/admin',{'X-Lab-Role':'admin'})).status,200);
 const result=await get('/lab-api/search?q='+encodeURIComponent("%' OR 1=1 --"));assert.equal(result.data.rows.length,2);assert(result.data.rows.some(r=>r.owner==='bob'));
 assert.equal((await get('/lab-api/search?q='+encodeURIComponent("' OR randomblob(99999999) --"))).status,400);
 }finally{await new Promise(r=>server.close(r));}
});
