# Vedomax – animation from the supplied OBJ

Source files supplied by the user:

- `Meshy_AI_Vivi_20261026_texture.obj`
- `Meshy_AI_Vivi_20261026_texture.mtl`
- `Meshy_AI_Vivi_20261026_texture.png`

The original OBJ has 147,112 vertices / 294,256 faces and no skeleton. `scripts/animate_mascot.py` imports it into an isolated Blender background scene, retains the original UV texture, normalizes its height, and adds root, waving-arm, hand and sparkle bones. Geodesic weights isolate the waving arm from the face. The original Downloads files are not modified.

Clips:

| Clip | Duration | Frames | Motion |
|---|---|---|---|
| `Idle_Wave` | 3 seconds | 60 at 20 fps | Gentle breathing/sway, hand wave, floating sparkle |
| `Celebrate` | 1.8 seconds | 36 at 20 fps | Small happy hop and faster wave |

Blender produces transparent 384 × 384 RGBA frames. `scripts/encode_mascot.py` encodes those frames as animated WebP with alpha, without altering the source texture. Flutter supports this animation format directly, avoiding a large 3D runtime or the 32 MB model download in the main menu.

Runtime assets: `vedomax_idle_wave.webp`, `vedomax_celebrate.webp` and `vedomax_still.png`. Large mascots animate; tapping triggers celebration. Small logo marks remain static. Reduced-motion and inactive `TickerMode` use the still render. Success feedback uses the celebration clip; other results retain the calm idle animation.

Editable exports are retained at `output/mascot/vedomax_animated.blend` and `output/mascot/vedomax_animated.glb`. The blend packs the texture and both actions. The GLB contains a skin and both named animation clips.

## Reproduce

```powershell
& 'C:\Program Files\Blender Foundation\Blender\blender.exe' --background --factory-startup --python scripts/animate_mascot.py
python -m pip install Pillow
python scripts/encode_mascot.py
```

Use `-- --source 'path/to/model.obj'` after the Blender command to supply another location; the PNG texture must sit beside the OBJ with the same basename. `-- --preview` renders front/back inspection images only. The pipeline uses Blender 5.1.2 and Pillow 13.0.0.
