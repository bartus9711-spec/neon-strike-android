(function installBackgrounds(){
 const themes=[
 ['🎄','Świąteczny salon','#27172d','#a83c44','christmas'],['🔥','Kominek i skarpeta','#382334','#8b4939','stocking'],['🎅','Wioska Mikołaja','#182e53','#b44454','santa'],['❄️','Śnieżna noc','#1d3660','#688dc5','snow'],['🎁','Prezenty pod choinką','#273c48','#ae6a68','gifts'],['🦌','Zaprzęg reniferów','#142b54','#597bb5','reindeer'],['🧣','Zimowa chatka','#1d4261','#9bc2dd','winter'],['🍪','Piernikowa kraina','#75423c','#dda36b','ginger'],['⛸️','Lodowisko','#37739b','#b8e7ef','ice'],['🌟','Gwiazda Betlejemska','#191d49','#624ab3','stars'],
 ['🌸','Wiosenny sad','#648c99','#e6bbcf','spring'],['🌷','Tulipanowy ogród','#85bdc2','#f3c7ac','flowers'],['🦋','Łąka motyli','#6da5a2','#b7d88d','meadow'],['🌈','Tęczowy park','#78b6df','#b4d9a2','rainbow'],['🌳','Park miejski','#668da1','#b5c8a1','park'],['⛲','Park z fontanną','#6dabb6','#a4c9bd','fountain'],['🌺','Ogród botaniczny','#497f70','#dbb5a2','garden'],['🏯','Ogród japoński','#8e99b3','#e5b6c6','japan'],
 ['☀️','Letnia plaża','#5fb7cf','#f1d8a1','beach'],['🏝️','Tropikalna wyspa','#3ca9c2','#b3dfc1','island'],['🌊','Morska zatoka','#348fb9','#b1d2e1','sea'],['🍉','Letni piknik','#88bb8b','#e9d5aa','picnic'],['🎡','Diabelski młyn','#565aa2','#ee9eb7','wheel'],['🎢','Kolejka górska','#4d7db2','#edbd8e','coaster'],['🎠','Karuzela','#7965a6','#d8a4ca','carousel'],['🎪','Cyrkowy lunapark','#67447e','#d96e89','circus'],['🎆','Lunapark nocą','#181d52','#8a4cbd','nightpark'],
 ['🍂','Jesienny park','#9d6e65','#dcab6a','autumn'],['🎃','Dyniowa alejka','#704663','#d48755','pumpkins'],['🌧️','Deszczowe miasto','#334d75','#778eae','rain'],['🍁','Klonowy las','#81594d','#c27e55','forest'],['🌫️','Mglisty poranek','#6b7c82','#a5afa8','mist'],['🌻','Słonecznikowe pole','#749c74','#efc56d','sunflower'],
 ['🌌','Galaktyka','#15184c','#653e9b','space'],['🪐','Planeta pierścieni','#172a54','#7763af','planet'],['🌙','Księżycowa noc','#172744','#5d6fa1','moon'],['🏰','Baśniowy zamek','#555a9c','#c7a5d8','castle'],['🪸','Podwodna rafa','#166986','#7ec0ba','reef'],['🌋','Wulkaniczna wyspa','#542a42','#b85e4c','volcano'],['🌆','Neonowe miasto','#20174b','#af3c9c','neon'],['💎','Kryształowa jaskinia','#242f70','#8d8bd0','crystal']
 ];
 const escXml=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&apos;'}[c]));
 function art(t){
  const [icon,name,a,b,type]=t;
  let foreground='';
  const stars=Array.from({length:22},(_,i)=>{const x=(i*137+41)%400,y=(i*71+23)%720;return '<circle cx="'+x+'" cy="'+y+'" r="'+(i%3+1)+'" fill="#fff8d8" opacity=".7"/>';}).join('');
  const tree=(x,y,scale=1)=>'<g transform="translate('+x+' '+y+') scale('+scale+')"><rect x="-9" y="0" width="18" height="82" fill="#6e4b40"/><path d="M0-146 -65-10H65Z" fill="#205d55"/><path d="M0-106 -73 27H73Z" fill="#2b7866"/><path d="M0-67 -77 54H77Z" fill="#1e6256"/><path d="M0-159l9 13 17 2-12 12 3 17-17-8-16 8 3-17-13-12 18-2z" fill="#ffdf7b"/></g>';
  const snow=Array.from({length:38},(_,i)=>'<circle cx="'+((i*79+29)%400)+'" cy="'+((i*149+21)%740)+'" r="'+(i%3+1.5)+'" fill="#fff" opacity=".8"/>').join('');
  const gift=(x,y,c)=>'<g transform="translate('+x+' '+y+')"><rect width="48" height="45" rx="3" fill="'+c+'"/><rect x="19" width="10" height="45" fill="#ffda9a"/><rect x="-4" y="-7" width="56" height="10" fill="'+c+'"/><path d="M24-7Q-10-30 7-35Q24-40 24-7Q40-42 54-34Q68-21 24-7" fill="none" stroke="#ffe6a5" stroke-width="5"/></g>';
  if(['christmas','stocking','gifts','ginger','winter','santa'].includes(type)){
    foreground='<rect y="520" width="400" height="220" fill="#65484b"/><path d="M0 530H400" stroke="#a77d72" stroke-width="15"/>';
    if(type==='christmas'||type==='gifts'||type==='santa')foreground+=tree(78,440,.8)+tree(335,420,.85)+gift(40,572,'#c64d63')+gift(312,598,'#437c8d');
    if(type==='stocking'||type==='christmas'){
      foreground+='<rect x="106" y="250" width="190" height="260" rx="12" fill="#c69c85"/><rect x="120" y="272" width="160" height="205" rx="8" fill="#4b3037"/><path d="M146 475Q140 340 200 325Q260 350 250 475Z" fill="#ffb348"/><path d="M165 477Q180 374 204 367Q226 389 235 477" fill="#ffd67e"/><rect x="85" y="240" width="230" height="30" rx="6" fill="#e9bca2"/>';
      foreground+='<path d="M156 260v58q-14 0-15 28q-1 24 29 25q35 0 35-32v-30h-22v25q-10 12-18 0v-74" fill="#c8495a" stroke="#fff5e2" stroke-width="7"/>';
      if(type==='stocking')foreground+='<g transform="translate(162 321) rotate(-8)"><ellipse cx="0" cy="0" rx="19" ry="26" fill="#e8c8a3" stroke="#fff3d9" stroke-width="5"/><text x="0" y="8" font-size="22" text-anchor="middle">🥚</text></g>';
      foreground+=tree(49,575,.46)+gift(308,615,'#b84e62');
    }
  }else if(['snow','ice','reindeer'].includes(type)){
    foreground='<path d="M0 545Q100 480 210 545T400 525V740H0Z" fill="#e6f5ff"/>'+tree(52,536,.55)+tree(347,545,.6)+snow;
  }else if(['park','fountain','spring','flowers','meadow','rainbow','garden','japan','picnic','sunflower'].includes(type)){
    foreground='<path d="M0 530Q120 485 240 525T400 510V740H0Z" fill="#79a779"/><path d="M130 740Q160 560 215 510Q245 610 300 740" fill="#d8bca0"/>'+tree(30,550,.65)+tree(365,560,.58);
    if(type==='fountain')foreground+='<ellipse cx="210" cy="588" rx="80" ry="24" fill="#8bd1e3"/><path d="M210 574Q170 520 210 475Q250 520 210 574" fill="none" stroke="#c4f7ff" stroke-width="10"/>';
  }else if(['wheel','coaster','carousel','circus','nightpark'].includes(type)){
    foreground='<rect y="595" width="400" height="145" fill="#4e5c7a"/>';
    if(type==='wheel'||type==='nightpark'){
      foreground+='<circle cx="200" cy="415" r="145" fill="none" stroke="#ffe5a1" stroke-width="10"/>';
      for(let i=0;i<12;i++){let x=200+145*Math.cos(i*Math.PI/6),y=415+145*Math.sin(i*Math.PI/6);foreground+='<path d="M200 415L'+x+' '+y+'" stroke="#eac6da" stroke-width="3"/><rect x="'+(x-13)+'" y="'+(y-3)+'" width="26" height="23" rx="6" fill="'+(i%2?'#ffb16e':'#a5e8ee')+'"/>';}
      foreground+='<path d="M200 415L125 620M200 415L275 620" stroke="#c0d5ed" stroke-width="11"/>';
    }else if(type==='coaster')foreground+='<path d="M0 550Q100 140 205 460T400 310" fill="none" stroke="#ffe49b" stroke-width="13"/><path d="M0 560Q100 150 205 470T400 320" fill="none" stroke="#bc86b2" stroke-width="5"/>';
    else foreground+='<path d="M45 460L200 255 355 460Z" fill="#f5c9ae"/><rect x="60" y="460" width="280" height="130" fill="#bf659a"/>';
  }else if(['autumn','pumpkins','forest','mist','rain'].includes(type)){
    foreground='<path d="M0 555Q140 505 250 560T400 525V740H0Z" fill="#8c795e"/>'+tree(35,530,.65)+tree(352,545,.65);
    foreground+=Array.from({length:24},(_,i)=>'<ellipse cx="'+((i*83+21)%400)+'" cy="'+((i*59+390)%740)+'" rx="6" ry="3" fill="'+(i%2?'#edb75d':'#cb6a51')+'" transform="rotate('+(i*29)+' '+((i*83+21)%400)+' '+((i*59+390)%740)+')"/>').join('');
    if(type==='pumpkins')foreground+='<text x="185" y="610" font-size="82">🎃</text>';
  }else if(['beach','island','sea','reef'].includes(type)){
    foreground='<path d="M0 495Q90 475 170 497T400 495V740H0Z" fill="#3bafc3"/><path d="M0 605Q130 565 240 610T400 605V740H0Z" fill="#e9ce91"/>';
    if(type==='island'||type==='beach')foreground+='<path d="M65 570Q90 440 120 350" stroke="#745b49" stroke-width="17" fill="none"/><path d="M120 350Q50 260 0 360M120 350Q190 250 235 365M120 350Q90 275 130 245" fill="none" stroke="#4eac77" stroke-width="24"/>';
  }else if(['space','planet','moon','stars','neon'].includes(type)){
    foreground=stars+'<circle cx="285" cy="360" r="115" fill="#8d83bd"/><ellipse cx="285" cy="360" rx="164" ry="34" fill="none" stroke="#dfb6d4" stroke-width="16" transform="rotate(-23 285 360)"/>';
  }else{
    foreground='<path d="M0 555Q120 505 240 560T400 530V740H0Z" fill="#7f8da7"/>'+stars;
  }
  const svg='<svg xmlns="http://www.w3.org/2000/svg" width="400" height="740" viewBox="0 0 400 740"><defs><linearGradient id="g" x2="0" y2="1"><stop stop-color="'+a+'"/><stop offset="1" stop-color="'+b+'"/></linearGradient></defs><rect width="400" height="740" fill="url(#g)"/>'+foreground+'<text x="200" y="84" font-family="sans-serif" font-size="46" text-anchor="middle" opacity=".7">'+escXml(icon)+'</text></svg>';
  return 'data:image/svg+xml;charset=utf-8,'+encodeURIComponent(svg);
 }
 const key='tamagotchi_background_v1';
 let selected=Number(localStorage.getItem(key)||0);
 if(!Number.isInteger(selected)||selected<0||selected>=themes.length)selected=0;
 const layer=document.createElement('div');layer.id='worldBackdrop';layer.setAttribute('aria-hidden','true');
 document.getElementById('app').prepend(layer);
 const css=document.createElement('style');
 css.textContent='#worldBackdrop{position:fixed;inset:0;z-index:0;pointer-events:none;background-size:cover;background-position:center;transition:background-image .2s;opacity:.92}#worldBackdrop:after{content:"";position:absolute;inset:0;background:linear-gradient(90deg,#100c2055,transparent 35%,transparent 65%,#100c2055)}.play-stage{position:relative;z-index:1}.theme-background-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px}.theme-background-tile{border:2px solid #8e6f9d;border-radius:15px;overflow:hidden;background:#3a2a4b;color:#fff1ee;font-weight:800;padding:5px}.theme-background-tile.active{border-color:#ffeaa6;box-shadow:0 0 0 2px #f5d4aa55}.theme-background-tile img{display:block;width:100%;height:145px;object-fit:cover;border-radius:10px}.theme-background-tile span{display:block;padding:7px 3px;font-size:12px}.background-category{margin:16px 0 8px;color:#ffe9bc;font-weight:900}';
 document.head.appendChild(css);
 function apply(n){selected=n;layer.style.backgroundImage='url("'+art(themes[n])+'")';localStorage.setItem(key,String(n));}
 apply(selected);
 function showBackgrounds(){
  const categories=[['🎄 Świąteczne i zimowe',0,10],['🌸 Wiosna i parki',10,18],['☀️ Lato i wesołe miasteczka',18,27],['🍂 Jesień',27,33],['🌌 Fantastyczne i pozostałe',33,themes.length]];
  const html='<p class="intro">Wybierz niezależnie tło otaczające jajko. Obudowa i pupil pozostają bez zmian. Świąteczny kominek ma nawet skarpetę z jajkiem! 🎄🥚</p>'+categories.map(([name,start,end])=>'<div class="background-category">'+name+'</div><div class="theme-background-grid">'+themes.slice(start,end).map((t,i)=>{const n=start+i;return '<button class="theme-background-tile '+(selected===n?'active':'')+'" data-background="'+n+'"><img alt="'+esc(t[1])+'" src="'+art(t)+'"><span>'+t[0]+' '+esc(t[1])+'</span></button>';}).join('')+'</div>').join('');
  showSheet('🌍 Motywy tła · '+themes.length,html,'backgrounds');
 }
 const oldSettings=showSettings;
 showSettings=function(){oldSettings();const buttons=$('sheetBody')?.querySelector('.action-list');if(buttons)buttons.insertAdjacentHTML('beforeend','<button class="secondary" data-backgrounds-open="1">🌍 Motywy tła (41)</button>');};
 const oldMenu=showMenu;
 showMenu=function(){oldMenu();const grid=$('sheetBody')?.querySelector('.menu-grid');if(grid)grid.insertAdjacentHTML('afterbegin','<button class="menu-card" data-backgrounds-open="1"><span class="emoji">🌍</span>Motywy tła<small>Święta, parki, pory roku i więcej</small></button>');};
 $('overlay').addEventListener('click',e=>{
  const opener=e.target.closest('[data-backgrounds-open]');if(opener){showBackgrounds();return;}
  const pick=e.target.closest('[data-background]');if(pick){apply(Number(pick.dataset.background));showBackgrounds();notify('🌍 Tło: '+themes[selected][1]);}
 });
 const originalRoute=route;
 route=function(where){if(where==='backgrounds')showBackgrounds();else originalRoute(where);};
 window.TamagotchiBackgrounds={themes,art,apply,showBackgrounds,get selected(){return selected;}};
})();