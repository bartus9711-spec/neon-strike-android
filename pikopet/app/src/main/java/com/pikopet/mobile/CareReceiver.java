package com.pikopet.mobile;
import android.app.AlarmManager;
import android.app.PendingIntent;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.SystemClock;
import android.Manifest;
import android.content.pm.PackageManager;
import org.json.JSONObject;

public class CareReceiver extends BroadcastReceiver {
 private static final String CHANNEL="pikopet_care";
 public static void schedule(Context context,boolean enabled){
   AlarmManager alarm=(AlarmManager)context.getSystemService(Context.ALARM_SERVICE);
   Intent i=new Intent(context,CareReceiver.class);
   i.setAction("com.pikopet.mobile.CHECK_CARE");
   PendingIntent pi=PendingIntent.getBroadcast(context,0,i,PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
   if(alarm==null)return;
   alarm.cancel(pi);
   if(enabled)alarm.setInexactRepeating(AlarmManager.ELAPSED_REALTIME_WAKEUP,SystemClock.elapsedRealtime()+30*60*1000L,30*60*1000L,pi);
 }
 @Override public void onReceive(Context context,Intent intent){
   SharedPreferences p=context.getSharedPreferences("MainActivity",Context.MODE_PRIVATE);
   if(intent!=null&&Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())){
     if(p.getBoolean("alerts_enabled",false))schedule(context,true);return;
   }
   if(!p.getBoolean("alerts_enabled",false))return;
   if(Build.VERSION.SDK_INT>=33&&context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)!=PackageManager.PERMISSION_GRANTED)return;
   long now=System.currentTimeMillis();
   if(now-p.getLong("last_care_alert",0)<2*60*60*1000L)return;
   String title=null,body=null;
   try{
     JSONObject state=new JSONObject(p.getString("pet_state","{}"));
     JSONObject pet=state.optJSONObject("pet");
     if(pet==null||!pet.optBoolean("alive",false))return;
     JSONObject settings=state.optJSONObject("settings");
     if(settings!=null&&!settings.optBoolean("notifications",false))return;
     double elapsed=Math.max(0,Math.min(15*1440,(now-state.optLong("lastUpdate",now))/60000.0));
     double factor=(settings!=null&&settings.optBoolean("gentle",false))?.52:1.0;
     double hunger=pet.optDouble("hunger",99)-.18*elapsed*factor;
     double clean=pet.optDouble("clean",99)-.13*elapsed*factor;
     boolean sick=pet.optBoolean("sick",false);
     String petName=pet.optString("name","Twój pupil");
     if(sick){title="💊 PikoPet: potrzebna pomoc!";body=petName+" źle się czuje. Zajrzyj do gry.";}
     else if(hunger<30){title="🍴 PikoPet: pora na jedzenie!";body=petName+" jest głodny. Nakarm swojego pupila.";}
     else if(clean<28){title="🧹 PikoPet: czas posprzątać!";body=petName+" potrzebuje czystego domku.";}
     else if(pet.optDouble("happy",99)-.12*elapsed*factor<30){title="💞 PikoPet: pobaw się ze mną!";body=petName+" czeka na Twoją uwagę.";}
   }catch(Exception e){return;}
   if(title==null)return;
   NotificationManager nm=(NotificationManager)context.getSystemService(Context.NOTIFICATION_SERVICE);
   if(nm==null)return;
   if(Build.VERSION.SDK_INT>=26)nm.createNotificationChannel(new NotificationChannel(CHANNEL,"Potrzeby pupila",NotificationManager.IMPORTANCE_DEFAULT));
   Intent launch=new Intent(context,MainActivity.class);
   launch.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP|Intent.FLAG_ACTIVITY_SINGLE_TOP);
   PendingIntent tap=PendingIntent.getActivity(context,1,launch,PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
   Notification.Builder n=Build.VERSION.SDK_INT>=26?new Notification.Builder(context,CHANNEL):new Notification.Builder(context);
   n.setSmallIcon(android.R.drawable.ic_dialog_info).setContentTitle(title).setContentText(body).setAutoCancel(true).setContentIntent(tap);
   nm.notify(1001,n.build());
   p.edit().putLong("last_care_alert",now).apply();
 }
}
