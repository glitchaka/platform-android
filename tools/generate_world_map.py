"""Draw the real room graph; export one shared scene to SVG and a raster renderer."""
from pathlib import Path
import json
import html

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Builds/Maps"
data = json.loads((OUT / "world-map-data.json").read_text(encoding="utf-8"))
rooms = {r["id"]: r for r in data["rooms"]}
assert len(rooms) == 55 and len(data["links"]) == 65
assert len({frozenset((e["a"], e["b"])) for e in data["links"]}) == 65
seen = {"tutorial"}
while True:
    new = seen | {e[k] for e in data["links"] if e["a"] in seen or e["b"] in seen for k in ("a", "b")}
    if new == seen: break
    seen = new
assert seen == rooms.keys()
audit = json.loads((ROOT / "Tests/portal-map-audit.json").read_text(encoding="utf-8"))
assert audit["failures"] == 0
actual = {(e["from"], e["portal"], e["to"]) for e in audit["transitions"]}
expected = {(r["id"], d["number"], d["to"]) for r in rooms.values() for d in r["doors"]}
assert actual == expected and len(actual) == 130

accents = {"Galeria": "Galería", "Camara": "Cámara", "Raices": "Raíces", "raices": "raíces", "Principe": "Príncipe", "Deposito": "Depósito", "Salon": "Salón", "Jardin del": "Jardín del"}
for room in rooms.values():
    for a, b in accents.items(): room["name"] = room["name"].replace(a,b)

W, H, S, OX, OY = 3680, 2750, 9, 100, 230
BG, FG, MUTED = "#10191d", "#eef3ea", "#a7b9b8"
commands = []
def rect(x,y,w,h,fill,stroke=None,sw=1,rx=0):
    commands.append(dict(kind="rect",x=x,y=y,w=w,h=h,fill=fill,stroke=stroke,sw=sw,rx=rx))
def text(x,y,value,size=24,color=FG,align="left",weight="normal"):
    commands.append(dict(kind="text",x=x,y=y,text=value,size=size,color=color,align=align,weight=weight))
def path(points,color,width=3,dash=False):
    commands.append(dict(kind="path",points=points,color=color,sw=width,dash=dash))
def blend(a,b,ratio):
    aa=[int(a[i:i+2],16) for i in (1,3,5)]; bb=[int(b[i:i+2],16) for i in (1,3,5)]
    return "#"+"".join(f"{round(x*(1-ratio)+y*ratio):02x}" for x,y in zip(aa,bb))
def px(point): return [OX+point[0]*S, OY+point[1]*S]

blocked=set()
for room in rooms.values():
    x,y,w,h=map(int,room["rect"])
    blocked.update((xx,yy) for xx in range(x,x+w+1) for yy in range(y,y+h+1))
def verified_route(edge):
    # Consume the same floor anchors and paths used by the in-game atlas.
    points = [tuple(map(int,p)) for p in edge["points"]]
    da = next(d for d in rooms[edge["a"]]["doors"] if d["to"] == edge["b"])
    db = next(d for d in rooms[edge["b"]]["doors"] if d["to"] == edge["a"])
    assert points[0] == tuple(da["map_port"]) and points[-1] == tuple(db["map_port"])
    cells = []
    for a,b in zip(points,points[1:]):
        assert a[0] == b[0] or a[1] == b[1]
        dx = (b[0]>a[0])-(b[0]<a[0]); dy = (b[1]>a[1])-(b[1]<a[1])
        for n in range(abs(b[0]-a[0])+abs(b[1]-a[1])):
            cells.append((a[0]+dx*n,a[1]+dy*n))
    cells.append(points[-1])
    assert not (set(cells[1:-1]) & blocked)
    return points

rect(0,0,W,H,BG)
text(96,50,"ASHEN MERIDIAN  /  ATLAS COMPLETO",46,weight="bold")
text(96,113,"55 salas · 9 zonas · 65 conexiones reales · versión 0.4.1",26,MUTED)
for i,(key,z) in enumerate(data["zones"].items()):
    xx=96+i*390
    rect(xx,174,18,18,z["color"],rx=3)
    text(xx+30,169,z["name"],21)

highlight={frozenset(("city_gate","reservoir")),frozenset(("reservoir","city_spire"))}
routed=[]
for e in data["links"]:
    points=verified_route(e)
    color="#efbf64" if frozenset((e["a"],e["b"])) in highlight else "#f08c74" if e["gate"] else "#60787c"
    path([px(p) for p in points],color,5 if color=="#efbf64" else 3.5,bool(e["gate"]))
    routed.append(dict(e,points=points))

rewards={"start":"INICIO","rest":"DESCANSO / TIENDA","boss":"GUARDIÁN","heart":"VIDA","coin":"TESORO","double_jump":"DOBLE SALTO","dash":"IMPULSO","ending":"FINAL"}
wrapped=[]
for room in rooms.values():
    x,y,w,h=room["rect"]; xx,yy=px((x,y)); ww,hh=w*S,h*S
    color=data["zones"][room["zone"]]["color"]
    important=room["id"] in ("canopy","city_spire","throne","aurora_gate")
    rect(xx,yy,ww,hh,blend(BG,color,.19),"#efbf64" if important else color,5 if important else 2.5,5)
    size=23 if ww>=130 else 20 if ww>=85 else 17
    budget=max(4,int((ww-18)/(size*.56)))
    lines=[]; line=""
    words=[]
    for word in room["name"].split():
        while len(word)>budget:
            words.append(word[:budget-1]+"-"); word=word[budget-1:]
        words.append(word)
    for word in words:
        if line and len(line)+len(word)+1>budget: lines.append(line); line=word
        else: line=(line+" "+word).strip()
    if line: lines.append(line)
    badge=rewards.get(room["reward"],"")
    if room["id"]=="aurora_gate": badge="5 MISIONES"
    badge_lines=[badge] if badge else []
    if badge and len(badge)*14*.57>ww-12: badge_lines=badge.replace(" / "," ").split()
    total=len(lines)*(size+3)+(len(badge_lines)*18+5 if badge else 0)
    assert total<=hh-4,(room["id"],total,hh)
    ty=yy+(hh-total)/2
    for label in lines:
        text(xx+ww/2,ty,label,size,FG,"center"); ty+=size+3
    if badge:
        ty+=5
        for label in badge_lines:
            text(xx+ww/2,ty,label,14,"#efbf64" if important else blend(color,FG,.4),"center"); ty+=18
    wrapped.append({"id":room["id"],"lines":lines,"badge":badge})

