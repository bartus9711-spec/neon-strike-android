(function installBluetoothUi(){
  const devices=new Map();
  let scanState='';let refreshAt=0;
  const oldShow=showVisits;
  showVisits=function(){
    oldShow();
    if(activeModal!=='visit'||!linkNative())return;
    if(LINK.state==='invite'||LINK.state==='visit')return;
    const body=$('sheetBody');
    const rows=Array.from(devices.values()).sort((a,b)=>(b.paired?1:0)-(a.paired?1:0));
    const rowsHTML=rows.length?rows.map(d=>
      `<div class="item-row" style="gap:8px">
        <span class="item-icon">📱</span>
        <span class="item-info"><b>${esc(d.name||'Telefon Bluetooth')}</b><small>${esc(d.address)} · ${d.paired?'✅ Sparowany':'Czeka na parowanie'}</small></span>
        <button class="${d.paired?'primary':'secondary'}" data-bt-tool="${d.paired?'connect':'pair'}" data-bt-address="${esc(d.address)}">${d.paired?'Połącz':'Sparuj'}</button>
      </div>`).join(''):'<p class="hint">Nie ma jeszcze wykrytych telefonów. Na jednym telefonie kliknij „Pokaż mój telefon”, na drugim „Szukaj telefonów”.</p>';
    body.insertAdjacentHTML('beforeend',`
      <div class="section-label">📡 Parowanie dwóch telefonów</div>
      <p class="hint">Na telefonie A włącz widoczność na 2 minuty. Na telefonie B uruchom skanowanie. Potwierdź identyczny kod parowania na obu ekranach.</p>
      <div class="action-list">
        <button class="secondary" data-bt-tool="discover">📱 Pokaż mój telefon (2 min)</button>
        <button class="primary" data-bt-tool="scan">🔍 Szukaj pobliskich</button>
        <button class="secondary" data-bt-tool="refresh">↻ Odśwież sparowane</button>
        <button class="secondary" data-bt-tool="settings">⚙️ Ustawienia Bluetooth</button>
      </div>
      ${scanState?'<div class="banner">'+esc(scanState)+'</div>':''}
      ${rowsHTML}
      <p class="hint">Po sparowaniu na telefonie A wybierz „Otwórz domek Bluetooth”, a na telefonie B przy telefonie A wybierz „Połącz”.</p>`);
  };
  function refresh(){
    if(!linkNative())return;
    try{
      const known=JSON.parse(PikoLinkNative.pairedBluetooth()||'[]');
      for(const d of known){
        if(!d.address)continue;
        devices.set(d.address,{name:d.name||'Telefon Bluetooth',address:d.address,paired:true});
      }
      LINK.paired=known;
      refreshAt=Date.now();
      scanState=known.length?'Znaleziono '+known.length+' wcześniej sparowanych urządzeń.':'Brak sparowanych telefonów. Spróbuj skanowania.';
    }catch(e){scanState='Nie udało się odczytać urządzeń.';}
    if(activeModal==='visit')showVisits();
  }
  $('overlay').addEventListener('click',e=>{
    const button=e.target.closest('[data-bt-tool]');if(!button)return;
    if(!linkNative()){notify('Potrzebna aplikacja Android.');return;}
    const op=button.dataset.btTool;
    try{
      if(op==='discover'){scanState='Potwierdź systemową prośbę o widoczność Bluetooth.';PikoLinkNative.makeDiscoverable();}
      else if(op==='scan'){scanState='🔍 Szukam pobliskich telefonów…';PikoLinkNative.scanBluetooth();}
      else if(op==='refresh'){refresh();return;}
      else if(op==='settings'){PikoLinkNative.openBluetoothSettings();}
      else if(op==='pair'){scanState='Potwierdź kod parowania na obu telefonach.';PikoLinkNative.pairBluetooth(button.dataset.btAddress);}
      else if(op==='connect'){
        if(!S.pet?.alive){notify('Najpierw wykluj pupila!');return;}
        syncVisitPet();
        LINK.state='waiting';LINK.status='Łączę przez Bluetooth…';
        PikoLinkNative.joinBluetooth(button.dataset.btAddress);
      }
      showVisits();
    }catch(err){scanState='Bluetooth niedostępny. Sprawdź zgody i włącz Bluetooth.';showVisits();}
  });
  const oldReceive=window.PikoLink.receive;
  window.PikoLink.receive=function(raw){
    let e;
    try{e=JSON.parse(raw);}catch(error){return oldReceive(raw);}
    if(e.type==='bt_found'&&e.address){
      devices.set(e.address,{address:e.address,name:e.name||'Telefon Bluetooth',paired:!!e.paired});
      scanState=e.paired?'✅ Sparowano: '+(e.name||'telefon'): 'Znaleziono telefon: '+(e.name||'Bluetooth');
    }
    oldReceive(raw);
    if(e.type==='bt_found'&&activeModal==='visit')showVisits();
  };
  window.PikoBluetooth={refresh,list:()=>Array.from(devices.values())};
})();