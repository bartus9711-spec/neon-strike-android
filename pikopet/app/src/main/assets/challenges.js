(function installChallenges(){
  const defs=[
    ['snake','🐍','Wąż – survival','Steruj po planszy, zbieraj owoce, nie uderzaj w ściany ani ogon.'],
    ['sokoban','📦','Skrzynki – łamigłówki','Przesuń wszystkie skrzynie na zaznaczone miejsca. Można je pchać, nie ciągnąć.'],
    ['merge','🔢','Kafelki 2048','Łącz cyfry w dowolnym kierunku, aby osiągnąć 256. Każdy ruch ma znaczenie.'],
    ['secret','🗝️','Tajemniczy labirynt','Odszukaj klucz i dwa skarby. Dopiero wtedy odblokujesz drzwi.']
  ];
  const style=document.createElement('style');
  style.textContent=`
  .challenge-board{display:grid;gap:3px;margin:12px auto;max-width:340px;width:100%;touch-action:none;user-select:none}
  .challenge-board.cols10{grid-template-columns:repeat(10,minmax(0,1fr))}
  .challenge-board.cols8{grid-template-columns:repeat(8,minmax(0,1fr))}
  .challenge-board.cols9{grid-template-columns:repeat(9,minmax(0,1fr))}
  .challenge-board.cols4{grid-template-columns:repeat(4,minmax(0,1fr))}
  .challenge-cell{aspect-ratio:1;display:flex;align-items:center;justify-content:center;border-radius:5px;font-size:clamp(12px,3.5vw,22px);background:#5c4c78;color:#ffeede;font-weight:900}
  .challenge-cell.wall{background:#251b39;border:1px solid #6b617e}
  .challenge-cell.head{background:#b1f1ba;color:#213c31}
  .challenge-cell.body{background:#70bda5;border:2px solid #bcefd3}
  .challenge-cell.food{background:#b178a0}
  .challenge-cell.goal{background:#ad9677}
  .challenge-cell.crate{background:#d8a272;border:2px solid #f5cf95}
  .challenge-cell.hero{background:#a4d3d2}
  .challenge-cell.n2{background:#f1dfbd;color:#402d45}
  .challenge-cell.n4{background:#edd1a4;color:#402d45}
  .challenge-cell.n8{background:#e8ab71;color:#402d45}
  .challenge-cell.n16{background:#dd8b72}
  .challenge-cell.n32{background:#c979b5}
  .challenge-cell.n64{background:#9d75ca}
  .challenge-cell.n128,.challenge-cell.n256,.challenge-cell.n512{background:#90dec7;color:#163e34}
  .challenge-controls{display:grid;grid-template-columns:repeat(3,minmax(52px,70px));gap:7px;justify-content:center;margin:12px auto}
  .challenge-controls button{height:54px;font-size:26px!important;border-radius:12px;border:2px solid #c5aad9;background:#604a75;color:#fff5e2;font-weight:900}
  .challenge-controls button:active{background:#9c72ac;transform:scale(.95)}
  .challenge-banner{border:1px solid #ad94bd;padding:12px;border-radius:13px;background:#3c3054;font-weight:800;text-align:center;margin:10px 0}
  .challenge-sub{color:#f3d4f6;font-size:12px;text-align:center}
  `;
  document.head.appendChild(style);
  const oldShowGames=showGames;
  showGames=function(){
    oldShowGames();
    const grid=$('sheetBody')?.querySelector('.menu-grid');
    if(grid)grid.insertAdjacentHTML('afterbegin',defs.map(d=>`<button class="menu-card" data-challenge="${d[0]}"><span class="emoji">${d[1]}</span>${d[2]}<small class="mini">${d[3]}</small></button>`).join(''));
    const intro=$('sheetBody')?.querySelector('.intro');
    if(intro)intro.textContent='20 minigier, w tym nowe wyzwania z ruchem i zagadkami. Trudniejsze gry wymagają planowania, a nie jednego trafienia w zielony pasek.';
  };
  const randInt=n=>Math.floor(Math.random()*n);
  const maps=[
    ['########','#......#','#..g...#','#..b...#','#..p...#','#......#','#......#','########'],
    ['########','#......#','#..gg..#','#..bb..#','#...p..#','#......#','#......#','########'],
    ['########','#......#','#..g.g.#','#..b.b.#','#...p..#','#......#','#......#','########']
  ];
  let G=null;
  function cell(ch,cls){return `<div class="challenge-cell ${cls||''}">${ch||''}</div>`;}
  function start(id){
    if(!ensurePet())return;
    const d=defs.find(x=>x[0]===id);if(!d)return;
    G={id,score:0,done:false,step:0,level:0,turns:0,started:Date.now()};
    gameSession={kind:'challenge',mode:id,done:false};
    if(id==='snake'){
      G.snake=[[4,5],[3,5],[2,5]];
      G.dx=1;G.dy=0;G.want=[1,0];G.last=Date.now();G.apples=0;apple();
    }else if(id==='merge'){
      G.tiles=Array(16).fill(0);newTile();newTile();
    }else if(id==='sokoban')loadMap(0);
    else{
      G.grid=['#########','#...#...#','#.#...#.#','#.#.#.#.#','#...#k..#','###.###.#','#...#...#','#.#....d#','#########'];
      G.x=1;G.y=1;G.hasKey=false;G.treasure=new Set(['7,1','1,6']);G.found=0;
    }
    showSheet(d[1]+' '+d[2],`<p class="intro">${d[3]}</p><div class="challenge-banner" id="challengeInfo"></div><div class="challenge-board" id="challengeBoard"></div><div class="challenge-controls"><span></span><button data-hardmove="up">↑</button><span></span><button data-hardmove="left">←</button><button data-hardmove="down">↓</button><button data-hardmove="right">→</button></div><div class="action-list"><button class="secondary" data-hardundo="1">↶ Cofnij ruch</button><button class="secondary" data-hardrestart="1">⟲ Od nowa</button><button class="secondary" data-go="games">↩ Lista minigier</button></div><p class="challenge-sub">Możesz też przesuwać palcem po planszy.</p>`,'game');
    render();
  }
  function apple(){
    const used=new Set(G.snake.map(s=>s.join(',')));
    const spots=[];for(let y=0;y<10;y++)for(let x=0;x<10;x++)if(!used.has(x+','+y))spots.push([x,y]);
    G.food=spots.length?spots[randInt(spots.length)]:null;
  }
  function loadMap(index){
    G.level=index;G.walls=new Set();G.goals=new Set();G.boxes=new Set();G.undo=[];
    for(let y=0;y<8;y++)for(let x=0;x<8;x++){
      const c=maps[index][y][x],k=x+','+y;
      if(c==='#')G.walls.add(k);
      if(c==='g')G.goals.add(k);
      if(c==='b')G.boxes.add(k);
      if(c==='p'){G.x=x;G.y=y;}
    }
  }
  function newTile(){
    const empties=G.tiles.map((x,i)=>x===0?i:-1).filter(x=>x>=0);
    if(empties.length)G.tiles[empties[randInt(empties.length)]]=Math.random()<.9?2:4;
  }
  function clearChallenge(){
    G=null;
    if(gameSession?.kind==='challenge')gameSession=null;
  }
  function finish(message,points){
    if(!G||G.done)return;
    G.done=true;const score=Math.min(30,Math.max(3,points));
    G=null;
    if(gameSession?.kind!=='challenge')return;
    finishGame(score,message);
  }
  function move(dir){
    if(!G||G.done||gameSession?.kind!=='challenge'||activeModal!=='game')return;
    if(G.id==='snake'){
      const choices={up:[0,-1],down:[0,1],left:[-1,0],right:[1,0]};
      const d=choices[dir];
      if(d&&(d[0]!==-G.dx||d[1]!==-G.dy))G.want=d;
      return;
    }
    if(G.id==='merge'){
      let moved=false,points=0;
      for(let line=0;line<4;line++){
        let ids=[];
        for(let i=0;i<4;i++){
          if(dir==='left')ids.push(line*4+i);
          else if(dir==='right')ids.push(line*4+3-i);
          else if(dir==='up')ids.push(i*4+line);
          else ids.push((3-i)*4+line);
        }
        const values=ids.map(i=>G.tiles[i]).filter(Boolean);
        const out=[];
        for(let k=0;k<values.length;k++){
          if(values[k]===values[k+1]){
            const sum=values[k]*2;out.push(sum);points+=sum;k++;
          }else out.push(values[k]);
        }
        while(out.length<4)out.push(0);
        for(let k=0;k<4;k++){if(G.tiles[ids[k]]!==out[k])moved=true;G.tiles[ids[k]]=out[k];}
      }
      if(moved){
        G.score+=points;G.turns++;newTile();sound(490+Math.min(500,points),.06);
        if(G.tiles.some(x=>x>=256)){finish('Dotarłeś do 256! Mistrz łączenia!',30);return;}
        const full=G.tiles.every(Boolean);
        const any=G.tiles.some((v,i)=>i%4!==3&&G.tiles[i+1]===v)||G.tiles.some((v,i)=>i<12&&G.tiles[i+4]===v);
        if(full&&!any){finish('Plansza pełna. Udało się stworzyć '+Math.max(...G.tiles)+'.',Math.floor(Math.log2(Math.max(...G.tiles))*3));return;}
      }
    }else if(G.id==='sokoban'){
      const d={up:[0,-1],down:[0,1],left:[-1,0],right:[1,0]}[dir];
      if(!d)return;
      const nx=G.x+d[0],ny=G.y+d[1],n=nx+','+ny;
      if(G.walls.has(n)||nx<0||nx>=8||ny<0||ny>=8)return;
      const snapshot={x:G.x,y:G.y,boxes:[...G.boxes]};
      if(G.boxes.has(n)){
        const bx=nx+d[0],by=ny+d[1],b=bx+','+by;
        if(bx<0||bx>=8||by<0||by>=8||G.boxes.has(b)||G.walls.has(b))return;
        G.boxes.delete(n);G.boxes.add(b);
      }
      G.undo.push(snapshot);if(G.undo.length>60)G.undo.shift();
      G.x=nx;G.y=ny;G.turns++;
      if([...G.goals].every(g=>G.boxes.has(g))){
        if(G.level===maps.length-1){finish('Wszystkie skrzynie ustawione! '+G.turns+' ruchów.',Math.max(12,29-Math.floor(G.turns/5)));return;}
        loadMap(G.level+1);notify('📦 Nowy poziom!');sound(900,.13);
      }
    }else if(G.id==='secret'){
      const d={up:[0,-1],down:[0,1],left:[-1,0],right:[1,0]}[dir];if(!d)return;
      const nx=G.x+d[0],ny=G.y+d[1],v=G.grid[ny]?.[nx];
      if(!v||v==='#')return;
      if(v==='d'&&(!G.hasKey||G.found<2)){notify('🔒 Potrzebujesz klucza i dwóch skarbów!');return;}
      G.x=nx;G.y=ny;G.turns++;
      if(v==='k'&&!G.hasKey){G.hasKey=true;notify('🗝️ Klucz znaleziony!');sound(840,.12);}
      const k=nx+','+ny;if(G.treasure.has(k)){G.treasure.delete(k);G.found++;notify('💎 Skarb '+G.found+'/2');}
      if(v==='d'&&G.hasKey&&G.found===2){finish('Pokonałeś labirynt! '+G.turns+' kroków.',Math.max(10,30-Math.floor(G.turns/8)));return;}
    }
    render();
  }
  function stepSnake(){
    if(!G||G.id!=='snake'||G.done)return;
    const [dx,dy]=G.want;
    if(dx!==-G.dx||dy!==-G.dy){G.dx=dx;G.dy=dy;}
    const [hx,hy]=G.snake[0],nx=hx+G.dx,ny=hy+G.dy,k=nx+','+ny;
    const eat=G.food&&nx===G.food[0]&&ny===G.food[1];
    const body=eat?G.snake:G.snake.slice(0,-1);
    if(nx<0||nx>=10||ny<0||ny>=10||body.some(p=>p.join(',')===k)){
      finish('Koniec biegu! Zebrano '+G.apples+' owoców.',Math.max(3,G.apples*4));return;
    }
    G.snake.unshift([nx,ny]);if(eat){G.apples++;G.score+=4;apple();sound(900,.08);}
    else G.snake.pop();
    G.step++;
    if(G.apples>=9){finish('Wąż mistrzem! 9 owoców!',30);return;}
    render();
  }
  function render(){
    if(!G||gameSession?.kind!=='challenge'||activeModal!=='game')return;
    const board=$('challengeBoard'),info=$('challengeInfo');if(!board||!info)return;
    let html='',columns=0;
    if(G.id==='snake'){
      columns=10;info.textContent='🍎 Owoce: '+G.apples+'/9 · Ruchy: '+G.step+' · im więcej owoców, tym szybciej';
      const head=G.snake[0].join(','),body=new Set(G.snake.slice(1).map(p=>p.join(','))),food=G.food?.join(',');
      for(let y=0;y<10;y++)for(let x=0;x<10;x++){
        const k=x+','+y;
        html+=cell(k===head?'🐍':body.has(k)?'':k===food?'🍎':'',k===head?'head':body.has(k)?'body':k===food?'food':'');
      }
    }else if(G.id==='sokoban'){
      columns=8;info.textContent='📦 Poziom '+(G.level+1)+'/3 · Ruchy: '+G.turns;
      for(let y=0;y<8;y++)for(let x=0;x<8;x++){
        const k=x+','+y,wall=G.walls.has(k),crate=G.boxes.has(k),goal=G.goals.has(k),hero=x===G.x&&y===G.y;
        html+=cell(wall?'':hero?'🐾':crate?'📦':goal?'⭐':'',wall?'wall':hero?'hero':crate?'crate':goal?'goal':'');
      }
    }else if(G.id==='merge'){
      columns=4;info.textContent='🔢 Wynik: '+G.score+' · Ruchy: '+G.turns+' · Cel: 256';
      html=G.tiles.map(n=>cell(n?String(n):'',n?'n'+Math.min(512,n):'')).join('');
    }else{
      columns=9;info.textContent='🗝️ Klucz: '+(G.hasKey?'✅':'❌')+' · 💎 '+G.found+'/2 · Kroki '+G.turns;
      for(let y=0;y<9;y++)for(let x=0;x<9;x++){
        const v=G.grid[y][x],k=x+','+y;
        const hero=x===G.x&&y===G.y,treasure=G.treasure.has(k),key=v==='k'&&!G.hasKey;
        html+=cell(v==='#'?'':hero?'🐾':treasure?'💎':key?'🗝️':v==='d'?'🚪':'',v==='#'?'wall':hero?'hero':treasure?'goal':'');
      }
    }
    board.className='challenge-board cols'+columns;
    board.innerHTML=html;
    const undo=$('sheetBody')?.querySelector('[data-hardundo]');
    if(undo)undo.hidden=G.id!=='sokoban';
  }
  function restart(){
    if(!G)return;start(G.id);
  }
  function undo(){
    if(!G||G.id!=='sokoban'||!G.undo.length)return;
    const previous=G.undo.pop();
    G.x=previous.x;G.y=previous.y;G.boxes=new Set(previous.boxes);G.turns++;render();
  }
  $('overlay').addEventListener('click',e=>{
    const b=e.target.closest('button');if(!b)return;
    if(b.dataset.challenge){start(b.dataset.challenge);return;}
    if(b.dataset.hardmove){move(b.dataset.hardmove);return;}
    if(b.dataset.hardrestart){restart();return;}
    if(b.dataset.hardundo){undo();return;}
  });
  let down=null;
  $('overlay').addEventListener('touchstart',e=>{
    if(!e.target.closest('#challengeBoard'))return;
    const t=e.touches[0];down={x:t.clientX,y:t.clientY};
  },{passive:true});
  $('overlay').addEventListener('touchend',e=>{
    if(!down)return;
    const t=e.changedTouches[0],dx=t.clientX-down.x,dy=t.clientY-down.y;down=null;
    if(Math.max(Math.abs(dx),Math.abs(dy))<20)return;
    move(Math.abs(dx)>Math.abs(dy)?dx>0?'right':'left':dy>0?'down':'up');
  },{passive:true});
  document.addEventListener('keydown',e=>{
    if(!G||gameSession?.kind!=='challenge'||activeModal!=='game')return;
    const d={ArrowLeft:'left',ArrowRight:'right',ArrowUp:'up',ArrowDown:'down'}[e.key];
    if(d){e.preventDefault();e.stopImmediatePropagation();move(d);}
  },true);
  setInterval(()=>{
    if(!G||G.id!=='snake'||gameSession?.kind!=='challenge'||activeModal!=='game')return;
    const now=Date.now(),interval=Math.max(135,400-G.apples*26);
    if(now-G.last>=interval){G.last=now;stepSnake();}
  },60);
  window.PikoChallenges={start,move,render,definitions:defs};
})();