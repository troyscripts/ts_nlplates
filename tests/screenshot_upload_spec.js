'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const { EventEmitter } = require('node:events');
let upload;
const requests = [], timers = new Map();
let nextTimer = 0;
const fakeHttps = { request(url, options, callback) {
    const req = new EventEmitter();
    req.end = body => { req.body = body; };
    req.destroy = () => { req.destroyed = true; req.emit('close'); };
    req.reply = (status, data) => {
        const res = new EventEmitter(); res.statusCode = status;
        res.destroy = () => res.emit('aborted'); callback(res);
        res.emit('data', Buffer.from(data)); res.emit('end'); req.emit('close');
    };
    Object.assign(req, { url, options }); requests.push(req); return req;
} };
vm.runInNewContext(fs.readFileSync('server/screenshot_upload.js', 'utf8'), {
    require: name => name === 'https' ? fakeHttps : require(name),
    exports: (name, fn) => { assert.equal(name, 'UploadDiscordPhoto'); upload = fn; },
    Buffer, setImmediate: fn => fn(),
    setTimeout: fn => { const id = ++nextTimer; timers.set(id, fn); return id; },
    clearTimeout: id => timers.delete(id)
});
(async () => {
    const url = 'https://discord.com/api/webhooks/1/test_token';
    const jpeg = Buffer.concat([Buffer.from([255,216,255]), Buffer.from(Array.from({length:256}, (_,i) => i)), Buffer.from([255,217])]);
    const uri = 'data:image/jpeg;base64,' + jpeg.toString('base64');
    const payload = JSON.stringify({embeds:[{title:'Gijzeling — foto',fields:[]}],allowed_mentions:{parse:{}}});
    const outcomes = [];
    upload(url, payload, uri, (...args) => outcomes.push(args));
    const req = requests[0];
    assert.equal(req.url, url+'?wait=true'); assert.equal(req.options.method, 'POST');
    assert.equal(req.options.headers['Content-Length'], req.body.length);
    const form = await new Response(req.body, {headers:{'Content-Type':req.options.headers['Content-Type']}}).formData();
    const file = form.get('files[0]');
    assert.equal(file.name, 'screenshot.jpg');
    assert.deepEqual(Buffer.from(await file.arrayBuffer()), jpeg, 'all bytes including NUL must survive multipart parsing');
    const parsed = JSON.parse(form.get('payload_json'));
    assert.deepEqual(parsed.allowed_mentions.parse, []);
    assert.equal(parsed.embeds[0].title, 'Gijzeling — foto');
    assert.equal(parsed.embeds[0].image.url, 'attachment://screenshot.jpg');
    req.reply(200,'{"id":"123"}'); req.emit('error',new Error('late'));
    assert.deepEqual(outcomes, [[200,'{"id":"123"}']]); assert.equal(timers.size,0);
    upload(url,payload,uri,(...args)=>outcomes.push(args));
    requests[1].reply(400,'{"code":50035}'); assert.deepEqual(outcomes[1],[400,'{"code":50035}']);
    upload(url,payload,uri,(...args)=>outcomes.push(args));
    [...timers.values()][0](); assert.equal(requests[2].destroyed,true);
    assert.equal(outcomes[2][0],0);
    const before=requests.length;
    upload('https://example.org',payload,uri,(status)=>assert.equal(status,-1));
    upload(url,payload,'data:image/jpeg;base64,invalid',(status)=>assert.equal(status,-1));
    assert.equal(requests.length,before);
    console.log('PASS: byte-exact multipart round-trip with NUL/high bytes, UTF-8 metadata, content length, confirmations, error body, deadline, URL validation, single callback');
})().catch(error=>{console.error(error);process.exitCode=1;});
