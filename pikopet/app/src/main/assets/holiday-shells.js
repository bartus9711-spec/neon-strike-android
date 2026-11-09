(function installHolidayShells(){
 const variants=[
 ['🎄','Choinka','#185443','#54a86c','#e9c78c','#f5dca5','tree'],
 ['🎅','Mikołaj','#a12638','#e54f5b','#fff0e1','#ffe0ad','santa'],
 ['🧦','Świąteczna skarpeta','#8e2946','#d94c5c','#fff0e4','#76c6a2','stocking'],
 ['🔥','Kominek','#733d31','#b76a4a','#ffd09a','#ffefc7','fire'],
 ['❄️','Śnieżynki','#277a9d','#89d6ec','#ffffff','#e1f6ff','snow'],
 ['🦌','Reniferek','#7d4b35','#c48a5a','#f3e1bf','#d94850','deer'],
 ['🎁','Prezenty','#325d75','#66b1a3','#f4e3a8','#f2a1b2','gift'],
 ['🍪','Piernik','#87532d','#ce935e','#ffe0aa','#f8f0dc','cookie'],
 ['⭐','Złota gwiazda','#826023','#d4a84c','#fff1b3','#fff7e0','star'],
 ['🍬','Laska cukrowa','#b42c4c','#f1748b','#fff7ed','#9fe2b8','candy'],
 ['⛄','Bałwanek','#5389a8','#b7e1e8','#fffaf2','#f1a87c','snowman'],
 ['🌲','Zimowy las','#244a64','#5e9caa','#d8f3e6','#fff5d6','forest'],
 ['🎀','Świąteczna kokarda','#852e4c','#d95a73','#ffdbdf','#f8c979','bow'],
 ['🕯️','Wigilijne świece','#483b75','#a37eaf','#ffebc1','#f9b976','candles'],
 ['🧊','Lodowy kryształ','#28628b','#6cb6d4','#d9f8ff','#ffffff','ice'],
 ['🔔','Dzwoneczki','#51653c','#8ba864','#ffdb73','#f8f4ce','bells']
 ];
 const xml=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&quot;'}[c]));
 function svg(v,n){
  const [icon,name,dark,mid,light,trim,kind]=v;
  let decor='';
  const snow=Array.from({length:32},(_,i)=>'<circle cx="'+(145+(i*83)%820)+'" cy="'+(160+(i*137)%1050)+'" r="'+(i%3+5)+'" fill="'+trim+'" opacity=".65"/>').join('');
  const stars=Array.from({length:24},(_,i)=>'<path d="M0-14 4-4 14 0 4 4 0 14-4 4-14 0-4-4Z" transform="translate('+(150+(i*97)%810)+' '+(130+(i*139)%1100)+') scale('+(i%3+1)*.6+')" fill="'+light+'" opacity=".7"/>').join('');
  if(['snow','snowman','forest','ice'].includes(kind))decor=snow;
  else if(['star','candles','bells','bow'].includes(kind))decor=stars;
  else if(['tree','santa','stocking','gift','deer','candy'].includes(kind)){
   decor=Array.from({length:13},(_,i)=>'<circle cx="'+(190+i*63%740)+'" cy="'+(240+i*71%930)+'" r="11" fill="'+(i%2?light:trim)+'"/>').join('');
   decor+='<path d="M185 315Q300 230 440 280T790 250T930 315" fill="none" stroke="'+trim+'" stroke-width="19" stroke-dasharray="30 17"/>';
  }else decor=stars;
  const special=kind==='tree'?'<path d="M558 122 500 211H616Z" fill="#2a8b61"/><path d="M558 154 476 245H641Z" fill="#1c694c"/><circle cx="557" cy="118" r="16" fill="#ffec8a"/>':kind==='stocking'?'<path d="M484 150v64q-12 45 38 49h71q49-13 26-58l-40 4v-59Z" fill="#f0e9df" stroke="'+dark+'" stroke-width="8"/>':'';
  const outline='M555 78 C286 78 149 329 145 699 C131 1043 284 1288 553 1333 C823 1303 991 1044 981 697 C974 330 828 78 555 78Z';
  const content='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1122 1402" width="1122" height="1402"><defs><linearGradient id="body" x1="0" y1="0" x2="1" y2="1"><stop stop-color="'+light+'"/><stop offset=".35" stop-color="'+mid+'"/><stop offset=".8" stop-color="'+dark+'"/><stop offset="1" stop-color="'+mid+'"/></linearGradient><clipPath id="clip"><path d="'+outline+'"/></clipPath></defs><ellipse cx="560" cy="60" rx="55" ry="42" fill="'+trim+'" stroke="'+dark+'" stroke-width="14"/><path d="'+outline+'" fill="url(#body)" stroke="'+trim+'" stroke-width="23"/><g clip-path="url(#clip)">'+decor+'</g>'+special+'<circle cx="560" cy="231" r="89" fill="'+dark+'" stroke="'+trim+'" stroke-width="13"/><text x="560" y="266" text-anchor="middle" font-size="99">'+xml(icon)+'</text><rect x="234" y="393" width="654" height="549" rx="47" fill="'+dark+'" stroke="'+trim+'" stroke-width="27"/><rect x="248" y="405" width="625" height="523" rx="29" fill="'+light+'" stroke="'+mid+'" stroke-width="16"/><rect x="256" y="411" width="606" height="512" rx="13" fill="#e9f4dd"/><text x="560" y="988" font-size="49" font-weight="900" text-anchor="middle" fill="'+light+'" stroke="'+dark+'" stroke-width="4" paint-order="stroke">ŚWIĘTA ✦ '+(n+1)+'</text>'+[[339,1105],[552,1168],[762,1105]].map(([x,y])=>'<ellipse cx="'+x+'" cy="'+y+'" rx="79" ry="58" fill="'+dark+'" stroke="'+trim+'" stroke-width="11"/><ellipse cx="'+x+'" cy="'+(y-6)+'" rx="62" ry="45" fill="'+light+'" stroke="'+mid+'" stroke-width="8"/>').join('')+'<text x="560" y="1302" font-size="48" text-anchor="middle" fill="'+light+'">'+xml(name)+'</text></svg>';
  return 'data:image/svg+xml;charset=utf-8,'+encodeURIComponent(content);
 }
 const start=THEMES.length;
 variants.forEach((v,n)=>THEMES.push({name:'🎄 '+v[1],hue:0,sat:1,bright:1,kind:'holiday',classic:false,art:svg(v,n)}));
 const oldShow=showThemes;
 let tab=S.theme>=start?'holiday':'new';
 function show(){
  if(tab!=='holiday'){oldShow();const tabs=$('sheetBody').querySelector('.shell-tabs');tabs?.insertAdjacentHTML('beforeend','<button data-holiday-tab="1">🎄 Święta (16)</button>');return;}
  showSheet('🎄 Świąteczne obudowy', '<p class="intro">16 wyjątkowych świątecznych jajek! Wybór nie usuwa pupila ani postępów. Obudowy możesz łączyć z kominkiem, choinką i innymi tłami.</p><div class="shell-tabs"><button data-shellgroup="new">✨ Deluxe</button><button data-shellgroup="classic">🥚 Klasyczne</button><button class="active" data-holiday-tab="1">🎄 Święta (16)</button></div><div class="skin-grid">'+THEMES.slice(start).map((t,i)=>'<button class="skin-tile '+(S.theme===start+i?'active':'')+'" data-holiday-theme="'+(start+i)+'"><img src="'+t.art+'" alt="'+xml(t.name)+'"><span>'+xml(t.name)+'</span></button>').join('')+'</div>','themes');
 }
 showThemes=function(){if(S.theme>=start)tab='holiday';show();};
 $('overlay').addEventListener('click',e=>{
  const holiday=e.target.closest('[data-holiday-tab]');if(holiday){tab='holiday';show();return;}
  const other=e.target.closest('[data-shellgroup]');if(other){tab='new';return;}
  const choice=e.target.closest('[data-holiday-theme]');if(choice){changeTheme(Number(choice.dataset.holidayTheme));tab='holiday';show();return;}
 });
 const oldSettings=showSettings;
 showSettings=function(){oldSettings();const b=$('sheetBody').querySelector('[data-go="themes"]');if(b)b.textContent='🎨 80 obudów (16 świątecznych)';};
 const oldMenu=showMenu;
 showMenu=function(){oldMenu();const grid=$('sheetBody').querySelector('.menu-grid');grid?.insertAdjacentHTML('afterbegin','<button class="menu-card" data-holiday-open="1"><span class="emoji">🎄</span>Świąteczne jajka</button>');};
 $('overlay').addEventListener('click',e=>{if(e.target.closest('[data-holiday-open]')){tab='holiday';show();}});
 const oldRender=renderUI;
 renderUI=function(){oldRender();const theme=THEMES[S.theme];if(theme?.kind==='holiday'){$('shellImage').classList.remove('skin-classic');$('shellImage').src=theme.art;}};
 renderUI();
})();