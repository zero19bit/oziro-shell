#!/usr/bin/env python3
"""On-demand NetworkManager client. JSON lines over stdin/stdout; no secret argv/logs."""
import json
import os
import pwd
import re
import sys
import time
import unicodedata

NM = "org.freedesktop.NetworkManager"
ROOT = "/org/freedesktop/NetworkManager"
DEV = NM + ".Device"
WIFI = DEV + ".Wireless"
AP = NM + ".AccessPoint"
PROFILE = NM + ".Settings.Connection"
ACTIVE = NM + ".Connection.Active"

def emit(obj):
    print(json.dumps(obj, ensure_ascii=True), flush=True)

def security(p):
    # NM80211ApSecurityFlags: PSK, SAE; reject unknown/legacy/enterprise.
    rsn, wpa = p.get("RsnFlags", 0), p.get("WpaFlags", 0)
    if p.get("Mode") != 2:
        return "unsupported"
    if rsn & 0x400:
        return "sae"
    if rsn & 0x100:
        return "wpa-psk"
    if not (p.get("Flags", 0) & 1) and not (rsn or wpa):
        return "open"
    return "unsupported"

def clean_label(raw):
    return "".join(c if not unicodedata.category(c).startswith("C") else "\ufffd"
                   for c in raw.decode("utf-8", "replace")) or "Unnamed"

def valid_secret(mode, secret):
    if not isinstance(secret, str) or "\x00" in secret or "\n" in secret or "\r" in secret:
        return False
    n = len(secret.encode("utf-8"))
    if mode == "open":
        return n == 0
    if mode == "wpa-psk":
        return 8 <= n <= 63 or bool(re.fullmatch("[0-9a-fA-F]{64}", secret))
    if mode == "sae":
        return 1 <= n <= 63
    return False

def mutation_allowed(action, uid, preview):
    return action == "list" or (uid != 0 and preview != "1")

def self_test():
    def p(flags=1, rsn=0, wpa=0, mode=2):
        return dict(Flags=flags, RsnFlags=rsn, WpaFlags=wpa, Mode=mode)
    checks = [
        security(p(0)) == "open", security(p(rsn=0x100)) == "wpa-psk",
        security(p(rsn=0x400)) == "sae", security(p(rsn=0x500)) == "sae",
        security(p()) == "unsupported", security(p(rsn=0x200)) == "unsupported",
        security(p(wpa=0x100)) == "unsupported", security(p(0,mode=1)) == "unsupported",
        valid_secret("open",""), not valid_secret("open","x"),
        valid_secret("wpa-psk","12345678"), not valid_secret("wpa-psk","1234567"),
        valid_secret("wpa-psk","a"*64), not valid_secret("wpa-psk","z"*64),
        valid_secret("sae","x"), not valid_secret("sae",""),
        not valid_secret("wpa-psk","12345678\n"), not valid_secret("sae","\x00"),
        clean_label(b"a\nb") == "a\ufffdb", clean_label(b"\xff") == "\ufffd",
        not mutation_allowed("join",1000,"1"), not mutation_allowed("disconnect",0,"0"),
        mutation_allowed("list",1000,"1"), mutation_allowed("join",1000,"0"),
    ]
    emit({"passed":sum(checks),"total":len(checks)})
    return 0 if all(checks) else 1

