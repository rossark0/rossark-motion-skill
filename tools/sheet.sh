#!/usr/bin/env bash
# sheet.sh: a contact sheet of a video, to study its timing frame by frame (or check your own render).
#
#   tools/sheet.sh VIDEO START DUR CROP [PER_ROW] [FPS] [OUT]
#
#   tools/sheet.sh ref.mp4 2.1 2 700:760:730:330            # every frame at the source's rate, 10 per row
#   tools/sheet.sh ref.mp4 0 5 640:600:760:700 16 10        # 10 frames a second, 16 per row
#   tools/sheet.sh ref.mp4 0 16 iw:ih:0:0 8 2 poses.png     # the whole frame, 2 a second: the poses
#
# A sheet at 2 frames a second shows the poses. Only the full frame rate shows the timing, the
# follow-through and the moving holds. Tiny motion (a 2% squash) won't show at all: measure it
# with tools/track_edges.py.
set -euo pipefail
video=$1 start=$2 dur=$3 crop=$4 per_row=${5:-10} fps=${6:-} out=${7:-sheet.png}
if [[ -z "$fps" ]]; then
  fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$video" | awk -F/ '{ printf "%g", $1 / ($2 ? $2 : 1) }')
fi
frames=$(awk -v d="$dur" -v f="$fps" 'BEGIN { n = d * f; printf "%d", (n == int(n)) ? n : int(n) + 1 }')
rows=$(( (frames + per_row - 1) / per_row ))
ffmpeg -v error -y -ss "$start" -t "$dur" -i "$video" \
  -vf "fps=$fps,crop=$crop,scale=200:-2,tile=${per_row}x${rows}" -frames:v 1 "$out"
echo "$out: $frames frames at $fps fps, $per_row per row"
