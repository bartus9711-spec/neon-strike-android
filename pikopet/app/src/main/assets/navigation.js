/* PikoPet Deluxe: one-step Back from every panel. */
(function installNavigation(){
  let stack=[];
  let isBack=false;
  const originalSheet=showSheet;
  const originalClose=hideSheet;
  showSheet=function(title,html,kind='sheet'){
    const visible=!$('overlay').hidden;
    if(!isBack&&visible&&activeModal&&activeModal!==kind){
      if(kind==='result'&&activeModal==='game'){
        // Finished game: do not return to a game session that is already over.
      }else if(kind==='games'&&(activeModal==='game'||activeModal==='result')&&stack[stack.length-1]==='games'){
        stack.pop();
      }else{
        stack.push(activeModal);
      }
    }
    if(stack.length>30)stack=stack.slice(-30);
    return originalSheet(title,html,kind);
  };
  function closeCompletely(){
    stack.length=0;
    isBack=false;
    originalClose();
  }
  function openPrevious(kind){
    if(kind==='game'||kind==='result'){showGames();return;}
    if(kind==='welcome'){showWelcome();return;}
    if(kind==='egg'){showEggPicker();return;}
    if(kind==='memorial'){showMemorial();return;}
    if(kind==='hatch'){showStats();return;}
    if(kind==='duoAlbum'){
      if(window.PikoDuoExtras?.album){window.PikoDuoExtras.album();return;}
      showVisits();return;
    }
    if(kind==='visit'){showVisits();return;}
    route(kind);
  }
  function back(){
    if($('overlay').hidden){showSettings();return;}
    if(activeModal==='game'||activeModal==='result')gameSession=null;
    const target=stack.pop();
    if(!target){closeCompletely();return;}
    isBack=true;
    try{openPrevious(target);}
    catch(err){console.warn('PikoPet back fallback',err);closeCompletely();}
    finally{isBack=false;}
  }
  hideSheet=back;
  const x=$('closeSheet');
  if(x){
    x.title='Wstecz — poprzedni ekran';
    x.setAttribute('aria-label','Wstecz do poprzedniego ekranu');
  }
  window.PikoNavigation={back,close:closeCompletely,depth:()=>stack.length};
})();
