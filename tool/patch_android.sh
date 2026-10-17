#!/usr/bin/env bash
# Dijalankan otomatis oleh workflow setelah folder android dibuat.
set -e
M=android/app/src/main/AndroidManifest.xml
python3 - "$M" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
perm = 'android.permission.INTERNET'  # untuk jembatan lokal 127.0.0.1 ke Bloader
if perm not in s:
    s = s.replace('<application', '    <uses-permission android:name="%s"/>\n    <application' % perm, 1)
# Matikan Impeller (mesin render baru Flutter). Di sebagian HP (Xiaomi/Redmi/Poco
# dan GPU tertentu) Impeller membuat game macet di logo / layar hitam.
meta = 'io.flutter.embedding.android.EnableImpeller'
if meta not in s:
    i = s.index('<application')
    j = s.index('>', i) + 1
    s = s[:j] + '\n        <meta-data android:name="%s" android:value="false"/>' % meta + s[j:]
open(p, 'w', encoding='utf-8').write(s)
PY

# Ikon aplikasi memakai logo yang sudah ada (assets/logo.png),
# diletakkan di atas latar navy supaya tidak transparan/hitam di launcher.
R=android/app/src/main/res
BG='#050B1A'
# Pilih alat gambar: ImageMagick bila ada, kalau tidak pakai Pillow (dipasang otomatis).
TOOL=""
if command -v convert >/dev/null 2>&1; then
  TOOL=convert
elif command -v magick >/dev/null 2>&1; then
  TOOL=magick
else
  python3 -c "import PIL" 2>/dev/null || python3 -m pip install --quiet pillow \
    || python3 -m pip install --quiet --break-system-packages pillow
fi
for pair in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
  d=${pair%%:*}; z=${pair##*:}
  mkdir -p "$R/mipmap-$d"
  out="$R/mipmap-$d/ic_launcher.png"
  if [ -n "$TOOL" ]; then
    inner=$((z * 82 / 100))
    $TOOL -size ${z}x${z} xc:"$BG" \( assets/logo.png -resize ${inner}x${inner} \) \
      -gravity center -composite "$out"
  else
    python3 - "$z" "$out" <<'PY'
import sys
from PIL import Image
z = int(sys.argv[1]); out = sys.argv[2]
bg = Image.new('RGBA', (z, z), (5, 11, 26, 255))
lg = Image.open('assets/logo.png').convert('RGBA')
n = int(z * 0.82)
lg = lg.resize((n, n), Image.LANCZOS)
bg.alpha_composite(lg, ((z - n) // 2, (z - n) // 2))
bg.convert('RGB').save(out)
PY
  fi
done
echo "patch_android selesai"
