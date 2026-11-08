package com.pikopet.mobile;

import android.Manifest;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothServerSocket;
import android.bluetooth.BluetoothSocket;
import android.content.pm.PackageManager;
import android.os.Build;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.Set;
import java.util.UUID;

/**
 * Local peer-to-peer pet visits: paired Bluetooth Classic or TCP within the
 * same Wi-Fi / phone hotspot. Guest requests a visit, host explicitly accepts.
 * Neither transport needs an account, internet or a remote game server.
 */
public final class PetLink {
  private static final UUID SERVICE=UUID.fromString("9c4289d3-52d0-4369-8c61-d26e985fee83");
  private static final int PORT=42731;
  private final Activity activity;
  private final WebView web;
  private final BluetoothAdapter bluetooth=BluetoothAdapter.getDefaultAdapter();
  private final Object writeLock=new Object();
  private volatile ServerSocket wifiServer;
  private volatile BluetoothServerSocket btServer;
  private volatile Socket wifi;
  private volatile BluetoothSocket bt;
  private volatile BufferedWriter writer;
  private volatile JSONObject myPet=new JSONObject();
  private volatile JSONObject guestPet=new JSONObject();
  private volatile boolean authorized=false;
  private volatile boolean hosting=false;
  private volatile int generation=0;
  private volatile String pin="";
  private volatile String joinPin="";
  private volatile long lastPlay=0;
  private volatile long lastGift=0;
  private volatile long lastCoopTap=0;

  public PetLink(Activity activity,WebView web){this.activity=activity;this.web=web;}

