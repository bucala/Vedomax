"""Create platform icon sizes from the supplied artwork without redesigning it."""
from pathlib import Path
from PIL import Image
import argparse
import shutil

root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--source',type=Path,default=root/'assets/brand/app-icon-source.png')
args=parser.parse_args()
source=root/'assets/brand/app-icon-source.png'
source.parent.mkdir(parents=True,exist_ok=True)
if args.source.resolve()!=source.resolve():
    shutil.copyfile(args.source,source)
original=Image.open(source).convert('RGBA')
original=original.crop(original.getchannel('A').getbbox())
icons=root/'web/icons'
icons.mkdir(parents=True,exist_ok=True)

def icon(size,maskable=False):
    canvas=Image.new('RGBA',(size,size),'#087f8c' if maskable else (0,0,0,0))
    image=original.copy()
    limit=round(size*(.60 if maskable else .90))
    image.thumbnail((limit,limit),Image.Resampling.LANCZOS)
    if max(image.size)<limit:
        factor=limit/max(image.size)
        image=image.resize((round(image.width*factor),round(image.height*factor)),Image.Resampling.LANCZOS)
    canvas.alpha_composite(image,((size-image.width)//2,(size-image.height)//2))
    return canvas

for size in [192,512]:
    icon(size).save(icons/f'Icon-{size}.png')
    icon(size,True).save(icons/f'Icon-maskable-{size}.png')
icon(180).save(icons/'apple-touch-icon.png')
icon(32).save(root/'web/favicon.png')
icon(48).save(root/'web/favicon.ico',sizes=[(16,16),(32,32),(48,48)])
print('Created favicon ICO/PNG, Apple icon and 192/512 standard/maskable app icons.')
