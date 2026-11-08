package pl.teamcs.network;

import android.app.Activity;
import android.content.Context;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.os.SystemClock;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;
import org.json.JSONObject;
import java.util.Objects;

/**
 * Android network routing for TeamCS 3D (Godot v2 Android plugin).
 * Changes ONLY this process's routing, never the device's Wi-Fi/mobile toggles.
 *
 * Auto explicitly opt-in, validated networks only, >= 60s cooldown and large
 * improvement threshold. Android estimated downstream bandwidth is NOT server RTT.
 * Switching a process route can terminate existing connections: rejoin is needed.
 */
public final class TeamCSNetwork extends GodotPlugin {
    private static final long COOLDOWN_MS = 60_000L;
    private static final float IMPROVEMENT = 1.55f;
    private boolean smart = false;
    private Network selected;
    private long lastSwitch = 0L;
    private String lastReason = "Android wybiera sieć";

    public TeamCSNetwork(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "TeamCSNetwork"; }

    private ConnectivityManager manager() {
        Activity activity = getActivity();
        if (activity == null) return null;
        return (ConnectivityManager) activity.getSystemService(Context.CONNECTIVITY_SERVICE);
    }

    private boolean valid(NetworkCapabilities c) {
        return c != null
            && c.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            && c.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
            && (c.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
                || c.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR));
    }

    private String transport(NetworkCapabilities caps) {
        if (caps == null) return "BRAK";
        if (caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) return "Wi-Fi";
        if (caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) return "Sieć komórkowa";
        if (caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)) return "Ethernet";
        return "Inna";
    }

    private float score(NetworkCapabilities caps) {
        if (!valid(caps)) return -1;
        // Android estimates, not real measured throughput or latency.
        float dl = Math.max(1000, caps.getLinkDownstreamBandwidthKbps());
        float ul = Math.max(128, caps.getLinkUpstreamBandwidthKbps());
        float total = dl * 0.65f + ul * 0.35f;
        // Limit unnecessary mobile-data usage when similar.
        if (caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) total *= 1.12f;
        return total;
    }

    @UsedByGodot public synchronized boolean setSmartMode(boolean enabled) {
        smart = enabled;
        ConnectivityManager cm = manager();
        if (cm == null) return false;
        if (!enabled) {
            cm.bindProcessToNetwork(null); // restore Android default network
            selected = null;
            lastReason = "Android wybiera sieć";
            return true;
        }
        lastReason = "Auto: tylko gra (eksperymentalnie)";
        return maybeSwitch(cm, true);
    }

    private synchronized boolean maybeSwitch(ConnectivityManager cm, boolean first) {
        if (!smart) return false;
        long now = SystemClock.elapsedRealtime();
        if (!first && now - lastSwitch < COOLDOWN_MS) return false;
        Network defaultNetwork = cm.getActiveNetwork();
        Network baseline = selected != null ? selected : defaultNetwork;
        float baselineScore = score(baseline == null ? null : cm.getNetworkCapabilities(baseline));
        Network best = null;
        float bestScore = -1f;
        boolean wifi = false, mobile = false;
        for (Network n : cm.getAllNetworks()) {
            NetworkCapabilities caps = cm.getNetworkCapabilities(n);
            if (!valid(caps)) continue;
            if (caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) wifi = true;
            if (caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) mobile = true;
            float proposed = score(caps);
            if (proposed > bestScore) { best = n; bestScore = proposed; }
        }
        if (best == null) {
            cm.bindProcessToNetwork(null);
            selected = null;
            lastReason = "Brak zweryfikowanej sieci; Android decyduje";
            return false;
        }
        if (Objects.equals(baseline, best)) return false;
        boolean baselineUnavailable = baselineScore < 0f;
        if (!baselineUnavailable && bestScore < baselineScore * IMPROVEMENT) return false;
        // Avoid selecting cellular when there is no available mobile transport.
        NetworkCapabilities bestCaps = cm.getNetworkCapabilities(best);
        if (bestCaps == null || !valid(bestCaps)) return false;
        if (!cm.bindProcessToNetwork(best.equals(defaultNetwork) ? null : best)) {
            lastReason = "Android odmówił zmiany trasy";
            return false;
        }
        selected = best.equals(defaultNetwork) ? null : best;
        lastSwitch = now;
        lastReason = (baselineUnavailable ? "Odzyskano połączenie" : "Szacowana lepsza przepustowość")
                + " → " + transport(bestCaps);
        return true;
    }

    @UsedByGodot public synchronized String getStateJson() {
        JSONObject json = new JSONObject();
        ConnectivityManager cm = manager();
        try {
            json.put("smart",smart);
            if (cm == null) {
                json.put("label","Android: brak dostępu do łączności");
                json.put("type","unknown");
                json.put("validated",false);
                json.put("wifiAvailable",false);
                json.put("mobileAvailable",false);
                return json.toString();
            }
            if (smart) maybeSwitch(cm,false);
            Network active = selected != null ? selected : cm.getActiveNetwork();
            NetworkCapabilities activeCaps = active == null ? null : cm.getNetworkCapabilities(active);
            boolean wifi = false, mobile = false;
            for (Network n : cm.getAllNetworks()) {
                NetworkCapabilities caps = cm.getNetworkCapabilities(n);
                if (!valid(caps)) continue;
                wifi |= caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI);
                mobile |= caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR);
            }
            String type = transport(activeCaps);
            json.put("type", type);
            json.put("label", type + (smart ? " / " + lastReason : " / Android decyduje"));
            json.put("validated",valid(activeCaps));
            json.put("wifiAvailable",wifi);
            json.put("mobileAvailable",mobile);
            json.put("downlinkEstimateKbps",activeCaps == null ? 0 : activeCaps.getLinkDownstreamBandwidthKbps());
            json.put("boundByGame",selected != null);
            // No invented ping; game-server RTT comes from online gameplay.
            return json.toString();
        } catch (Exception e) {
            return "{\"type\":\"unknown\",\"label\":\"Status sieci niedostępny\",\"validated\":false}";
        }
    }
}
