const test=require('node:test'),assert=require('node:assert/strict');
const {sanitizeAiFilters}=require('../services/ai/queryUnderstandingService');
test('AI filters cap numbers and reject unsupported categories, sorts and coercive flags',()=>{
 const out=sanitizeAiFilters({filters:{categories:['unknown','food_dining'],sortBy:'$where',minDiscountPercent:1000,radiusKm:9999,featuredOnly:'false'},intent:{wantsNearby:'false'}});
 assert.deepEqual(out.filters.categories,['food_dining']);assert.equal(out.filters.sortBy,'relevance');
 assert.equal(out.filters.minDiscountPercent,100);assert.equal(out.filters.radiusKm,100);
 assert.equal(out.filters.featuredOnly,false);assert.equal(out.intent.wantsNearby,false);
});
