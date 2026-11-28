#!/usr/bin/env python3
"""Read-only Linux thermal capability snapshot; no sysfs writes or privileged commands."""
import json
import os
import re
import sys
import tempfile
from pathlib import Path

def read(path, default=""):
    try:
        with path.open(encoding="utf-8", errors="replace") as stream:
            return stream.read(256).strip()
    except OSError:
        return default

def integer(path, low, high):
    value = read(path)
    if not re.fullmatch(r"-?[0-9]{1,9}", value):
        return None
    n = int(value)
    return n if low <= n <= high else None

def asus_curves(controls):
    result = []
    for channel, fan in ((1, "CPU"), (2, "GPU")):
        rows = [c for c in controls if c["driver"] == "asus_custom_fan_curve"]
        prefix = "pwm" + str(channel)
        def value(attribute):
            matches = [c["value"] for c in rows if c["attribute"] == attribute]
            return matches[0] if len(matches) == 1 else None
        points = []
        for i in range(1, 9):
            base = prefix + "_auto_point" + str(i)
            t, p = value(base+"_temp"), value(base+"_pwm")
            if t is None or p is None or not (0 <= t <= 100 and 0 <= p <= 255):
                break
            points.append(dict(temp=t,pwm=p))
        if len(points)==8 and all(a["temp"] < b["temp"] for a,b in zip(points,points[1:])):
            result.append(dict(fan=fan,mode=value(prefix+"_enable"),points=points))
    return result

def snapshot(root=Path("/sys")):
    fans, temps, controls = [], [], []
    for hw in sorted((root / "class/hwmon").glob("hwmon*"))[:128]:
        name = read(hw / "name", "unknown")
        for f in sorted(hw.glob("fan*_input"))[:32]:
            match = re.fullmatch(r"fan([0-9]+)_input", f.name)
            if not match:
                continue
            n = match.group(1)
            rpm = integer(f, 0, 100000)
            if rpm is not None:
                fans.append(dict(driver=name, label=read(hw / ("fan"+n+"_label"), "Fan "+n), rpm=rpm))
        for f in sorted(hw.glob("temp*_input"))[:32]:
            match = re.fullmatch(r"temp([0-9]+)_input", f.name)
            if not match:
                continue
            n = match.group(1)
            value = integer(f, -40000, 160000)
            if value is not None:
                temps.append(dict(driver=name, label=read(hw / ("temp"+n+"_label"), "Temperature "+n), celsius=round(value/1000,1)))
        # Presence is evidence only, not permission, compatibility or safe control.
        for f in sorted(hw.glob("*"))[:512]:
            if re.fullmatch(r"pwm[0-9]+(?:_enable|_auto_point[0-9]+_(?:pwm|temp))?|fan[0-9]+_target", f.name):
                controls.append(dict(driver=name, attribute=f.name,
                    value=integer(f,-40000,1000000), writable=os.access(f,os.W_OK)))
    dmi = root / "class/dmi/id"
    acpi = root / "firmware/acpi"
    return dict(vendor=read(dmi/"sys_vendor"), model=read(dmi/"product_name"),
                fans=fans, temperatures=temps, controls=controls, curves=asus_curves(controls),
                platformProfile=read(acpi/"platform_profile"),
                platformChoices=read(acpi/"platform_profile_choices").split(),
                asusctl=Path("/usr/bin/asusctl").is_file(),
                manualSupported=False)

def self_test():
    with tempfile.TemporaryDirectory() as directory:
        root=Path(directory)
        h=root/"class/hwmon/hwmon0"
        h.mkdir(parents=True)
        fixture={"name":"asus","fan1_input":"2800","fan2_input":"0","fan3_input":"-1",
                 "fan1_label":"CPU","temp1_input":"42500","temp2_input":"bad",
                 "pwm1_enable":"2","fan1_target":"3000","pwm1_auto_point1_temp":"45000"}
        for name,value in fixture.items():
            (h/name).write_text(value)
        s=snapshot(root)
        checks=[len(s["fans"])==2, s["fans"][0]["rpm"]==2800,
                s["fans"][0]["label"]=="CPU",s["fans"][1]["rpm"]==0,
                len(s["temperatures"])==1,s["temperatures"][0]["celsius"]==42.5,
                len(s["controls"])==3,not s["manualSupported"],
                all((h/k).read_text()==v for k,v in fixture.items()),
                not snapshot(root/"missing")["fans"]]
        rows=[]
        for i in range(1,9):
            for attr,v in (("temp",30+i*5),("pwm",i*20)):
                rows.append(dict(driver="asus_custom_fan_curve",attribute="pwm1_auto_point"+str(i)+"_"+attr,value=v))
        curves=asus_curves(rows)
        checks.extend([not s["curves"], len(curves)==1, curves[0]["fan"]=="CPU",
                       len(curves[0]["points"])==8, curves[0]["points"][0]==dict(temp=35,pwm=20),
                       not asus_curves(rows[:-1]), not asus_curves(rows+rows[:1])])
        print(json.dumps(dict(passed=sum(checks),total=len(checks))))
        return 0 if all(checks) else 1

if __name__=="__main__":
    if sys.argv[1:]==["--self-test"]:
        sys.exit(self_test())
    if sys.argv[1:] not in ([],["--probe"]):
        sys.exit(2)
    print(json.dumps(snapshot(), ensure_ascii=True,
                     indent=2 if sys.argv[1:] else None))
