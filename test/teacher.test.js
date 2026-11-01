const {test}=require('node:test'),assert=require('node:assert/strict');
const {app}=require('../src/server');
async function boot(){const server=app.listen(0,'127.0.0.1');await new Promise(r=>server.once('listening',r));return {server,base:`http://127.0.0.1:${server.address().port}`};}
const post=(base,p,body,headers={})=>fetch(base+p,{method:'POST',headers:{'content-type':'application/json',...headers},body:JSON.stringify(body||{})});
test('the reset is disabled until a teacher password is configured',async()=>{
 delete process.env.TEACHER_PASSWORD;const {server,base}=await boot();
 try{assert.equal((await post(base,'/teacher/reset',{password:'anything'})).status,503);assert.equal((await post(base,'/teacher/status',{})).status,503);}
 finally{await new Promise(r=>server.close(r));}
});
test('only the teacher can see or clear the sessions, and students start fresh afterwards',async()=>{
 process.env.TEACHER_PASSWORD='correct-horse-battery';const {server,base}=await boot();
 try{
  const login=async()=>{const r=await fetch(base+'/demo/login',{method:'POST'});return r.headers.getSetCookie().map(c=>c.split(';')[0]).join('; ');};
  const a=await login(),b=await login();
  const get=(c)=>fetch(base+'/lab-api/notes/101',{headers:{cookie:c}});
  assert.equal((await get(a)).status,200);assert.equal((await get(b)).status,200);
  assert.equal((await post(base,'/teacher/reset',{password:'wrong'})).status,401);
  assert.equal((await post(base,'/teacher/reset',{})).status,401);
  assert.equal((await get(a)).status,200,'a wrong password must not reset anything');
  const st=await (await post(base,'/teacher/status',{password:'correct-horse-battery'})).json();
  assert.equal(st.sessions>=2,true);
  const done=await post(base,'/teacher/reset',{password:'correct-horse-battery'});assert.equal(done.status,200);
  const body=await done.json();assert.equal(body.cleared>=2,true);assert.ok(body.lastReset);
  assert.equal((await get(a)).status,401);assert.equal((await get(b)).status,401);
  const c=await login();assert.equal((await get(c)).status,200,'a new demo session works after the reset');
  assert.equal(JSON.stringify(body).includes('correct-horse-battery'),false,'the password is never echoed');
  const page=await fetch(base+'/teacher.html');assert.equal(page.status,200);assert.match(await page.text(),/Reset the class/);
 }finally{await new Promise(r=>server.close(r));delete process.env.TEACHER_PASSWORD;}
});
test('repeated wrong passwords are throttled',async()=>{
 process.env.TEACHER_PASSWORD='another-long-password';const {server,base}=await boot();
 try{let last;for(let i=0;i<7;i++)last=(await post(base,'/teacher/reset',{password:'nope'+i})).status;assert.equal(last,429);
  assert.equal((await post(base,'/teacher/reset',{password:'another-long-password'})).status,429,'even the right password waits out the lockout');}
 finally{await new Promise(r=>server.close(r));delete process.env.TEACHER_PASSWORD;}
});
