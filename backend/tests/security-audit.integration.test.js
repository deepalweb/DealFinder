// Never import server.js or dotenv: only an ephemeral loopback MongoDB is allowed.
const {test,before,after}=require('node:test');
const assert=require('node:assert/strict');
process.env.NODE_ENV='test';process.env.DATA_SOURCE='mongo';process.env.DATABASE_URL='';
process.env.JWT_SECRET='isolated-audit-access-signing-secret';process.env.JWT_REFRESH_SECRET='isolated-audit-refresh-signing-secret';
process.env.IMAGE_STORAGE_PROVIDER='local';
const mongoose=require('mongoose'),express=require('express'),jwt=require('jsonwebtoken'),bcrypt=require('bcryptjs'),crypto=require('crypto');
const {MongoMemoryServer}=require('mongodb-memory-server');
let providerIdentity={email:'firebase@audit.test',uid:'public-fixture-uid',name:'Fixture',email_verified:true};
const firebasePath=require.resolve('../services/firebaseAdmin');
require.cache[firebasePath]={id:firebasePath,filename:firebasePath,loaded:true,exports:{ensureFirebaseAdminInitialized:()=>true,
 admin:{auth:()=>({verifyIdToken:async()=>providerIdentity,revokeRefreshTokens:async(uid)=>{firebaseRevoked.push(uid);}})}}};
const firebaseRevoked=[];
let writes=0;
const storagePath=require.resolve('../services/imageStorage');
require.cache[storagePath]={id:storagePath,filename:storagePath,loaded:true,exports:{isConfigured:()=>true,
 uploadImage:async()=>{writes++;return 'https://images.audit.test/fixture.png';},deleteImage:async()=>{writes++;}}};
