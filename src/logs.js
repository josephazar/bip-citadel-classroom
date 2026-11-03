module.exports=(req,res)=>{
 // C2: a production-style log response reveals a bearer credential and personal data.
 // C2: Diagnostic access reveals an email and a reusable bearer token.
 res.json({logs:['login: fictional.alice@example.test','session='+req.sessionToken,'debug=CLASSROOM{LOGS_ARE_DATA_STORES}']});
};