class Client:
    def __init__(self):
        from gi.repository import Gio, GLib
        self.Gio, self.V = Gio, GLib.Variant
        self.bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)

    def call(self, path, iface, method, sig=None, args=(), timeout=3500):
        v = self.V(sig,args) if sig else None
        result = self.bus.call_sync(NM,path,iface,method,v,None,
                                    self.Gio.DBusCallFlags.NONE,timeout,None)
        return result.unpack()

    def props(self,path,iface):
        return self.call(path,"org.freedesktop.DBus.Properties","GetAll","(s)",(iface,))[0]

    def devices(self):
        paths = self.call(ROOT,NM,"GetDevices")[0]
        return [d for d in paths if self.props(d,DEV).get("DeviceType") == 2
                and self.props(d,DEV).get("Managed")]

    def profiles(self,device):
        out = []
        for path in self.props(device,DEV).get("AvailableConnections",[])[:128]:
            try:
                s = self.call(path,PROFILE,"GetSettings")[0]
                w = s.get("802-11-wireless",{})
                if w.get("mode","infrastructure") != "infrastructure":
                    continue
                k = s.get("802-11-wireless-security",{}).get("key-mgmt","open")
                out.append((path,bytes(w.get("ssid",[])),k))
            except Exception:
                continue
        return out

    def rows(self,device):
        wireless = self.props(device,WIFI)
        active = wireless.get("ActiveAccessPoint","/")
        connected = self.props(device,DEV).get("State") == 100
        profiles = self.profiles(device)
        rows = []
        for path in self.call(device,WIFI,"GetAccessPoints")[0][:256]:
            try:
                p = self.props(path,AP)
                raw = bytes(p.get("Ssid",[]))
                if not raw or len(raw)>32:
                    continue
                mode = security(p)
                saved = [x[0] for x in profiles if x[1]==raw and
                         (x[2]==mode or (mode=="sae" and x[2]=="wpa-psk" and p.get("RsnFlags",0)&0x100))]
                rows.append(dict(device=device, ap=path, token=raw.hex(), name=clean_label(raw),
                                 security=mode, strength=max(0,min(100,int(p.get("Strength",0)))),
                                 connected=connected and path==active, saved=saved[0] if len(saved)==1 else "",
                                 ambiguous=len(saved)>1))
            except Exception:
                continue
        return rows

    def snapshot(self,scan=False):
        manager = self.props(ROOT,NM)
        enabled = bool(manager.get("WirelessEnabled") and manager.get("WirelessHardwareEnabled"))
        devices = self.devices()
        note = ""
        if scan and enabled:
            # Explicit scan only. Bounded reconciliation of LastScan, never resident polling.
            waiting = {}
            for d in devices:
                try:
                    old = self.props(d,WIFI).get("LastScan",-1)
                    self.call(d,WIFI,"RequestScan","(a{sv})",({},))
                    waiting[d] = old
                except Exception:
                    note = "Scan unavailable or rate limited; showing cached results."
            deadline = time.monotonic()+6
            while waiting and time.monotonic()<deadline:
                time.sleep(.35)
                for d in list(waiting):
                    if self.props(d,WIFI).get("LastScan",-1) != waiting[d]:
                        del waiting[d]
            if waiting:
                note = "Scan still updating; showing cached results."
        rows = []
        if enabled:
            for d in devices:
                rows.extend(self.rows(d))
        rows.sort(key=lambda x:(not x["connected"],-x["strength"],x["name"]))
        # Deduplicate APs by device, SSID and security, retain connected/strongest.
        unique = {}
        for x in rows:
            unique.setdefault((x["device"],x["token"],x["security"]),x)
        return dict(ok=True,enabled=enabled,available=bool(devices),networks=list(unique.values())[:100],message=note)

    def target(self,req):
        d = req.get("device")
        if d not in self.devices():
            raise ValueError("stale")
        row = next((x for x in self.rows(d) if x["ap"]==req.get("ap")
                    and x["token"]==req.get("token") and x["security"]==req.get("security")),None)
        if not row:
            raise ValueError("stale")
        return row

    def wait_active(self,path):
        deadline=time.monotonic()+22
        while time.monotonic()<deadline:
            try:
                state=self.props(path,ACTIVE).get("State")
            except Exception:
                return dict(ok=False,message="Connection ended. Check password or permissions.")
            if state==2:
                return dict(ok=True,message="Connected to Wi-Fi.")
            if state in (3,4):
                return dict(ok=False,message="Connection failed. Check password or permissions.")
            time.sleep(.45)
        return dict(ok=False,message="Connection still pending. Refresh to check status.")

    def join(self,req):
        row=self.target(req)
        mode=row["security"]
        if row["connected"]:
            return dict(ok=True,message="Already connected.")
        if mode=="unsupported" or row["ambiguous"]:
            return dict(ok=False,message="Unsupported security or multiple saved profiles.")
        if row["saved"] and not req.get("newPassword"):
            active=self.call(ROOT,NM,"ActivateConnection","(ooo)",
                             (row["saved"],row["device"],row["ap"]),timeout=8000)[0]
        else:
            secret=req.get("password","")
            if not valid_secret(mode,secret):
                return dict(ok=False,message="Invalid password length or characters.")
            save=req.get("save") is True and not row["saved"]
            v=self.V
            conn={
                "connection":{"id":v("s",row["name"]),"type":v("s","802-11-wireless"),
                              "autoconnect":v("b",False),
                              "permissions":v("as",["user:"+pwd.getpwuid(os.getuid()).pw_name+":"])},
                "802-11-wireless":{"ssid":v("ay",list(bytes.fromhex(row["token"]))),
                                   "mode":v("s","infrastructure")},
                "ipv4":{"method":v("s","auto")},
                "ipv6":{"method":v("s","auto")},
            }
            if mode!="open":
                conn["802-11-wireless-security"]={"key-mgmt":v("s",mode),"psk":v("s",secret)}
            # Always activate volatile first; save only after successful connection.
            profile,active,_=self.call(ROOT,NM,"AddAndActivateConnection2","(a{sa{sv}}ooa{sv})",
                              (conn,row["device"],row["ap"],{"persist":v("s","volatile")}),timeout=8000)
            result=self.wait_active(active)
            if result["ok"] and save:
                try:
                    self.call(profile,PROFILE,"Save",timeout=5000)
                    result["message"]="Connected; profile saved in NetworkManager."
                except Exception:
                    result["message"]="Connected, but saving the profile failed."
            return result
        return self.wait_active(active)

    def disconnect(self,req):
        row=self.target(req)
        if not row["connected"]:
            return dict(ok=False,message="Network is no longer active.")
        active=self.props(row["device"],DEV).get("ActiveConnection","/")
        if active=="/":
            return dict(ok=False,message="Network is no longer active.")
        self.call(ROOT,NM,"DeactivateConnection","(o)",(active,),timeout=8000)
        return dict(ok=True,message="Disconnect requested. Refresh to confirm.")

def main():
    if sys.argv[1:] == ["--self-test"]:
        return self_test()
    if len(sys.argv)!=1:
        return 2
    emit({"ready":True})
    try:
        line=sys.stdin.readline(4097)
        if not line.endswith("\n") or len(line)>4096:
            raise ValueError("request")
        req=json.loads(line)
        action=req.get("action")
        if action not in ("list","scan","join","disconnect") or not mutation_allowed(action,os.getuid(),os.environ.get("OZIRO_NESTED_PREVIEW")):
            emit(dict(ok=False,message="Action disabled in preview or privileged context."))
            return 1
        client=Client()
        result=(client.snapshot(action=="scan") if action in ("list","scan") else
                client.join(req) if action=="join" else client.disconnect(req))
        emit(result)
        return 0 if result["ok"] else 1
    except ImportError:
        emit(dict(ok=False,message="Install python-gobject to use Wi-Fi Manager."))
    except Exception:
        # Never print exception text; D-Bus errors can contain private details.
        emit(dict(ok=False,message="NetworkManager unavailable, permission denied, or network changed."))
    return 1

if __name__=="__main__":
    sys.exit(main())
