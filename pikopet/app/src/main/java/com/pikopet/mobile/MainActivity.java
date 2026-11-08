package com.pikopet.mobile;
import android.Manifest;
import android.app.Activity;
import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Intent;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.SystemClock;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.ValueCallback;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebSettings;
import android.view.View;
import android.view.WindowManager;
import java.io.InputStream;
import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;

public class MainActivity extends Activity {
 private WebView web;
 private ValueCallback<Uri[]> fileCallback;
 private static final int PICK_FILE=44;
 private static final int ASK_NOTICE=66;
 private static final String HOST="appassets.androidplatform.net";

 @Override public void onCreate(Bundle b){
  super.onCreate(b);
  getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,WindowManager.LayoutParams.FLAG_FULLSCREEN);
  getWindow().getDecorView().setSystemUiVisibility(5894 | View.SYSTEM_UI_FLAG_LAYOUT_STABLE | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION);
  getWindow().setNavigationBarColor(Color.BLACK);
  web=new WebView(this);
  web.setBackgroundColor(Color.rgb(21,12,36));
  WebSettings ws=web.getSettings();
  ws.setJavaScriptEnabled(true);
  ws.setDomStorageEnabled(true);
  ws.setAllowFileAccess(false);
  ws.setAllowContentAccess(false);
  ws.setBuiltInZoomControls(false);
  ws.setDisplayZoomControls(false);
  ws.setMediaPlaybackRequiresUserGesture(false);
  web.addJavascriptInterface(new NativeBridge(),"PikoNative");
  web.setWebViewClient(new WebViewClient(){
   @Override public WebResourceResponse shouldInterceptRequest(WebView v,WebResourceRequest req){
     Uri uri=req.getUrl();
     if(!HOST.equals(uri.getHost()))return super.shouldInterceptRequest(v,req);
     String path=uri.getPath();
     if(path==null||path.equals("/")||path.equals("/index.html")){
       try{InputStream data=getAssets().open("index.html");return new WebResourceResponse("text/html","UTF-8",data);}catch(Exception e){return new WebResourceResponse("text/plain","UTF-8",new ByteArrayInputStream("Error".getBytes(StandardCharsets.UTF_8)));}
     }
     return new WebResourceResponse("text/plain","UTF-8",new ByteArrayInputStream(new byte[0]));
   }
   @Override public boolean shouldOverrideUrlLoading(WebView v,WebResourceRequest req){
      return !HOST.equals(req.getUrl().getHost());
   }
  });
  web.setWebChromeClient(new WebChromeClient(){
   @Override public boolean onShowFileChooser(WebView v,ValueCallback<Uri[]> callback,FileChooserParams p){
     if(fileCallback!=null)fileCallback.onReceiveValue(null);
     fileCallback=callback;
     try{Intent intent=p.createIntent();startActivityForResult(intent,PICK_FILE);return true;}
     catch(Exception e){fileCallback=null;return false;}
   }
  });
  setContentView(web);
  if(getPreferences(Context.MODE_PRIVATE).getBoolean("alerts_enabled",false))CareReceiver.schedule(this,true);
  web.loadUrl("https://"+HOST+"/index.html");
 }
 private class NativeBridge {
   @JavascriptInterface public void updateState(String json){
     if(json!=null && json.length()<300000){
      getPreferences(Context.MODE_PRIVATE).edit().putString("pet_state",json).apply();
     }
   }
   @JavascriptInterface public void setAlerts(boolean enabled){
     getPreferences(Context.MODE_PRIVATE).edit().putBoolean("alerts_enabled",enabled).apply();
     runOnUiThread(()->{
       CareReceiver.schedule(MainActivity.this,enabled);
       if(enabled&&Build.VERSION.SDK_INT>=33&&checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)!=PackageManager.PERMISSION_GRANTED){
         requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS},ASK_NOTICE);
       }
     });
   }
 }
 @Override protected void onActivityResult(int requestCode,int resultCode,Intent data){
   super.onActivityResult(requestCode,resultCode,data);
   if(requestCode==PICK_FILE&&fileCallback!=null){
      fileCallback.onReceiveValue(resultCode==RESULT_OK&&data!=null&&data.getData()!=null?new Uri[]{data.getData()}:null);
      fileCallback=null;
   }
 }
 @Override public void onBackPressed(){
   web.evaluateJavascript("if(!document.getElementById('overlay').hidden){hideSheet()}else{showSettings()}",null);
 }
 @Override public void onDestroy(){if(web!=null){web.destroy();web=null;}super.onDestroy();}
}
