"""Encode Blender RGBA render sequences without altering the supplied texture."""
from pathlib import Path
from PIL import Image
import json
import shutil

ROOT=Path(__file__).resolve().parents[1]
frames=ROOT/'output/mascot/frames'
assets=ROOT/'assets/mascot'
assets.mkdir(exist_ok=True)
report={}
for clip,count in [('idle_wave',60),('celebrate',36)]:
    paths=sorted((frames/clip).glob('*.png'))
    assert len(paths)==count,(clip,len(paths))
    images=[Image.open(p).convert('RGBA') for p in paths]
    path=assets/f'vedomax_{clip}.webp'
    images[0].save(path,save_all=True,append_images=images[1:],duration=50,loop=0,
                   quality=85,method=3,lossless=False,exact=True,kmin=9,kmax=17)
    with Image.open(path) as result:
        assert result.n_frames==count
        assert result.size==(384,384)
        assert result.convert('RGBA').getchannel('A').getextrema()==(0,255)
        report[clip]={'frames':result.n_frames,'fps':20,'bytes':path.stat().st_size,'size':list(result.size),'transparent':True}
    for image in images:image.close()
shutil.copyfile(frames/'idle_wave/0001.png',assets/'vedomax_still.png')
(assets/'animation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print(json.dumps(report))
