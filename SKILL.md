---
name: rossark-motion-skill
description: Bring anything drawn to life with calm, believable motion. It covers characters and creatures (gliding pupils, blinks, breathing, head tilts), full-body acting (landing, waving, leaning, levitating, kicking a ball), plants, fabric, fire, smoke, water, weather, lights, machines, vehicles, icons, logos, charts and whole scenes. Use it whenever someone asks to animate an illustration, an icon, a mascot or a scene, to make something "feel alive", to add idle motion, to turn a static drawing into a living one, or to recreate the motion of a reference video. Comes with a small motion engine and templates for React Native (react-native-svg + Reanimated) and SwiftUI (TimelineView + Canvas), tools that measure a reference video frame by frame, and offline rendering to video, in a phone frame too. The method also works on the web.
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
12. **Give every move enough frames.** At 30 fps, anything shorter than about 100 ms is two or three frames and flickers. Make fast moves (blinks, contact, snaps) last long enough, and render or export at 60 fps when the platform allows.

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
  - `track` stops at every key, which is right for ONE move (a blink, a lid, a door).
  - For acting, a chain of poses (a body, arms, a head turn), use `flow(t, keys)` with keys `[ms, value]`. It passes through every key with a continuous speed and never overshoots one. With `track`, the character stops dead at each pose and reads as a robot (section 5).
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
| **Something waiting to be tapped** (a box, a gift, a card) | a jiggle | It never sits still while it waits: a quick, small squash-and-widen pulse (1.5–3%) on a 200–350 ms beat, with the bulge moving to one side and then the other (about 1% of its width). Stop it during the tap's anticipation, and bring it back once the object is at rest again |
| **Floating, levitating** | a float | It rises in from well below (a quarter to a third of its height) and slows, drifts a few percent of its height down and back, and leaves rising as it fades. Its feet hang limp and its shadow breathes with the height (section 5) |
| **Icon, logo** | a moment | Play once on appear (a draw-on, a small turn, a blink), then rest. No endless loops on UI chrome. A press is a 0.97 scale on the button, not inside the drawing |
| **Chart, diagram** | draw-on | One-shot: lines draw with a stroke-dash offset, bars grow from their base with ease-out and a small stagger (40–80 ms), and numbers count up with ease-out. Final frame = the data |
| **Scene** | a story | One one-shot action when the scene appears (section 6), then the idle loops of whatever is in it |

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
- **Blinks:** one every 3 to 4 s. Close in about 110 ms, hold 30–50 ms, and reopen in about 190 ms with `'out'`: reopening is slower than closing. Let the lower lid rise about 15% to meet the upper one, so the eye closes near its middle. Blink on head turns. Now and then, a double blink. A shorter blink (a 70 ms close) is only two frames at 30 fps and reads as a flicker.
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

## 5. Acting: a character that feels alive

Section 4 makes a face alive. This section is for a whole character, or a creature, that performs: arrives, lands, gestures, shifts its weight, reacts, plays with something. A character can hit every pose and still read as a robot. What makes it alive is how it moves between the poses, and the fact that it never fully stops.

**The rules:**

1. **Poses flow; they don't stop.** Read every acting channel with `flow`, never `track`. `track` drops the speed to zero at each key, so the character freezes at every pose. To hold a pose, repeat its value in the keys; the idle layer keeps the hold moving.
2. **Never a frozen frame (moving holds).** While the character is on screen, every channel carries a small idle layer, even in a "still" pose. Use periods that divide the loop, and give each part its own:
   - breathing: the body's height ±1–1.5% over 2–3 s;
   - limbs: a few degrees of sway on two different periods, with the left and right sides out of phase;
   - joints (elbows, knees, wrists): a few degrees;
   - head tilt: ±2° over 4–5 s;
   - weight: a little sideways drift over 4–5 s;
   - head turn: a hint, about 5% of a full turn.
3. **Layer every channel.** Final value = key pose (`flow`) + idle (`wave`s) + follow-through (a delayed copy of the parent) + accents (a `wave` switched on by a `seg` window: a hand waving, wings flapping, a tail wagging).
4. **Follow-through by delay, not by springs.** A child part reads its parent a moment earlier, 60–150 ms, at 0.3–0.6 of its strength:
   - **Counter-motion:** `head(t) = own(t) − 0.45 × lean(t − 110 ms)`. The head rights itself a beat after the body leans.
   - **Trailing:** `joint(t) += 0.45 × (parent(t − 90 ms) − parent(t))`. When the parent swings, the child lags and then catches up, with no overshoot. Forearms, hands, tails, ears and hair all work this way.
