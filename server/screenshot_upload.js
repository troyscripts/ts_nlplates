'use strict';
// Server-only: keep binary data out of Lua PerformHttpRequest's C-string body.
const https = require('https');
const crypto = require('crypto');

exports('UploadDiscordPhoto', (url, payloadJson, dataUri, callback) => {
    if (typeof callback !== 'function') return;
    let finished = false;
    const finish = (status, body) => {
        if (finished) return;
        finished = true;
        // Re-enter the FiveM main runtime before invoking a Lua function reference.
        setImmediate(() => callback(status, body));
    };
    let req;
    try {
        if (typeof url !== 'string' || !/^https:\/\/discord\.com\/api\/(?:v\d+\/)?webhooks\/\d+\/[\w-]+$/.test(url)) {
            finish(-1, ''); return;
        }
        if (typeof payloadJson !== 'string' || Buffer.byteLength(payloadJson) > 256 * 1024 ||
            typeof dataUri !== 'string' || dataUri.length > 24 * 1024 * 1024) {
            finish(-1, ''); return;
        }
        const match = /^data:image\/jpe?g;base64,([A-Za-z0-9+/]+={0,2})$/.exec(dataUri);
        if (!match || match[1].length % 4 !== 0) { finish(-1, ''); return; }
        const jpeg = Buffer.from(match[1], 'base64');
        if (jpeg.length < 3 || jpeg.length > 16 * 1024 * 1024 ||
            jpeg[0] !== 255 || jpeg[1] !== 216 || jpeg[2] !== 255 || jpeg.toString('base64') !== match[1]) {
            finish(-1, ''); return;
        }
        const payload = JSON.parse(payloadJson);
        if (!payload || !Array.isArray(payload.embeds) || !payload.embeds[0]) { finish(-1, ''); return; }
        payload.allowed_mentions = { parse: [] };
        payload.attachments = [{ id: 0, filename: 'screenshot.jpg' }];
        payload.embeds[0].image = { url: 'attachment://screenshot.jpg' };
        let boundary;
        do { boundary = 'tsBridge' + crypto.randomBytes(18).toString('hex'); }
        while (jpeg.includes(boundary) || JSON.stringify(payload).includes(boundary));
        const body = Buffer.concat([
            Buffer.from('--' + boundary + '\r\nContent-Disposition: form-data; name="payload_json"\r\nContent-Type: application/json\r\n\r\n' + JSON.stringify(payload) + '\r\n'),
            Buffer.from('--' + boundary + '\r\nContent-Disposition: form-data; name="files[0]"; filename="screenshot.jpg"\r\nContent-Type: image/jpeg\r\n\r\n'),
            jpeg,
            Buffer.from('\r\n--' + boundary + '--\r\n')
        ]);
        req = https.request(url + '?wait=true', {
            method: 'POST',
            headers: { 'Content-Type': 'multipart/form-data; boundary=' + boundary,
                'Content-Length': body.length, 'User-Agent': 'TroyScripts-ts_bridge/1.0.0' }
        }, res => {
            const chunks = [];
            let size = 0;
            res.on('data', chunk => {
                size += chunk.length;
                if (size > 256 * 1024) { finish(0, ''); res.destroy(); return; }
                chunks.push(chunk);
            });
            res.on('end', () => finish(res.statusCode || 0, Buffer.concat(chunks).toString('utf8')));
            res.on('error', () => finish(0, ''));
            res.on('aborted', () => finish(0, ''));
        });
        const deadline = setTimeout(() => { finish(0, ''); req.destroy(); }, 25000);
        req.on('close', () => clearTimeout(deadline));
        req.on('error', () => { clearTimeout(deadline); finish(0, ''); });
        req.end(body);
    } catch (_) {
        // No URLs or exceptions containing webhook tokens leave this uploader.
        if (req) req.destroy();
        finish(req ? 0 : -1, '');
    }
});
