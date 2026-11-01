(function () {
  var out = document.getElementById('out'), pw = document.getElementById('pw');
  function show(text, bad) { out.textContent = text; out.className = bad ? 'err' : ''; }
  function call(path) {
    return fetch(path, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ password: pw.value }) })
      .then(function (r) { return r.json().then(function (d) { return { status: r.status, data: d }; }); });
  }
  document.getElementById('check').addEventListener('click', function () {
    call('/teacher/status').then(function (x) {
      if (x.status !== 200) return show(x.data.error || 'Request failed.', true);
      show('Active demo sessions: ' + x.data.sessions + (x.data.lastReset ? '. Last reset: ' + new Date(x.data.lastReset).toLocaleTimeString() + '.' : '. No reset yet since the server started.'));
    }).catch(function () { show('Could not reach the server.', true); });
  });
  document.getElementById('reset').addEventListener('click', function () {
    if (!window.confirm('Sign out every student now?')) return;
    call('/teacher/reset').then(function (x) {
      if (x.status !== 200) return show(x.data.error || 'Request failed.', true);
      show('Done. ' + x.data.cleared + ' session(s) cleared at ' + new Date(x.data.lastReset).toLocaleTimeString() + '. Students: click Load demo as Alice again.');
    }).catch(function () { show('Could not reach the server.', true); });
  });
})();
