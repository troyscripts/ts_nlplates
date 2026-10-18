'use strict';
const card = document.getElementById('alert');
let timer, activeId;
function hide() { card.hidden = true; activeId = null; clearInterval(timer); }
window.addEventListener('message', ({data}) => {
    if (!data || typeof data !== 'object') return;
    if (data.action === 'hide') { hide(); return; }
    if (data.action !== 'show' || !Number.isFinite(data.duration) || data.duration <= 0) return;
    hide(); activeId = data.id;
    for (const key of ['title', 'description', 'location', 'postal', 'acceptKey', 'dismissKey', 'acceptLabel', 'dismissLabel']) {
        const el = document.getElementById(key);
        el.textContent = typeof data[key] === 'string' ? data[key] : '';
        if (['description','location','postal'].includes(key)) el.hidden = !el.textContent;
    }
    const id = activeId, deadline = Date.now() + data.duration;
    const tick = () => {
        if (id !== activeId) return;
        const remaining = Math.max(0, Math.ceil((deadline-Date.now())/1000));
        document.getElementById('seconds').textContent = `${remaining} ${data.remainingLabel || ''}`;
        if (!remaining) hide();
    };
    card.hidden = false; tick(); timer = setInterval(tick, 200);
});
// Geen focus/cursor: alle rijbediening blijft bij GTA. Handshake voorkomt verloren eerste melding.
async function ready() {
    try { await fetch(`https://${GetParentResourceName()}/ready`, {method:'POST',headers:{'Content-Type':'application/json'},body:'{}'}); }
    catch (_) { setTimeout(ready, 1000); }
}
ready();
