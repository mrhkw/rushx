package com.hkw.wifi;

import android.Manifest;
import android.app.Activity;
import android.content.*;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.net.*;
import android.net.wifi.*;
import android.os.*;
import android.provider.Settings;
import android.text.InputType;
import android.view.*;
import android.widget.*;
import java.net.InetAddress;
import java.util.*;

public class MainActivity extends Activity {
    private static final int REQ_WIFI = 41;
    private WifiManager wifi;
    private LinearLayout root, content;
    private TextView status;
    private ArrayList<ScanResult> results = new ArrayList<>();
    private final int bg = Color.rgb(7,17,29), card = Color.rgb(14,31,48), cyan = Color.rgb(70,217,255), text = Color.rgb(235,245,250), muted = Color.rgb(155,180,195);

    @Override public void onCreate(Bundle b) { super.onCreate(b); wifi=(WifiManager)getApplicationContext().getSystemService(WIFI_SERVICE); buildShell(); requestWifiPermissions(); }
    private void buildShell() {
        root=new LinearLayout(this); root.setOrientation(LinearLayout.VERTICAL); root.setBackgroundColor(bg);
        TextView bar=label("hkw wi-fi",24,cyan); bar.setPadding(22,22,22,12); root.addView(bar,new LinearLayout.LayoutParams(-1,72));
        content=new LinearLayout(this); content.setOrientation(LinearLayout.VERTICAL); content.setPadding(18,0,18,12); ScrollView scroll=new ScrollView(this); scroll.addView(content); root.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
        status=label("Ready",14,muted); status.setPadding(22,8,22,12); root.addView(status,new LinearLayout.LayoutParams(-1,45)); setContentView(root); dashboard();
    }
    private TextView label(String s,int size,int c){ TextView v=new TextView(this); v.setText(s); v.setTextSize(size); v.setTextColor(c); return v; }
    private Button button(String s){ Button b=new Button(this); b.setText(s); b.setTextColor(text); b.setTextSize(14); b.setAllCaps(false); return b; }
    private void clear(){ content.removeAllViews(); }
    private void title(String s,String sub){ TextView t=label(s,22,text); t.setPadding(0,12,0,2); content.addView(t); TextView x=label(sub,13,muted); x.setPadding(0,0,0,12); content.addView(x); }
    private void section(String s){ TextView t=label(s,15,cyan); t.setPadding(0,16,0,7); content.addView(t); }
    private TextView cardText(String s){ TextView v=label(s,15,text); v.setBackgroundColor(card); v.setPadding(18,14,18,14); LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,-2); p.setMargins(0,4,0,4); content.addView(v,p); return v; }
    private void requestWifiPermissions(){ ArrayList<String> p=new ArrayList<>(); if(Build.VERSION.SDK_INT>=33 && checkSelfPermission(Manifest.permission.NEARBY_WIFI_DEVICES)!=PackageManager.PERMISSION_GRANTED)p.add(Manifest.permission.NEARBY_WIFI_DEVICES); if(Build.VERSION.SDK_INT<=32 && checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)!=PackageManager.PERMISSION_GRANTED)p.add(Manifest.permission.ACCESS_FINE_LOCATION); if(!p.isEmpty())requestPermissions(p.toArray(new String[0]),REQ_WIFI); else refreshDashboard(); }
    @Override public void onRequestPermissionsResult(int r,String[] p,int[] g){super.onRequestPermissionsResult(r,p,g); refreshDashboard();}
    private WifiInfo info(){ try{return wifi.getConnectionInfo();}catch(Exception e){return null;} }
    private String ssid(){ WifiInfo i=info(); if(i==null||i.getSSID()==null)return "Not connected"; return i.getSSID().replace("\"",""); }
    private String quality(int rssi){ if(rssi>=-55)return "Excellent"; if(rssi>=-67)return "Good"; if(rssi>=-75)return "Fair"; return "Weak"; }
    private void dashboard(){ clear(); title("Network dashboard","Advanced local Wi-Fi analysis"); section("CURRENT CONNECTION"); TextView conn=cardText("Loading connection details…"); section("TOOLS"); LinearLayout row=new LinearLayout(this); row.setOrientation(LinearLayout.HORIZONTAL); Button scan=button("Scan networks"); Button diag=button("Diagnostics"); row.addView(scan,new LinearLayout.LayoutParams(0,58,1)); row.addView(diag,new LinearLayout.LayoutParams(0,58,1)); content.addView(row); Button settings=button("Open Android Wi-Fi settings"); content.addView(settings); scan.setOnClickListener(v->scan()); diag.setOnClickListener(v->diagnostics()); settings.setOnClickListener(v->startActivity(new Intent(Settings.ACTION_WIFI_SETTINGS))); refreshDashboard(); }
    private void refreshDashboard(){ if(content==null)return; WifiInfo i=info(); String s="SSID: "+ssid(); if(i!=null){ int r=i.getRssi(); s+="\nSignal: "+r+" dBm ("+quality(r)+")\nLink speed: "+i.getLinkSpeed()+" Mbps\nFrequency: "+i.getFrequency()+" MHz\nBSSID: "+(i.getBSSID()==null?"Unavailable":i.getBSSID()); } for(int n=0;n<content.getChildCount();n++){View v=content.getChildAt(n); if(v instanceof TextView && ((TextView)v).getText().toString().startsWith("Loading connection")){((TextView)v).setText(s);break;} } status.setText("Updated "+new Date().toString()); }
    private void scan(){ clear(); title("Nearby networks","Android may throttle repeated scans for battery and privacy"); Button b=button("Refresh scan"); content.addView(b); b.setOnClickListener(v->doScan()); TextView hint=cardText("Scanning…"); doScan(); }
    private void doScan(){ if(Build.VERSION.SDK_INT<=32 && !isLocationEnabled()){ status.setText("Turn on Location for Wi-Fi scanning"); return; } try{ wifi.startScan(); new Handler().postDelayed(()->{ try{results=new ArrayList<>(wifi.getScanResults());}catch(Exception e){results.clear();} renderResults();},1200); }catch(SecurityException e){status.setText("Wi-Fi permission is required");} }
    private boolean isLocationEnabled(){ return ((android.location.LocationManager)getSystemService(LOCATION_SERVICE)).isLocationEnabled(); }
    private void renderResults(){ clear(); title("Nearby networks",results.size()+" access points found"); Button b=button("Refresh scan"); content.addView(b); b.setOnClickListener(v->doScan()); if(results.isEmpty()){cardText("No scan results. Check Wi-Fi and Nearby devices permission.");return;} Collections.sort(results,(a,z)->z.level-a.level); for(ScanResult r:results){String sec=r.capabilities==null?"Unknown":r.capabilities; String band=r.frequency<3000?"2.4 GHz":(r.frequency<6000?"5 GHz":"6 GHz"); Button n=button((r.SSID==null||r.SSID.isEmpty()?"Hidden network":r.SSID)+"\n"+r.level+" dBm • "+quality(r.level)+" • "+band+" • "+sec); n.setOnClickListener(v->networkDetails(r)); content.addView(n);}}
    private void networkDetails(ScanResult r){ new AlertDialog.Builder(this).setTitle(r.SSID==null?"Hidden network":r.SSID).setMessage("BSSID: "+r.BSSID+"\nFrequency: "+r.frequency+" MHz\nChannel: "+channel(r.frequency)+"\nSignal: "+r.level+" dBm ("+quality(r.level)+")\nSecurity: "+r.capabilities+"\n\nAndroid will ask for approval before connecting.").setPositiveButton("Open Wi-Fi settings",(d,w)->startActivity(new Intent(Settings.ACTION_WIFI_SETTINGS))).setNegativeButton("Close",null).show(); }
    private int channel(int f){ if(f>=2412&&f<=2484)return f==2484?14:(f-2407)/5; if(f>=5000)return (f-5000)/5; return 0; }
    private void diagnostics(){ clear(); title("Diagnostics","Connection, gateway and internet health"); WifiInfo i=info(); StringBuilder s=new StringBuilder(); s.append("SSID: ").append(ssid()).append("\n"); if(i!=null)s.append("RSSI: ").append(i.getRssi()).append(" dBm\nLink speed: ").append(i.getLinkSpeed()).append(" Mbps\n"); ConnectivityManager cm=(ConnectivityManager)getSystemService(CONNECTIVITY_SERVICE); Network n=cm.getActiveNetwork(); NetworkCapabilities c=n==null?null:cm.getNetworkCapabilities(n); s.append("Transport: ").append(c!=null&&c.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)?"Wi-Fi":"Unavailable").append("\nInternet validated: ").append(c!=null&&c.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)?"Yes":"No"); cardText(s.toString()); Button ping=button("Run internet latency test"); content.addView(ping); TextView out=cardText("Tap to test www.google.com"); ping.setOnClickListener(v->{out.setText("Testing…"); new Thread(()->{long st=System.currentTimeMillis(); String result; try{boolean ok=InetAddress.getByName("www.google.com").isReachable(3000); result=(ok?"Reachable":"Not reachable")+" • "+(System.currentTimeMillis()-st)+" ms";}catch(Exception e){result="DNS or internet test failed";} String finalR=result; runOnUiThread(()->out.setText(finalR));}).start();}); Button back=button("Back to dashboard"); content.addView(back); back.setOnClickListener(v->dashboard()); }
}