const User=require('../models/User'),Merchant=require('../models/Merchant'),Promotion=require('../models/Promotion'),Redemption=require('../models/Redemption'),Click=require('../models/PromotionClick');
let mongo,server,base,A,B,MA,MB,P,accessA,accessB;
const sign=(user,extra={})=>jwt.sign({id:String(user._id),role:user.role,merchantId:String(user.merchantId||''),tokenVersion:user.tokenVersion||0,sid:String(user._id),...extra},process.env.JWT_SECRET,{expiresIn:'10m'});
async function request(path,{token,method='GET',body}={}){return fetch(base+path,{method,headers:{'Content-Type':'application/json',...(token?{Authorization:'Bearer '+token}:{})},...(body?{body:JSON.stringify(body)}:{})});}
before(async()=>{
 mongo=await MongoMemoryServer.create({instance:{ip:'127.0.0.1',dbName:'dealfinder_isolated_audit'}});
 const uri=mongo.getUri();assert.match(uri,/^mongodb:\/\/127\.0\.0\.1:/);
 await mongoose.connect(uri,{dbName:'dealfinder_isolated_audit'});
 MA=await Merchant.create({name:'Audit Store A',location:{type:'Point',coordinates:[79.85,6.91]}});
 MB=await Merchant.create({name:'Audit Store B',location:{type:'Point',coordinates:[79.86,6.91]}});
 A=await User.create({name:'A',email:'a@audit.test',password:await bcrypt.hash('audit-password-123',10),role:'merchant',merchantId:MA._id});
 B=await User.create({name:'B',email:'b@audit.test',password:await bcrypt.hash('audit-password-456',10),role:'merchant',merchantId:MB._id});
 P=await Promotion.create({title:'Audit offer',description:'Fixture',discount:'25% off',category:'food_dining',merchant:MB._id,startDate:new Date(Date.now()-86400000),endDate:new Date(Date.now()+86400000),status:'active'});
 await Promise.all([User.init(),Merchant.init(),Promotion.init(),Redemption.init()]);
 const app=express();app.use(express.json());
 app.use('/users',require('../routes/userRoutes'));app.use('/promotions',require('../routes/promotionRoutes'));app.use('/images',require('../routes/imageRoutes'));app.use('/bank-offers',require('../routes/bankOfferRoutes'));app.get('/ready',require('../middleware/readiness'));app.use('/merchants',require('../routes/merchantRoutes'));
 app.use('/notifications',require('../routes/notificationRoutes'));app.use('/ai',require('../routes/aiRoutes'));
 server=await new Promise(resolve=>{const s=app.listen(0,'127.0.0.1',()=>resolve(s));});base=`http://127.0.0.1:${server.address().port}`;
 await require('../models/SessionFamily').create([A,B].map(user=>({_id:String(user._id),user:user._id,expiresAt:new Date(Date.now()+600000)})));
 accessA=sign(A);accessB=sign(B);
});
after(async()=>{if(server)await new Promise(r=>server.close(r));await mongoose.disconnect();if(mongo)await mongo.stop();});
test('P0 Firebase UID is not a usable password',async()=>{
 assert.equal((await request('/users/firebase-auth',{method:'POST',body:{idToken:'isolated-fake-provider-token'}})).status,200);
 assert.equal((await request('/users/login',{method:'POST',body:{email:'firebase@audit.test',password:'public-fixture-uid'}})).status,401);
});
test('P0 self profile never exposes reset secrets',async()=>{
 await User.updateOne({_id:A._id},{$set:{resetPasswordToken:'fixture-secret',resetPasswordExpires:new Date(Date.now()+60000)}});
 const r=await request('/users/'+A._id,{token:accessA});assert.equal(r.status,200);
 const data=await r.json();assert.equal(data.resetPasswordToken,undefined);assert.equal(data.resetPasswordExpires,undefined);
});
test('P0 ownership uses current account link rather than token merchant claim',async()=>{
 const r=await request('/promotions/'+P._id,{method:'PUT',token:sign(A,{merchantId:String(MB._id)}),body:{title:'Cross-owner update'}});
 assert.equal(r.status,403);
});
test('P0 truncated image signature is rejected before storage',async()=>{
 const form=new FormData();form.append('image',new Blob([Buffer.from([255,216,255,224,0])]),'spoof.jpg');const previous=writes;
 const r=await fetch(base+'/images/upload',{method:'POST',headers:{Authorization:'Bearer '+accessA},body:form});
 assert.equal(r.status,400);assert.equal(writes,previous);
});
test('P0 public discovery excludes unapproved records',async()=>{
 const draft={...P.toObject(),_id:new mongoose.Types.ObjectId(),title:'Private pending offer',status:'pending_approval'};
 await Promotion.collection.insertOne(draft);
 const r=await request('/promotions?limit=100');assert.equal(r.status,200);
 assert.ok(!(await r.json()).some(p=>p.title===draft.title));
});
test('P1 category input is literal and invalid geographic ranges are rejected',async()=>{
 assert.equal((await request('/promotions?category=%5B')).status,200);
 assert.equal((await request('/promotions/nearby?latitude=95&longitude=79')).status,400);
});
test('P1 anonymous clicks cannot forge redemptions or user identity',async()=>{
 const r=await request('/promotions/'+P._id+'/click',{method:'POST',body:{type:'redeem',userId:String(B._id)}});assert.equal(r.status,400);
});
test('P1 a cancelled entitlement cannot be redeemed',async()=>{
 const row=await Redemption.create({promotion:P._id,merchant:MB._id,user:A._id,token:crypto.randomBytes(24).toString('hex'),status:'cancelled',expiresAt:new Date(Date.now()+60000)});
 const r=await request('/promotions/redemptions/redeem',{method:'POST',token:accessB,body:{token:row.token}});assert.equal(r.status,409);
});
test('P1 simultaneous redemption succeeds once with one audit event',async()=>{
 const row=await Redemption.create({promotion:P._id,merchant:MB._id,user:A._id,token:crypto.randomBytes(24).toString('hex'),expiresAt:new Date(Date.now()+60000)});
 const responses=await Promise.all(Array.from({length:8},()=>request('/promotions/redemptions/redeem',{method:'POST',token:accessB,body:{token:row.token}})));
 assert.equal(responses.filter(r=>r.status===200).length,1);assert.equal(responses.filter(r=>r.status===409).length,7);
 assert.equal(await Click.countDocuments({promotion:P._id,type:'redeem'}),1);
});