5. **Bend the limbs.** A limb is two segments that share one round joint, driven by two angles: the root's angle `a` and the joint's bend `e`. For an arm, `a` is the shoulder's outward angle (0 hangs down) and the forearm points at `a + e`. Straight limbs only swing like pendulums; the joint is where the acting happens. Keep both segments about the same length. Starting angles for common arm gestures:

   | Gesture | a | e | Note |
   |---|---|---|---|
   | wave | 60° | +110° | forearm up beside the head, waving ±10–15° every 0.6–0.9 s |
   | hand on the hip | 30° | −95° | the hand goes behind the body and the joint breaks the silhouette |
   | fist pump, cheer | 55° | +60° | |
   | arms flung for balance | 80–120° | about 0 | |
   | arms up in a V | 150° | 0 | a raised straight limb can stretch about 30% (cartoon reach) |

6. **Turn without new drawings (2.5D).** A `yaw` from −1 to 1 slides each part by its depth:
   - what sticks out the most (a nose, a beak, a snout) slides the most, about 13% of the head's width;
   - the eyes and mouth slide about 10%;
   - the outline doesn't move;
   - parts at the back (ears, back hair) slide the other way, about 9%, so the far one tucks behind the head;
   - prints and stripes on the chest slide 8–12% of the torso's width, clipped to it.

   The pupils lead the turn. Blink on a head turn, as people do.
7. **Shift the weight.** The hips slide sideways and carry everything above them. The legs rotate from the hips so the feet stay planted: the angle is about the shift divided by the leg's length, in radians. The leg that carries no weight lifts out a little.
8. **Land like a body.**
   - **Air time:** hover a moment, then fall with gravity, `lift = top × (1 − k²)`, stretching 5–10%. Right before contact, the arms go up.
   - **Contact:** squash 15–20%, snap the arms out, recover with one small overshoot, then settle.
   - **A hop:** crouch 5–10%, stretch 5–10%, a parabola up and down, then the same squash.
9. **Keep the volume.** When the height scales by `sy`, the width scales by `1 / sy^0.6`.
10. **Break the symmetry.** Left and right never mirror each other. Give them different angles, phases and bends. A symmetric pose reads as a mannequin.
11. **In the air, the feet hang.** Anything held up by nothing hangs. That covers floating, levitating, hovering before a fall and being carried:
    - the legs fall limp and close together;
    - the toes point down, the foot turned 60–80° at the ankle;
    - one knee folds a little, so that leg reads shorter, and the two legs trade slowly;
    - the arms hang a little out and sway.

    Float rather than stand: rise in from well below and slow, drift a few percent of the body's height down and back, and leave rising as you fade. Flatten the feet just before they touch down.
