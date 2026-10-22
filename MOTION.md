# MOTION.md: living illustrations in this project

> Copy this file next to the project's illustrations (for example `src/art/MOTION.md`) and fill in **Part 2** as you learn the project. Part 1 is the method and stays as it is. The `rossark-motion-skill` reads this file first, and Part 2 overrides the skill's defaults.

---

## Part 1. The method

**The goal:** characters that feel alive and calm. Nothing teleports, nothing bounces, nothing shouts.

### Rules
1. **Never swap drawings mid-motion.** Pupils slide, lids lower and rise, mouths open and close, heads rotate.
2. **No bounce.** Timed motion with strong curves, never springy overshoot.
3. **Small amplitudes.**
   - breathing: 1 to 2 units;
   - head tilt: 3 to 6°;
   - gaze: a few units inside the eye.
4. **Opacity only to appear or disappear**, never to dim a part halfway.
5. **The art keeps its layout.** Motion happens inside the drawing (translate and rotate on groups), never by resizing or moving the view.
6. **Reduced motion means still.** Frame 0 of every clock must be a good drawing.
7. **One main action per scene, plus two or three idle loops.** Side characters and mascots stay quiet.
8. **Unique SVG ids** (clip paths are global to the screen).

### Curves
- **Things that travel** (gaze, head, lid closing): ease-in-out `bezier(0.77, 0, 0.175, 1)`.
- **Things that open** (mouth, lid reopening, a prop appearing): ease-out `bezier(0.23, 1, 0.32, 1)`.
- **Endless loops** (rain, conveyor, rotation): linear.
- **Declare easings at the top of the module:** worklets capture them when they are created.
- **In SwiftUI:** `UnitCurve.bezier` with the same points, or `.timingCurve(...)`, and never a spring with bounce.

### The live face
1. Draw the eyes as plain whites, with no pupils.
2. On top, in the head's coordinates, draw:
   - the live eyes: the pupil slides, clipped to the white, and the lid and cheek are skin clipped to a shape 2 units larger than the white;
   - then whatever covers the lids (nose, fringe);
   - then the live mouth.
3. **One clock per character** (0 to `period` ms, looping). Every channel is a keyframe track `[ms, value, 'out'?]` read from it:
   - `lookX` and `lookY`: where the pupil looks;
   - `lid`, 0 open to 1 closed (`lidRight` for one eye only);
   - `cheek`, 0 to 1, for a happy squint;
   - `mouth`, the depth of the open mouth;
   - `tilt`, the head angle in degrees.
4. **A loop of 6 to 9 s:**
   - a resting gaze, plus one or two glances that glide in about 500 ms and hold for at least 1 s;
   - a blink every 3 to 4 s: close in ~90 ms, hold up to 60 ms, reopen in ~150 ms with ease-out;
   - the last key equals the first.

| Feeling | Gaze | Lid | Extra |
|---|---|---|---|
| tired | down or at a screen | rests at 0.3 to 0.4 | slow blinks |
| sad | down and away | rests at 0.1 | slow blinks, one slow look up |
| happy | at the viewer or a friend | 0 | `cheek` up once per loop |
| talking | at the listener | 0 | `mouth` in syllables |
| focused | on the task | 0.1 | rare blinks |

### Body, head, scene
- **Breathing:** the character's layer rises 1 to 2 units over 3 to 5 s, ease-in-out. Characters on the same screen breathe out of phase.
- **Head tilt:** layers for back hair, body, head and front, with the head and back hair rotating around the neck pivot. Don't tilt if a hand touches the face.
- **Cropped by an edge:** draw a few units below the crop, so the cut never shows when the character rises.
- **Props:**
  - steam rises and fades in and out (`sin(π·p)`);
  - rain and drift are linear loops, each with its own phase;
  - a clock's colon blinks and its hand steps;
  - a phone buzzes in short ±3° bursts, then pauses.
- **A scene that tells an action** plays a one-shot clock when it appears, with windows for each beat. After that, only the idle loops run.

### Performance
- One clock per character or scene; everything else is a worklet reading it.
- Freeze clocks off screen, when hidden and with reduced motion. A loop running behind opacity 0 still costs.
- A repeating animation restarts from its current value: reset to 0 before starting, and cancel on cleanup.
- Prefer one SVG per layer over many animated views.

### Workflow
1. Read Part 2 and the header comments of the illustration file.
2. List what could live, pick one main action and two or three idle loops.
3. Put every number in a token object at the top of the file.
4. Check frame 0 and that every loop closes without a jump.
5. Run the project's checks.
6. Hand off: what moves, and what hasn't been seen on a real device.

---

## Part 2. This project

> Fill these in. Delete the hints in *italics* as you go.

### Where the code is
- **Platform:** *React Native, SwiftUI, web*
- **Live face module:** *path, or "copy `templates/liveFace.tsx` (React Native) or `templates/LiveFace.swift` (SwiftUI) from the skill"*
- **Character / kit / poses:** *paths, and the character's coordinate system (where the head centre is, units)*
- **Existing animated scenes to copy from:** *paths*

### The owner's rules
*Quote them in their own words, with the date. They override Part 1.*
- …

### Rig limits
*Which poses or characters can't do what (no separate head layer, eyes baked into the drawing, a hand on the face).*
- …

### How changes are checked
*Device or simulator, who tests, the type, lint and test commands, known pre-existing errors.*
- …
