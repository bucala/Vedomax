# Vedomax V emblem

## Application and website icons

`app-icon-source.png` is the exact 140 × 160 PNG supplied by the user. `python scripts/create_app_icons.py` exports it to the website favicon (16/32/48 ICO and 32 PNG), Apple touch icon (180 PNG), and 192/512 standard and maskable manifest icons. Maskable exports have a solid teal background and keep the artwork within the central safe circle. Upscaling creates the required platform dimensions; it does not add detail to the supplied source. The original illustration is preserved.

## Original generated emblem

`vedomax-v.png`: original transparent 1280 × 1280 image generated with built-in ImageGen on 2026-10-26. The emblem is also the main-menu mascot. Flutter's `Brand` widget combines it with the `vedomax` wordmark; the slogan is ordinary accessible UI text.

Exact generation prompt:

> Use case: logo-brand. Create one polished original app mascot emblem on a genuinely transparent background, for Slovak educational game Vedomax for ages 13–15. The mascot IS a bold uppercase letter V, a friendly intelligent little character with a clear V-shaped teal/turquoise body, two expressive large eyes nestled on its top arms, tiny purple sneakers, a small orange/gold four-point sparkle hovering above its right side. Playful premium clean rounded 2.5D illustration, restrained soft shading, thick confident silhouette legible as a small app icon. Entire character full body centered with generous transparent padding, approximately square. Deep teal #087f8c, mint #4fd1b5, violet #7157d9 and warm amber. Youthful but not babyish. No owl, no resemblance to Duolingo characters. No text, no wordmark, no background, no frame, no watermark. This single V emblem will be used both as app logo and main-menu mascot.
