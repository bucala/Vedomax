"""Render repository artwork from the existing mascot animation; no external assets."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root=Path(__file__).resolve().parents[1]
out=root/'docs/media'
out.mkdir(parents=True,exist_ok=True)
font=lambda size,weight='regular':ImageFont.truetype(str(root/f'assets/fonts/roboto-{weight}.ttf'),size)
size=(1200,400)
background=Image.new('RGB',size,'#102027')
gradient=Image.new('RGB',size)
d=ImageDraw.Draw(gradient)
for y in range(size[1]):
    t=y/size[1]
    d.line((0,y,size[0],y),fill=tuple(round(a+(b-a)*t) for a,b in zip((10,137,149),(13,93,94))))
mask=Image.new('L',size,0)
ImageDraw.Draw(mask).rounded_rectangle((0,0,1199,399),radius=32,fill=255)
background=Image.composite(gradient,background,mask)
draw=ImageDraw.Draw(background)
draw.rounded_rectangle((44,32,371,64),radius=10,fill='#237f83')
draw.text((58,39),'MALÉ KROKY. VEĽKÉ VEDOMOSTI.',font=font(16,'bold'),fill='#d6f6eb')
draw.text((42,76),'Vedomax',font=font(82,'black'),fill='white')
draw.text((46,180),'Vedomosti na Maximum',font=font(38,'bold'),fill='white')
draw.text((47,230),'pre všetky deti.',font=font(30),fill='#c6f2df')
for x,width,label in [(46,166,'336 otázok'),(228,125,'14 dní'),(369,234,'8. a 9. ročník')]:
    draw.rounded_rectangle((x,304,x+width,353),radius=15,fill='#e4a32b')
    draw.text((x+17,316),label,font=font(23,'bold'),fill='#18363a')
frames=[]
with Image.open(root/'assets/mascot/vedomax_idle_wave.webp') as animation:
    for index in range(animation.n_frames):
        animation.seek(index)
        frame=background.copy().convert('RGBA')
        frame.alpha_composite(animation.convert('RGBA'),(780,8))
        frames.append(frame.convert('RGB'))
frames[0].save(out/'hero.png')
palette=frames[0].quantize(colors=160)
indexed=[frame.quantize(palette=palette,dither=Image.Dither.FLOYDSTEINBERG) for frame in frames]
indexed[0].save(out/'hero.gif',save_all=True,append_images=indexed[1:],duration=50,loop=0,optimize=True,disposal=1)
with Image.open(out/'hero.gif') as result:
    assert result.n_frames==60
    print('README hero:',result.size,result.n_frames,'frames;', (out/'hero.gif').stat().st_size,'bytes')
