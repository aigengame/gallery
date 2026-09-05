"""Exercise real player UI and a complete walking route through gda.

Run against a freshly started windowed session. Continuous actions use InputMap;
mouse coordinates come from game rect rather than screenshot pixels.
"""
import json
import math
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "evidence/raw/playtest"
OUT.mkdir(parents=True, exist_ok=True)
results = []

def gda(*args):
    command = ["gda", *map(str, args), "--project", str(ROOT), "--json"]
    process = subprocess.run(command, capture_output=True, text=True, timeout=45)
    data = json.loads(process.stdout)
    results.append({"args": list(map(str,args)), "exit":process.returncode, "result":data})
    (OUT / "operations.json").write_text(json.dumps(results,ensure_ascii=False,indent=2)+"\n")
    if process.returncode or "error" in data:
        raise RuntimeError(data)
    return data

def state():
    return gda("game", "call", "/root/Verdant/World", "--method", "get_snapshot")["value"]

def find(name):
    def walk(node):
        if node["name"] == name:
            return node["path"]
        for child in node.get("children", []):
            found = walk(child)
            if found:
                return found
    found = walk(gda("game", "tree")["root"])
    if not found:
        raise RuntimeError("Missing player control: " + name)
    return found

def click(name):
    rect = gda("game", "rect", find(name))
    x,y = rect["position"]
    w,h = rect["size"]
    gda("input", "mouse-click", x+w/2, y+h/2)

def tap(key):
    gda("input", "tap", "--key", key)

def hold(action, frames):
    gda("input", "sequence", "--events", json.dumps([
        {"type":"action","action":action,"physics_frame":0},
        {"type":"action","action":action,"release":True,"physics_frame":frames}]))

def capture(name):
    return gda("screen","capture","--output",OUT/(name+".png"))

def locale():
    return gda("game","get","/root/Verdant/Overlay","--property","current_locale")["properties"][0]["value"]

def main():
    click("LanguageChinese")
    assert locale() == "zh"
    capture("title-zh")
    click("LanguageEnglish")
    assert locale() == "en"
    capture("title-en")
    click("StartExploring")
    assert state()["started"] and not state()["paused"]
    print("Player start and both languages passed.", flush=True)
    before = state()["distance_walked"]
    hold("walk_forward",120)
    assert state()["distance_walked"] > before+6.5
    tap("Escape")
    assert state()["paused"]
    before = state()["distance_walked"]
    hold("walk_forward",30)
    assert abs(state()["distance_walked"]-before)<0.01
    click("Resume")
    assert not state()["paused"]
    print("Walking, pause and resume passed.",flush=True)

    for index,(tx,tz) in enumerate([(-18,5),(10,-22),(34,8)]):
        for _ in range(4):
            snapshot=state()
            x,_,z=map(float,re.findall(r"-?\d+(?:\.\d+)?",snapshot["position"]))
            distance=math.hypot(tx-x,tz-z)
            if distance<2.3:
                break
            yaw=math.atan2(-(tx-x),-(tz-z))
            gda("game","set","/root/Verdant/World/Explorer","--property","yaw","--value",str(yaw))
            frames=min(580,max(1,int((distance-1.5)/3.8*60)))
            hold("walk_forward",frames)
        snapshot=state()
        assert snapshot["nearest_viewpoint"]==index and snapshot["visit_distance"]<3
        tap("E")
        snapshot=state()
        assert snapshot["visited_count"]==index+1
        capture("viewpoint-"+str(index+1))
        print("Visited viewpoint",index+1,flush=True)

    assert state()["paused"]
    click("KeepExploring")
    assert not state()["paused"]
    tap("Escape")
    click("RestartFromPause")
    assert state()["visited_count"]==0 and not state()["paused"]
    errors=gda("diag","errors")
    assert not errors["errors"], errors
    summary={"passed":True,"language_switch":True,"real_action_movement":True,
             "pause_freezes_movement":True,"viewpoints_visited":3,
             "completion_continue":True,"restart_clears_progress":True,
             "runtime_errors":[],"operations":len(results)}
    (OUT/"summary.json").write_text(json.dumps(summary,indent=2)+"\n")
    print(json.dumps(summary),flush=True)


if __name__ == "__main__":
    main()
