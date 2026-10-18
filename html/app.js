const card = document.getElementById('card');
function text(id, value) { document.getElementById(id).textContent = String(value ?? 'Onbekend'); }
window.addEventListener('message', ({data}) => {
    if (data?.action === 'close') { card.hidden = true; return; }
    if (data?.action !== 'open' || !data.data) return;
    const d = data.data;
    text('plate', d.plate); text('owner', d.owner); text('brand', d.brandName);
    text('model', d.modelName); text('number', 'TS-' + String(d.documentId).padStart(7, '0'));
    text('date', d.issued); text('hint', data.own ? 'ESC om te sluiten' : 'BACKSPACE • SLUIT NA 15 SECONDEN');
    document.getElementById('close').hidden = !data.own;
    card.hidden = false;
});
async function close() {
    card.hidden = true;
    try {
        await fetch('https://' + GetParentResourceName() + '/close', {
            method: 'POST', headers: {'Content-Type': 'application/json'}, body: '{}'
        });
    } catch (_) {}
}
document.getElementById('close').addEventListener('click', close);
document.addEventListener('keydown', e => { if (e.key === 'Escape') close(); });
