(function installGames(){
 const BONUS=[
  ["fruit","🍎","Łap owoce","Wybierz tylko świeży owoc.",10],
  ["hide","🥣","Gdzie pupil?","Zgadnij, pod którą miseczką się ukrył.",6],
  ["treasure","💎","Skarby","Odkrywaj pola ze skarbami, omijaj pustki.",6],
  ["maze","🧭","Labirynt","Dotrzyj do gwiazdki, omijając ściany.",15],
  ["fishing","🎣","Łowienie rybek","Zatrzymaj znacznik w zielonym obszarze.",7],
  ["rhythm","🎶","Rytm","Klikaj w rytm, gdy pojawi się zielony błysk.",8],
  ["jump","🐰","Skakanka","Skacz, gdy znacznik przechodzi przez pole skoku.",8],
  ["sort","🧺","Porządki","Włóż jedzenie i zabawki do właściwych koszyków.",10],
  ["pattern","🔷","Sekwencje","Odgadnij następny symbol.",8],
  ["dodge","🚀","Kosmiczna podróż","Wybierz bezpieczny korytarz.",10],
  ["blocks","🧱","Wieża","Zatrzymaj klocek blisko środka.",7],
  ["whack","🐹","Zabawa w chowanego","Znajdź pupila w dziewięciu kryjówkach.",12]
 ];
 const style=document.createElement("style");
 style.textContent=`
 .bonus-board{background:linear-gradient(165deg,#554079,#2a2144);border:2px solid #ab9bc3;border-radius:20px;box-shadow:inset 0 2px 16px #160e2766;min-height:180px;padding:14px 10px;margin:10px 0;overflow:hidden}
 .bonus-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:10px;max-width:330px;margin:10px auto}
 .bonus-tile,.bonus-choice,.bonus-arrow{border:2px solid #9d86ad;background:linear-gradient(#574870,#3b3052);box-shadow:0 5px 0 #21182a;color:#fff6ec;border-radius:15px;min-height:64px;font-size:30px;font-weight:900}
 .bonus-tile:active,.bonus-choice:active,.bonus-arrow:active{transform:translateY(3px);box-shadow:0 2px 0 #21182a}
 .bonus-tile.revealed{background:#588475;border-color:#abddc0}
 .bonus-tile.blocked{background:#343344;opacity:.5}
 .bonus-tile.current{background:#8a617d;border-color:#fff5c7}
 .bonus-choice{padding:12px 8px;min-height:72px}
 .bonus-grid.cols5{grid-template-columns:repeat(5,1fr);max-width:335px;gap:4px}
 .bonus-grid.cols5 .bonus-tile{font-size:19px;min-height:44px;border-radius:7px}
 .bonus-choice-row{display:flex;justify-content:center;gap:10px;flex-wrap:wrap;padding:12px 0}
 .bonus-arrow{min-width:70px;min-height:55px;font-size:27px}
 .bonus-meter{height:32px;border:2px solid #bfb1cd;background:linear-gradient(90deg,#db728e 0 36%,#83db9e 36% 64%,#db728e 64%);border-radius:18px;position:relative;margin:20px 9px 25px}
 #bonusMarker{position:absolute;top:-10px;bottom:-10px;width:8px;background:#fff6cc;box-shadow:0 0 6px #130a21;border-radius:4px;left:50%}
 .bonus-btn{display:block;margin:12px auto!important;min-height:60px;width:90%;font-size:18px!important}
 .bonus-info{font-size:14px;font-weight:850;text-align:center;padding:11px;background:#382948;border-radius:14px;color:#ffe3d8}
 .bonus-target{font-size:42px;letter-spacing:9px;text-align:center;padding:15px}
 .bonus-hint{font-size:12px;text-align:center;color:#dec4ec}
 .bonus-timer{color:#b1ffbd;font-size:28px;text-align:center;font-weight:900;padding:8px}
 `;
 document.head.appendChild(style);
 const oldShowGames=showGames,oldStartGame=startGame;
 showGames=function(){
   oldShowGames();
   const grid=$("sheetBody").querySelector(".menu-grid");if(!grid)return;
   grid.insertAdjacentHTML("beforeend",BONUS.map(([id,emoji,title,desc])=>
      `<button class="menu-card" data-bonus="${id}"><span class="emoji">${emoji}</span>${title}<small class="mini">${desc}</small></button>`).join(""));
   const intro=$("sheetBody").querySelector(".intro");
   if(intro)intro.textContent="16 grywalnych minigier: zręczność, pamięć, refleks i odkrywanie. Graj offline, zdobywaj gwiazdki i poprawiaj nastrój pupila.";
 };
 startGame=function(kind){const g=BONUS.find(x=>x[0]===kind);if(g)startBonus(kind);else oldStartGame(kind);};
 const pickRandom=a=>a[Math.floor(Math.random()*a.length)];
 const freshChallenge=g=>{
    switch(g.mode){
      case "fruit":{
       const foods=["🍎","🍐","🍊","🍓","🍇","🍌"],bad=["🪳","🦠","🧅"];
       g.target=pickRandom(foods);
       g.spots=[g.target,pickRandom(bad),pickRandom(bad)].sort(()=>Math.random()-.5);break;
      }
      case "hide":g.target=Math.floor(Math.random()*3);break;
      case "treasure":break;
      case "fishing":case "blocks":case "jump":g.started=Date.now();break;
      case "rhythm":g.beatAt=Date.now()+1600;break;
      case "sort":{
       const items=[["🍎","food"],["🍓","food"],["🍪","food"],["🍣","food"],["🍉","food"],["⚽","toy"],["🧸","toy"],["🎾","toy"],["🪀","toy"],["🪁","toy"]];
       g.item=pickRandom(items);break;
      }
      case "pattern":{
       const pairs=[["◆","●"],["♥","★"],["▲","■"],["☀","☾"],["●","◇"]];
       const pair=pickRandom(pairs);g.pattern=pair[0]+" "+pair[1]+" "+pair[0]+" "+pair[1]+" "+pair[0];g.target=pair[1];
       g.spots=[pair[0],pair[1],pickRandom(["✿","☀","✚","◇"])];break;
      }
      case "dodge":g.target=Math.floor(Math.random()*3);break;
      case "whack":g.target=Math.floor(Math.random()*9);break;
    }
 };
 function startBonus(mode){
   if(!ensurePet())return;
   const row=BONUS.find(x=>x[0]===mode);if(!row)return;
   gameSession={kind:"bonus",mode,started:Date.now(),score:0,round:0,max:row[4],done:false,
     found:[],x:0,y:0,moves:0};
   const g=gameSession;
   if(mode==="treasure"){
     const indices=Array.from({length:9},(_,i)=>i).sort(()=>Math.random()-.5);
     g.treasures=indices.slice(0,4);g.traps=indices.slice(4,6);
   }else if(mode==="maze"){
     g.walls=[6,7,8,11,13,16,17,18].filter(x=>![0,1,2,3,4,9,14,19,24].includes(x));
   }
   freshChallenge(g);
   showSheet(row[1]+" "+row[2],`<p class="intro">${row[3]}</p><div class="bonus-info" id="bonusInfo"></div><div id="bonusBoard" class="bonus-board"></div><button class="secondary" style="width:100%;margin-top:9px" data-go="games">↩ Minigry</button>`,"game");
   renderBonus();
 }
 function tile(v,action,klass=""){
   return `<button class="bonus-tile ${klass}" data-bonuspick="${action}">${v}</button>`;
 }
 function choices(items){
   return `<div class="bonus-choice-row">${items.map(([v,label])=>`<button class="bonus-choice" data-bonuspick="${v}">${label}</button>`).join("")}</div>`;
 }
 function renderBonus(){
   const g=gameSession,board=$("bonusBoard"),info=$("bonusInfo");
   if(!g||g.kind!=="bonus"||!board||g.done)return;
   info.textContent=`Runda ${Math.min(g.max,g.round+1)} / ${g.max} · Wynik: ${g.score}`;
   let html="";
   switch(g.mode){
     case "fruit":
       html=`<p class="bonus-hint">Wybierz świeży owoc 🍎</p>${choices(g.spots.map((v,i)=>[String(i),v]))}`;break;
     case "hide":
       html=`<p class="bonus-hint">Kotek ukrywa się pod jedną z miseczek!</p><div class="bonus-grid">${[0,1,2].map(i=>tile("🥣",i)).join("")}</div>`;break;
     case "treasure":
       html=`<p class="bonus-hint">Odkryj 6 pól. Szukaj 💎!</p><div class="bonus-grid">${Array.from({length:9},(_,i)=>tile(g.found.includes(i)?(g.treasures.includes(i)?"💎":g.traps.includes(i)?"🪨":"✨"):"❔",i,g.found.includes(i)?"revealed":"")).join("")}</div>`;break;
     case "maze":
       html=`<p class="bonus-hint">🦊 Dotknij strzałek, aby dotrzeć do ⭐. Masz 15 ruchów.</p><div class="bonus-grid cols5">${Array.from({length:25},(_,i)=>tile(g.x+g.y*5===i?"🐾":i===24?"⭐":g.walls.includes(i)?"🪨":"·",i,g.walls.includes(i)?"blocked":g.x+g.y*5===i?"current":"")).join("")}</div>
       <div class="bonus-choice-row"><button class="bonus-arrow" data-bonusmove="up">↑</button><button class="bonus-arrow" data-bonusmove="left">←</button><button class="bonus-arrow" data-bonusmove="down">↓</button><button class="bonus-arrow" data-bonusmove="right">→</button></div>`;break;
     case "fishing":case "blocks":case "jump":{
       const icon={fishing:"🎣",blocks:"🧱",jump:"🐰"}[g.mode];
       html=`<div class="bonus-target">${icon}</div><div class="bonus-meter"><div id="bonusMarker"></div></div><button class="primary bonus-btn" data-bonuspick="stop">${g.mode==="fishing"?"🎣 Wyciągnij rybkę":g.mode==="blocks"?"🧱 Postaw klocek":"🐰 Skacz!"}</button><p class="bonus-hint">Traf w zieloną strefę. Wskazówka nie zatrzymuje się!</p>`;break;
     }
     case "rhythm":
       html=`<div id="bonusBeat" class="bonus-timer">♪ ♪ ♪</div><button class="primary bonus-btn" data-bonuspick="tap">🥁 UDERZ W RYTM!</button><p class="bonus-hint">Zielony błysk = idealny moment</p>`;break;
     case "sort":
       html=`<div class="bonus-target">${g.item[0]}</div>${choices([["food","🍎 Jedzenie"],["toy","🧸 Zabawka"]])}`;break;
     case "pattern":
       html=`<div class="bonus-target" style="font-size:25px">${g.pattern} ?</div>${choices(g.spots.map((s,i)=>[String(i),s]))}`;break;
     case "dodge":
       html=`<p class="bonus-hint">Zawierucha w kosmosie! Wybierz bezpieczny tunel</p><div class="bonus-grid">${[0,1,2].map(i=>tile(i===g.target?"✨":"☄️",i)).join("")}</div>`;break;
     case "whack":
       html=`<p class="bonus-hint">Znajdź zwierzaka, zanim schowa się ponownie!</p><div class="bonus-grid">${Array.from({length:9},(_,i)=>tile(i===g.target?"🐹":"🌿",i)).join("")}</div>`;break;
   }
   board.innerHTML=html;
   animateBonusMeter();
 }
 function phase(g){
   if(!g)return .5;
   return .5+.47*Math.sin((Date.now()-g.started)/(g.mode==="blocks"?310:g.mode==="jump"?380:460));
 }
 function animateBonusMeter(){
   const g=gameSession;if(!g||g.kind!=="bonus"||g.done||activeModal!=="game")return;
   const marker=$("bonusMarker");
   if(marker)marker.style.left=(phase(g)*100)+"%";
   if(g.mode==="rhythm"){
     const beat=$("bonusBeat");
     if(beat){
       const delta=g.beatAt-Date.now();
       beat.textContent=Math.abs(delta)<=280?"🟢 TERAZ!":delta>0?`${(delta/1000).toFixed(1)} s`:"🔴 Za późno";
       beat.style.color=Math.abs(delta)<=280?"#9cffa4":delta<0?"#ffa4b2":"#e4d6ef";
     }
     if(Date.now()>g.beatAt+800){
       g.round++;
       if(g.round>=g.max)completeBonus();
       else{freshChallenge(g);renderBonus();}
     }
   }
 }
 function completeBonus(){
   const g=gameSession;if(!g||g.done)return;
   const points=Math.min(20,Math.max(1,Math.round(g.score)));
   finishGame(points,`Wynik: ${g.score} · ${BONUS.find(x=>x[0]===g.mode)?.[2]||"Minigra"}`);
 }
 function bonusAction(value){
   const g=gameSession;if(!g||g.kind!=="bonus"||g.done)return;
   let score=0,correct=false,moveNext=true;
   switch(g.mode){
     case "fruit":correct=g.spots[+value]===g.target;score=correct?2:0;break;
     case "hide":correct=(+value===g.target);score=correct?4:0;break;
     case "treasure":{
       const idx=Number(value);if(!Number.isInteger(idx)||idx<0||idx>8||g.found.includes(idx))return;
       g.found.push(idx);score=g.treasures.includes(idx)?4:g.traps.includes(idx)?0:1;break;
     }
     case "fishing":case "jump":case "blocks":correct=phase(g)>.36&&phase(g)<.64;score=correct?3:0;break;
     case "rhythm":{
       const delta=Math.abs(Date.now()-g.beatAt);
       score=delta<=200?3:delta<=360?1:0;break;
     }
     case "sort":correct=value===g.item[1];score=correct?2:0;break;
     case "pattern":correct=g.spots[Number(value)]===g.target;score=correct?2:0;break;
     case "dodge":correct=Number(value)===g.target;score=correct?2:0;break;
     case "whack":correct=Number(value)===g.target;score=correct?2:0;break;
     default:moveNext=false;break;
   }
   if(!moveNext)return;
   g.score+=score;g.round++;
   sound(score?850:370,.05);
   if(g.round>=g.max){completeBonus();return;}
   freshChallenge(g);
   renderBonus();
 }
 function mazeMove(direction){
   const g=gameSession;if(!g||g.kind!=="bonus"||g.mode!=="maze")return;
   const delta={up:[0,-1],down:[0,1],left:[-1,0],right:[1,0]}[direction];if(!delta)return;
   const x=g.x+delta[0],y=g.y+delta[1];
   if(x<0||x>=5||y<0||y>=5||g.walls.includes(x+y*5)){sound(260,.04);notify("🪨 Ściana!");return;}
   g.x=x;g.y=y;g.round++;g.moves++;
   if(x===4&&y===4){g.score=Math.max(4,24-g.round);completeBonus();return;}
   if(g.round>=g.max){g.score=3;completeBonus();return;}
   renderBonus();
 }
 const overlay=$("overlay");
 overlay.addEventListener("click",e=>{
   const b=e.target.closest("button");if(!b)return;
   if(b.dataset.bonus){startBonus(b.dataset.bonus);return;}
   if(b.dataset.bonuspick!==undefined){bonusAction(b.dataset.bonuspick);return;}
   if(b.dataset.bonusmove!==undefined){mazeMove(b.dataset.bonusmove);return;}
 });
 setInterval(animateBonusMeter,110);
 window.PikoBonusGames={count:BONUS.length,launch:startBonus,action:bonusAction};
})();