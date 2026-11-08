package pl.neonstrike.mobile;

import android.app.Activity;
import android.content.Intent;
import android.content.res.AssetManager;
import android.content.res.Configuration;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.view.InputDevice;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.webkit.JavascriptInterface;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Locale;

public class MainActivity extends Activity {
    private static final String HOST="appassets.androidplatform.net";
    private static final String HOME="https://appassets.androidplatform.net/assets/index.html";
    private WebView web;
    private int padId=-1;
    private String padName="Kontroler Bluetooth";
    private final float[] axes=new float[4], triggers=new float[2];
    private final boolean[] buttons=new boolean[17];

    @Override public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        fullscreen();
        preferHighRefreshRate();
        web=new WebView(this);
        web.setLayerType(View.LAYER_TYPE_HARDWARE,null);
        web.setBackgroundColor(Color.rgb(5,13,21));
        WebSettings settings=web.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setAllowFileAccess(false);
        settings.setAllowContentAccess(false);
        settings.setAllowFileAccessFromFileURLs(false);
        settings.setAllowUniversalAccessFromFileURLs(false);
        settings.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);
        settings.setMediaPlaybackRequiresUserGesture(false);
        web.addJavascriptInterface(new AndroidBridge(),"NeonAndroid");
        web.setWebViewClient(new WebViewClient() {
            @Override public WebResourceResponse shouldInterceptRequest(WebView view,WebResourceRequest request) {
                Uri uri=request.getUrl();
                if(!"https".equalsIgnoreCase(uri.getScheme()) || !HOST.equalsIgnoreCase(uri.getHost())) return null;
                String path=uri.getPath();
                if(path==null || !path.startsWith("/assets/")) return null;
                String file=path.substring("/assets/".length());
                if(file.isEmpty()) file="index.html";
                if(file.startsWith("/") || file.contains("..") || file.contains("\\")) return null;
                try {
                    InputStream in=getAssets().open(file,AssetManager.ACCESS_STREAMING);
                    String mime=file.endsWith(".html")?"text/html":file.endsWith(".js")?"text/javascript":file.endsWith(".webmanifest")?"application/manifest+json":file.endsWith(".png")?"image/png":"text/plain";
                    return new WebResourceResponse(mime,"UTF-8",in);
                }catch(IOException ex){
                    return new WebResourceResponse("text/plain","UTF-8",404,"Not Found",null,new ByteArrayInputStream(new byte[0]));
                }
            }
            @Override public boolean shouldOverrideUrlLoading(WebView view,WebResourceRequest request){
                Uri u=request.getUrl();
                if(HOST.equalsIgnoreCase(u.getHost()))return false;
                if(request.isForMainFrame()){
                    try{startActivity(new Intent(Intent.ACTION_VIEW,u));}catch(Exception ignored){}
                    return true;
                }
                return false;
            }
        });
        setContentView(web);
        launch(getIntent());
    }
    private void launch(Intent intent) {
        Uri uri=intent==null?null:intent.getData();
        String code=uri!=null&&"neonstrike".equals(uri.getScheme())?uri.getQueryParameter("room"):null;
        web.loadUrl(code!=null && code.matches("[A-Za-z2-9]{6}")?HOME+"?room="+code.toUpperCase(Locale.US):HOME);
    }
    @Override protected void onNewIntent(Intent intent){super.onNewIntent(intent);setIntent(intent);launch(intent);}
    // Hint only: Android or WebView may still impose a 60 Hz rendering limit.
    private void preferHighRefreshRate(){
        try{
            android.view.Display display=getWindowManager().getDefaultDisplay();
            android.view.Display.Mode current=display.getMode();
            android.view.Display.Mode best=current;
            for(android.view.Display.Mode mode:display.getSupportedModes()){
                if(mode.getPhysicalWidth()!=current.getPhysicalWidth()||mode.getPhysicalHeight()!=current.getPhysicalHeight())continue;
                if(mode.getRefreshRate()>best.getRefreshRate()&&mode.getRefreshRate()<=120.5f)best=mode;
            }
            WindowManager.LayoutParams params=getWindow().getAttributes();
            params.preferredDisplayModeId=best.getModeId();
            params.preferredRefreshRate=best.getRefreshRate();
            getWindow().setAttributes(params);
        }catch(Exception ignored){
            // Keep default mode on devices without selectable refresh modes.
        }
    }
    private void fullscreen(){
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY|View.SYSTEM_UI_FLAG_FULLSCREEN|View.SYSTEM_UI_FLAG_HIDE_NAVIGATION|View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN|View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION|View.SYSTEM_UI_FLAG_LAYOUT_STABLE);
    }
    @Override public void onWindowFocusChanged(boolean focused){super.onWindowFocusChanged(focused);if(focused)fullscreen();}
    @Override public void onConfigurationChanged(Configuration c){super.onConfigurationChanged(c);if(web!=null)web.invalidate();}
    @Override public void onBackPressed(){
        if(web==null){super.onBackPressed();return;}
        web.evaluateJavascript("(function(){var p=document.getElementById('settingsPanel');if(p&&!p.classList.contains('hidden')){document.getElementById('resumeTop').click();return 0;}var m=document.getElementById('mainMenu');if(m&&m.classList.contains('hidden')){document.getElementById('menuButton').click();return 0;}return 1;})()",v->{if("1".equals(v))finish();});
    }
    private boolean isPad(InputDevice d){
        if(d==null)return false;
        int src=d.getSources();
        return (src&InputDevice.SOURCE_GAMEPAD)==InputDevice.SOURCE_GAMEPAD || (src&InputDevice.SOURCE_JOYSTICK)==InputDevice.SOURCE_JOYSTICK;
    }
    private void register(int id){
        InputDevice d=InputDevice.getDevice(id);
        if(!isPad(d))return;
        synchronized(this){
            if(padId!=id){
                java.util.Arrays.fill(axes,0f);
                java.util.Arrays.fill(buttons,false);
                java.util.Arrays.fill(triggers,0f);
            }
            padId=id;
            padName=d.getName();
        }
    }
    @Override public boolean dispatchKeyEvent(KeyEvent e){
        if(isPad(e.getDevice())) {
            int i=-1;
            switch(e.getKeyCode()) {
                case KeyEvent.KEYCODE_BUTTON_A:i=0;break;
                case KeyEvent.KEYCODE_BUTTON_B:i=1;break;
                case KeyEvent.KEYCODE_BUTTON_X:i=2;break;
                case KeyEvent.KEYCODE_BUTTON_Y:i=3;break;
                case KeyEvent.KEYCODE_BUTTON_L1:i=4;break;
                case KeyEvent.KEYCODE_BUTTON_R1:i=5;break;
                case KeyEvent.KEYCODE_BUTTON_L2:i=6;break;
                case KeyEvent.KEYCODE_BUTTON_R2:i=7;break;
                case KeyEvent.KEYCODE_BUTTON_SELECT:i=8;break;
                case KeyEvent.KEYCODE_BUTTON_START:i=9;break;
                case KeyEvent.KEYCODE_BUTTON_THUMBL:i=10;break;
                case KeyEvent.KEYCODE_BUTTON_THUMBR:i=11;break;
                case KeyEvent.KEYCODE_DPAD_UP:i=12;break;
                case KeyEvent.KEYCODE_DPAD_DOWN:i=13;break;
                case KeyEvent.KEYCODE_DPAD_LEFT:i=14;break;
                case KeyEvent.KEYCODE_DPAD_RIGHT:i=15;break;
                case KeyEvent.KEYCODE_BUTTON_MODE:i=16;break;
            }
            if(i>=0){register(e.getDeviceId());synchronized(this){buttons[i]=e.getAction()==KeyEvent.ACTION_DOWN;}return true;}
        }
        return super.dispatchKeyEvent(e);
    }
    @Override public boolean dispatchGenericMotionEvent(MotionEvent e){
        if((e.getSource()&InputDevice.SOURCE_JOYSTICK)==InputDevice.SOURCE_JOYSTICK&&e.getAction()==MotionEvent.ACTION_MOVE){
            register(e.getDeviceId());
            float zx=e.getAxisValue(MotionEvent.AXIS_Z),zy=e.getAxisValue(MotionEvent.AXIS_RZ);
            synchronized(this){
                axes[0]=e.getAxisValue(MotionEvent.AXIS_X);
                axes[1]=e.getAxisValue(MotionEvent.AXIS_Y);
                axes[2]=(Math.abs(zx)+Math.abs(zy)>.04f)?zx:e.getAxisValue(MotionEvent.AXIS_RX);
                axes[3]=(Math.abs(zx)+Math.abs(zy)>.04f)?zy:e.getAxisValue(MotionEvent.AXIS_RY);
                triggers[0]=Math.max(0,Math.max(e.getAxisValue(MotionEvent.AXIS_LTRIGGER),e.getAxisValue(MotionEvent.AXIS_BRAKE)));
                triggers[1]=Math.max(0,Math.max(e.getAxisValue(MotionEvent.AXIS_RTRIGGER),e.getAxisValue(MotionEvent.AXIS_GAS)));
            }
            return true;
        }
        return super.dispatchGenericMotionEvent(e);
    }
    public class AndroidBridge {
        @JavascriptInterface public String getGamepad(){
            JSONObject json=new JSONObject();
            synchronized(MainActivity.this){
                try{
                    boolean active=padId!=-1&&isPad(InputDevice.getDevice(padId));
                    if(!active)padId=-1;
                    json.put("connected",active);
                    json.put("id",padName);
                    JSONArray coords=new JSONArray(),keys=new JSONArray();
                    for(float a:axes)coords.put((double)a);
                    json.put("axes",coords);
                    for(int i=0;i<buttons.length;i++){
                        JSONObject button=new JSONObject();
                        boolean p=buttons[i]||(i==6&&triggers[0]>.55f)||(i==7&&triggers[1]>.55f);
                        button.put("pressed",p);
                        button.put("value",p?1:(i==6?triggers[0]:(i==7?triggers[1]:0)));
                        keys.put(button);
                    }
                    json.put("buttons",keys);
                }catch(Exception ignored){}
            }
            return json.toString();
        }
        @JavascriptInterface public void shareInvite(String code){
            if(code==null||!code.matches("[A-Za-z2-9]{6}"))return;
            runOnUiThread(()->{
                Intent send=new Intent(Intent.ACTION_SEND);
                send.setType("text/plain");
                send.putExtra(Intent.EXTRA_TEXT,"TeamCS 5v5 — kod pokoju: "+code+"\nOtwórz aplikację, wybierz MULTI i DOŁĄCZ.\nneonstrike://join?room="+code);
                try{startActivity(Intent.createChooser(send,"Zaproś do gry"));}catch(Exception ignored){}
            });
        }
    }
    @Override protected void onDestroy(){
        if(web!=null){web.loadUrl("about:blank");web.destroy();web=null;}
        super.onDestroy();
    }
}
