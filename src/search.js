const initSqlJs=require('sql.js');
const SQL=initSqlJs();
module.exports=async(req,res)=>{
 const q=String(req.query.q||'').slice(0,160);
 // Resource bound, not an injection defense: the OR demonstration remains possible.
 if(!/^[a-zA-Z0-9 _%"'=!\-]*$/.test(q)||/\b(join|with|union|pragma|attach|insert|update|delete|drop|alter|create)\b/i.test(q))return res.status(400).json({error:'This lab accepts simple title searches and OR demonstrations only.'});
 const db=new (await SQL).Database();
 try{
  db.run('CREATE TABLE notes(owner TEXT,title TEXT,body TEXT)');
  db.run("INSERT INTO notes VALUES ('alice','Shopping','My groceries'),('bob','Archive','CLASSROOM{DATA_BECAME_SQL}')");
  // C5: client text becomes part of the SQL statement.
  // C5: Input becomes SQL syntax; an OR payload bypasses the owner filter.
  // Bound parameters would keep the search text as data.
  const query=`SELECT * FROM notes WHERE owner = '${req.user.id}' AND title LIKE '%${q}%'`;
  const stmt=db.prepare(query),rows=[];
  while(stmt.step()&&rows.length<10)rows.push(stmt.getAsObject());stmt.free();
  res.json({query,rows});
 }catch{res.status(400).json({error:'SQL syntax error.'});}finally{db.close();}
};
