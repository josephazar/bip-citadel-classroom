// Only fictional classroom fixtures. No requests are made to third-party services.
const express = require('express');
const router = express.Router();
const flags = {
  credential: 'CLASSROOM{APKS_ARE_NOT_SECRET_VAULTS}',
  dependency: 'CLASSROOM{REVIEW_THE_DEPENDENCY}',
  transport: 'CLASSROOM{TLS_IS_A_TRUST_BOUNDARY}',
  binary: 'CLASSROOM{A_PATCHED_UI_IS_NOT_AUTHORITY}',
};

router.get('/partner', (req, res) => {
  // C6 / M1: a privileged shared key is shipped inside the APK assets.
  if (req.get('X-Partner-Key') !== 'fictional-partner-key-2026') {
    return res.status(403).json({error: 'Partner key required.'});
  }
  res.json({report: 'Fictional partner-only archive', flag: flags.credential});
});

router.post('/insights', (req, res) => {
  // C7 / M2: the vendored SDK sends credentials to its collector.
  // This sink is the same classroom API, never a real external collector.
  const leaked = req.body.token === req.sessionToken && req.body.email === 'fictional.alice@example.test';
  res.json({received: Object.keys(req.body), flag: leaked ? flags.dependency : null});
});

router.get('/transport', (req, res) => {
  // C8 / M5: this endpoint accepts authenticated traffic over HTTP.
  res.json({encrypted: req.secure, message: 'Inspect the actual request protocol.', flag: flags.transport});
});

router.get('/vault', (req, res) => {
  // C9 / M7: a patchable client decision is treated as authorization.
  if (req.get('X-App-Verified') !== 'true') return res.status(403).json({error: 'Premium membership required.'});
  res.json({archive: 'Fictional premium notebook', flag: flags.binary});
});
module.exports = {router, flags};
