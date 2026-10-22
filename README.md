# rossark-motion-skill

![A creature with live eyes, snow in the window, steam, a candle and a swaying plant, all on one clock](demo/demo.gif)

<sub>Rendered from `demo/DemoScene.swift` with the SwiftUI templates in this repo: one clock, an 8-second loop. [MP4 version](demo/demo.mp4).</sub>

A Claude Code skill for bringing anything drawn to life: characters and creatures, plants, cloth, fire, smoke, water, weather, lights, machines, vehicles, icons, logos, charts and whole scenes. The motion is calm and believable, and it never teleports. Characters can act: land, gesture, shift their weight, turn their head, float and play with props, without ever freezing between poses.

It comes with:
- a small motion engine and templates for React Native (`react-native-svg` + `react-native-reanimated`) and SwiftUI (`TimelineView` + `Canvas`, iOS 17+ / macOS 14+);
- tools that measure a reference video frame by frame;
- an offline renderer that turns scenes into MP4 and GIF, in a phone frame too.

The method works the same on the web.

## What's inside

| File | What it is |
|---|---|
| `SKILL.md` | The skill: principles, the engine, recipes for every kind of subject, faces, full-body acting, scenes that tell an action, pitfalls, platforms, working from a reference video, and a workflow. |
| `MOTION.md` | A notes file to copy into your project. Part 1 is the method in short form; Part 2 is where your project's specifics go (where the code is, the owner's rules, rig limits, how changes are checked). The skill reads it first. |
| `templates/react-native/motion.ts` | The engine: loop and one-shot clocks, keyframe `track`, `flow` (smooth acting through key poses), `seg`, `wave`, `loop`, `bell`, `seeded` and the curves. |
| `templates/react-native/liveFace.tsx` | A live face on top of the engine: `LiveEye`, `LiveMouth`, `Choreo`. You give it the eye geometry and colours. |
| `templates/swiftui/Motion.swift` | The same engine in SwiftUI: `LoopClock`, `OneShotClock`, `track`, `flow`, `seg`, `wave`, `loop`, `bell`, `seeded`, and the `travel` and `open` animations. |
| `templates/swiftui/LiveFace.swift` | The same live face, drawn into a `Canvas`: `drawLiveEye`, `drawLiveMouth`, `Choreo`. |
| `tools/sheet.sh` | Contact sheets of a video at its full frame rate, to study timing (or to check your own render). |
| `tools/track_edges.py` | Measures a subject's edges frame by frame, so you can see motion too small for the eye (a 2% jiggle, a float, a sway). |
| `tools/sample_colors.py` | Reads exact colours from a video frame. |
| `demo/` | Three scenes, a phone frame (`PhoneMockup.swift`) and the renderer (`render.swift`). |

## Install

For all your projects:

```bash
git clone https://github.com/rossark0/rossark-motion-skill ~/.claude/skills/rossark-motion-skill
```

For one project only, clone it into that project's `.claude/skills/rossark-motion-skill` instead.

Then, in Claude Code, ask it to animate something ("make this plant sway", "bring the mascot to life", "make it move like this video"), or type `/rossark-motion-skill`.

## First time in a project

1. Copy `MOTION.md` next to your art (for example `src/art/MOTION.md`).
2. Fill in Part 2 as you go: the files, your rules (in your own words), what your art can't do, and how you test.
3. Copy the engine for your platform (`templates/react-native/` or `templates/swiftui/`) if the project doesn't have one yet.

## The idea in one paragraph

Every moving thing reads a clock. A loop clock gives idle life; a one-shot clock tells a small story when a scene appears. Parts are layers that rotate around their real pivots, trailing parts lag behind, and repeated things never move in sync. Characters get live eyes, and when they act, every channel is a smooth path through key poses, plus idle life that never stops, plus follow-through. Amplitudes stay small and the curves are strong. Everything stops on a good frame when the user asks for reduced motion, and nothing runs off screen.

## The demos

All three are drawn with `templates/swiftui/`, each on one clock, in seamless loops.

**Room** (`demo/DemoScene.swift`, at the top of this page):
- a creature that breathes, with ears that follow through and live eyes that look, blink and smile;
- snow in the window, with seeded variety;
- steam that rises and fades;
- a candle flickering on two waves;
- a plant swaying around its base, with leaves that lag behind.

**Orbit** (`demo/OrbitScene.swift`):

![A round bird with closed eyes floats while a tilted ring of cards orbits around it, with sparkles twinkling](demo/orbit.gif)

- a ring of cards orbiting in depth: the fronts in front of the bird, the backs behind it, edge-on at the sides;
- the bird floats and tilts, its wings flutter, and its feet and tufts follow through;
- sparkles that appear and disappear once per loop, at seeded times.

[MP4 version](demo/orbit.mp4).

**Reveal** (`demo/RevealScene.swift`), full-body acting in a phone frame:

![A blue silhouette floats in with dangling feet, then a kid in a striped kit drops in, lands, waves, leans, kicks a ball that rolls in from the right, grins and hops](demo/reveal.gif)

- a mystery silhouette floats in, its feet hanging limp, its shadow breathing with the height;
- the kid hovers, falls with gravity, squashes on landing and keeps the volume;
- poses flow into each other with `flow`; idle life never stops; the head and forearms follow through;
- elbows bend, the head turns by sliding the face (2.5D), and the weight shifts from leg to leg;
- a ball rolls in from off screen, the eyes follow it, the kick hits at the middle of the swing, and the ball flies off spinning;
- a toy-like build seen from a little above: a big head, a short torso, round shoes and a wide oval shadow.

[MP4 version](demo/reveal.mp4), square and ready to post.

To render them again on macOS 14+:

```bash
swiftc -parse-as-library -target arm64-apple-macos14 \
  templates/swiftui/Motion.swift templates/swiftui/LiveFace.swift demo/*.swift -o /tmp/render-demo
/tmp/render-demo room /tmp/frames              # or: orbit, reveal
/tmp/render-demo reveal /tmp/frames phone fps=60   # inside a phone frame, on a square page, at 60 fps
ffmpeg -framerate 60 -i /tmp/frames/%04d.png -c:v libx264 -pix_fmt yuv420p -crf 20 demo/reveal.mp4
```

## License

MIT. See `LICENSE`.