test('P1 combined filters run before stable pagination and online offers have no physical distance',async()=>{
 for(let i=0;i<4;i++)await Promotion.create({title:'Combined '+i,description:'Fixture',discount:'20% off',category:i<2?'food_dining':'electronics',
  merchant:MA._id,startDate:new Date(Date.now()-60000),endDate:new Date(Date.now()+600000),status:'active',bankName:'Audit Bank',cardTypes:['credit'],deliveryAvailable:true,discountedPrice:1000});
 const query='/promotions?category=food_dining&bankName=Audit%20Bank&cardType=credit&fulfillment=delivery&latitude=6.91&longitude=79.85&radiusKm=3&limit=1&sortBy=price_low';
 let r=await request(query);assert.equal(r.status,200);assert.equal(r.headers.get('X-Total-Count'),'2');const first=await r.json();
 r=await request(query+'&skip=1');const second=await r.json();assert.equal(first.length,1);assert.equal(second.length,1);assert.notEqual(first[0]._id,second[0]._id);
 const online=await Promotion.create({title:'Online only',description:'Fixture',discount:'20% off',category:'shopping_retail',merchant:MA._id,
  startDate:new Date(Date.now()-60000),endDate:new Date(Date.now()+600000),status:'active',fulfillmentType:'order'});
 r=await request('/promotions?fulfillment=online&latitude=6.91&longitude=79.85');const rows=await r.json();
 assert.equal(rows.find(p=>p._id===String(online._id)).distanceKm,undefined);
 r=await request('/promotions/nearby?latitude=6.91&longitude=79.85&radius=3');assert.ok(!(await r.json()).some(p=>p._id===String(online._id)));
 assert.equal((await request('/promotions?limit=99999')).status,400);
});
test('P0 a malformed or foreign image never reaches storage; decoded PNG does',async()=>{
 const sharp=require('sharp');const buffer=await sharp({create:{width:2,height:2,channels:4,background:'#007b59'}}).png().toBuffer();
 const form=new FormData();form.append('image',new Blob([buffer]),'offer.png');
 const r=await fetch(base+'/images/upload',{method:'POST',headers:{Authorization:'Bearer '+accessA},body:form});assert.equal(r.status,200);
 const previous=writes;const bad=await request('/images/delete',{method:'DELETE',token:accessA,body:{imageUrl:`https://images.audit.test/u${B._id}-images/aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa.png`}});
 assert.equal(bad.status,403);assert.equal(writes,previous);
});
test('P1 sessions survive a new process, rotate and reject reused refresh tokens',async()=>{
 const sessions=require('../services/sessionService');const pair=await sessions.issue(A);
 const child=require('node:child_process');
 const script=`(async()=>{const m=require('mongoose');await m.connect(process.env.AUDIT_URI);const r=await require('./services/sessionService').rotate(process.env.AUDIT_TOKEN);process.stdout.write(JSON.stringify(r));await m.disconnect();})().catch(()=>process.exit(1))`;
 const result=JSON.parse(child.execFileSync(process.execPath,['-e',script],{cwd:require('node:path').resolve(__dirname,'..'),env:{...process.env,AUDIT_URI:mongo.getUri('dealfinder_isolated_audit'),AUDIT_TOKEN:pair.refreshToken},encoding:'utf8'}));
 assert.ok(result.token);assert.notEqual(result.refreshToken,pair.refreshToken);
 assert.equal(await sessions.rotate(pair.refreshToken),null);assert.equal(await sessions.rotate(result.refreshToken),null);
});
test('P1 logout revokes both access and refresh session without removing other sessions',async()=>{
 const sessions=require('../services/sessionService');const pair=await sessions.issue(A),other=await sessions.issue(A);
 assert.equal((await request('/users/logout',{method:'POST',token:pair.token,body:{refreshToken:pair.refreshToken}})).status,200);
 assert.equal((await request('/users/'+A._id,{token:pair.token})).status,403);
 assert.equal(await sessions.rotate(pair.refreshToken),null);
 assert.equal((await request('/users/'+A._id,{token:other.token})).status,200);
});
test('P0 reset tokens are hashed, expire, and have one atomic consumer',async()=>{
 const sessions=require('../services/sessionService');const raw=crypto.randomBytes(32).toString('hex');
 const user=await User.create({name:'Reset',email:'reset@audit.test',password:await bcrypt.hash('previous-password',10),resetPasswordToken:sessions.hash(raw),resetPasswordExpires:new Date(Date.now()+60000)});
 const pair=await sessions.issue(user);
 const replies=await Promise.all(Array.from({length:4},()=>request('/users/reset-password/confirm',{method:'POST',body:{token:raw,password:'replacement-password'}})));
 assert.equal(replies.filter(r=>r.status===200).length,1);assert.equal(replies.filter(r=>r.status===400).length,3);
 assert.equal((await request('/users/'+user._id,{token:pair.token})).status,403);assert.equal(await sessions.rotate(pair.refreshToken),null);
 await User.updateOne({_id:user._id},{$set:{resetPasswordToken:sessions.hash(raw),resetPasswordExpires:new Date(Date.now()-1)}});
 assert.equal((await request('/users/reset-password/confirm',{method:'POST',body:{token:raw,password:'replacement-password'}})).status,400);
});
test('P1 concurrent issuance returns one active entitlement and rejects a draft',async()=>{
 const replies=await Promise.all(Array.from({length:8},()=>request('/promotions/'+P._id+'/redemptions',{method:'POST',token:accessA,body:{}})));
 const payloads=await Promise.all(replies.map(async r=>{assert.ok([200,201].includes(r.status));return r.json();}));
 assert.equal(new Set(payloads.map(p=>p.token)).size,1);
 const draft=await Promotion.create({title:'Private draft',description:'Fixture',discount:'20% off',category:'food_dining',merchant:MA._id,startDate:new Date(Date.now()-60000),endDate:new Date(Date.now()+60000),status:'draft'});
 assert.equal((await request('/promotions/'+draft._id+'/redemptions',{method:'POST',token:accessA,body:{}})).status,400);
});

