(function install(){
 const profiles=[
 ["Kosmiczna","COSMOS","#291b72","#8546d6","#f8b8ff","#f7db94","🪐","✦","cosmos",0],
 ["Lodowa","ARKTYKA","#0b7198","#9bdeeb","#ffffff","#cee8fe","❄️","◆","ice",1],
 ["Wulkaniczna","MAGMA","#5d1426","#dd4a14","#ffd076","#ff7144","🌋","▲","lava",2],
 ["Egipska","FARAON","#8f5b17","#d9ad43","#fff0aa","#3dabc1","𓂀","☀","egypt",3],
 ["Steampunkowa","STEAMPUNK","#443021","#a56d37","#e9c689","#dbb078","⚙️","✧","steampunk",4],
 ["Cukierkowa","CANDY","#ff83b0","#f9d0e5","#ffffff","#a8f8e8","🍭","♡","candy",5],
 ["Japońska","SAKURA","#8a3067","#f2a1c9","#fff4ef","#ffd18f","🌸","❀","sakura",6],
 ["Retro 90s","RETRO 1997","#61598c","#00b4b0","#ffcb48","#f572b0","▣","✳","retro",3],
 ["Leśna","W LESIE","#225b3f","#5fac65","#dcf5ae","#a5cb62","🌿","❧","forest",0],
 ["Oceaniczna","ATLANTYDA","#065474","#1ca8b5","#b0f5e8","#ffd0a3","🐚","〰","ocean",0],
 ["Cyberpunkowa","CYBER CITY","#1e1955","#7044c9","#00f5eb","#ff58c9","⚡","⌁","cyber",1],
 ["Gotycka","NOC","#271b34","#6d476e","#f0d8eb","#a08fae","🦇","✞","gothic",2],
 ["Piracka","KORSARZ","#34435b","#9b603a","#eed3a1","#cd8b54","⚓","☠","pirate",3],
 ["Smocza","SMOCZE JAJO","#4a2430","#b33933","#f5d39a","#d3a44c","🐲","✧","dragon",0],
 ["Dżungla","TROPIKI","#27552f","#7a9b45","#fcef8c","#f7a853","🌴","✿","jungle",4],
 ["UFO","AREA 51","#192e48","#4aa99a","#b3f1c4","#8cedfd","👽","⌾","ufo",1],
 ["Dinozaury","JURA","#47543b","#a4b475","#f2dca4","#dca85f","🦕","⬟","dino",0],
 ["Miodowa","UL","#ba7722","#f7c64d","#fff4b5","#8e5025","🐝","⬡","honey",0],
 ["Różany ogród","RÓŻE","#77364d","#d57191","#fff0c8","#f7b7c8","🌹","❀","roses",0],
 ["Chmurki","NIEBO","#5a91b7","#b0d9ec","#ffffff","#fbe4a1","☁️","✧","clouds",1],
 ["Kryształowa","KRYSZTAŁ","#343e91","#888de9","#d9e5ff","#a4f4ee","💎","◇","crystal",2],
 ["Mecha","ROBO","#2b455a","#6a8b9b","#bff5e9","#ffcb71","🤖","▤","mecha",4],
 ["Księżycowa","LUNA","#273c75","#6872b3","#f0e7cd","#c4cbee","🌙","✦","moon",0],
 ["Wróżkowa","FAIRY","#54366a","#b97ed7","#f2d6fb","#a7e6b6","🧚","✿","fairy",0],
 ["Y2K","RETRO 2000","#225e78","#5fcae8","#fdf4fd","#e5b5f2","💿","✳","y2k",3],
 ["Deszczowa","KROPELKI","#295678","#618db9","#d2e8ff","#a2cae8","☔","☂","rain",1],
 ["Słoneczna","SUNNY","#ad6627","#f3b04d","#fff4b4","#e68646","☀️","✺","sun",0],
 ["Gwiezdna noc","STARS","#20255b","#575ab2","#fff3b8","#9ab9f3","⭐","✦","stars",0],
 ["Puchata","KAWAII","#995d88","#db9ac7","#fff5ef","#f0b2c2","🐻","♡","fluffy",0],
 ["Arcade","ARCADE","#1a4e45","#247d67","#daff6e","#fb85d6","🕹️","▦","arcade",4],
 ["Pustynna","SAHARA","#ad6c3a","#dcad6f","#fff0c6","#c47550","🏜️","◇","desert",3],
 ["Perłowa","PEARL","#66859a","#c3dce6","#fff2fb","#d4c7e6","🐚","✧","pearl",0]
 ];
 // Protects the HTML when drawing SVG text.
 const xml=s=>String(s).replace(/[&<>"]/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"}[c]));
 function shellSvg(p){
   const [name,tag,dark,mid,light,trim,symbol,motif,kind,shape]=p;
   const paths=[
     "M555 78 C286 78 149 329 145 699 C131 1043 284 1288 553 1333 C823 1303 991 1044 981 697 C974 330 828 78 555 78Z",
     "M555 78 C308 75 136 320 141 700 C143 1037 298 1316 556 1330 C832 1323 987 1033 978 700 C975 322 800 75 555 78Z",
     "M556 69 L720 119 Q982 260 990 650 L971 1080 L811 1279 L560 1336 L310 1279 L145 1080 L122 650 Q140 254 391 119Z",
     "M545 99 L666 126 L826 209 L959 404 L987 704 L918 1101 L766 1289 L548 1335 L332 1289 L186 1100 L117 704 L153 403 L287 208 L430 126Z",
     "M555 90 C344 81 177 274 132 616 L137 958 Q181 1230 414 1320 Q553 1377 694 1320 Q930 1228 977 956 L990 614 Q957 275 755 122 C693 85 617 90 555 90Z"
   ];
   const outline=paths[shape]||paths[0];
   const geometry={
    cosmos:`<g opacity=".7">${Array.from({length:19},(_,i)=>`<circle cx="${175+(i*113)%790}" cy="${190+(i*89)%1040}" r="${i%3?5:10}" fill="${i%2?trim:light}"/>`).join("")}<ellipse cx="550" cy="228" rx="76" ry="25" fill="none" stroke="${light}" stroke-width="11" transform="rotate(-16 550 228)"/></g>`,
    ice:`<g fill="${light}" stroke="${trim}" stroke-width="7"><path d="M353 177 397 90 426 227 369 345Z"/><path d="M685 154 757 85 742 325 690 284Z"/><path d="M220 957 263 900 300 1016 259 1100Z"/><path d="M867 932 934 995 869 1120 825 1030Z"/></g>`,
    lava:`<path d="M162 535 Q229 489 190 618 T180 770 M923 538 Q862 583 929 637 T914 767" fill="none" stroke="#ff9a29" stroke-width="43" stroke-linecap="round"/><g fill="${light}"><path d="M406 186 438 125 472 186Z M672 201 699 121 726 201Z M500 1010 534 958 573 1026Z"/></g>`,
    egypt:`<g fill="none" stroke="${trim}" stroke-width="13"><path d="M391 207 548 110 714 207 548 300Z"/><path d="M239 590H153 M964 590H881 M248 710H156 M965 710H878"/><path d="M418 1018H705 M449 1050H673"/></g><circle cx="554" cy="209" r="33" fill="${light}"/>`,
    steampunk:`${[["324","213","69"],["758","220","64"],["209","963","52"],["897","965","60"]].map(([x,y,r])=>`<g transform="translate(${x} ${y})" fill="none" stroke="${trim}" stroke-width="10"><circle r="${r}"/><circle r="${Number(r)*.44}"/>${Array.from({length:8},(_,i)=>`<path d="M0 ${-r-10}v27" transform="rotate(${45*i})"/>`).join("")}</g>`).join("")}`,
    candy:`<g fill="none" stroke="${trim}" stroke-width="27"><path d="M279 172 Q343 261 410 178 Q486 99 560 178 Q640 259 718 171 Q791 106 843 191"/><path d="M205 1024 Q287 942 340 1025 M773 1020 Q835 934 919 1021"/></g><g fill="${light}"><circle cx="418" cy="192" r="24"/><circle cx="707" cy="193" r="24"/></g>`,
    sakura:`<g fill="${light}" opacity=".95">${[[320,220],[765,232],[216,748],[907,743],[336,997],[772,1006]].map(([x,y])=>`<g transform="translate(${x} ${y})">${Array.from({length:5},(_,i)=>`<ellipse cx="0" cy="-27" rx="18" ry="31" transform="rotate(${i*72})"/>`).join("")}<circle r="12" fill="${trim}"/></g>`).join("")}</g>`,
    retro:`<g stroke="${light}" stroke-width="11" fill="none"><path d="m202 399 60 -45 48 45 63-45 M743 369l61-44 49 44 62-44"/><path d="M185 1009h99v-31h60v30 M802 978h70v-30h51"/></g>${[[320,204],[758,200],[228,825],[888,821]].map(([x,y])=>`<rect x="${x}" y="${y}" width="47" height="47" transform="rotate(25 ${x} ${y})" fill="${trim}"/>`).join("")}`,
    forest:`<g fill="none" stroke="${trim}" stroke-width="18" stroke-linecap="round"><path d="M220 1002Q148 752 240 418M899 1002Q970 747 893 409"/><path d="M301 196Q445 110 560 211Q680 106 818 192"/></g>${[[202,528],[224,748],[909,533],[886,754]].map(([x,y],i)=>`<ellipse cx="${x}" cy="${y}" rx="27" ry="60" fill="${light}" transform="rotate(${i%2?42:-34} ${x} ${y})"/>`).join("")}`,
    ocean:`<g fill="none" stroke="${trim}" stroke-width="18" opacity=".8"><path d="M188 557Q236 510 269 555T352 553M761 556Q816 505 865 553T954 550"/><path d="M251 991q65-65 123 0t123 0M636 990q65-65 123 0t123 0"/></g>${[[216,416,22],[920,448,17],[256,768,14],[875,774,22]].map(([x,y,r])=>`<circle cx="${x}" cy="${y}" r="${r}" fill="none" stroke="${light}" stroke-width="8"/>`).join("")}`,
    cyber:`<g fill="none" stroke="${trim}" stroke-width="8"><path d="M180 440h61l44-44M945 436h-61l-44-44M200 900h51v93h86M925 900h-51v93h-86"/><path d="M361 222h109v-50h160v50h118"/></g><g fill="${light}">${Array.from({length:12},(_,i)=>`<rect x="${180+i*70}" y="${980+(i%2)*20}" width="16" height="27"/>`).join("")}</g>`,
    gothic:`<g stroke="${trim}" stroke-width="10" fill="none"><path d="M345 280Q545 60 761 280L707 222L550 159L403 222Z"/><path d="M202 510l59-40-20 83 58 43-67 17-24 91-26-97-52-10 55-46Z"/><path d="M920 510l-59-40 20 83-58 43 67 17 24 91 26-97 52-10-55-46Z"/></g>`,
    default:`<g opacity=".85">${[[321,218],[796,217],[218,567],[921,572],[223,910],[905,910],[341,1013],[773,1013]].map(([x,y],i)=>`<circle cx="${x}" cy="${y}" r="${(i%3+1)*9}" fill="${i%2?trim:light}" stroke="${dark}" stroke-width="4"/>`).join("")}</g>`
   };
   const decor=geometry[kind]||geometry.default;
   const medallion=`<g transform="translate(560,230)"><circle r="93" fill="${dark}" fill-opacity=".66" stroke="${trim}" stroke-width="13"/><circle r="78" fill="none" stroke="${light}" stroke-width="5" stroke-dasharray="13 9"/><text x="0" y="17" font-size="86" text-anchor="middle" font-family="sans-serif">${xml(symbol)}</text></g>`;
   const body=`<path d="${outline}" fill="url(#body)" stroke="${trim}" stroke-width="21"/><path d="${outline}" fill="none" stroke="${light}" stroke-opacity=".42" stroke-width="7" transform="translate(0,-6) scale(1,.988)"/>`;
   return `<svg xmlns="http://www.w3.org/2000/svg" width="1122" height="1402" viewBox="0 0 1122 1402"><defs>
     <linearGradient id="body" x1="0" y1="0" x2=".93" y2="1"><stop offset="0" stop-color="${light}"/><stop offset=".26" stop-color="${mid}"/><stop offset=".7" stop-color="${dark}"/><stop offset="1" stop-color="${mid}"/></linearGradient>
     <linearGradient id="screen" x1="0" y1="0" x2="1" y2="1"><stop stop-color="${light}"/><stop offset=".5" stop-color="${trim}"/><stop offset="1" stop-color="${dark}"/></linearGradient>
     <radialGradient id="button"><stop stop-color="#fff7f8"/><stop offset=".3" stop-color="${light}"/><stop offset=".7" stop-color="${mid}"/><stop offset="1" stop-color="${dark}"/></radialGradient>
     <pattern id="dots" width="34" height="34" patternUnits="userSpaceOnUse"><circle cx="8" cy="8" r="3" fill="${light}" opacity=".58"/></pattern>
     <clipPath id="clip"><path d="${outline}"/></clipPath>
     </defs>
     <ellipse cx="560" cy="58" rx="60" ry="47" fill="${trim}" stroke="${dark}" stroke-width="14"/>
     <ellipse cx="560" cy="56" rx="35" ry="25" fill="${dark}" stroke="${light}" stroke-width="6"/>
     ${body}
     <g clip-path="url(#clip)"><path d="${outline}" fill="url(#dots)" opacity=".36"/><path d="M238 313Q323 184 408 176" fill="none" stroke="#fff" stroke-width="27" opacity=".25" stroke-linecap="round"/>${decor}</g>
     ${medallion}
     <g><rect x="234" y="393" width="654" height="549" rx="47" fill="${dark}" stroke="${trim}" stroke-width="27"/><rect x="248" y="405" width="625" height="523" rx="29" fill="${light}" stroke="${mid}" stroke-width="16"/><rect x="256" y="411" width="606" height="512" rx="13" fill="#e9f4dd"/></g>
     <text x="560" y="987" font-size="47" font-weight="900" text-anchor="middle" font-family="sans-serif" fill="${light}" stroke="${dark}" stroke-width="4" paint-order="stroke">${xml(tag)}</text>
     ${[[339,1105],[552,1168],[762,1105]].map(([x,y],i)=>`<g><ellipse cx="${x}" cy="${y+9}" rx="84" ry="64" fill="${dark}" stroke="${trim}" stroke-width="10"/><ellipse cx="${x}" cy="${y}" rx="64" ry="48" fill="url(#button)" stroke="${light}" stroke-width="8"/><ellipse cx="${x-17}" cy="${y-16}" rx="27" ry="11" fill="#fff" opacity=".38"/></g>`).join("")}
     <text x="560" y="1302" font-size="56" fill="${light}" text-anchor="middle" font-family="sans-serif" opacity=".92">${xml(motif)}　${xml(name)}　${xml(motif)}</text>
     </svg>`;
 }
 const shellCache=profiles.map(p=>"data:image/svg+xml;charset=utf-8,"+encodeURIComponent(shellSvg(p)));
 // Original 32 brokatowe obudowy z PikoPet 1.x (obraz oryginalny + oryginalne barwy).
 const classics=THEMES.map(t=>({...t,kind:"classic",classic:true,art:SHELL_SRC}));
 // New Deluxe indexes 0..31 stay unchanged: existing Deluxe save keeps its chosen shell.
 // Classic variants are appended as 32..63 to avoid altering the saved selection.
 THEMES.splice(0,THEMES.length,...profiles.map((p,i)=>({name:p[0],hue:0,sat:1,bright:1,kind:p[8],classic:false,art:shellCache[i]})),...classics);
 const css=document.createElement("style");css.textContent=`
 #shellImage{filter:none!important}
 #shellImage.skin-classic{filter:hue-rotate(var(--hue)) saturate(var(--sat)) brightness(var(--bright,1))!important}
 .skin-tile img{object-fit:contain!important;filter:none!important;image-rendering:auto}
 .skin-tile img.classic-preview{filter:var(--skin-color)!important}
 .shell-tabs{display:flex;gap:8px;margin:12px 0;position:sticky;top:0;z-index:3;padding:7px 0;background:#21152af0}
 .shell-tabs button{flex:1;min-width:0;min-height:42px;border-radius:14px;border:2px solid #ad89b8;background:#30203e;color:#ffe4f4;font-weight:900}
 .shell-tabs button.active{border-color:#ffe8ac;background:#674679;color:#ffffff}
 .skin-tile{min-height:166px}
 .skin-tile span{line-height:1.25!important}
 .mini-status{display:flex;align-items:center;gap:6px;justify-content:space-between;padding:9px 12px;border-radius:12px;border:1px solid #c2a0df55;background:#39284e;color:#ffebfc;font-size:12px;font-weight:800}
 .activity-card{display:grid;grid-template-columns:47px 1fr auto;align-items:center;gap:10px;margin:9px 0;padding:10px;border:1px solid #af8dbd88;border-radius:14px;background:#30213f;color:#fff3db}
 .activity-card b{display:block}.activity-card small{display:block;color:#d6bade;font-size:12px;margin-top:3px}
 .activity-card button{padding:8px 11px!important}
 .activity-emoji{font-size:34px}
 .pet-mood{font-size:12px;color:#a9ffc6;margin:8px 0 12px}
 `;document.head.appendChild(css);
 let previousSkin=-1,prevRenderUI=renderUI;
 renderUI=function(){
   prevRenderUI();
   if(previousSkin!==S.theme){
     previousSkin=S.theme;
     const shell=THEMES[S.theme]||THEMES[0];
     $('shellImage').classList.toggle("skin-classic",!!shell?.classic);
     $('shellImage').src=shell?.art||shellCache[0];
   }
 };
 let shellGroup=S.theme>=profiles.length?"classic":"new";
 showThemes=function(){
    const from=shellGroup==="classic"?profiles.length:0;
    const to=from+32;
    showSheet("🎨 64 wymienne obudowy",
      `<p class="intro"><b>32 klasyczne brokatowe + 32 nowe Deluxe</b>. Stare wzory wróciły bez utraty nowych, a zwierzak i zapis pozostają bez zmian.</p>
      <div class="shell-tabs"><button data-shellgroup="new" class="${shellGroup==="new"?"active":""}">✨ Nowe (32)</button><button data-shellgroup="classic" class="${shellGroup==="classic"?"active":""}">🥚 Klasyczne (32)</button></div>
      <div class="skin-grid">${
        THEMES.slice(from,to).map((t,n)=>{
          const i=n+from;
          const style=t.classic?` style="--skin-color:hue-rotate(${t.hue}deg) saturate(${t.sat}) brightness(${t.bright})"`:"";
          return `<button class="skin-tile ${S.theme===i?'active':''}" data-theme="${i}">
             <img ${t.classic?'data-classic-shell="1"':''} ${t.classic?'':'src="'+t.art+'"'} class="${t.classic?'classic-preview':''}"${style} alt="${xml(t.name)}">
             <span>${i+1}. ${xml(t.name)}</span>
           </button>`;
        }).join("")
      }</div>`,"themes");
    if(shellGroup==="classic")document.querySelectorAll("[data-classic-shell]").forEach(img=>{img.src=SHELL_SRC;});
 };
 $("overlay").addEventListener("click",e=>{
   const button=e.target.closest("[data-shellgroup]");
   if(!button)return;
   shellGroup=button.dataset.shellgroup==="classic"?"classic":"new";
   showThemes();
 });
 const activities=[
  {id:"stroke",icon:"🐾",name:"Głaskanie",desc:"Pogłaszcz pupila i obserwuj serduszka",happy:6,affection:10,energy:0},
  {id:"bath",icon:"🛁",name:"Kąpiel",desc:"Piana, bąbelki i czyste futerko",happy:5,clean:32,energy:-2},
  {id:"walk",icon:"🌳",name:"Spacer",desc:"Odkryjcie okolicę, czasem znajdziesz prezent",happy:15,energy:-13,hunger:-8},
  {id:"ball",icon:"⚽",name:"Aportowanie",desc:"Rzucanie piłki i wesołe podskoki",happy:16,energy:-9,affection:4},
  {id:"brush",icon:"🪮",name:"Czesanie",desc:"Nowa fryzura, lepszy nastrój",happy:7,clean:14,affection:4},
  {id:"dance",icon:"🎵",name:"Wspólny taniec",desc:"Pupil tańczy i macha łapkami",happy:17,energy:-11},
  {id:"story",icon:"📖",name:"Bajka na dobranoc",desc:"Spokój i odprężenie",happy:7,energy:9,affection:8},
  {id:"bubbles",icon:"🫧",name:"Bańki mydlane",desc:"Łapanie bąbelków w powietrzu",happy:13,clean:5},
  {id:"tickle",icon:"💞",name:"Łaskotki",desc:"Śmieszne miny i skakanie",happy:11,affection:5},
  {id:"sing",icon:"🎤",name:"Śpiewanie",desc:"Twój pupil nuci własną melodię",happy:12,energy:-3},
  {id:"picnic",icon:"🧺",name:"Piknik",desc:"Odpoczynek na świeżym powietrzu",happy:9,energy:7,affection:6},
  {id:"gift",icon:"🎁",name:"Mały prezent",desc:"Niespodzianka dla Twojego pupila",happy:15,affection:9,cost:12}
 ];
 let activityEffect=null,activityAt=0,lastPet=0;
 const favorites={śpioch:"story",łobuziak:"tickle",łasuch:"picnic",ciekawski:"walk",nieśmiały:"brush",energiczny:"ball",spokojny:"stroke",przytulaśny:"stroke"};
 function applyActivity(id){
   if(!ensurePet())return;
   if(S.pet.sleeping){notify("Pupil śpi. Najpierw obudź go w menu snu!");return;}
   const a=activities.find(x=>x.id===id);if(!a)return;
   if(a.cost&&!spend(a.cost))return;
   const p=S.pet;
   let happy=a.happy||0,aff=a.affection||0;
   const favourite=favorites[p.personality];
   if(favourite===a.id){happy+=7;aff+=4;}
   const moodPenalty=(p.energy<18&&a.energy<0)?-.5:1;
   p.happy=clamp(p.happy+happy*moodPenalty);
   p.affection=clamp(p.affection+aff);
   p.energy=clamp(p.energy+(a.energy||0));
   p.hunger=clamp(p.hunger+(a.hunger||0));
   p.clean=clamp(p.clean+(a.clean||0));
   S.stats.play++; S.stats.care++; tickGoal("play");
   if(id==="bath"){S.stats.clean++;tickGoal("clean");}
   const find=Math.random()<.13&&id==="walk"?Math.floor(rand(5,24)):0;
   if(find){gainCoins(find);notify("🎁 Znalazłeś "+find+" gwiazdek!");}
   else notify(a.icon+" "+a.name+(favourite===a.id?" — ulubiona zabawa! 💖":"!"));
   writeJournal(`${p.name}: ${a.name}. ${favourite===a.id?"To jego ulubiona czynność!":""}`);
   activityEffect=id;activityAt=Date.now();
   sound(id==="sing"?900:690,.1);
   save();renderUI();
   if(activeModal==="activities")showActivities();
 }
 function showActivities(){
   if(!ensurePet())return;
   const p=S.pet,fav=favorites[p.personality]||"stroke";
   showSheet("💞 Zabawy i opieka",`
   <div class="mini-status">🐾 ${esc(p.name)} <span>😊 ${Math.round(p.happy)}% · 💗 ${Math.round(p.affection)}%</span></div>
   <p class="pet-mood">Charakter: <b>${esc(p.personality)}</b>. Ulubiona aktywność: ${activities.find(x=>x.id===fav)?.name||"Głaskanie"}.</p>
   ${activities.map(a=>`<div class="activity-card"><span class="activity-emoji">${a.icon}</span><span><b>${a.name}${a.id===fav?" ⭐":""}</b><small>${a.desc}</small></span><button class="secondary" data-activity="${a.id}">${a.cost?a.cost+" ✦":"Baw się"}</button></div>`).join("")}
   <p class="hint">Dłuższa zabawa męczy pupila. Gdy jest senny, daj mu odpocząć.</p>`,"activities");
 }
 // Add a dedicated interactive-care entry, with no new visible bar under the shell.
 const oldShowMenu=showMenu;
 showMenu=function(){
   oldShowMenu();
   const grid=$("sheetBody").querySelector(".menu-grid");
   grid?.insertAdjacentHTML("afterbegin",'<button class="menu-card" data-go="activities"><span class="emoji">💞</span>Opieka i zabawy<small class="mini">12 aktywności</small></button>');
 };
 const oldSettings=showSettings;
 showSettings=function(){
   oldSettings();
   const actions=$("sheetBody").querySelector(".action-list");
   actions?.insertAdjacentHTML("afterbegin",'<button class="primary" data-go="activities">💞 12 zabaw z pupilem</button>');
 };
 const oldRoute=route;
 route=function(where){if(where==="activities")showActivities();else oldRoute(where);};
 $("overlay").addEventListener("click",e=>{
   const b=e.target.closest("[data-activity]");
   if(b)applyActivity(b.dataset.activity);
 });
 // Reward finger swipes on the LCD without eliminating the original single-tap actions.
 let fingerStart=null;
 const viewport=$("lcdViewport");
 viewport.addEventListener("pointerdown",e=>{
   fingerStart={x:e.clientX,y:e.clientY,t:Date.now()};
 });
 viewport.addEventListener("pointerup",e=>{
   if(!fingerStart)return;
   const distance=Math.hypot(e.clientX-fingerStart.x,e.clientY-fingerStart.y);
   fingerStart=null;
   if(distance>24&&S.pet?.alive&&!S.pet.sleeping&&Date.now()-lastPet>5000){
     lastPet=Date.now();applyActivity("stroke");
   }
 });
 const prevDraw=draw;
 draw=function(){
   prevDraw();
   if(Date.now()-activityAt>3200||!S.pet?.alive)return;
   ctx.save();ctx.imageSmoothingEnabled=false;
   const phase=Math.floor((Date.now()-activityAt)/300);
   switch(activityEffect){
     case "stroke":case "tickle":case "gift":pixelHeart(17+(phase%4)*13,10+((phase*3)%5),PINK);break;
     case "ball":px(66-(phase%5)*7,48-(phase%2)*10,10,10,"#e774ab");px(68-(phase%5)*7,50-(phase%2)*10,6,6,"#fff6dc");break;
     case "bath":case "bubbles":for(let i=0;i<4;i++){ctx.strokeStyle="#7ccde4";ctx.lineWidth=2;ctx.strokeRect(10+i*22,47-(phase+i)%8*5,6,6);}break;
     case "sing":case "dance":px(14,17-(phase%2)*5,4,4,"#543264");px(76,10+(phase%3)*4,5,4,"#543264");break;
     case "story":case "picnic":pixelHeart(73,15,"#e3ad8e");break;
     case "walk":case "brush":pixelHeart(15,15,"#85bc9c");break;
   }
   ctx.restore();
 };
 // Dynamic contexts and old saved theme selection still survive this expansion.
 renderUI();
 window.PikoFeaturePack={showActivities,applyActivity,shellCount:THEMES.length,activities:activities.length};
})();