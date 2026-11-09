(function installFriendshipShop(){
 const KEY='tama_friendships_v1';
 const GIFTS=[
 ['🦴','Przysmak',100,10],['⚽','Piłka',150,15],['🧸','Pluszak',300,25],['🧣','Kocyk',400,30],['📿','Obroża',500,40],
 ['👑','Korona',750,60],['🎅','Świąteczny strój',800,60],['🏮','Lampion',1000,80],['🎲','Zestaw zabawek',1250,100],['🎁','Prezent premium',2000,150]
 ];
 let friends={};try{friends=JSON.parse(localStorage.getItem(KEY)||'{}')||{}}catch(e){}
 function friendKey(){if(!LINK.other)return null;return String(LINK.other.species||'pet')+':'+String(LINK.other.name||'friend').slice(0,32)}
 function current(){const k=friendKey();if(!k)return null;if(!friends[k])friends[k]={name:LINK.other.name||'Pupil',species:LINK.other.species||'cat',points:0,visits:0,gifts:0,lastSeen:0,events:[]};return friends[k]}
 function persist(){localStorage.setItem(KEY,JSON.stringify(friends))}
 function earn(amount,why){const f=current();if(!f)return;f.points=Math.min(100000,f.points+amount);f.lastSeen=Date.now();f.events.unshift({at:Date.now(),why,amount});f.events=f.events.slice(0,30);persist();save();}
 function level(p){return Math.min(10,1+Math.floor(Math.sqrt(p/120)))}
 function showShop(){
  if(LINK.state!=='visit'||!LINK.other){notify('🎁 Prezenty kupisz podczas aktywnej wizyty.');showVisits();return;}
  const f=current();const lvl=level(f.points),need=120*lvl*lvl;
  const html='<div class="banner">💞 '+esc(f.name)+' · poziom przyjaźni '+lvl+'<br>❤️ '+f.points+' pkt · Do kolejnego poziomu: '+Math.max(0,need-f.points)+' pkt<br>🪙 Twoje gwiazdki: '+S.coins+'</div><p class="intro">Wybierz podarunek dla przyjaciela. Koszt odejmuje gwiazdki, a punkty zwiększają przyjaźń.</p><div class="friend-gift-grid">'+GIFTS.map((g,i)=>'<button class="friend-gift" data-buy-gift="'+i+'"><span class="gift-emoji">'+g[0]+'</span><strong>'+g[1]+'</strong><small>🪙 '+g[2]+' · ❤️ +'+g[3]+' pkt</small></button>').join('')+'</div><details class="tama-drawer"><summary>🎮 Wspólne aktywności i punkty</summary><div class="drawer-content">Pierwsze spotkanie: +20 pkt. Wspólna zabawa: +8 pkt. Prezenty: od +10 do +150 pkt. Punkty i historia zostają zapisane na tym telefonie.</div></details><div class="action-list"><button class="secondary" data-friend-view="1">👥 Historia przyjaźni</button><button class="secondary" data-go="visits">↩ Odwiedziny</button></div>';
  showSheet('🎁 Sklep z prezentami',html,'friendShop');
 }
 function friendsView(){
  const entries=Object.values(friends).sort((a,b)=>b.points-a.points);
  showSheet('❤️ Znajomi i przyjaźnie','<p class="intro">Znajomości zapisane na tym telefonie po prawdziwych spotkaniach BT / Wi-Fi.</p>'+ (entries.length?entries.map(f=>'<details class="tama-drawer"><summary>🐾 '+esc(f.name)+' · ❤️ '+f.points+' pkt · poziom '+level(f.points)+'</summary><div class="drawer-content">Spotkania: '+f.visits+' · Prezenty: '+f.gifts+'<br>'+f.events.slice(0,10).map(e=>'<div class="record-row">'+new Date(e.at).toLocaleDateString('pl-PL')+' · '+esc(e.why)+' · +'+e.amount+' pkt</div>').join('')+'</div></details>').join(''):'<div class="banner">Nie masz jeszcze zapisanych przyjaciół. Połącz dwa telefony i odwiedź pupila!</div>')+'<div class="action-list"><button class="secondary" data-go="visits">↩ Odwiedziny</button></div>','friends');
 }
 const oldVisits=showVisits;
 showVisits=function(){oldVisits();if(activeModal==='visit'){const list=$('sheetBody').querySelector('.action-list');if(list&&LINK.state==='visit'){const f=current();list.insertAdjacentHTML('beforeend','<button class="primary" data-friend-shop="1">🎁 Sklep prezentów · ❤️ '+f.points+' pkt</button>');}$('sheetBody').insertAdjacentHTML('beforeend','<details class="tama-drawer"><summary>👥 Znajomi i punkty przyjaźni</summary><div class="drawer-content"><button class="secondary" data-friend-view="1">Otwórz zapisane przyjaźnie</button></div></details>');}};
 const previousReceive=window.PikoLink?.receive;
 if(previousReceive)window.PikoLink.receive=function(raw){
  let evt=null;try{evt=JSON.parse(raw)}catch(e){}
  previousReceive(raw);
  if(!evt)return;
  if(evt.type==='visit'&&LINK.state==='visit'){const f=current();if(f){f.visits++;earn(20,'Spotkanie');}}
  if(evt.type==='gift'&&LINK.state==='visit'){const f=current();if(f){f.gifts++;earn(10,'Otrzymany prezent');}}
  if(evt.type==='play'&&LINK.state==='visit')earn(8,'Wspólna zabawa');
 };
 const oldMenu=showMenu;
 showMenu=function(){oldMenu();$('sheetBody').querySelector('.menu-grid')?.insertAdjacentHTML('beforeend','<button class="menu-card" data-friend-view="1"><span class="emoji">💞</span>Przyjaźnie</button>');};
 $('overlay').addEventListener('click',e=>{
  if(e.target.closest('[data-friend-view]')){friendsView();return;}
  if(e.target.closest('[data-friend-shop]')){showShop();return;}
  const buy=e.target.closest('[data-buy-gift]');if(!buy)return;
  const g=GIFTS[Number(buy.dataset.buyGift)];
  if(!g||LINK.state!=='visit'||!LINK.other){notify('Spotkanie zostało zakończone.');return;}
  if(S.coins<g[2]){notify('🪙 Za mało gwiazdek na ten prezent.');return;}
  try{PikoLinkNative.gift()}catch(err){notify('Nie udało się wysłać prezentu.');return;}
  S.coins-=g[2];S.duo=S.duo||{cards:[],gifts:0,coops:0};S.duo.gifts=(S.duo.gifts||0)+1;
  const f=current();f.gifts++;earn(g[3],'Podarowano: '+g[1]);save();
  notify('🎁 '+g[1]+' · ❤️ +'+g[3]+' pkt!');showShop();
 });
 window.TamagotchiFriendships={showShop,friendsView};
})();