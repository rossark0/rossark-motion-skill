#!/usr/bin/env python3
"""Measure how something moves in a reference video, frame by frame.

Small motion (a 2% squash, a 5-pixel sway, a float of 5% of a body's height) is invisible on a
contact sheet, and it is exactly what makes the reference feel alive. This prints, for every
frame, where the subject's edges are:
  - the top edge at a few columns: does it bob, squash or tilt?
  - the left and right edges on one row: does it widen, sway or lean?

The subject is every pixel close to one of the given colours; a run of several such pixels is
needed, so sparkles and anti-aliased edges don't count. Needs ffmpeg; Python standard library only.

Examples:
  # an object that might be jiggling while it waits: read it at the source's frame rate
  python3 -I tools/track_edges.py ref.mp4 --start 0 --dur 1.2 --fps 60 \\
      --crop X:Y:W:H --colors RRGGBB,RRGGBB,RRGGBB --cols 110,320,530 --row 300

  # a figure floating in: where is its top, frame by frame?
  python3 -I tools/track_edges.py ref.mp4 --start 0 --dur 2.2 --fps 15 \\
      --crop X:Y:W:H --colors RRGGBB --tol 60 --cols 60,190,320
"""
import argparse
import subprocess


def hex_rgb(h):
    h = h.strip().lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def main():
    ap = argparse.ArgumentParser(description="Track a subject's edges in a video, frame by frame.")
    ap.add_argument("video")
    ap.add_argument("--start", default="0", help="seconds")
    ap.add_argument("--dur", default="2", help="seconds")
    ap.add_argument("--fps", default="60", help="read at this rate (use the source's rate for timing)")
    ap.add_argument("--crop", required=True, help="x:y:w:h in video pixels")
    ap.add_argument("--colors", required=True, help="comma-separated hex colours of the subject")
    ap.add_argument("--tol", type=float, default=40, help="colour distance that still counts (0-441)")
    ap.add_argument("--cols", default="", help="columns, inside the crop, to read the top edge at")
    ap.add_argument("--row", type=int, default=-1, help="row, inside the crop, to read the left/right edges at")
    ap.add_argument("--run", type=int, default=6, help="pixels in a row needed to count as the subject")
    a = ap.parse_args()

    x, y, w, h = map(int, a.crop.split(":"))
    targets = [hex_rgb(c) for c in a.colors.split(",")]
    cols = [int(c) for c in a.cols.split(",") if c]
    cmd = ["ffmpeg", "-v", "error", "-ss", a.start, "-t", a.dur, "-i", a.video,
           "-vf", f"fps={a.fps},crop={w}:{h}:{x}:{y}", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"]
    raw = subprocess.run(cmd, capture_output=True, check=True).stdout
    size = w * h * 3
    tol2 = a.tol ** 2

    def hit(o, px, py):
        i = o + (py * w + px) * 3
        r, g, b = raw[i], raw[i + 1], raw[i + 2]
        return any((r - tr) ** 2 + (g - tg) ** 2 + (b - tb) ** 2 <= tol2 for tr, tg, tb in targets)

    def first(o, coords):
        run = 0
        for k, (px, py) in enumerate(coords):
            if hit(o, px, py):
                run += 1
                if run >= a.run:
                    return k - a.run + 1
            else:
                run = 0
        return None

    def cell(v, width):
        return f"{'-' if v is None else v:>{width}}"

    head = "frame     ms " + " ".join(f"top@{c:<5}" for c in cols)
    if a.row >= 0:
        head += "   left  right  width"
    print(head)
    for f in range(len(raw) // size):
        o = f * size
        line = f"{f:5d} {round(f * 1000 / float(a.fps)):6d} "
        line += " ".join(cell(first(o, [(c, yy) for yy in range(h)]), 9) for c in cols)
        if a.row >= 0:
            left = first(o, [(xx, a.row) for xx in range(w)])
            back = first(o, [(xx, a.row) for xx in range(w - 1, -1, -1)])
            right = None if back is None else w - 1 - back
            width = None if left is None or right is None else right - left
            line += f" {cell(left, 6)} {cell(right, 6)} {cell(width, 6)}"
        print(line)


if __name__ == "__main__":
    main()