12. **The shadow moves with the height.** The shadow stays on the floor, with a visible gap under anything in the air. Its size scales with the distance (for example `1 − height / 220` in the drawing's units), so it breathes as a body floats and grows as it falls. A shadow that never changes pins the body to the ground. Its shape follows the camera (rule 14): a thin pill for a flat view, a wide oval for a view from above.
13. **Props and contact.**
    - **Entry:** a prop enters already moving, from beyond the visible edge. In a device frame, that means beyond the screen's edge.
    - **Rolling:** a rolling prop turns by the distance over its radius (`angle = Δx / r`) and slows to a stop with ease-out.
    - **Eyes:** the eyes and head follow the prop, toward it as it comes and after it as it goes. Blink on the turn toward it.
    - **A strike (a kick, a hit, a swing):**
      - the weight goes onto the support side and the free limbs open for balance;
      - the striking limb winds up and stops at the top;
      - it swings through the prop at its fastest: contact at the middle of the swing, never at the end;
      - it follows through and comes back, with the opposite arm swinging against it.
    - **Launch:** a launched prop flies as a throw, `x = x0 + vx·s` and `y = y0 − vy·s + g·s²/2` (s in seconds), spinning. It squashes for 60–100 ms at contact (about 15% along the hit, 10% wider across it).
    - **Afterwards:** the character watches it go, then reacts.
14. **The camera angle is a build, not a tweak.** A flat side view keeps the drawing's own proportions and a thin pill shadow. A camera a little above the character (friendly and toy-like, common in games, avatars and reward screens) changes the whole build. Nudging a side-view body by a few percent doesn't get there: it just reads as stretched. In head widths:
    - the head is 40–50% of the total height;
    - the torso is short, about 0.6 head widths tall, and narrower than the head, tapering a little toward the waist;
    - the head sits right on the collar, with no neck showing;
    - the legs are short, a quarter of the height or less, and close together;
    - the arms hang to about the hips;
    - the feet are round, dark shapes seen from above, with their tops tucked under the sock or the trouser;
    - the floor shows, so the shadow is a wide oval (1.3–1.5 head widths, about a third as tall as wide). The feet stand in its lower half.

    Keep these numbers in one `build` object, so the whole body changes in one place. Compute where the feet touch the floor from them.
15. **Frame it for where it will be seen.** On a phone screen, make the character as big as the screen allows, with room for its widest pose and its highest jump, and set its feet in the lower part of the screen. A small figure lost in the middle of the screen reads as a placeholder.

**A shape for the code** (it works the same in React Native and SwiftUI):

```swift
struct Pose { var lift, sy, lean, shift, yaw, head: Double; var armL, armR: (a: Double, e: Double); var legL, legR: Double }

func pose(_ t: Double) -> Pose {
    let on = onScreen(t) ? 1.0 : 0.0                                  // idle only while visible
    let lean = flow(t, Act.lean) + 1.5 * wave(t, period: 4500) * on
    let head = flow(t, Act.head) - 0.45 * flow(t - 110, Act.lean)   // follow-through
    func arm(_ ka: FlowKeys, _ ke: FlowKeys, _ ph: Double) -> (a: Double, e: Double) {
        let a = flow(t, ka) + (4 * wave(t, period: 3000, phase: ph) + 2 * wave(t, period: 1800, phase: ph + 0.3)) * on
        let e = flow(t, ke) + 5 * wave(t, period: 2250, phase: ph + 0.6) * on + 0.45 * (flow(t - 90, ka) - flow(t, ka))
        return (a, e)
    }
    // ...
}
```

Keep the key poses together as data (an `Act` enum or object), one array per channel, so "hold the wave longer" means editing one row. `demo/RevealScene.swift` is a full worked example.

**Before calling it alive, check:**
- [ ] Nothing is frozen while the character is on screen, even in a held pose.
- [ ] There is no moment where every part stops at once.
- [ ] The head and the outer parts of the limbs arrive after the body.
- [ ] Left and right don't mirror each other.
- [ ] The weight moves from one side to the other at least once.
- [ ] The head turns at least once, and the character blinks on the turn.
- [ ] Landings squash and keep the volume.
- [ ] Anything in the air has hanging feet and a shadow that changes with its height.
- [ ] Every prop enters from off screen already moving, and the eyes follow it.

## 6. Scenes that tell an action

Some scenes tell a small story: the phone buzzes, she picks it up, the alarm stops. Here's how to build one.

1. **The clock:** a one-shot clock of a few seconds that starts when the scene appears.
2. **The beats:** each beat is a window, with `seg(t, a, b)` turning it into 0 to 1. Write them as data, for example `{ ring: [0, 900], reach: [900, 1500], stop: [1500, 1700] }`.
3. **Overlap:** the next beat starts a little before the last one ends.
4. **The end:** the scene holds on its final frame and only the idle loops keep running.
5. **A carousel of scenes:** the one leaving finishes its exit before the next one starts (or crossfades over it, never through an empty or dark frame). Only the scene on screen runs.

## 7. Motion in an interface

Illustrations live inside an interface, and the interface has its own rules. These follow Emil Kowalski's design-engineering rules and Benji Taylor's "Family values" (simplicity, fluidity, delight). Where this skill already agrees with them (never teleport, strong curves, transform-only, reduced motion, stagger), it says so in the sections above. This section adds the rest.

1. **Frequency decides how much.** The more often people see something, the less it should move:

   | How often | What it gets |
   |---|---|
   | Hundreds of times a day (shortcuts, typing, a list scroll) | no animation |
   | Tens of times a day (hovers, tab switches, toggles) | a minimal, fast change |
   | Now and then (sheets, toasts, a screen change) | a standard transition |
   | Rarely (onboarding, rewards, celebrations, empty states) | full delight: characters, scenes, a story |

   Delight is selective emphasis: spend it where people pass rarely, and keep frequent paths quiet.
2. **Every motion has a purpose.** It should do at least one of these:
   - show where something came from and where it goes;
   - show that a state changed;
   - confirm a touch;
   - explain how something works;
   - celebrate a rare moment.

   "It looks cool" isn't a purpose on a screen people see often.
3. **Continuity: fly, don't teleport.**
   - An element that exists on both screens travels or morphs between them. It is never removed and redrawn.
   - A transition moves in the direction of the action that caused it: the tab you tapped, the side you swiped.
   - A label that changes meaning morphs into the new one (Continue becomes Confirm). It doesn't swap.
4. **Durations.** These are for interface moves. Idle loops in an illustration run for seconds and are exempt.

   | Move | Duration |
   |---|---|
   | press feedback | 100–160 ms |
   | small popovers and tooltips | 125–200 ms |
   | menus | 150–250 ms |
   | sheets and modals | 200–500 ms |

   Keep interface moves under 300 ms when you can. Fast feels responsive.
5. **Curves.**
   - Entering or responding: a strong ease-out.
   - Moving on screen: a strong ease-in-out.
   - Constant motion: linear.
   - Never ease-in on something the user is waiting for. Ease-in is only for things falling away, like gravity in a drawing.
6. **Asymmetric timing.** Be slow where the user is deciding (a hold to confirm) and fast where the system answers (the release, a dismissal). An exit is usually quicker than the entrance. A blink closes faster than it opens.
7. **Nothing appears from nothing.** A shape enters from a scale of 0.9–0.97 with opacity, never from scale 0. Tiny sparkles and dots are the exception.
8. **Press feedback.** A pressable thing scales to about 0.97 on press and comes back. The drawing inside stays as it is.
9. **Interruptible.** If the user can act again mid-animation (tap again, swipe back), continue from the current value toward the new target. Never restart from zero, and never jump.
10. **Glitches cost trust.** A hairline seam, a dropped frame, a jump at a loop's seam or a flickering blink tells people the product isn't careful. Check at full resolution and at full frame rate before calling anything done.

## 8. Performance and pitfalls

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
- **Drawing traps that show up in motion:**
  - **A seam where two edges meet.** Whenever two anti-aliased edges land on the same line, a hairline shows there. That covers a cutout (an even-odd hole) ending on its shape's outline, and a clip edge on top of another edge. The hairline can cut straight across a face or an object. Draw the shape as ONE outline instead (an upside-down U around a face, not a cap with a hole), and zoom in on the result to check.
  - **Overlapping parts in one path.** A union built as several subpaths in one path can cancel where the directions differ (nonzero winding), punching holes. Fill each part on its own.
  - **A glasses ring around closed eyes.** Clip the lid to a shape 2 units larger than the eye white (section 4).

## 9. Platforms

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

## 10. Working from a reference video

When someone hands you a video and says "make it like this", watch it frame by frame. Don't work from one look at it. The tools are in `tools/` (ffmpeg plus Python's standard library; run Python with `-I`). Keep the downloaded video in a folder of its own.

