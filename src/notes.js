const notes={101:{id:101,owner:'alice',title:'My shopping',body:'Buy a stronger gate.'},102:{id:102,owner:'bob',title:'Private archive',body:'CLASSROOM{AN_ID_IS_NOT_AUTHORITY}'}};
module.exports=(req,res)=>{
 // C3: the identifier is checked, but the authenticated owner is not.
 const note=notes[req.params.id];
 if(!note)return res.status(404).json({error:'Note not found.'});
 // C3: No owner check: Alice can request Bob's note by changing the ID.
 res.json(note);
};
