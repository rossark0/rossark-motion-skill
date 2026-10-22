#!/usr/bin/env python3
"""Read exact colours from a frame of a reference video instead of guessing them.

  python3 -I tools/sample_colors.py ref.mp4 --at 1.0 900,1065 1075,915 1080,1090

Prints each point (in video pixels) and its hex colour. For a lit or glowing state, sample
that moment too, then blend between the two colours in code (never swap one for the other).
Needs ffmpeg; Python standard library only.
"""
import argparse
import subprocess


def main():
    ap = argparse.ArgumentParser(description="Sample hex colours at points of one video frame.")
    ap.add_argument("video")
    ap.add_argument("--at", default="0", help="seconds")
    ap.add_argument("points", nargs="+", help="x,y in video pixels")
    a = ap.parse_args()

    probe = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
                            "stream=width,height", "-of", "csv=p=0", a.video],
                           capture_output=True, text=True, check=True).stdout.strip()
    w, h = map(int, probe.split(",")[:2])
    raw = subprocess.run(["ffmpeg", "-v", "error", "-ss", a.at, "-i", a.video, "-frames:v", "1",
                          "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], capture_output=True, check=True).stdout
    for p in a.points:
        x, y = map(int, p.split(","))
        if not (0 <= x < w and 0 <= y < h):
            print(f"{x},{y}  outside the {w}x{h} frame")
            continue
        i = (y * w + x) * 3
        print(f"{x},{y}  #{raw[i]:02X}{raw[i + 1]:02X}{raw[i + 2]:02X}")


if __name__ == "__main__":
    main()
