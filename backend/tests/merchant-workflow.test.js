const {test,after}=require('node:test');
const assert=require('node:assert/strict');
const express=require('express');const jwt=require('jsonwebtoken');
const {pickDraft,validateOffer,promotionPayload,normalizePhone,httpUrl}=require('../utils/merchantWorkflow');
const {imageContent,uploadFolder,canDelete}=require('../utils/imagePolicy');
const Draft=require('../models/MerchantDraft');const User=require('../models/User');const Merchant=require('../models/Merchant');const Promotion=require('../models/Promotion');
const A='aaaaaaaaaaaaaaaaaaaaaaaa',B='bbbbbbbbbbbbbbbbbbbbbbbb',MA='111111111111111111111111',MB='222222222222222222222222';
const store={_id:MA,name:'Test Cafe',profile:'Local food',category:'food_dining',currency:'LKR',contactNumber:'+94771234567',merchantType:'offline',address:'Nugegoda',location:{coordinates:[79.9,6.86]},status:'active'};
const data={title:'Lunch sets',description:'One lunch set',discount:'25% off',category:'food_dining',startDate:'2099-01-01',endDate:'2099-01-02',fulfillmentType:'visit',originalPrice:'3200',discountedPrice:'2400',images:[],bankName:'',cardTypes:[]};
test('draft allowlist excludes ownership, privileges and account secrets',()=>{assert.deepEqual(pickDraft({title:'',merchant:MB,owner:B,status:'active',featured:true,adminVerified:true,token:'secret'}),{title:''});assert.throws(()=>pickDraft({images:Array(6).fill('x')}));assert.throws(()=>pickDraft({title:{html:'unsafe'}}));});
test('publication validates pricing, percentage, dates and conditional destinations',()=>{assert.deepEqual(validateOffer(data,store),{});assert.equal(validateOffer({...data,discount:'101% off'},store).discount,'percentage');assert.equal(validateOffer({...data,benefitType:'special',benefitValue:'3500',discount:'LKR 3500'},store).discountedPrice,'price');assert.equal(validateOffer({...data,discountedPrice:'3200'},store).discountedPrice,'percentagePrice');assert.equal(validateOffer({...data,endDate:'2020-01-01'},store).endDate,'date');assert.equal(validateOffer({...data,startDate:'2099-02-31',endDate:'2099-03-04'},store).startDate,'date');assert.equal(validateOffer({...data,fulfillmentType:'order',orderLink:'javascript:alert(1)'},store).orderLink,'url');assert.equal(validateOffer(data,{...store,location:null}).fulfillmentType,'storeLocation');assert.deepEqual(validateOffer({...data,fulfillmentType:'order',orderLink:'https://merchant.example/coupon'}, {...store,merchantType:'online',location:null}),{});});
test('bank conditions are paired and absent prices stay absent, caps remain caps',()=>{assert.equal(validateOffer({...data,bankName:'Bank'},store).cardTypes,'required');const p=promotionPayload({...data,discount:'Buy 1 get 1',originalPrice:null,discountedPrice:null,minimumSpend:'1000',maximumBenefit:'500'},store);assert.ok(!Object.hasOwn(p,'originalPrice'));assert.ok(!Object.hasOwn(p,'discountedPrice'));assert.equal(p.maximumBenefit,500);assert.equal(p.featured,false);assert.equal(p.adminVerified,false);assert.equal(p.status,'pending_review');assert.equal(p.startDate.toISOString(),'2098-12-31T18:30:00.000Z');assert.equal(p.endDate.toISOString(),'2099-01-02T18:29:59.999Z');});
test('image bytes and account namespaces reject spoofed uploads and foreign deletion',()=>{assert.equal(imageContent(Buffer.from('not an image'), 'offer.jpg'),false);assert.equal(imageContent(Buffer.from([255,216,255,224,0]),'offer.jpg'),true);assert.equal(imageContent(Buffer.from([255,216,255,224,0]),'offer.png'),false);const folder=uploadFolder({id:A},'../../merchants');assert.equal(folder,`u${A}-images`);assert.equal(canDelete({id:A,role:'merchant'},`https://images.test/u${A}-promotions/aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa.jpg`),true);assert.equal(canDelete({id:A,role:'merchant'},`https://images.test/u${B}-promotions/aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa.jpg`),false);assert.equal(canDelete({id:A,role:'merchant'},'https://images.test/promotions/legacy.jpg'),false);});
test('phone normalization and URL validation preserve international contacts',()=>{assert.equal(normalizePhone('077 123 4567'),'+94771234567');assert.equal(normalizePhone('+44 20 1234 5678'),'+442012345678');assert.equal(httpUrl('https://user:password@site.test'),false);assert.equal(httpUrl('https://site.test'),true);});
// Isolated HTTP integration harness. In-memory model doubles: no real database or jobs.
require('../models/SessionFamily').exists=async()=>true;
process.env.JWT_SECRET='merchant-workflow-unit-test-only';process.env.DATA_SOURCE='mongo';
const rows=[];const published=new Map();let seq=0;
const scope=(x,q)=>Object.entries(q).every(([k,v])=>typeof v==='object'&&v?.$exists!==undefined?(Object.hasOwn(x,k)===v.$exists):String(x[k])===String(v));
User.findById=id=>({select:async()=>({role:'merchant',merchantId:id===A?MA:MB})});
Merchant.findById=async id=>({...store,_id:id,name:id===MA?'Cafe A':'Cafe B'});Merchant.updateOne=async()=>({modifiedCount:1});
Draft.find=q=>({sort:()=>({lean:async()=>rows.filter(x=>scope(x,q))})});
Draft.findOne=async q=>rows.find(x=>scope(x,q))||null;
Draft.findOneAndUpdate=async(q,update)=>{let d=rows.find(x=>scope(x,q));if(!d){if(rows.some(x=>x.owner===q.owner&&x.clientKey===q.clientKey)){const e=new Error('Duplicate');e.code=11000;throw e;}d={owner:q.owner,merchant:q.merchant,clientKey:q.clientKey,_id:(++seq).toString(16).padStart(24,'0'),promotionId:(100+seq).toString(16).padStart(24,'0'),save:async()=>{},updatedAt:new Date()};rows.push(d);}d.data=update.$set.data;return d;};
Promotion.find=q=>({sort:()=>({lean:async()=>[...published.values()].filter(x=>String(x.merchant)===String(q.merchant))})});
Promotion.findOneAndUpdate=async(q,update)=>{if(!published.has(q._id))published.set(q._id,{_id:q._id,...update.$setOnInsert});return published.get(q._id);};
const app=express();app.use(express.json());app.use('/api/merchant-workspace',require('../routes/merchantWorkspaceRoutes'));const server=app.listen(0,'127.0.0.1');after(()=>server.close());
async function request(owner,path,method='GET',body){const url=`http://127.0.0.1:${server.address().port}/api/merchant-workspace${path}`;return fetch(url,{method,headers:{'Content-Type':'application/json',Authorization:'Bearer '+jwt.sign({id:owner,sid:'fixture-session',tokenVersion:0,role:'merchant',merchantId:owner===A?MA:MB},process.env.JWT_SECRET)},...(body?{body:JSON.stringify(body)}:{})});}
test('HTTP draft isolation, incomplete persistence, publication checks and idempotent review submission',async()=>{
 let r=await request(A,'/drafts/lunch','PUT',{data:{title:'Unfinished',featured:true}});assert.equal(r.status,200);const d=await r.json();assert.equal(d.owner,A);assert.equal(d.data.featured,undefined);
 assert.equal((await request(B,'/drafts/'+d._id)).status,404);
 assert.equal((await request(B,'/drafts/'+d._id+'/submit','POST')).status,404);
 assert.equal((await request(A,'/drafts/'+d._id+'/submit','POST')).status,400);
 r=await request(A,'/drafts/lunch','PUT',{data});assert.equal(r.status,200);
 const result=await Promise.all([request(A,'/drafts/'+d._id+'/submit','POST'),request(A,'/drafts/'+d._id+'/submit','POST')]);assert.ok(result.every(x=>x.status===200));assert.equal(published.size,1);assert.equal([...published.values()][0].status,'pending_review');assert.equal([...published.values()][0].merchant,MA);
 assert.equal((await request(A,'/drafts/lunch','PUT',{data})).status,409);
 assert.equal((await (await request(B,'/')).json()).drafts.length,0);
 const w=await (await request(A,'/')).json();assert.equal(w.drafts.length,0);assert.equal(w.promotions.length,1);
});

