const sharp=require('sharp');
const {imageContent}=require('./imagePolicy');
async function validateImage(file){
 if(!imageContent(file.buffer,file.originalname))return false;
 try{
  const decoder=sharp(file.buffer,{limitInputPixels:25000000,failOn:'warning'});
  const meta=await decoder.metadata();
  if(!meta.width||!meta.height||meta.pages>100)return false;
  await decoder.raw().toBuffer();
  return true;
 }catch{return false;}
}
module.exports={validateImage};
