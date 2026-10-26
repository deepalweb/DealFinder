const mongoose=require('mongoose');
module.exports=async(_req,res)=>{
 if(process.env.DATA_SOURCE==='postgres')return res.status(503).json({ready:false,provider:'postgres',reason:'Account workflows are not supported by this provider.'});
 if(mongoose.connection.readyState!==1)return res.status(503).json({ready:false,provider:'mongo'});
 let timer;
 try{
  await Promise.race([mongoose.connection.db.admin().ping(),new Promise((_,reject)=>{timer=setTimeout(()=>reject(new Error('timeout')),2000);timer.unref();})]);
  res.json({ready:true,provider:'mongo'});
 }catch{res.status(503).json({ready:false,provider:'mongo'});}
 finally{clearTimeout(timer);}
};
