(function seasonalTamagotchiMusic(){
 const KEY='tama_music_settings_v1';
 let prefs={enabled:false,volume:35,season:'auto'};try{Object.assign(prefs,JSON.parse(localStorage.getItem(KEY)||'{}'))}catch(e){}
 const melodies={
 spring:[[64,1],[67,1],[69,1],[72,2],[71,1],[69,1],[67,2],[64,1],[67,1],[72,1],[76,2],[74,1],[72,1],[69,2]],
 summer:[[72,1],[76,1],[79,1],[76,1],[74,1],[72,1],[69,2],[72,1],[74,1],[76,1],[81,2],[79,1],[76,1],[72,2]],
 autumn:[[69,1],[72,1],[71,1],[67,2],[64,1],[67,1],[69,2],[72,1],[71,1],[69,1],[64,2],[62,1],[64,1],[67,2]],
 winter:[[76,1],[74,1],[72,1],[69,2],[72,1],[74,1],[76,2],[79,1],[76,1],[74,1],[72,2],[69,1],[72,1],[76,2]],
 jingle:[[64,1],[64,1],[64,2],[64,1],[64,1],[64,2],[64,1],[67,1],[60,1],[62,1],[64,4],[65,1],[65,1],[65,1],[65,1],[65,1],[64,1],[64,1],[64,1],[64,1],[62,1],[62,1],[64,1],[62,2],[67,2]],
 christmas:[[67,1],[71,1],[74,2],[72,1],[71,1],[67,2],[64,1],[67,1],[69,2],[67,2],[71,1],[74,1],[76,2],[74,1],[72,1],[71,2],[69,1],[67,1],[64,2],[67,2]],
 deck:[[72,1],[70,1],[69,1],[67,1],[65,1],[67,1],[69,1],[65,1],[67,1],[69,1],[70,1],[67,1],[69,2],[67,2],[65,1],[67,1],[69,1],[65,1],[67,1],[69,1],[70,1],[67,1],[69,1],[67,1],[65,1],[64,1],[65,2],[65,2]],
 wish:[[67,1],[72,1],[72,1],[74,1],[72,1],[71,1],[69,2],[69,1],[74,1],[74,1],[76,1],[74,1],[72,1],[71,2],[67,1],[76,1],[76,1],[77,1],[76,1],[74,1],[72,2],[69,1],[67,1],[69,1],[74,1],[71,1],[72,3]],
 silent:[[67,2],[69,1],[67,2],[64,3],[67,2],[69,1],[67,2],[64,3],[74,2],[74,1],[71,3],[72,2],[72,1],[67,3],[69,2],[69,1],[72,1],[71,1],[69,1],[67,2],[69,1],[67,2],[64,3]],
 tree:[[67,1],[72,1],[72,1],[72,1],[74,1],[76,1],[76,1],[76,1],[76,1],[74,1],[76,1],[77,1],[71,1],[74,1],[72,2],[67,1],[72,1],[72,1],[72,1],[74,1],[76,1],[76,1],[76,1],[76,1],[74,1],[76,1],[77,1],[71,1],[74,1],[72,2]],
 joy:[[72,2],[71,1],[69,1],[67,2],[65,1],[64,1],[62,2],[60,2],[67,1],[69,1],[69,1],[71,1],[71,1],[72,1],[72,2],[72,1],[71,1],[69,1],[67,1],[65,1],[64,1],[72,2]],
 snowglobe:[[72,1],[76,1],[79,2],[81,1],[79,1],[76,2],[74,1],[72,1],[69,2],[72,1],[74,1],[76,2],[79,2],[76,1],[74,1],[72,2]],
 sleigh:[[79,1],[76,1],[72,1],[74,1],[76,1],[79,1],[81,2],[79,1],[76,1],[74,1],[72,1],[69,2],[72,1],[76,1],[79,1],[84,2],[81,1],[79,1],[76,2]]
 };
 const labels={auto:'Automatycznie',spring:'🌸 Wiosna',summer:'☀️ Lato',autumn:'🍂 Jesień',winter:'❄️ Zima',jingle:'🔔 Jingle Bells',christmas:'🎄 Świąteczna nostalgia',deck:'🎊 Deck the Halls',wish:'🎁 We Wish You a Merry Christmas',silent:'🌙 Cicha noc',tree:'🌲 O Christmas Tree',joy:'⭐ Joy to the World',snowglobe:'❄️ Śnieżna kula',sleigh:'🛷 Saneczkowa przygoda'};
 let ctx=null,timer=null,step=0,playing=false;
 function season(){if(prefs.season!=='auto')return prefs.season;const m=new Date().getMonth();return m>=2&&m<=4?'spring':m>=5&&m<=7?'summer':m>=8&&m<=10?'autumn':'winter'}
 function persist(){localStorage.setItem(KEY,JSON.stringify(prefs))}
 function note(midi,beats){
  if(!ctx)return;
  const now=ctx.currentTime,osc=ctx.createOscillator(),gain=ctx.createGain();
  osc.type='triangle';osc.frequency.value=440*Math.pow(2,(midi-69)/12);
  const duration=Math.min(.72,beats*.24);
  gain.gain.setValueAtTime(0,now);gain.gain.linearRampToValueAtTime(prefs.volume/100*.055,now+.025);gain.gain.exponentialRampToValueAtTime(.0001,now+duration);
  osc.connect(gain);gain.connect(ctx.destination);osc.start(now);osc.stop(now+duration+.01);
 }
 function tick(){if(!playing||!ctx)return;const notes=melodies[season()],n=notes[step%notes.length];step++;note(n[0],n[1]);timer=setTimeout(tick,n[1]*285+45)}
 function stop(){playing=false;if(timer)clearTimeout(timer);timer=null;if(ctx){ctx.close().catch(()=>{});ctx=null}}
 function start(){if(!prefs.enabled||playing||document.hidden)return;try{ctx=new (window.AudioContext||window.webkitAudioContext)();ctx.resume().then(()=>{if(!playing){playing=true;step=0;tick()}}).catch(()=>{})}catch(e){}}
 function set(k,v){prefs[k]=v;persist();stop();if(prefs.enabled)start();if(activeModal==='settings')showSettings()}
 document.addEventListener('visibilitychange',()=>{if(document.hidden)stop();else if(prefs.enabled)start()});
 document.addEventListener('pointerdown',()=>{if(prefs.enabled&&!playing)start()},{passive:true});
 const previousSettings=showSettings;
 showSettings=function(){previousSettings();if(activeModal!=='settings')return;
 const b=$('sheetBody'),section=document.createElement('div');
 section.innerHTML='<div class="section-label">🎵 Muzyka retro — pory roku i świąteczne melodie</div><div class="settings-row"><strong>🎶 Muzyka: '+(prefs.enabled?'WŁ.':'WYŁ.')+'</strong><button class="toggle '+(prefs.enabled?'on':'')+'" data-music-toggle="1">'+(prefs.enabled?'Wyłącz':'Włącz')+'</button></div><div class="settings-row"><strong>🎼 Melodia: '+labels[season()]+'</strong><select id="tamaMusicSeason" style="max-width:155px;background:#332441;color:white;border:1px solid #a782c8;border-radius:8px;padding:8px">'+Object.keys(labels).map(k=>'<option value="'+k+'" '+(prefs.season===k?'selected':'')+'>'+labels[k]+'</option>').join('')+'</select></div><div class="settings-row"><strong>🔉 Głośność muzyki: '+prefs.volume+'%</strong><input id="tamaMusicVolume" type="range" min="0" max="100" step="5" value="'+prefs.volume+'" style="max-width:125px"></div><p class="hint">Klasyczne melodie świąteczne i autorskie motywy 8-bit: Świąteczna nostalgia, Śnieżna kula i Saneczkowa przygoda. W trybie automatycznym melodia zmienia się wraz z porą roku. Muzyka zatrzymuje się po przejściu aplikacji do tła; ustawienie zostaje zapisane.</p>';
 b.insertBefore(section,b.querySelector('.section-label')||b.firstChild);
 };
 $('overlay').addEventListener('click',e=>{if(e.target.closest('[data-music-toggle]'))set('enabled',!prefs.enabled)});
 $('overlay').addEventListener('change',e=>{if(e.target.id==='tamaMusicSeason')set('season',e.target.value);if(e.target.id==='tamaMusicVolume')set('volume',Number(e.target.value))});
 window.TamagotchiMusic={start,stop,season};
})();