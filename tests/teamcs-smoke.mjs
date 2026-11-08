/**
 * TeamCS browser smoke tests — real headless Chromium WebGL rendering.
 * Loads the exact HTML packed into the Android WebView.
 */
import {chromium} from 'playwright';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';

const html=fs.readFileSync(path.resolve('app/src/main/assets/index.html'));
const server=http.createServer((req,res)=>{
  const route=new URL(req.url,'http://localhost').pathname;
  if(route==='/'||route==='/index.html'){
    res.writeHead(200,{'Content-Type':'text/html; charset=utf-8','Cache-Control':'no-store'});
    res.end(html);
  }else {res.writeHead(404);res.end();}
});
await new Promise(ok=>server.listen(0,'127.0.0.1',ok));
const address='http://127.0.0.1:'+server.address().port+'/index.html';
fs.mkdirSync('test-results',{recursive:true});
let browser;
const findings=[];
function log(name){findings.push('PASS '+name);console.log('PASS '+name);}
async function runTest(name,params){
  const page=await browser.newPage(params);
  const errors=[];
  page.on('pageerror',e=>errors.push(String(e)));
  await page.goto(address,{waitUntil:'load',timeout:30000});
  await page.waitForTimeout(1200);
  assert.equal(await page.locator('#bootError').isVisible(),false,'Boot error: '+await page.locator('#bootError').innerText());
  assert.equal(await page.locator('#mainMenu').isVisible(),true,'Main menu hidden');
  assert.match(await page.title(),/TeamCS/i,'Title is not TeamCS');
  assert.ok(await page.locator('#mapCards .map-card').count()>=8,'Not all eight maps loaded');
  const gameCanvas=await page.evaluate(()=>({width:document.querySelector('#gameCanvas').width,height:document.querySelector('#gameCanvas').height,ok:!!document.querySelector('#gameCanvas').getContext('webgl')}));
  assert.ok(gameCanvas.ok&&gameCanvas.width>0&&gameCanvas.height>0,'WebGL canvas unavailable');
  log(name+': boot, menu, eight maps, WebGL');
  if(params.isMobile){
    assert.equal(await page.locator('#btnFire').isVisible(),false,'Mobile controls visible too early');
  }
  await page.locator('#qualitySelect').selectOption('low');
  await page.locator('#soloButton').click();
  await page.waitForTimeout(550);
  assert.equal(await page.locator('#gameOverlay').isVisible(),true,'Solo overlay not visible');
  assert.equal(await page.locator('#mainMenu').isVisible(),false,'Main menu not dismissed');
  assert.notEqual(await page.locator('#weaponTitle').innerText(),'','Missing weapon HUD');
  log(name+': SOLO launched and HUD rendered');
  await page.locator('#shopHudButton').click();
  assert.equal(await page.locator('#shopOverlay').isVisible(),true,'Shop did not open');
  assert.equal(await page.locator('#shopWallet').innerText(),'$800','Initial match budget incorrect');
  const item=page.locator('#shopTiles .shop-tile').filter({hasText:'TEC'});
  assert.equal(await item.count(),1,'Shop item not found');
  await item.locator('button').first().click();
  assert.equal(await page.locator('#shopWallet').innerText(),'$150','Purchase did not change funds');
  assert.equal(await page.locator('#weaponTitle').innerText(),'TEC-9','Purchased item not selected');
  log(name+': shop buy and cash deduction');
  console.log('QA sale phase:',await page.locator('#shopClock').innerText(),'; enabled:',await item.locator('button').nth(1).isEnabled());
  await item.locator('button').nth(1).click({timeout:6500});
  assert.equal(await page.locator('#shopWallet').innerText(),'$572','Sell refund incorrect');
  log(name+': shop sell and refund');
  await page.locator('#shopClose').click();
  assert.equal(await page.locator('#shopOverlay').isVisible(),false,'Shop still open');
  await page.waitForTimeout(350);
  await page.screenshot({path:'test-results/'+name+'-solo.png',animations:'disabled'});
  assert.ok(errors.length===0,'Uncaught JS errors: '+errors.join('\n'));
  log(name+': no uncaught runtime errors');
  await page.close();
}
try{
  browser=await chromium.launch({headless:true,args:['--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage']});
  await runTest('desktop',{viewport:{width:1440,height:900}});
  await runTest('mobile',{viewport:{width:844,height:390},isMobile:true,hasTouch:true,deviceScaleFactor:2});
  console.log('\n'+findings.join('\n'));
  console.log('RESULT: '+findings.length+' test steps passed.');
}catch(error){
  console.error('TEAMCS SMOKE TEST FAILED:',error);
  process.exitCode=1;
}finally{
  if(browser)await browser.close();
  await new Promise(ok=>server.close(ok));
}
