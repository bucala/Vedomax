"""Create a local, offline review page for the rendered OBJ animation."""
from pathlib import Path

root=Path(__file__).resolve().parents[1]
path=root/'output/mascot/preview.html'
path.write_text('''<!doctype html>
<html lang="sk"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Vedomax – animovaný 3D maskot</title>
<style>body{margin:0;background:#102027;color:#e5f3ee;font:16px system-ui,sans-serif}main{max-width:1000px;margin:auto;padding:40px 20px}h1{font-size:32px}.clips{display:flex;gap:24px;flex-wrap:wrap}figure{margin:0;flex:1;min-width:260px;padding:24px;background:#087f8c;border-radius:24px;text-align:center}img{width:100%;max-width:384px}figcaption{font-weight:700}a{color:#9ce8d0}p{line-height:1.6}</style>
<main><h1>Vedomax ožil v 3D</h1><p>Animácia vytvorená zo zadaného OBJ modelu a pôvodnej textúry. Bez účtu či internetového pripojenia.</p>
<div class="clips"><figure><picture><source media="(prefers-reduced-motion:reduce)" srcset="../../assets/mascot/vedomax_still.png"><img src="../../assets/mascot/vedomax_idle_wave.webp" alt="Vedomax sa jemne pohupuje a máva rukou"></picture><figcaption>Jemné pohupovanie a mávanie · 3 sekundy</figcaption></figure>
<figure><picture><source media="(prefers-reduced-motion:reduce)" srcset="../../assets/mascot/vedomax_still.png"><img src="../../assets/mascot/vedomax_celebrate.webp" alt="Vedomax oslavuje úspech malým výskokom"></picture><figcaption>Oslava úspechu · 1,8 sekundy</figcaption></figure></div>
<p><a href="vedomax_animated.blend">Upraviteľná Blender scéna</a> · <a href="vedomax_animated.glb">3D model s oboma animáciami (GLB)</a></p>
<p>V aplikácii ťukni na maskota a spustí oslavu. Nastavenie Obmedziť animácie zobrazí pokojnú statickú verziu.</p></main></html>''',encoding='utf8')
print(path)