const {authenticateJWT,authorizeMerchantSelfOrAdmin}=require('../middleware/auth');
app.put('/merchant/:id',authenticateJWT,authorizeMerchantSelfOrAdmin,(_req,res)=>res.json({accepted:true}));
test('profile authorization uses linked account ownership, not a stale/forged merchant claim',async()=>{
 const call=(merchant,role='merchant')=>fetch(`http://127.0.0.1:${server.address().port}/merchant/${merchant}`,{method:'PUT',headers:{Authorization:'Bearer '+jwt.sign({id:A,sid:'fixture-session',tokenVersion:0,role,merchantId:MB},process.env.JWT_SECRET)}});
 assert.equal((await call(MB)).status,403);assert.equal((await call(MA)).status,200);assert.equal((await call(MA,'user')).status,403);
});

test('actual Mongoose schema casts the submitted consumer fields without dropping them',async()=>{
 const submitted=promotionPayload({...data,benefitType:'percentage',benefitValue:'25',bankName:'Test Bank',cardTypes:['credit'],termsAndConditions:'Fridays. Show the card.'},store);
 const document=new Promotion(submitted);await document.validate();const row=document.toObject();assert.equal(row.benefitValue,25);assert.equal(row.discountedPrice,2400);assert.equal(row.bankName,'Test Bank');assert.equal(row.termsAndConditions,'Fridays. Show the card.');assert.equal(row.status,'pending_review');
 const draft=new Draft({owner:A,merchant:MA,clientKey:'incomplete',data:{title:''}});await draft.validate();assert.equal(draft.data.title,'');assert.ok(draft.promotionId);
});
