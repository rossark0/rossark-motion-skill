---
name: rossark-motion-skill
description: Bring character illustrations to life (mascots, people, scenes drawn in SVG) with calm, believable idle motion. Eyes whose pupils glide and lids blink, breathing, head tilts, and small scene props like steam, rain, a ticking clock or a buzzing phone. Use it whenever someone asks to animate an illustration, make a character "feel alive", add blinking or breathing, or build a scene's motion. Written for React Native (react-native-svg + Reanimated); the method also works on the web.
---

# rossark-motion-skill: living illustrations

A method for making drawn characters feel alive without making them busy. It came from a production app's onboarding and paywall art, where the brief was "the character has to feel ALIVE" and "NO TELEPORTING in the animation".

## 0. Read the project's notes first

Before touching anything, look for the project's own motion notes: a `MOTION.md` next to the illustrations (search the repo for `MOTION.md`), the project's `CLAUDE.md`, and any saved memory about animation. **Project rules override the defaults below.** They usually name the existing live-face module, the character kit, poses that can't be animated a certain way, and things the owner has banned.

If the project has none, copy `MOTION.md` from this skill's folder next to the illustrations. Its Part 1 is this method in short form; fill in Part 2 (where the code is, the owner's rules, rig limits, how changes are checked) as you learn the project, and keep it up to date after each round.

## 1. Rules

- **Never swap drawings mid-motion.** Pupils slide, lids lower and rise, mouths open and close, heads rotate. Snapping from one expression to another is "teleporting", and it is what makes animation look cheap.
- **No bounce.** Use timed motion with strong curves (below), not springy overshoot. Characters breathe; they don't wobble.
- **Small amplitudes.**
  - breathing: 1 to 2 drawing units;
  - head tilt: 3 to 6 degrees;
  - gaze: a few units inside the eye.
  This is life, not a dance.
- **Opacity only for appearing and disappearing** (steam, raindrops, a notification). Never use it to dim a part halfway.
- **Never animate the view's size or position on the page.** The art keeps its layout; motion happens inside the drawing (translate and rotate on groups). The size goes in as a transform matrix, not as a view scale.
- **Reduced motion means still.** Every clock frozen at 0, and frame 0 must be a good-looking drawing on its own.
- **One main action per scene, plus two or three idle loops.** Mascots and side characters stay quiet unless the scene is about them.
- **Unique ids.** SVG `clipPath` ids are global to the screen.

## 2. Curves

```ts
// At the TOP of the module: a worklet captures what it references when it's created,
// and easings declared further down are undefined inside it.
const EASE_IN_OUT = Easing.bezierFn(0.77, 0, 0.175, 1); // things that travel: gaze, head, lid closing
const EASE_OUT = Easing.bezierFn(0.23, 1, 0.32, 1);     // things that open: mouth, lid reopening, a prop appearing
```

Continuous loops (rain, conveyor, rotating sun) are linear.

## 3. The live face