1. **Read its frame rate and length:**
   ```bash
   ffprobe -v error -show_entries stream=width,height,r_frame_rate,duration -of compact ref.mp4
   ```
2. **Make contact sheets at the full frame rate**, cropped to the subject, a second or two per sheet, and read them:
   ```bash
   tools/sheet.sh ref.mp4 START DUR W:H:X:Y              # every frame, 10 per row
   tools/sheet.sh ref.mp4 0 LENGTH iw:ih:0:0 8 2 poses.png  # 2 a second: just the poses
   ```
   A 2-frames-per-second sheet shows the poses. Only the full frame rate shows the timing, the follow-through and the moving holds, and those are what make it feel alive.
3. **Measure the motion with numbers; don't trust your eyes.** Motion of 1–5% (a jiggle, a breath, a float, a sway) doesn't show on a contact sheet, and it is often exactly what makes the reference feel alive. Something that looks still may not be. Track the subject's edges frame by frame, at the source's frame rate, using the subject's own colors:
   ```bash
   python3 -I tools/track_edges.py ref.mp4 --start S --dur D --fps SOURCE_FPS \
       --crop X:Y:W:H --colors RRGGBB,RRGGBB --cols C1,C2,C3 --row R
   ```
   The top edge at a few columns shows bobbing, squash and tilt. The left and right edges on one row show widening, swaying and leaning. Read off the amplitude, as a percentage of the subject's size, and the period, then use those numbers.