test('P0 public ratings do not expose account email or credential fields',async()=>{
 await Promotion.updateOne({_id:P._id},{$push:{ratings:{user:A._id,value:5}}});
 const r=await request('/promotions/'+P._id+'/ratings');assert.equal(r.status,200);
 const text=await r.text();assert.ok(!text.includes(A.email));assert.ok(!text.includes('password'));
});
test('P0 private promotion subresources do not bypass detail authorization',async()=>{
 const id=(await Promotion.findOne({title:'Private draft'}))._id;
 for(const suffix of ['', '/comments','/ratings','/stats','/redemption-feedback'])
  assert.equal((await request('/promotions/'+id+suffix)).status,404);
});
test('P1 bank resource shape stays separate from promotion favorites and analytics',async()=>{
 const Bank=require('../models/BankOffer');const bank=await Bank.create({title:'Audit bank offer',description:'Fixture',discount:'10% off',code:'FIXTURE',
  bankName:'Audit Bank',cardTypes:['credit'],offerType:'discount',startDate:new Date(Date.now()-60000),endDate:new Date(Date.now()+600000),status:'active'});
 const r=await request('/bank-offers/'+bank._id);assert.equal(r.status,200);assert.equal((await r.json()).bankName,'Audit Bank');
 assert.equal((await request('/promotions/'+bank._id)).status,404);
 assert.equal((await request('/users/'+A._id+'/favorites',{method:'POST',token:accessA,body:{promotionId:String(bank._id)}})).status,404);
});
test('P1 invalid pricing and reversed validity fail schema validation',async()=>{
 const data={...P.toObject(),_id:new mongoose.Types.ObjectId()};
 await assert.rejects(new Promotion({...data,originalPrice:-1}).validate());
 await assert.rejects(new Promotion({...data,originalPrice:1000,discountedPrice:1500}).validate());
 await assert.rejects(new Promotion({...data,discount:'150% off'}).validate());
 await assert.rejects(new Promotion({...data,startDate:new Date(Date.now()+86400000),endDate:new Date()}).validate());
});
test('P0 reset email transport receives the raw token but storage and responses do not',async()=>{
 let delivered;const mailPath=require.resolve('../mailer');require.cache[mailPath]={id:mailPath,filename:mailPath,loaded:true,exports:{sendMail:async mail=>{delivered=mail;}}};
 process.env.M365_EMAIL='mailer@audit.test';process.env.M365_PASSWORD='fixture-not-real';
 try{
  const r=await request('/users/reset-password',{method:'POST',body:{email:A.email}});assert.equal(r.status,200);
  const response=await r.text();const raw=new URL(delivered.text.split('password: ')[1]).searchParams.get('token');
  const user=await User.findById(A._id).select('+resetPasswordToken +resetPasswordExpires');
  assert.equal(user.resetPasswordToken,require('../services/sessionService').hash(raw));assert.ok(!response.includes(raw));
  assert.ok(user.resetPasswordExpires.getTime()>Date.now());
 }finally{delete process.env.M365_EMAIL;delete process.env.M365_PASSWORD;}
});
test('P1 selected-provider gaps fail explicitly instead of switching databases',async()=>{
 process.env.DATA_SOURCE='postgres';try{
  assert.equal((await request('/users/login',{method:'POST',body:{email:A.email,password:'audit-password-123'}})).status,503);
  assert.equal((await request('/promotions?radiusKm=3&latitude=6.91&longitude=79.85')).status,501);
  assert.equal((await request('/ready')).status,503);
 }finally{process.env.DATA_SOURCE='mongo';}
 assert.equal((await request('/ready')).status,200);
});

