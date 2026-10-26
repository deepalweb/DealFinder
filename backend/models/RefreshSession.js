const mongoose=require('mongoose');
const schema=new mongoose.Schema({
 user:{type:mongoose.Schema.Types.ObjectId,ref:'User',required:true,index:true},
 family:{type:String,required:true,index:true},tokenHash:{type:String,required:true,unique:true},
 expiresAt:{type:Date,required:true,index:{expires:0}},revokedAt:Date,
 tokenVersion:{type:Number,default:0}
},{timestamps:true});
module.exports=mongoose.model('RefreshSession',schema);
