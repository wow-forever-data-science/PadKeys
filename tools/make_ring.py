# Ring textures for PadKeys_Readout's ring at the mouse: 128x128, white,
# alpha = coverage of a ring, antialiased by 4x4 supersampling.
#   python3 make_ring.py Ring.tga 0.80 0.97        sharp ring, inner and
#                                                   outer radius (1 = edge)
#   python3 make_ring.py RingGlow.tga 0.62 1.0 soft the same, fading out
#                                                   towards both edges
import math, struct, sys
N, SS = 128, 4
inner, outer = float(sys.argv[2]), float(sys.argv[3])
soft = len(sys.argv) > 4 and sys.argv[4] == "soft"
mid, half = (inner + outer) / 2, (outer - inner) / 2
def alpha(x, y):
    r = math.hypot(x - N / 2, y - N / 2) / (N / 2)
    if soft:
        t = abs(r - mid) / half
        return max(0.0, 1 - t) ** 2
    return 1.0 if inner <= r <= outer else 0.0
rows = []
for y in range(N):
    row = bytearray()
    for x in range(N):
        a = sum(alpha(x + (i + 0.5) / SS, y + (j + 0.5) / SS)
                for i in range(SS) for j in range(SS)) / (SS * SS)
        row += bytes((255, 255, 255, round(255 * a)))
    rows.append(row)
# TGA: uncompressed true colour, 32 bpp, 8 alpha bits, origin top-left.
header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, N, N, 32, 8 | 0x20)
open(sys.argv[1], "wb").write(header + b"".join(rows))
