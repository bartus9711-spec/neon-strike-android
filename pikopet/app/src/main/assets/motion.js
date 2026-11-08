(function installMotion(){
  const motion={kind:'',x:22,direction:1,target:37,last:Date.now(),pause:0,walking:false,hop:0};
  let guestLeft=58,guestDirection=-1,lastVisit=Date.now();
  const clampPos=(x,n)=>Math.min(95-n-1,Math.max(1,x));
  function sprite(ctx,im,x,y,w,flip){
    if(!im?.complete||!im.naturalWidth)return;
    ctx.save();
    if(flip){ctx.translate(Math.round(x+w),0);ctx.scale(-1,1);ctx.drawImage(im,0,Math.round(y),w,w);}
    else ctx.drawImage(im,Math.round(x),Math.round(y),w,w);
    ctx.restore();
  }
  function step(p,side){
    if(motion.kind!==p.species){motion.kind=p.species;motion.x=(96-side)/2;motion.target=motion.x;motion.pause=Date.now()+1200;}
    const now=Date.now(),dt=Math.min(.3,(now-motion.last)/1000);motion.last=now;
    motion.walking=false;
    if(!p.sleeping&&!p.sick&&LINK.state!=='visit'&&now>motion.pause){
      if(Math.abs(motion.target-motion.x)<1.2){
        motion.pause=now+800+Math.random()*1400;
        motion.target=2+Math.random()*Math.max(2,94-side);
      }else{
        motion.direction=motion.target>motion.x?1:-1;
        motion.x=clampPos(motion.x+motion.direction*(11+Math.max(0,p.energy-50)*.075)*dt,side);
        motion.walking=true;
      }
    }
    const bounce=motion.walking?Math.round(Math.sin(now/115)*2):Math.round(Math.sin(now/650));
    return {x:Math.round(clampPos(motion.x,side)),y:Math.max(0,57-side)+bounce,flip:motion.direction<0};
  }
  const rect=(ctx,x,y,w,h,c)=>{ctx.fillStyle=c;ctx.fillRect(Math.round(x),Math.round(y),Math.round(w),Math.round(h));};
  const line=(ctx,x,y,w,h,c)=>rect(ctx,x,y,w,h,c);
  function cozy(ctx,frame,S,LINK,SPRITES){
    const now=Date.now(),dt=Math.min(.3,(now-lastVisit)/1000);lastVisit=now;
    ctx.imageSmoothingEnabled=false;
    ctx.clearRect(0,0,96,66);
    // Warm room: striped walls, window with nighttime view, curtains, bookshelf, plant and carpet.
    rect(ctx,0,0,96,47,'#f8ddc8');
    for(let x=4;x<96;x+=18)rect(ctx,x,0,1,42,'#ead0ba');
    rect(ctx,0,43,96,23,'#d2ac8f');
    rect(ctx,0,44,96,3,'#b9847e');
    for(let x=0;x<96;x+=14)rect(ctx,x,61,12,1,'#b98d79');
    // window & sky
    rect(ctx,27,4,39,24,'#af7d84');
    rect(ctx,30,6,33,20,'#5b7398');
    rect(ctx,35,9,3,3,'#f8eaa4');
    rect(ctx,53,12,2,2,'#ffffda');
    rect(ctx,45,20,2,2,'#ffffda');
    rect(ctx,46,6,2,20,'#f2c8ad');
    rect(ctx,30,17,33,2,'#f2c8ad');
    rect(ctx,26,3,6,25,'#dc8999');
    rect(ctx,63,3,6,25,'#dc8999');
    // warm ceiling lamp, gentle glow
    rect(ctx,74,4,13,3,'#ac7985');
    rect(ctx,79,7,3,5,'#a88f7c');
    rect(ctx,75,12,11,5,'#ffe5a3');
    rect(ctx,78,17,6,2,'#edd39a');
    // plant
    rect(ctx,86,36,8,8,'#c48165');
    rect(ctx,89,27,2,12,'#7e966a');
    for(const [x,y] of [[84,28],[91,25],[85,32],[93,32]])rect(ctx,x,y,5,5,'#86b989');
    // shelf, picture and toys
    rect(ctx,3,14,17,2,'#956675');
    rect(ctx,4,8,4,6,'#7ba7b4');
    rect(ctx,9,6,4,8,'#f0b77b');
    rect(ctx,14,9,4,5,'#b28ec6');
    rect(ctx,4,29,12,8,'#a58076');
    rect(ctx,6,31,8,4,'#f7dfb0');
    rect(ctx,8,43,8,5,'#ce9a83');
    rect(ctx,9,47,6,3,'#f0d2bb');
    // cozy rug: under pets
    rect(ctx,16,54,66,9,'#c591a2');
    rect(ctx,19,55,60,7,'#f4d0cb');
    rect(ctx,23,57,52,2,'#d5a2af');
    // dot toy near rug
    rect(ctx,45,46,7,7,'#82bfd3');
    rect(ctx,47,45,2,2,'#f8fff0');
    const p=S.pet||{};
    const a=LINK.other||{};
    const img1=SPRITES[p.species],img2=SPRITES[a.species];
    const size=33;
    const swinging=Math.sin(now/1700);
    const greetings=Math.abs(swinging)>.8;
    const moving1=!p.sleeping&&Math.abs(Math.sin(now/1400))>.26;
    const moving2=Math.abs(Math.sin(now/1600+1))>.26;
    const x1=clampPos(11+swinging*7,size),x2=clampPos(54-swinging*7,size);
    sprite(ctx,img1,x1,23+(moving1?Math.round(Math.sin(now/170)*2):0),size,false);
    sprite(ctx,img2,x2,23+(moving2?Math.round(Math.sin(now/190)*2):0),size,true);
    if(greetings){
      rect(ctx,46,18,3,3,'#d66e96');rect(ctx,50,18,3,3,'#d66e96');rect(ctx,45,21,9,4,'#e69bb3');rect(ctx,48,25,3,2,'#b35f86');
    }
    if(LINK.plays>0 && now%1800<440){
      rect(ctx,49,10,2,2,'#fdd0ae');rect(ctx,44,9,2,2,'#a4d6b2');
    }
  }
  const oldReceive=window.PikoLink?.receive;
  if(oldReceive){
    window.PikoLink.receive=function(raw){
      let event;
      try{event=JSON.parse(raw);}catch(e){return oldReceive(raw);}
      oldReceive(raw);
      if(event.type==='visit'){
        // Immediately return from the connection dialog to the pet's warm guest room.
        if(window.PikoNavigation?.close)window.PikoNavigation.close();
        else{$('overlay').hidden=true;activeModal='';}
        notify('🏡 Goście w przytulnym pokoju! Dotknij LCD, aby otworzyć zabawy.');
        draw();
      }
      if(event.type==='ended'){motion.pause=Date.now()+850;draw();}
    };
  }
  $('lcdViewport').addEventListener('click',e=>{
    if(LINK.state==='visit'){
      e.preventDefault();e.stopImmediatePropagation();showVisits();
    }
  },true);
  window.PikoMotion={step,cozy};
})();