A ready-made module is in `templates/liveFace.tsx` (in this skill's folder). Copy it into the project, or use the project's own version if the notes name one. It exports `LiveEye`, `LiveMouth`, `track`, `Choreo`, `Keys` and `useChoreoClock`.

1. **The static eyes.** Draw the character with plain eye whites and no pupils (if the character comes from a kit, use its "no pupils" option).
2. **The live layer.** Inside the same transform as the head, draw two `LiveEye` on top, then anything that must cover the lids (nose, hair, glasses), then `LiveMouth` if the mouth talks or laughs.
3. **The clock.** Run one clock per character, and derive every channel from it:

```tsx
const clock = useChoreoClock(CHOREO.period, live); // live = on screen && !reducedMotion
<G transform={`translate(${headX} ${headY}) scale(${s})`}>
  <LiveEye side={-1} eye={EYE_L} ink={INK} choreo={CHOREO} clock={clock} id="introEyeL" />
  <LiveEye side={1} eye={EYE_R} ink={INK} choreo={CHOREO} clock={clock} id="introEyeR" />
  {/* nose / hair fringe here, above the lids */}
</G>
```

### The choreography

A `Choreo` holds keyframe tracks `[ms, value, 'out'?]`. Each segment eases in and out, or eases out when marked `'out'`.

| Track | What it moves |
|---|---|
| `lookX` / `lookY` | pupil offset |
| `lid` (and `lidRight`) | upper eyelid, from 0 (open) to 1 (closed) |
| `cheek` | happy squint, from 0 to 1 |
| `mouth` | depth of the open mouth |
| `tilt` | head rotation, in degrees, which you apply to the head layer |

The recipe for one loop of 6 to 9 seconds:
- **Gaze:** a resting gaze, plus one or two glances at something in the scene. Glide there in about 500 ms and hold for at least 1 s.
- **Blinks:** one every 3 to 4 s. Close in about 90 ms with ease-in-out, hold 0 to 60 ms, and reopen in about 150 ms with `'out'`. Now and then, a double blink.
- **The loop closes:** the last key equals the first, so the loop never jumps.

| Feeling | Gaze | Lid | Extra |
|---|---|---|---|
| tired | down or at a screen | rests at 0.3 to 0.4 | slow blinks, one heavy blink |
| sad | down and away | rests at 0.1 | slow blinks, one slow look up |
| happy | at the viewer and at a friend | 0 | `cheek` up once per loop |
| talking | at the listener | 0 | `mouth` in syllables (8 to 14, around 180 ms each) |
| focused | fixed on the task | 0.1 | rare blinks, small saccades |
| sleepless | wide, at the ceiling, then the clock | 0 | a slow, tired close near the end |

## 4. Body, head and scene

- **Breathing:** the whole body rises 1 to 2 units and comes back over 3 to 5 s, with ease-in-out, on a loop (`translateY` on the character's layer). Characters on the same screen should be out of phase.
- **Head tilt:** split the character into layers: back hair, body, head (with the live face) and front (hands, held props). Rotate the head and back-hair layers around the neck pivot with the `tilt` track. If a hand touches the face, don't tilt; it would come apart.
- **Cropped characters** (cut by a card edge): when they bob, draw a few units below the crop line, or the cut edge shows at the top of the motion. Things in front (a desk, a table) go on a layer above.
- **Scene props:**
  - **steam:** a wisp rises about 10 units while its opacity follows `sin(π·p)`, so it fades in and out;
  - **rain and drift:** linear loops, each item with its own phase;
  - **ticking clock:** the colon blinks every 0.5 s and a hand steps once a second, with ease-out;
  - **buzzing phone:** short bursts of ±3 degrees (4 cycles in about 0.45 s), then a pause, with vibration ticks that show only during the burst.
- **A scene that tells an action** (press, buzz, a message arrives): run a one-shot clock that plays once when the scene appears, with windows `seg(t, a, b)` for each beat. After that, only the idle loops run.

## 5. Performance and pitfalls

- One clock per character or scene; everything else is a worklet reading it.
- Put `live` in the dependencies of every `useAnimatedProps`, and freeze clocks for anything off screen or hidden. A layer at opacity 0 with a running loop still costs.
- `withRepeat` restarts from the current value: set it to 0 before starting again, and cancel in the effect cleanup.
- Clip the skin (lid, cheek) to a shape 2 units larger than the eye white. Clipped to the exact white, the anti-aliased edge leaks around a closed eye and looks like glasses.
- Prefer one SVG per layer over many animated views. Canvas engines (Skia) are heavier: don't multiply them.

## 6. Workflow

1. Read the project notes (section 0) and the header comments of the illustration file; decisions recorded there are law.
2. List what could live: the face, the body, the head, the props and the mascot.
3. Pick ONE main action and two or three idle loops. Less is more.
4. Put every number in a token object at the top of the file, so "slower" or "smaller" is a one-line change.
5. Check frame 0 (reduced motion) and that every loop closes without a jump.
6. Run the project's type check, lint and tests.
7. Hand off in plain words: what moves on each screen, and what has not been seen on a real device yet.

## On the web

The same model works: one clock (`requestAnimationFrame`, or a Motion value) feeding keyframe tracks into SVG attributes. Animate only `transform` and `opacity`, and respect `prefers-reduced-motion`.
