---
name: rossark-motion-skill
description: Bring anything drawn to life with calm, believable motion. It covers characters and creatures (gliding pupils, blinks, breathing, head tilts), plants, fabric, fire, smoke, water, weather, lights, machines, vehicles, icons, logos, charts and whole scenes. Use it whenever someone asks to animate an illustration, an icon, a mascot or a scene, to make something "feel alive", to add idle motion, or to turn a static drawing into a living one. Comes with a small motion engine and templates for React Native (react-native-svg + Reanimated) and SwiftUI (TimelineView + Canvas); the method also works on the web.
---

# rossark-motion-skill: bring anything to life

A method for making drawn things feel alive without making them busy. It came from a production app's onboarding and paywall art, where the brief was "it has to feel ALIVE" and "NO TELEPORTING in the animation". It works the same for a character, a houseplant, a candle, a rainy street, a logo or a chart.

## 0. Read the project's notes first

Before touching anything, look for the project's motion notes:
- a `MOTION.md` next to the art (search the repo for it);
- the project's `CLAUDE.md`;
- any saved memory about animation.

**Project rules override everything below.** They usually name the existing motion code, the art kit, what the rig can't do, and what the owner has banned.

If the project has no notes:
1. Copy `MOTION.md` from this skill's folder next to the art. Its Part 1 is this method in short form.
2. Fill in Part 2 as you learn the project.
3. Keep it up to date after each round.

## 1. Principles

These hold for anything you animate.

1. **Never teleport.** Interpolate everything. A pupil slides, a door swings, a flame leans; nothing snaps from one drawing to another.
2. **Calm by default.** Use timed motion with strong curves. No bouncy overshoot unless the project explicitly wants a bouncy brand.
3. **Small amplitudes.** Life is subtle. See the table in section 3; when unsure, halve it.
4. **Arcs and pivots.** Real things rotate around a joint. Draw every moving part as its own layer and rotate it around its pivot: a stem's base, a door's hinge, a head's neck, a lamp's hook. Sliding in a straight line looks mechanical.
5. **Overlap and follow-through.** Parts don't move together. The tip of a branch moves later and further than its base; hair and tails lag behind the head; a hanging sign keeps swinging after the wind stops. In practice, give each part the same wave with a phase delay that grows along the chain.
6. **Variety without chaos.**
   - Repeated items (raindrops, leaves, stars, bubbles) each get their own phase and a slightly different speed and size, from `seeded(i)`.
   - Never `Math.random()` per frame, and never everything in sync.
   - Things on the same screen breathe out of phase.
7. **One main action per scene, plus two or three idle loops.** The main action tells the story: the alarm rings, the plant gets watered, the chart draws on. The loops only say "this place is alive". Side characters, mascots and backgrounds stay quiet.
8. **Opacity only to appear or disappear** (steam, a drop, a sparkle, a notification). Never use it to dim something halfway.
9. **The layout never moves.** Motion happens inside the drawing (transforms on groups), never by resizing or moving the view on the page.
10. **Reduced motion means still.**
    - Loops freeze at frame 0, which must be a good drawing.
    - One-shot scenes show their final frame, which must read on its own.
11. **Nothing runs unseen.** Off screen, hidden or in the background, every clock is paused.

## 2. The engine

The templates have one small engine per platform:
- **React Native:** `templates/react-native/motion.ts`;
- **SwiftUI:** `templates/swiftui/Motion.swift`.

Copy it into the project, unless the project's notes name its own.

- **Clocks.** Everything that moves reads a clock.
  - `useLoopClock(period, live)` / `LoopClock` loops forever, for idle life.
  - `useOneShotClock(duration, play, reduced)` / `OneShotClock` plays once and holds, for a scene that tells an action.
  - Use one clock per character, object group or scene, never one per tiny part.
- **Tracks.** Keyframes `[ms, value, 'out'?]` read with `track(t, keys)`. Each segment eases in and out, or eases out when marked `'out'`. The last key equals the first, so a loop never jumps.
- **Shaping helpers:**
  - `wave(t, period, phase)` gives a smooth -1 to 1, for sway, bob and breathing;
  - `loop(t, period, phase)` gives 0 to 1 progress, for drift and falling;
  - `bell(p)` fades in and out over a loop;
  - `seg(t, a, b)` turns a window of a one-shot clock into 0 to 1, for one beat of a scene;
  - `seeded(i)` gives stable per-item variety.
- **Curves.**
  - Things that travel (gaze, sway, a door, a lid closing) use ease-in-out `bezier(0.77, 0, 0.175, 1)`.
  - Things that open or arrive (a mouth, a lid reopening, a prop appearing, a bar growing) use ease-out `bezier(0.23, 1, 0.32, 1)`.
  - Only things leaving or falling away use ease-in.
  - Endless loops (rain, conveyor, gears, rotation) are linear.

## 3. Recipes by subject