  private JSONObject obj(String kind){
    JSONObject j=new JSONObject();
    try{j.put("type",kind);}catch(Exception ignored){}
    return j;
  }
  private void sendEvent(JSONObject data){
    if(data==null)return;
    String packed=JSONObject.quote(data.toString());
    activity.runOnUiThread(()->web.evaluateJavascript(
      "window.PikoLink&&window.PikoLink.receive("+packed+")",null));
  }
  private void status(String msg){try{JSONObject e=obj("status");e.put("message",msg);sendEvent(e);}catch(Exception ignored){}}
  private boolean btOk(){
    if(bluetooth==null){status("Ten telefon nie obsługuje Bluetooth.");return false;}
    if(Build.VERSION.SDK_INT>=31 &&
        activity.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT)!=PackageManager.PERMISSION_GRANTED){
      activity.runOnUiThread(()->activity.requestPermissions(
        new String[]{Manifest.permission.BLUETOOTH_CONNECT},72));
      status("Zezwól na Urządzenia w pobliżu, potem spróbuj ponownie.");
      return false;
    }
    if(!bluetooth.isEnabled()){
      status("Włącz Bluetooth w ustawieniach telefonu.");return false;
    }
    return true;
  }
  public final class Bridge {
    @JavascriptInterface public void setPet(String json){
      try{
        JSONObject p=new JSONObject(json);
        String species=p.optString("species","").replaceAll("[^a-z]","");
        String name=p.optString("name","Pupil").replaceAll("[\\r\\n]"," ");
        if(species.length()>30||name.length()>25)return;
        JSONObject safe=new JSONObject();
        safe.put("species",species);safe.put("name",name);
        myPet=safe;
      }catch(Exception ignored){}
    }
    @JavascriptInterface public String pairedBluetooth(){
      JSONArray list=new JSONArray();
      if(!btOk())return list.toString();
      try{
        Set<BluetoothDevice> paired=bluetooth.getBondedDevices();
        for(BluetoothDevice d:paired){
          JSONObject item=new JSONObject();
          item.put("name",d.getName()==null?"Telefon Bluetooth":d.getName());
          item.put("address",d.getAddress());
          list.put(item);
        }
      }catch(Exception e){status("Nie udało się odczytać sparowanych urządzeń.");}
      return list.toString();
    }
    @JavascriptInterface public void hostBluetooth(){
      if(!btOk())return;
      close();
      int g=generation;
      hosting=true;
      new Thread(()->{
        try{
          btServer=bluetooth.listenUsingRfcommWithServiceRecord("PikoPet wizyta",SERVICE);
          status("Bluetooth: czekam na połączenie drugiego PikoPeta…");
          BluetoothSocket s=btServer.accept();
          if(g!=generation){s.close();return;}
          bt=s;
          try{btServer.close();}catch(Exception ignored){}
          btServer=null;
          session(s.getInputStream(),s.getOutputStream(),s::close,g);
        }catch(Exception e){if(g==generation)status("Bluetooth: nie udało się połączyć. Sprawdź parowanie.");}
      },"PikoPet-BtHost").start();
    }
    @JavascriptInterface public void joinBluetooth(String address){
      if(!btOk())return;
      if(address==null||!address.matches("(?i)[0-9a-f]{2}(:[0-9a-f]{2}){5}")){status("Wybierz sparowany telefon.");return;}
      close();
      int g=generation;
      hosting=false;
      new Thread(()->{
        try{
          BluetoothDevice device=bluetooth.getRemoteDevice(address);
          if(!bluetooth.getBondedDevices().contains(device)){status("Najpierw sparuj telefony w systemie Bluetooth.");return;}
          BluetoothSocket s=device.createRfcommSocketToServiceRecord(SERVICE);
          bt=s;
          s.connect();
          if(g!=generation){s.close();return;}
          session(s.getInputStream(),s.getOutputStream(),s::close,g);
        }catch(Exception e){if(g==generation)status("Nie można połączyć przez Bluetooth. Otwórz domek na drugim telefonie.");}
      },"PikoPet-BtJoin").start();
    }
    @JavascriptInterface public void hostWifi(){
      close();
      final int g=generation;
      hosting=true;
      pin=String.format(java.util.Locale.ROOT,"%06d",new java.security.SecureRandom().nextInt(1000000));
      String ip=localIPv4();
      if(ip.isEmpty()){status("Połącz oba telefony z tą samą siecią Wi-Fi albo hotspotem.");return;}
      try{
        JSONObject j=obj("wifi_host");
        j.put("ip",ip);j.put("port",PORT);j.put("pin",pin);sendEvent(j);
      }catch(Exception ignored){}
      new Thread(()->{
        try{
          ServerSocket ss=new ServerSocket(PORT);
          ss.setReuseAddress(true);wifiServer=ss;
          Socket s=ss.accept();
          if(g!=generation){s.close();return;}
          wifi=s;
          try{ss.close();}catch(Exception ignored){}
          wifiServer=null;
          session(s.getInputStream(),s.getOutputStream(),s::close,g);
        }catch(Exception e){if(g==generation)status("Wi-Fi: nie można otworzyć domku. Spróbuj ponownie.");}
      },"PikoPet-WifiHost").start();
    }
    @JavascriptInterface public void joinWifi(String address,String code){
      if(address==null||!address.matches("(?:\\d{1,3}\\.){3}\\d{1,3}")){status("Podaj poprawny adres IPv4 gospodarza.");return;}
      try{
        String[] split=address.split("\\.");
        for(String a:split){int v=Integer.parseInt(a);if(v<0||v>255)throw new Exception();}
        if(split.length!=4)throw new Exception();
        if(!InetAddress.getByName(address).isSiteLocalAddress())throw new Exception();
      }catch(Exception e){status("Adres musi należeć do lokalnej sieci Wi-Fi.");return;}
      if(code==null||!code.matches("\\d{6}")){status("Podaj sześciocyfrowy kod wizyty.");return;}
      close();
      final int g=generation;
      hosting=false;joinPin=code;
      new Thread(()->{
        try{
          Socket s=new Socket();
          wifi=s;
          s.connect(new java.net.InetSocketAddress(address,PORT),9000);
          s.setSoTimeout(120000);
          if(g!=generation){s.close();return;}
          session(s.getInputStream(),s.getOutputStream(),s::close,g);
        }catch(Exception e){if(g==generation)status("Wi-Fi: nie można połączyć. Sprawdź IP, kod i tę samą sieć.");}
      },"PikoPet-WifiJoin").start();
    }
    @JavascriptInterface public void accept(){
      if(!hosting||guestPet.optString("species","").isEmpty())return;
      authorized=true;
      try{
        JSONObject accept=obj("accept");accept.put("pet",myPet);
        sendWire(accept);
        JSONObject e=obj("visit");e.put("role","host");e.put("pet",guestPet);
        sendEvent(e);
      }catch(Exception ignored){}
    }
    @JavascriptInterface public void reject(){
      if(hosting){sendWire(obj("reject"));close();sendEvent(obj("ended"));}
    }
    @JavascriptInterface public void play(){
      if(!authorized)return;
      long now=System.currentTimeMillis();
      if(now-lastPlay<12000){status("Pupile potrzebują chwili odpoczynku.");return;}
      lastPlay=now;
      JSONObject p=obj("play");sendWire(p);sendEvent(p);
    }
    @JavascriptInterface public void gift(){
      if(!authorized)return;
      long now=System.currentTimeMillis();
      if(now-lastGift<120000){status("Prezent można wręczyć raz na 2 minuty.");return;}
      lastGift=now;
      JSONObject p=obj("gift");sendWire(p);sendEvent(p);
    }
    @JavascriptInterface public void startCoop(){
      if(!authorized)return;
      JSONObject p=obj("coop_start");sendWire(p);sendEvent(p);
    }
    @JavascriptInterface public void coopTap(){
      if(!authorized)return;
      long now=System.currentTimeMillis();
      if(now-lastCoopTap<650)return;
      lastCoopTap=now;
      JSONObject p=obj("coop_tap");sendWire(p);sendEvent(p);
    }
    @JavascriptInterface public void endVisit(){
      sendWire(obj("bye"));close();sendEvent(obj("ended"));
    }
  }

  private void session(java.io.InputStream in,java.io.OutputStream out,
                       java.io.Closeable endpoint,int current){
    try{
      synchronized(writeLock){
        writer=new BufferedWriter(new OutputStreamWriter(out,StandardCharsets.UTF_8));
      }
      status(hosting?"Połączono. Oczekuję na prośbę o wizytę…":"Połączono. Wysyłam prośbę gospodarzowi…");
      if(!hosting){
        JSONObject req=obj("request");
        req.put("pet",myPet);
        req.put("pin",joinPin);
        sendWire(req);
      }
      BufferedReader reader=new BufferedReader(new InputStreamReader(in,StandardCharsets.UTF_8));
      String line;
      while(current==generation && (line=readLineLimited(reader))!=null){
        JSONObject request=new JSONObject(line);
        String type=request.optString("type","");
        if(type.equals("request")&&hosting&&!authorized){
          if(pin.length()>0&&!pin.equals(request.optString("pin",""))){
            sendWire(obj("reject"));status("Odrzucono niepoprawny kod wizyty.");break;
          }
          JSONObject visitor=sanitizePet(request.optJSONObject("pet"));
          if(visitor.optString("species","").isEmpty()){sendWire(obj("reject"));break;}
          guestPet=visitor;
          JSONObject e=obj("invite");e.put("pet",visitor);sendEvent(e);
        }else if(type.equals("accept")&&!hosting){
          guestPet=sanitizePet(request.optJSONObject("pet"));
          authorized=true;
          JSONObject e=obj("visit");e.put("role","guest");e.put("pet",guestPet);sendEvent(e);
        }else if(type.equals("reject")){status("Gospodarz nie przyjął zaproszenia.");break;}
        else if(type.equals("play")&&authorized){
          long now=System.currentTimeMillis();
          if(now-lastPlay>=11000){lastPlay=now;sendEvent(obj("play"));}
        }else if(type.equals("gift")&&authorized){sendEvent(obj("gift"));}
        else if(type.equals("coop_start")&&authorized){sendEvent(obj("coop_start"));}
        else if(type.equals("coop_tap")&&authorized){sendEvent(obj("coop_tap"));}
        else if(type.equals("bye")){break;}
      }
    }catch(Exception e){
      if(current==generation)status("Połączenie zostało przerwane.");
    }finally{
      try{endpoint.close();}catch(Exception ignored){}
      if(current==generation){close();sendEvent(obj("ended"));}
    }
  }
  private static String readLineLimited(BufferedReader r)throws java.io.IOException{
    StringBuilder s=new StringBuilder();
    for(int i=0;i<2048;i++){
      int c=r.read();if(c==-1)return null;
      if(c=='\n')return s.toString();
      if(c!='\r')s.append((char)c);
    }
    throw new java.io.IOException("Message too long");
  }
  private JSONObject sanitizePet(JSONObject raw)throws Exception{
    JSONObject safe=new JSONObject();
    if(raw==null)return safe;
    String species=raw.optString("species","").replaceAll("[^a-z]","");
    if(species.length()>30)return safe;
    safe.put("species",species);
    safe.put("name",raw.optString("name","Pupil").replaceAll("[\\r\\n]"," ").substring(0,Math.min(24,raw.optString("name","Pupil").length())));
    return safe;
  }
  private void sendWire(JSONObject payload){
    synchronized(writeLock){
      try{if(writer!=null){writer.write(payload.toString());writer.write("\n");writer.flush();}}
      catch(Exception e){status("Nie można wysłać wiadomości.");}
    }
  }
  public synchronized void close(){
    generation++;
    authorized=false;guestPet=new JSONObject();writer=null;pin="";joinPin="";
    try{if(wifiServer!=null)wifiServer.close();}catch(Exception ignored){}
    try{if(btServer!=null)btServer.close();}catch(Exception ignored){}
    try{if(wifi!=null)wifi.close();}catch(Exception ignored){}
    try{if(bt!=null)bt.close();}catch(Exception ignored){}
    wifiServer=null;btServer=null;wifi=null;bt=null;
  }
  private String localIPv4(){
    try{
      String fallback="";
      for(NetworkInterface network:Collections.list(NetworkInterface.getNetworkInterfaces())){
        if(!network.isUp()||network.isLoopback()||network.isVirtual())continue;
        for(InetAddress addr:Collections.list(network.getInetAddresses())){
          if(addr instanceof Inet4Address && addr.isSiteLocalAddress()){
            if(network.getName().startsWith("wlan")||network.getName().startsWith("ap"))return addr.getHostAddress();
            fallback=addr.getHostAddress();
          }
        }
      }
      return fallback;
    }catch(Exception ignored){return "";}
  }
}