test('P0 unpublished bank offers are not available through public detail IDs',async()=>{
 const Bank=require('../models/BankOffer');const b=await Bank.create({title:'Private bank draft',description:'Fixture',discount:'20% off',code:'PRIVATE',
  bankName:'Audit Bank',cardTypes:['credit'],offerType:'discount',startDate:new Date(),endDate:new Date(Date.now()+600000),status:'draft'});
 assert.equal((await request('/bank-offers/'+b._id)).status,404);
 const r=await request('/bank-offers?bankName=Audit%20Bank&cardType=debit');assert.equal(r.status,200);assert.deepEqual(await r.json(),[]);
});

test('P0 matching a public store contact never grants ownership',async()=>{
 const orphan=await Merchant.create({name:'Legacy unclaimed fixture',contactInfo:'orphan@audit.test'});
 let r=await request('/users/register',{method:'POST',body:{name:'New merchant',email:'orphan@audit.test',password:'fixture-password-123',role:'merchant'}});assert.equal(r.status,201);
 r=await request('/users/login',{method:'POST',body:{email:'orphan@audit.test',password:'fixture-password-123'}});assert.equal(r.status,200);
 const data=await r.json();assert.notEqual(String(data.merchantId),String(orphan._id));
});
test('P0 verified provider sign-in repairs a historical UID-derived password',async()=>{
 await User.deleteOne({email:'firebase@audit.test'});
 const user=await User.create({name:'Legacy Firebase',email:'firebase@audit.test',password:await bcrypt.hash('public-fixture-uid',10)});
 assert.equal((await request('/users/firebase-auth',{method:'POST',body:{idToken:'isolated-fake-provider-token'}})).status,200);
 assert.equal((await request('/users/login',{method:'POST',body:{email:user.email,password:'public-fixture-uid'}})).status,401);
});
test('P1 password change revokes existing access and refresh sessions',async()=>{
 const user=await User.create({name:'Password',email:'password@audit.test',password:await bcrypt.hash('previous-password',10)});
 const sessions=require('../services/sessionService'),pair=await sessions.issue(user);
 const r=await request('/users/'+user._id+'/change-password',{method:'POST',token:pair.token,body:{currentPassword:'previous-password',newPassword:'replacement-password'}});assert.equal(r.status,200);
 assert.equal((await request('/users/'+user._id,{token:pair.token})).status,403);assert.equal(await sessions.rotate(pair.refreshToken),null);
});

test('P1 editing published merchant terms requires a fresh review and clears verification',async()=>{
 const offer=await Promotion.create({title:'Editable',description:'Fixture',discount:'20% off',category:'food_dining',merchant:MA._id,
 startDate:new Date(Date.now()-60000),endDate:new Date(Date.now()+600000),status:'active',adminVerified:true});
 const r=await request('/promotions/'+offer._id,{method:'PUT',token:accessA,body:{title:'Changed terms',bankName:'Audit Bank',cardTypes:['credit']}});
 assert.equal(r.status,200);const data=await r.json();assert.equal(data.status,'pending_review');assert.equal(data.adminVerified,false);
 assert.equal((await request('/promotions/'+offer._id)).status,404);
});

test('P1 pending stores are visible to their owner but absent from public directory and details',async()=>{
 const store=await Merchant.create({name:'Pending fixture store',status:'pending_approval'});
 const account=await User.create({name:'Pending owner',email:'pending@audit.test',password:await bcrypt.hash('fixture-password',10),role:'merchant',merchantId:store._id});
 const pair=await require('../services/sessionService').issue(account);
 assert.equal((await request('/merchants/'+store._id)).status,404);
 assert.equal((await request('/merchants/'+store._id,{token:pair.token})).status,200);
 const r=await request('/merchants');assert.ok(!(await r.json()).some(m=>m._id===String(store._id)));
});

