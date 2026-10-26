const mongoose=require('mongoose');
module.exports=mongoose.model('SessionFamily',new mongoose.Schema({
 _id:{type:String},user:{type:mongoose.Schema.Types.ObjectId,ref:'User',required:true,index:true},
 revokedAt:Date,expiresAt:{type:Date,required:true,index:{expires:0}}
},{timestamps:true}));
