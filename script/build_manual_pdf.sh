#!/usr/bin/env bash
# Mencetak HTML hasil script/build_manual.rb menjadi PDF A4.
#
#   script/build_manual_pdf.sh app_info/manual-book.html Manual_Book_SPK_SEBUSE.pdf
#
# Pencetaknya adalah Microsoft Edge headless di sisi Windows. Berkas disalin
# lebih dahulu ke C:\Temp karena Edge dijalankan pada sesi Windows yang tidak
# mengenali drive jaringan tempat repositori ini berada; membacanya langsung
# menghasilkan halaman "File not found" berisi satu halaman.
set -euo pipefail

SOURCE=${1:?berkas HTML sumber belum disebutkan}
OUTPUT=${2:-$(basename "${SOURCE%.html}").pdf}

EDGE="/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
[ -x "$EDGE" ] || EDGE="/mnt/c/Program Files/Microsoft/Edge/Application/msedge.exe"
[ -x "$EDGE" ] || { echo "Microsoft Edge tidak ditemukan"; exit 1; }

STAGE=/mnt/c/Temp/spk-manual-$$
mkdir -p "$STAGE"
trap 'rm -rf "$STAGE"' EXIT

cp "$SOURCE" "$STAGE/dokumen.html"
# Gambar yang dirujuk dokumen ikut disalin agar tata letaknya utuh.
if [ -d "$(dirname "$SOURCE")/../gambar" ]; then
  mkdir -p "$STAGE/../gambar" && cp -r "$(dirname "$SOURCE")/../gambar/." "$STAGE/../gambar/"
fi

WIN_STAGE="C:\\Temp\\spk-manual-$$"
"$EDGE" --headless --disable-gpu --no-pdf-header-footer \
        --print-to-pdf="$WIN_STAGE\\hasil.pdf" \
        "file:///C:/Temp/spk-manual-$$/dokumen.html" >/dev/null 2>&1

TARGET="$(dirname "$SOURCE")/$OUTPUT"
cp "$STAGE/hasil.pdf" "$TARGET"
echo "$TARGET ($(( $(stat -c%s "$TARGET") / 1024 )) KB)"