test('P0 unverified provider identity cannot link an existing email account',async()=>{
 const previous=providerIdentity;providerIdentity={email:A.email,uid:'unverified-fixture-uid',name:'Fixture',email_verified:false};
 try {assert.equal((await request('/users/firebase-auth',{method:'POST',body:{idToken:'isolated-fake-provider-token'}})).status,401);}
 finally{providerIdentity=previous;}
});
test('P0 current roles and ownership protect user, merchant, bank and redemption actions',async()=>{
 assert.equal((await request('/users/'+B._id,{token:accessA})).status,403);
 assert.equal((await request('/merchants/'+MB._id,{method:'PUT',token:accessA,body:{name:'Not mine'}})).status,403);
 assert.equal((await request('/promotions/'+P._id,{method:'DELETE',token:accessA})).status,403);
 assert.equal((await request('/bank-offers',{method:'POST',token:accessA,body:{}})).status,403);
 assert.equal((await request('/bank-offers/admin',{token:sign(A,{role:'admin'})})).status,403);
 const row=await Redemption.findOne({merchant:MB._id});
 assert.equal((await request('/promotions/redemptions/verify',{method:'POST',token:accessA,body:{token:row.token}})).status,403);
});

// --- Round 2: notifications, analytics, private store fields, store visibility, input bounds ---
test('P0 notification preferences cannot reassign ownership or inject delivery channels',async()=>{
 const Pref=require('../models/NotificationPreference');
 const r=await request('/notifications/preferences',{method:'PUT',token:accessA,body:{userId:String(B._id),channels:{web:{subscription:{endpoint:'http://127.0.0.1:9/x'}}},preferences:{flashSales:{enabled:false}}}});
 assert.equal(r.status,200);
 assert.equal(await Pref.exists({userId:B._id}),null);
 const mine=await Pref.findOne({userId:A._id}).lean();
 assert.equal(mine.channels?.web?.subscription,undefined);assert.equal(mine.preferences.flashSales.enabled,false);
});
test('P1 push subscriptions must target a known push service over HTTPS',async()=>{
 const keys={p256dh:'BAudit',auth:'audit'};
 assert.equal((await request('/notifications/subscribe',{method:'POST',token:accessA,body:{subscription:{endpoint:'http://169.254.169.254/latest',keys}}})).status,400);
 assert.equal((await request('/notifications/subscribe',{method:'POST',token:accessA,body:{subscription:{endpoint:'https://fcm.googleapis.com.evil.test/x',keys}}})).status,400);
 assert.equal((await request('/notifications/subscribe',{method:'POST',token:accessA,body:{subscription:{endpoint:'https://fcm.googleapis.com/fcm/send/audit',keys}}})).status,200);
 assert.equal((await request('/notifications/subscribe',{method:'POST',token:accessA,body:{type:'push',subscription:{token:'x'}}})).status,400);
});
test('P2 expired web push subscriptions are removed after the push service rejects them',async()=>{
 const Pref=require('../models/NotificationPreference'),webpush=require('web-push'),service=require('../services/NotificationService');
 const prefs=await Pref.findOneAndUpdate({userId:A._id},{$set:{'channels.web.enabled':true,'channels.web.subscription':{endpoint:'https://fcm.googleapis.com/fcm/send/gone'}}},{new:true});
 const original=webpush.sendNotification;webpush.sendNotification=async()=>{throw Object.assign(new Error('Gone'),{statusCode:410});};
 try{await service._sendWebPushNotification(prefs,'t','b',{},{status:{web:{}}});}finally{webpush.sendNotification=original;}
 const after=await Pref.findById(prefs._id).lean();assert.equal(after.channels.web.subscription,undefined);assert.equal(after.channels.web.enabled,false);
});
test('P0 merchant analytics never expose customer account fields and work for the owner',async()=>{
 await User.updateOne({_id:A._id},{$set:{pushSubscription:{endpoint:'https://fcm.googleapis.com/fcm/send/private'}}});
 await Click.create({promotion:P._id,merchant:MB._id,user:A._id,type:'click'});
 for(const path of ['/promotions/'+P._id+'/analytics','/promotions/analytics/merchant/'+MB._id]){
  const r=await request(path,{token:accessB});assert.equal(r.status,200,path);
  const text=await r.text();assert.ok(!text.includes(A.email)&&!text.includes('pushSubscription')&&!text.includes('favorites'),path);
 }
});
test('P0 private store contact is absent from homepage, sections, favorites and followed stores',async()=>{
 await Merchant.updateOne({_id:MB._id},{$set:{contactInfo:'private-contact@audit.test',status:'active'}});
 await User.updateOne({_id:A._id},{$addToSet:{favorites:P._id,followingMerchants:MB._id}});
 await Promotion.updateOne({_id:P._id},{$set:{status:'active',startDate:new Date(Date.now()-86400000),endDate:new Date(Date.now()+86400000)}});
 for(const [path,token] of [['/promotions/sections/nearby?latitude=6.91&longitude=79.86&radius=5'],['/promotions/homepage'],['/promotions/sections'],['/users/'+A._id+'/favorites',accessA],['/users/'+A._id+'/following-merchants',accessA]]){
  const r=await request(path,{token});assert.equal(r.status,200,path);assert.ok(!(await r.text()).includes('private-contact@audit.test'),path);
 }
});
test('P1 offers from suspended or unapproved stores stay out of every public discovery surface',async()=>{
 const store=await Merchant.create({name:'Suspended discovery store',status:'suspended',location:{type:'Point',coordinates:[79.86,6.91]}});
 const offer=await Promotion.create({title:'Suspended store offer',description:'Fixture',discount:'30% off',category:'food_dining',merchant:store._id,
  startDate:new Date(Date.now()-60000),endDate:new Date(Date.now()+600000),status:'active'});
 await Promotion.collection.insertOne({title:'Pending suggestion offer',description:'Fixture',discount:'10% off',category:'food_dining',merchant:MA._id,startDate:new Date(Date.now()-60000),endDate:new Date(Date.now()+600000),status:'pending_approval'});
 require('../services/sectionService').invalidateSectionCaches();
 for(const path of ['/promotions/sections/nearby?latitude=6.91&longitude=79.86&radius=5','/promotions/recommended?limit=30','/promotions/sections']){
  const r=await request(path);assert.equal(r.status,200,path);assert.ok(!(await r.text()).includes(String(offer._id)),path);
 }
 let r=await request('/ai/search/suggestions?q=Suspended');assert.deepEqual((await r.json()).suggestions,[]);
 r=await request('/ai/search/suggestions?q=Pending%20suggestion');assert.deepEqual((await r.json()).suggestions,[]);
 r=await request('/ai/search',{method:'POST',body:{query:'Suspended store offer'}});assert.equal(r.status,200);assert.ok(!(await r.text()).includes(String(offer._id)));
});
test('P1 comments and reports are bounded strings',async()=>{
 assert.equal((await request('/promotions/'+P._id+'/comments',{method:'POST',token:accessA,body:{text:{$gt:''}}})).status,400);
 assert.equal((await request('/promotions/'+P._id+'/comments',{method:'POST',token:accessA,body:{text:'x'.repeat(1001)}})).status,400);
 assert.equal((await request('/promotions/'+P._id+'/comments',{method:'POST',token:accessA,body:{text:'Worked at the till'}})).status,201);
 assert.equal((await request('/promotions/'+P._id+'/reports',{method:'POST',token:accessA,body:{reason:'spam',description:'x'.repeat(2001)}})).status,400);
});
test('P1 an "up to" discount cap is not treated as a guaranteed saving',async()=>{
 const cap=await Promotion.create({title:'Cap fixture',description:'Fixture',discount:'Up to 60% off',category:'food_dining',merchant:MA._id,startDate:new Date(Date.now()-60000),endDate:new Date(Date.now()+600000),status:'active'});
 const flat=await Promotion.create({title:'Flat fixture',description:'Fixture',discount:'55% off',category:'food_dining',merchant:MA._id,startDate:new Date(Date.now()-60000),endDate:new Date(Date.now()+600000),status:'active'});
 const rows=await (await request('/promotions?minDiscount=50&limit=100')).json();
 assert.ok(rows.some(p=>p._id===String(flat._id)));assert.ok(!rows.some(p=>p._id===String(cap._id)));
});
test('P0 encoded or traversal image URLs are refused before storage deletion',async()=>{
 const previous=writes;
 for(const imageUrl of [`https://images.audit.test/other%2F..%2Fu${A._id}-images/aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa.png`,`https://images.audit.test/victim/../u${A._id}-images/aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa.png`]){
  assert.equal((await request('/images/delete',{method:'DELETE',token:accessA,body:{imageUrl}})).status,403,imageUrl);
 }
 assert.equal(writes,previous);
});

