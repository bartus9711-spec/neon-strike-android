(function(){
 const newcomers=[
 ['raccoon','Szopik','🦝','uncommon'],['otter','Wyderek','🦦','uncommon'],['beaver','Bóberek','🦫','uncommon'],['squirrel','Wiewiórek','🐿️','common'],
 ['snail','Ślimaczek','🐌','common'],['butterfly','Motylek','🦋','uncommon'],['ladybug','Biedroneczka','🐞','common'],['crab','Krabik','🦀','uncommon'],
 ['whale','Wielorybek','🐳','rare'],['shark','Rekinek','🦈','rare'],['elephant','Słonik','🐘','uncommon'],['giraffe','Żyrafka','🦒','uncommon'],
 ['lion','Lwiątko','🦁','rare'],['tiger','Tygrysek','🐯','rare'],['peacock','Pawik','🦚','rare'],['griffin','Gryfek','🦅','legend']
 ];
 function makeSprite(emoji,bg){
  const svg='<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96"><rect x="8" y="8" width="80" height="80" rx="22" fill="'+bg+'" opacity=".15"/><ellipse cx="48" cy="83" rx="26" ry="5" fill="#6d5b80" opacity=".22"/><text x="48" y="68" font-size="61" text-anchor="middle">'+emoji+'</text></svg>';
  return 'data:image/svg+xml;charset=utf-8,'+encodeURIComponent(svg);
 }
 for(const [id,name,emoji,tier] of newcomers){
  if(SPECIES.some(s=>s.id===id))continue;
  SPECIES.push({id,name,emoji,tier});
  const img=new Image();img.src=makeSprite(emoji,tier==='legend'?'#dfb66c':'#b9d3bc');img.onload=()=>draw();SPRITES[id]=img;
 }
 const oldWelcome=showWelcome;
 showWelcome=function(){oldWelcome();const body=$('sheetBody');body.innerHTML=body.innerHTML.replace('32 zwierzaki','48 zwierzaków');};
 window.TamagotchiNewPets={count:newcomers.length,total:SPECIES.length};
})();