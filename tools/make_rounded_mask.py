# Rounded-square mask: 64x64, white, alpha = coverage of a rounded square
# filling the whole image (corner radius R), antialiased by 4x4 supersampling.
import struct, sys
N, R, SS = 64, int(sys.argv[2]), 4
def inside(x, y):
    cx = min(max(x, R), N - R)
    cy = min(max(y, R), N - R)
    return (x - cx) ** 2 + (y - cy) ** 2 <= R * R
rows = []
for y in range(N):
    row = bytearray()
    for x in range(N):
        hits = sum(inside(x + (i + 0.5) / SS, y + (j + 0.5) / SS)
                   for i in range(SS) for j in range(SS))
        row += bytes((255, 255, 255, round(255 * hits / (SS * SS))))
    rows.append(row)
# TGA: uncompressed true colour, 32 bpp, 8 alpha bits, origin top-left.
header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, N, N, 32, 8 | 0x20)
open(sys.argv[1], "wb").write(header + b"".join(rows))