test('P0 people can delete their own account and its personal data',async()=>{
 const Pref=require('../models/NotificationPreference'),Alert=require('../models/DealAlert');
 const store=await Merchant.create({name:'Deleting owner store',status:'active'});
 const user=await User.create({name:'Leaving',email:'leaving@audit.test',password:await bcrypt.hash('fixture-password',10),role:'merchant',merchantId:store._id});
 const pair=await require('../services/sessionService').issue(user);
 await Pref.create({userId:user._id});await Alert.create({userId:user._id,promotion:P._id,alertTypes:['expiry']});
 await Promotion.updateOne({_id:P._id},{$push:{comments:{user:user._id,text:'Leaving soon'},ratings:{user:user._id,value:4}}});
 await Click.create({promotion:P._id,merchant:MB._id,user:user._id,type:'view'});
 const issued=await Redemption.create({promotion:P._id,merchant:MB._id,user:user._id,token:crypto.randomBytes(24).toString('hex'),expiresAt:new Date(Date.now()+60000)});
 assert.equal((await request('/users/me',{method:'DELETE'})).status,401);
 const r=await request('/users/me',{method:'DELETE',token:pair.token});assert.equal(r.status,200);
 assert.equal(await User.exists({_id:user._id}),null);
 assert.equal(await Pref.exists({userId:user._id}),null);assert.equal(await Alert.exists({userId:user._id}),null);
 const offer=await Promotion.findById(P._id).lean();
 assert.ok(!offer.comments.some(c=>String(c.user)===String(user._id))&&!offer.ratings.some(c=>String(c.user)===String(user._id)));
 assert.equal(await Click.exists({user:user._id}),null);
 assert.equal((await Redemption.findById(issued._id)).status,'cancelled');
 assert.equal((await Merchant.findById(store._id)).status,'suspended');
 assert.equal(await require('../services/sessionService').rotate(pair.refreshToken),null);
 assert.equal((await request('/users/'+A._id,{token:pair.token})).status,403);
 assert.equal(await User.exists({_id:A._id})!==null,true);
});
test('P1 the last administrator cannot delete their own account',async()=>{
 await User.deleteMany({role:'admin'});
 const admin=await User.create({name:'Only admin',email:'only-admin@audit.test',password:await bcrypt.hash('fixture-password',10),role:'admin'});
 const pair=await require('../services/sessionService').issue(admin);
 assert.equal((await request('/users/me',{method:'DELETE',token:pair.token})).status,409);
 assert.notEqual(await User.exists({_id:admin._id}),null);
});