# The numbers match the floor portals in the game, in left-to-right order.
for room in rooms.values():
    for door in room["doors"]:
        xx,yy = px(door["map_port"])
        rect(xx-8,yy+1,16,19,BG)
        text(xx,yy+2,str(door["number"]),15,"#efbf64","center",weight="bold")

path([[96,2270],[W-96,2270]],"#3a5055",2)
columns=[
    (96,"PARA ENCONTRAR LAS HABILIDADES",[
        "DOBLE SALTO: cofre de la Copa, en Hongos.",
        "IMPULSO: cofre en lo alto de la Aguja, en Ruinas.",
        "Ruta dorada: Puerta de Ciudad → Depósito → Aguja.",
        "En ambas salas, sigue la puerta del centro.",
        "El nombre de la sala aparece al acercarte a la puerta.",
        "El HUD superior muestra el nombre de la zona."
    ]),
    (1330,"ACCESO A LAS REGIONES · CAMPAÑA",[
        "Pueblo / Cruces: medalla del cofre del Sendero.",
        "Hongos: vence al Nido y cobra al guía del Pueblo.",
        "Huesos: consigue el doble salto de la Copa.",
        "Ruinas: recoge la llave del Príncipe de Huesos.",
        "Palacio: impulso y llave real; entrada desde Hongos.",
        "Alba: cinco misiones; puerta derecha del Trono."
    ]),
    (2500,"CONEXIONES CON REQUISITO",[
        "Línea coral discontinua: acceso condicionado.",
        "Tallo → Senda enterrada: doble salto.",
        "Depósito → Ciudad profunda: impulso.",
        "Puerta del musgo → Salón: las dos llaves.",
        "Tesoros de Huesos / Ruinas: vence a su guardián.",
        "Trono → Umbral del Alba: cinco misiones."
    ])
]
for xx,heading,lines in columns:
    text(xx,2310,heading,25,"#efbf64",weight="bold")
    for i,line in enumerate(lines): text(xx,2361+i*38,line,22)
text(96,2640,"Números: portales de izquierda a derecha, iguales al juego. Las líneas unen esos portales; sus cruces no crean salidas. Distancias esquemáticas.",22,MUTED)
text(96,2680,"Tras el final, las misiones reabren Hongos, Huesos, Ruinas y Palacio en orden. La quinta abre Jardines del Alba. Datos extraídos del juego.",22,MUTED)

svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" role="img" aria-labelledby="map-title"><title id="map-title">Mapa completo de Ashen Meridian: 55 salas y 65 conexiones</title>']
for c in commands:
    if c["kind"]=="rect":
        svg.append(f'<rect x="{c["x"]}" y="{c["y"]}" width="{c["w"]}" height="{c["h"]}" rx="{c["rx"]}" fill="{c["fill"]}" stroke="{c["stroke"] or "none"}" stroke-width="{c["sw"]}"/>')
    elif c["kind"]=="path":
        pp=" ".join(f'{x},{y}' for x,y in c["points"])
        svg.append(f'<polyline points="{pp}" fill="none" stroke="{c["color"]}" stroke-width="{c["sw"]}" stroke-linejoin="round"'+(' stroke-dasharray="12 8"' if c["dash"] else '')+'/>')
    else:
        svg.append(f'<text x="{c["x"]}" y="{c["y"]+c["size"]*.92}" text-anchor="{"middle" if c["align"]=="center" else "start"}" font-family="Arial, sans-serif" font-size="{c["size"]}" font-weight="{c["weight"]}" fill="{c["color"]}">{html.escape(c["text"])}</text>')
svg.append('</svg>')
(OUT/"mapa-completo.svg").write_text("\n".join(svg),encoding="utf-8")
(OUT/"map-drawing.json").write_text(json.dumps(dict(width=W,height=H,commands=commands),ensure_ascii=False),encoding="utf-8")
(OUT/"map-validation.json").write_text(json.dumps(dict(rooms=55,links=65,actual_directed_transitions=130,connected=True,routes_avoid_rooms=True,portal_endpoints_match=True,labels=wrapped),ensure_ascii=False,indent=2),encoding="utf-8")
(OUT/"world-map-data.json").write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding="utf-8")
widget = OUT/"mapa-de-salas.html"
if widget.exists():
    fragment = widget.read_text(encoding="utf-8")
    marker = '<script type="application/json" data-world-map>'
    start = fragment.index(marker)+len(marker)
    end = fragment.index('</script>',start)
    widget.write_text(fragment[:start]+json.dumps(data,ensure_ascii=False,indent=2)+fragment[end:],encoding="utf-8")
print(f"Map generated: {len(rooms)} labeled rooms, {len(routed)} obstacle-routed links; SVG and drawing commands.")
