module.exports=(req,res)=>{
 // C4: an arbitrary request header chooses the trusted role.
 // C4: The caller controls this header; the server must determine roles.
 const role=req.get('X-Lab-Role')||'user';
 if(role!=='admin')return res.status(403).json({error:'Admin only.'});
 res.json({users:['fictional-alice','fictional-bob'],flag:'CLASSROOM{A_HEADER_IS_NOT_A_ROLE}'});
};
