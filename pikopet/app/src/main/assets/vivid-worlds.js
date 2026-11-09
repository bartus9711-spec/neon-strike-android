(function(){
 const style=document.createElement('style');
 style.textContent='@keyframes tamaWorldDrift{0%{transform:scale(1.04) translate3d(-1%,0,0)}50%{transform:scale(1.11) translate3d(1%,-1%,0)}100%{transform:scale(1.04) translate3d(-1%,0,0)}}@keyframes tamaStars{0%,100%{opacity:.24;transform:translateY(0)}50%{opacity:.64;transform:translateY(-12px)}}#worldBackdrop{overflow:hidden;filter:saturate(1.3) contrast(1.08);animation:tamaWorldDrift 19s ease-in-out infinite;will-change:transform}#app:before{animation:tamaStars 9s ease-in-out infinite}#overlay .sheet:before{animation:tamaWorldDrift 25s ease-in-out infinite;opacity:.62!important;filter:saturate(1.3)}#overlay .sheet:after{background:linear-gradient(180deg,#20132ae8,#1e1225bd 40%,#1b122ce5)!important}.egg{width:min(106vw,620px,calc((100dvh - env(safe-area-inset-top,0px) - env(safe-area-inset-bottom,0px) - 4px)*.82317))!important;max-width:none!important}@media(prefers-reduced-motion:reduce){#worldBackdrop,#app:before,#overlay .sheet:before{animation:none!important}}';
 document.head.appendChild(style);
 const oldVisits=showVisits;
 showVisits=function(){oldVisits();if(activeModal!=='visit')return;const body=$('sheetBody');if(!body)return;
  const blocks=Array.from(body.children).filter(el=>el.matches('.action-list'));
  if(LINK.state!=='visit'&&blocks.length>1){const drawer=document.createElement('details');drawer.className='tama-drawer';drawer.innerHTML='<summary>📱 Rozwiń urządzenia i opcje połączenia</summary><div class="drawer-content"></div>';blocks.slice(1).forEach(el=>drawer.querySelector('.drawer-content').appendChild(el));body.appendChild(drawer);}
 };
})();