4. **Write the beats as data:** each beat with its start and end in milliseconds, such as `{ enter: [300, 900], hold: [900, 1650], leave: [1650, 2350] }`.
5. **Go part by part.** For every part (the feet, the hands, the head, the eyes, the shadow, the props, the background), ask what the reference does with it, and make yours do it too. A part that does nothing while the rest moves reads as dead: feet standing flat under a floating body, a shadow that never changes, eyes that ignore what is happening.
6. **Measure the proportions as ratios of one unit.** Even when you draw your own character, measure the reference's build in head widths: the head's share of the total height, the torso's height and width, the leg length, the size of the feet and the shadow. Then compare them with yours. "It looks stretched" or "it looks off" almost always means one of these ratios is far from the reference's, not a few percent.
7. **Measure the drawing when it must match exactly.** Crop the subject, scale it 2x and lay a grid over it (`drawgrid=w=100:h=100`). Read every shape's corners and curves off the grid, in one unit system (the video's pixels work well).
8. **Sample the colors from pixels; don't guess:**
   ```bash
   python3 -I tools/sample_colors.py ref.mp4 --at SECONDS X1,Y1 X2,Y2
   ```
   For a lit or glowing state, sample that moment too, then blend between the two colors (never swap them).
9. **Compare side by side at the same moments.** Render your version at the same times, stack it under the reference (`vstack`) and look for differences in timing, amplitude and pose. Run `track_edges.py` on your own render too, and compare the numbers.
10. **Make it yours if it will be published.** Measuring and copying a drawing exactly is fine for a private test. A published demo, repo or product needs original characters and art: brand mascots and illustrations are trademarks and copyrighted.

**Checking without a device.** On macOS, render frames offline (SwiftUI `ImageRenderer` into PNGs, then `ffmpeg` into MP4 and GIF; see `demo/render.swift`). Read contact sheets of your own frames before showing anything. When you crop them, use the PNG's pixel size: with `renderer.scale = 2`, a 720-point scene is 1440 pixels wide.

**Showing it in a device frame.** Give the scene a `height` and place its stage inside it: backgrounds and skies fill the whole height, and the action stays where you put it. Scale it to the screen inside the frame (`demo/PhoneMockup.swift`), and frame for the screen, not for the source: make the subject as big as the screen allows, with room for its widest pose and its highest jump, and set it where the eye expects it (feet in the lower part of the screen, not floating in the middle). Use a dark status bar on light screens and a white one on colored screens. Anything that enters "from off screen" must start beyond the device's screen edge, not just the scene's.

**Exporting for social posts.** Render the frames at 2x and at 60 fps (`render-demo ... fps=60`), then scale them down with a good filter. Check each platform's current limits first. For X: square takes the most room in the feed, and uploads are capped at 1920×1200 (or 1200×1900).
```bash
ffmpeg -framerate 60 -i frames/%04d.png -vf "scale=1080:1080:flags=lanczos,format=yuv420p" \
  -c:v libx264 -profile:v high -level 4.2 -preset slow -crf 18 -r 60 -movflags +faststart post.mp4
```

## 11. Workflow

1. **Read** the project notes (section 0) and the header comments of the art file; decisions recorded there are law. With a reference video, study it first (section 10).
2. **List** what could live in the drawing: the main subject, its parts and pivots, repeated items, light, the background.
3. **Pick** ONE main action and two or three idle loops. Cut the rest.
4. **Split** the art into layers at their pivots, without changing how it looks at frame 0.
5. **Tune** by putting every number in a token object at the top of the file, so "slower", "smaller" or "less" is a one-line change.
6. **Check** frame 0 (reduced motion), the final frame of one-shots, and that every loop closes without a jump. For a character, run the "alive" checklist in section 5, and look at a contact sheet of every 4th frame of your own render.
7. **Run** the project's type check, lint and tests.
8. **Hand off** in plain words: what moves, what was left still on purpose, and what hasn't been seen on a real device yet.