Numbers are in drawing units (the artwork's own coordinate system) and milliseconds. They are starting points, not laws.

| Subject | What lives | Recipe |
|---|---|---|
| **Character, creature** | eyes, breath, head | See section 4. Breathing 1–2 units over 3–5 s; head tilt 3–6°; a blink every 3–4 s |
| **Tail, ears, hair, antenna** | follow-through | Rotation around the root, `wave` with the phase delayed 0.1–0.2 per segment; 4–10° |
| **Plant, tree, grass** | sway | Rotation around the base, 1.5–4°, 3–6 s per cycle. Leaves add their own small sway with a phase from `seeded(i)`; tips move more than the base |
| **Flag, curtain, cloth, scarf** | wave | Split into strips or points; each one offsets by `wave(t, period, phase = k·i)`, so the wave travels along the length. Amplitude grows away from the fixed edge |
| **Fire, candle** | flicker | Lean the flame 2–4° and stretch it 3–6% in the drawing on two waves of different periods (for example 700 and 1100 ms); the inner flame moves on a third. No random jitter |
| **Smoke, steam** | rise | Wisps rise 8–14 units while `bell(p)` fades them in and out; 2–3 wisps out of phase |
| **Water** | ripples, waves | Ripples are rings that grow 0 → 1 and fade with `bell`. Surface waves are a path whose points follow `wave` with a travelling phase. Floating things bob 1–2 units and rock 2° |
| **Rain, snow, leaves falling** | fall | `loop` per item with a seeded phase, speed (±20%) and x drift. Snow sways sideways with a slow `wave`. Linear |
| **Clouds, sky** | drift | Horizontal `loop` over 20–60 s; layers further back move slower (parallax). Sun rays rotate one turn in 30–60 s |
| **Lights, lamps, stars, screens** | glow, twinkle | A glow grows 2–5% in the drawing over 2–4 s. Stars twinkle with a small scale and an opacity dip at seeded times. An LED blinks on and off. A screen flickers rarely, never constantly |
| **Machines, gears, fans, clocks** | mechanism | Gears rotate linearly at speeds set by their tooth ratio. A clock hand steps once a second with ease-out; the colon blinks every 0.5 s. A fan spins steadily |
| **Phone, alarm, notification** | buzz | Bursts of ±3° (4 cycles in about 0.45 s), then a pause; vibration ticks show only during the burst. A notification slides in with ease-out and stays |
| **Vehicles** | ride | The body bobs 0.5–1 unit; wheels rotate linearly; scenery passes in parallax `loop`s. Never shake the whole frame |
| **Icon, logo** | a moment | Play once on appear (a draw-on, a small turn, a blink), then rest. No endless loops on UI chrome. A press is a 0.97 scale on the button, not inside the drawing |
| **Chart, diagram** | draw-on | One-shot: lines draw with a stroke-dash offset, bars grow from their base with ease-out and a small stagger (40–80 ms), and numbers count up with ease-out. Final frame = the data |
| **Scene** | a story | One one-shot action when the scene appears (section 5), then the idle loops of whatever is in it |

## 4. Characters in depth

**The live face.** The templates (`templates/react-native/liveFace.tsx` and `templates/swiftui/LiveFace.swift`) use the engine:
1. Draw the eyes as plain whites, with no pupils (if the art comes from a kit, use its "no pupils" option).
2. On top, in the head's coordinates, draw the two live eyes. The pupil slides, clipped to the white; the lid and cheek are skin clipped to a shape 2 units LARGER than the white. With the exact white, the anti-aliased edge leaks around a closed eye and looks like glasses.
3. Then draw whatever covers the lids (nose, fringe, glasses), then the live mouth.

A `Choreo` holds the tracks:

| Track | What it moves |
|---|---|
| `lookX` / `lookY` | pupil offset |
| `lid` (and `lidRight`) | upper eyelid, from 0 (open) to 1 (closed) |
| `cheek` | happy squint, from 0 to 1 |
| `mouth` | depth of the open mouth |
| `tilt` | head rotation, in degrees, which you apply to the head layer |

The recipe for one loop of 6 to 9 s:
- **Gaze:** a resting gaze, plus one or two glances at something in the scene. Glide there in about 500 ms and hold for at least 1 s.
- **Blinks:** one every 3 to 4 s. Close in about 90 ms, hold up to 60 ms, reopen in about 150 ms with `'out'`. Now and then, a double blink.
- **The loop closes:** the last key equals the first.

| Feeling | Gaze | Lid | Extra |
|---|---|---|---|
| tired | down or at a screen | rests at 0.3 to 0.4 | slow blinks, one heavy blink |
| sad | down and away | rests at 0.1 | slow blinks, one slow look up |
| happy | at the viewer and at a friend | 0 | `cheek` up once per loop |
| talking | at the listener | 0 | `mouth` in syllables (8 to 14, around 180 ms each) |
| focused | fixed on the task | 0.1 | rare blinks, small saccades |
| sleepless | wide, at the ceiling, then the clock | 0 | a slow, tired close near the end |

**Body and head.**
- **Layers:** split the character into back hair, body, head (with the live face) and front (hands, held props).
- **Breathing:** the character's layer rises 1 to 2 units, with ease-in-out.
- **Head tilt:** the head and back hair rotate around the neck pivot. Don't tilt if a hand touches the face; it would come apart.
- **Cropped by an edge:** draw a few units below the crop, so the cut never shows when the character rises.
- **Creatures without a face rig:** breathing, ear and tail follow-through, and an occasional whole-head turn still make them feel alive.

## 5. Scenes that tell an action

Some scenes tell a small story: the phone buzzes, she picks it up, the alarm stops. Here's how to build one.

1. **The clock:** a one-shot clock of a few seconds that starts when the scene appears.
2. **The beats:** each beat is a window, with `seg(t, a, b)` turning it into 0 to 1. Write them as data, for example `{ ring: [0, 900], reach: [900, 1500], stop: [1500, 1700] }`.
3. **Overlap:** the next beat starts a little before the last one ends.
4. **The end:** the scene holds on its final frame and only the idle loops keep running.
5. **A carousel of scenes:** the one leaving finishes its exit before the next one starts (or crossfades over it, never through an empty or dark frame). Only the scene on screen runs.

## 6. Performance and pitfalls

- **Clocks:** one clock per character, group or scene; everything else is a function of its time.
- **Pausing:** pause clocks off screen, when hidden, in the background and with reduced motion. A loop running behind opacity 0 still costs.
- **React Native:**
  - put `live` in the dependencies of every `useAnimatedProps`;
  - `withRepeat` restarts from the current value, so reset it to 0 before starting and cancel it in the cleanup;
  - declare easings at the top of the module, because worklets capture them when they're created.
- **SwiftUI:** a `TimelineView(.animation)` redraws every frame while it runs. Pause it, and keep one per scene rather than one per part.
- **Many items** (particles, leaves, stars): draw them in one SVG or one `Canvas`, computing each from the same clock, never one animated view each.
- **Unique SVG ids:** clip paths are global to the screen.
- **Canvas engines** (Skia, a big `Canvas`): they're heavier. Don't multiply them, and don't keep one running behind another.

## 7. Platforms

| Piece | React Native | SwiftUI | Web |
|---|---|---|---|
| Engine | `templates/react-native/motion.ts` | `templates/swiftui/Motion.swift` | the same math on `requestAnimationFrame` or a Motion value |
| Loop clock | `useLoopClock` (Reanimated `withRepeat`) | `LoopClock { t in ... }` (`TimelineView(.animation)`) | a time value modulo the period |
| Drawing | `react-native-svg` groups, `useAnimatedProps` | `Canvas` with `GraphicsContext`, or views with `.offset` and `.rotationEffect` | SVG attributes, or CSS `transform` on groups |
| Reduced motion | `useReducedMotion()` | `@Environment(\.accessibilityReduceMotion)` (built into the clocks) | `prefers-reduced-motion` |
| Curves | `Easing.bezierFn` | `UnitCurve.bezier`; `Animation.travel(_:)` and `.open(_:)` | `cubic-bezier(...)` |

SwiftUI example: a plant that sways and a character with live eyes, on one clock.

```swift
LoopClock(period: 6000, paused: !visible) { t in
    ZStack {
        Plant()
            .rotationEffect(.degrees(2.5 * wave(t, period: 4200)), anchor: .bottom)
        CharacterArt()                                   // eyes drawn as plain whites
            .offset(y: -1.5 * (wave(t, period: 3600) + 1) / 2)
        Canvas { ctx, _ in
            var head = ctx
            head.translateBy(x: headX, y: headY)
            drawLiveEye(head, side: -1, eye: eyeL, ink: ink, choreo: choreo, t: t)
            drawLiveEye(head, side: 1, eye: eyeR, ink: ink, choreo: choreo, t: t)
        }
        .allowsHitTesting(false)
    }
}
```

React Native example: falling snow, with one clock and one SVG.

```tsx
const t = useLoopClock(8000, live);
function Flake({ i }: { i: number }) {
  const speed = 0.8 + seeded(i) * 0.4;
  const props = useAnimatedProps(() => {
    const p = loop(t.value * speed, 8000, seeded(i, 1));
    return { cx: 20 + seeded(i, 2) * 360 + 6 * wave(t.value, 3000, seeded(i, 3)), cy: -10 + p * 420 };
  }, [live]);
  return <ACircle animatedProps={props} r={2 + seeded(i, 4) * 2} fill="#fff" />;
}
```

## 8. Workflow

1. **Read** the project notes (section 0) and the header comments of the art file; decisions recorded there are law.
2. **List** what could live in the drawing: the main subject, its parts and pivots, repeated items, light, the background.
3. **Pick** ONE main action and two or three idle loops. Cut the rest.
4. **Split** the art into layers at their pivots, without changing how it looks at frame 0.
5. **Tune** by putting every number in a token object at the top of the file, so "slower", "smaller" or "less" is a one-line change.
6. **Check** frame 0 (reduced motion), the final frame of one-shots, and that every loop closes without a jump.
7. **Run** the project's type check, lint and tests.
8. **Hand off** in plain words: what moves, what was left still on purpose, and what hasn't been seen on a real device yet.