// --- Sign-in round: Firebase sessions and merchant sign-up ---
test('P1 password change and account deletion also revoke Firebase sessions',async()=>{
 const user=await User.create({name:'Firebase owner',email:'firebase-owner@audit.test',firebaseUid:'firebase-owner-uid',password:await bcrypt.hash('previous-password',10)});
 const sessions=require('../services/sessionService');let pair=await sessions.issue(user);
 assert.equal((await request('/users/'+user._id+'/change-password',{method:'POST',token:pair.token,body:{currentPassword:'previous-password',newPassword:'replacement-password'}})).status,200);
 assert.ok(firebaseRevoked.includes('firebase-owner-uid'));
 firebaseRevoked.length=0;pair=await sessions.issue(await User.findById(user._id));
 assert.equal((await request('/users/me',{method:'DELETE',token:pair.token})).status,200);
 assert.ok(firebaseRevoked.includes('firebase-owner-uid'));
});
test('P2 merchant sign-up with a business name already in use gets its own pending store',async()=>{
 const previous=providerIdentity;
 try{
  providerIdentity={email:'second-store@audit.test',uid:'second-store-uid',name:'Second',email_verified:true};
  const r=await request('/users/firebase-auth',{method:'POST',body:{idToken:'fixture',role:'merchant',businessName:'Audit Store A'}});
  assert.equal(r.status,200);const data=await r.json();
  const store=await Merchant.findById(data.merchantId);
  assert.ok(store);assert.notEqual(String(store._id),String(MA._id));assert.equal(store.status,'pending_approval');
  assert.equal(await User.countDocuments({email:'second-store@audit.test'}),1);
 }finally{providerIdentity=previous;}
});
