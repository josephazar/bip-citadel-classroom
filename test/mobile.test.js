const {test} = require('node:test');
const assert = require('node:assert/strict');
const {app} = require('../src/server');
test('native bearer sessions and the extra mobile fixtures', async () => {
  const server = app.listen(0, '127.0.0.1');
  await new Promise(r => server.once('listening', r));
  const base = `http://127.0.0.1:${server.address().port}`;
  try {
    const login = await fetch(base + '/demo/login', {method: 'POST'});
    const {sessionToken} = await login.json();
    const headers = {Authorization: `Bearer ${sessionToken}`, 'Content-Type': 'application/json'};
    const get = (p, h = {}) => fetch(base + p, {headers: {...headers, ...h}});
    assert.equal((await get('/lab-api/notes/101')).status, 200);
    assert.equal((await get('/lab-api/partner')).status, 403);
    assert.equal((await get('/lab-api/partner', {'X-Partner-Key': 'fictional-partner-key-2026'})).status, 200);
    const insight = await fetch(base + '/lab-api/insights', {method: 'POST', headers, body: JSON.stringify({event: 'notebook_opened', email: 'fictional.alice@example.test', token: sessionToken})});
    assert((await insight.json()).flag);
    assert.equal((await (await get('/lab-api/transport')).json()).encrypted, false);
    assert.equal((await get('/lab-api/vault', {'X-App-Verified': 'true'})).status, 200);
    assert.equal((await get('/lab-api/vault')).status, 403);
    await fetch(base + '/demo/logout', {method: 'POST', headers});
    assert.equal((await get('/lab-api/notes/101')).status, 401);
  } finally { await new Promise(r => server.close(r)); }
});
