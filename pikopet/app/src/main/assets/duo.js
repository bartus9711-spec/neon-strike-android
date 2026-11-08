(function installDuo(){
 if(!window.PikoLink||typeof PikoLinkNative==="undefined")return;
 if(!S.duo)S.duo={cards:[],gifts:0,coops:0};
 let coopCount=0,coopActive=false,coopPaid=false;
 function addCard(reason){
   if(!S.pet||!LINK.other)return;
   const other=LINK.other,now=Date.now();
   const last=S.duo.cards[0];
   if(reason==="visit"&&last&&now-last.time<180000&&last.species===other.species)return;
   S.duo.cards.unshift({time:now,name:other.name||"Pupil",species:other.species||"cat",own:S.pet.species,reason,photo:""});
   S.duo.cards=S.duo.cards.slice(0,20);
   save();
 }
 function makePhoto(){
   if(!S.pet||!LINK.other){notify("Najpierw rozpocznij wizytę.");return;}
   const can=document.createElement("canvas");can.width=300;can.height=200;
   const c=can.getContext("2d");c.imageSmoothingEnabled=false;
   const grd=c.createLinearGradient(0,0,0,200);
   grd.addColorStop(0,"#cba2e1");grd.addColorStop(1,"#ebdec9");
   c.fillStyle=grd;c.fillRect(0,0,300,200);
   c.fillStyle="#aa92b1";c.fillRect(0,160,300,40);
   for(let i=0;i<18;i++){c.fillStyle=i%2?"#fff2d4":"#e4f6cc";c.fillRect((i*41)%300,7+(i*31)%50,3,3);}
   const pics=[SPRITES[S.pet.species],SPRITES[LINK.other.species]];
   for(let i=0;i<2;i++){
     const img=pics[i];if(img?.complete&&img.naturalWidth){c.drawImage(img,32+i*140,56,95,95);}
   }
   c.fillStyle="#5c3c6d";c.fillRect(0,0,300,37);
   c.fillStyle="#fff9da";c.font="bold 17px sans-serif";c.textAlign="center";c.fillText("PIKOPET · FRIENDS ♥",150,25);
   c.fillStyle="#36223d";c.font="bold 13px sans-serif";
   c.fillText(String(S.pet.name||"Pupil").slice(0,12),83,179);
   c.fillText(String(LINK.other.name||"Gość").slice(0,12),224,179);
   let photo="";try{photo=can.toDataURL("image/png");}catch(e){}
   if(photo){
     const now=Date.now();
     const last=S.duo.cards[0];
     if(last&&last.species===LINK.other.species){last.photo=photo;last.reason="photo";last.time=now;}
     else{addCard("photo");S.duo.cards[0].photo=photo;}
     save();
     showDuoAlbum();
     notify("📸 Pamiątka zapisana w albumie!");
   }
 }
 function showDuoAlbum(){
   const cards=S.duo.cards||[];
   showSheet("📸 Pamiątki z wizyt",
     `<div class="banner">💌 Spotkania: ${cards.length} · Prezenty: ${S.duo.gifts||0} · Wspólne gry: ${S.duo.coops||0}</div>
     ${cards.length?cards.map(r=>`<div class="record-row">
       <b>🐾 ${esc(r.name)} · ${new Date(r.time).toLocaleDateString("pl-PL")}</b>
       <small>${r.reason==="photo"?"Zdjęcie pamiątkowe":r.reason==="coop"?"Wspólna minigra":"Wspólna wizyta"}</small>
       ${r.photo?`<img style="width:100%;max-width:320px;image-rendering:pixelated;border-radius:12px;margin-top:6px" src="${r.photo}" alt="Zdjęcie z wizyty">`:""}
       </div>`).join(""):'<p class="intro">Po pierwszej wizycie pojawią się tu wspomnienia i zdjęcia Twoich pupili.</p>'}
     <div class="action-list"><button class="secondary" data-go="visits">↩ Wróć do odwiedzin</button></div>`,"duoAlbum");
 }
 const priorShow=showVisits;
 showVisits=function(){
   priorShow();
   if(activeModal!=="visit")return;
   const actions=$("sheetBody").querySelector(".action-list");
   if(LINK.state==="visit"&&actions){
     actions.insertAdjacentHTML("beforeend",
       `<button class="primary" data-duo="coop">🎮 Wspólna minigra ${coopActive?"· "+coopCount+"/10":""}</button>
        ${coopActive&&!coopPaid?'<button class="primary" data-duo="tap">🐾 Przybij łapkę! +1</button>':""}
        <button class="secondary" data-duo="gift">🎁 Podaruj prezent</button>
        <button class="secondary" data-duo="photo">📸 Zdjęcie pamiątkowe</button>`);
   }
   const box=$("sheetBody");
   box.insertAdjacentHTML("beforeend",
     `<div class="action-list"><button class="secondary" data-duo="album">💌 Album wspomnień (${S.duo.cards.length})</button></div>`);
 };
 const priorReceive=window.PikoLink.receive;
 window.PikoLink.receive=function(raw){
   let e;try{e=JSON.parse(raw);}catch(err){return;}
   priorReceive(raw);
   if(e.type==="visit"){
     coopCount=0;coopActive=false;coopPaid=false;
     addCard("visit");
   }else if(e.type==="gift"&&LINK.state==="visit"){
     S.duo.gifts++; S.pet.happy=clamp(S.pet.happy+6);S.pet.affection=clamp(S.pet.affection+7);
     writeJournal("Pikopet otrzymał prezent podczas wizyty.");save();notify("🎁 Prezent! +7 miłości");
   }else if(e.type==="coop_start"&&LINK.state==="visit"){
     coopCount=0;coopActive=true;coopPaid=false;notify("🎮 Wspólna minigra — zbierzcie 10 przybić łapek!");
   }else if(e.type==="coop_tap"&&LINK.state==="visit"&&coopActive&&!coopPaid){
     coopCount++;
     sound(460+coopCount*50,.06);
     if(coopCount>=10){
       coopPaid=true;coopActive=false;S.duo.coops++;
       S.pet.happy=clamp(S.pet.happy+18);S.pet.affection=clamp(S.pet.affection+8);
       S.stats.games++;S.coins+=12;
       addCard("coop");writeJournal("Wspólna minigra z drugim pupilem — +12 gwiazdek.");
       save();notify("🏆 Drużynowy sukces! +12 gwiazdek i +18 humoru!");
     }
   }else if(e.type==="ended"){coopCount=0;coopActive=false;coopPaid=false;}
   if(activeModal==="visit")showVisits();
 };
 $("overlay").addEventListener("click",e=>{
   const b=e.target.closest("[data-duo]");if(!b)return;
   const id=b.dataset.duo;
   if(id==="album"){showDuoAlbum();return;}
   if(id==="photo"){makePhoto();return;}
   if(LINK.state!=="visit")return;
   try{
     if(id==="gift")PikoLinkNative.gift();
     if(id==="coop")PikoLinkNative.startCoop();
     if(id==="tap"){if(!coopPaid)PikoLinkNative.coopTap();}
   }catch(e){notify("Nie można wysłać wiadomości.");}
 });
 const oldShowMenu=showMenu;
 showMenu=function(){
   oldShowMenu();
   $("sheetBody").querySelector(".menu-grid")?.insertAdjacentHTML("beforeend",
     '<button class="menu-card" data-duo="album"><span class="emoji">📸</span>Pamiątki z wizyt</button>');
 };
 window.PikoDuoExtras={album:showDuoAlbum};
})();