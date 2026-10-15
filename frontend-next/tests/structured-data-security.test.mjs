import test from 'node:test';
import assert from 'node:assert/strict';
import {serializeStructuredData} from '../lib/structured-data.ts';
test('merchant names cannot break out of a JSON-LD script',()=>{
 const data={'@type':'Store',name:'</script><script>alert(1)</script>',description:'Normal store data'};
 const text=serializeStructuredData(data);
 assert.ok(!text.includes('<'));assert.ok(!text.includes('</script>'));
 assert.deepEqual(JSON.parse(text),data);
});
