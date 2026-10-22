# rossark-motion-skill

![A creature with live eyes, snow in the window, steam, a candle and a swaying plant, all on one clock](demo/demo.gif)

<sub>Rendered from `demo/DemoScene.swift` with the SwiftUI templates in this repo: one clock, an 8-second loop. [MP4 version](demo/demo.mp4).</sub>

A Claude Code skill for bringing anything drawn to life: characters and creatures, plants, cloth, fire, smoke, water, weather, lights, machines, vehicles, icons, logos, charts and whole scenes. The motion is calm and believable; it never teleports and never bounces.

It comes with a small motion engine and templates for React Native (`react-native-svg` + `react-native-reanimated`) and SwiftUI (`TimelineView` + `Canvas`, iOS 17+ / macOS 14+), and the method works the same on the web.

## What's inside

| File | What it is |
|---|---|
| `SKILL.md` | The skill: principles, the engine, recipes for every kind of subject, characters in depth, scenes that tell an action, performance pitfalls, platforms and a workflow. |
| `MOTION.md` | A notes file to copy into your project. Part 1 is the method in short form; Part 2 is where your project's specifics go (where the code is, the owner's rules, rig limits, how changes are checked). The skill reads it first. |
| `templates/react-native/motion.ts` | The engine: loop and one-shot clocks, keyframe `track`, `seg`, `wave`, `loop`, `bell`, `seeded` and the curves. |
| `templates/react-native/liveFace.tsx` | A live face on top of the engine: `LiveEye`, `LiveMouth`, `Choreo`. You give it the eye geometry and colours. |
| `templates/swiftui/Motion.swift` | The same engine in SwiftUI: `LoopClock`, `OneShotClock`, `track`, `seg`, `wave`, `loop`, `bell`, `seeded`, and the `travel` and `open` animations. |
| `templates/swiftui/LiveFace.swift` | The same live face, drawn into a `Canvas`: `drawLiveEye`, `drawLiveMouth`, `Choreo`. |

## Install

For all your projects:

```bash
git clone https://github.com/rossark0/rossark-motion-skill ~/.claude/skills/rossark-motion-skill
```

For one project only, clone it into that project's `.claude/skills/rossark-motion-skill` instead.

Then, in Claude Code, ask it to animate something ("make this plant sway", "bring the mascot to life", "animate the onboarding illustrations"), or type `/rossark-motion-skill`.

## First time in a project

1. Copy `MOTION.md` next to your art (for example `src/art/MOTION.md`).
2. Fill in Part 2 as you go: the files, your rules (in your own words), what your art can't do, and how you test.
3. Copy the engine for your platform (`templates/react-native/` or `templates/swiftui/`) if the project doesn't have one yet.

## The idea in one paragraph

Every moving thing reads a clock. A loop clock gives idle life; a one-shot clock tells a small story when a scene appears. Parts are layers that rotate around their real pivots, trailing parts lag behind, and repeated things never move in sync. Amplitudes stay small, the curves are strong and nothing bounces. Characters get live eyes: pupils glide and lids blink over plain eye whites. Everything stops on a good frame when the user asks for reduced motion, and nothing runs off screen.

## The demo

`demo/DemoScene.swift` draws the scene above with `templates/swiftui/`:
- a creature that breathes, with ears that follow through and live eyes that look, blink and smile;
- snow in the window, with seeded variety;
- steam that rises and fades;
- a candle flickering on two waves;
- a plant swaying around its base, with leaves that lag behind.

Every period divides 8 s, so the loop is seamless. To render it again on macOS 14+:

```bash
swiftc -parse-as-library -target arm64-apple-macos14 \
  templates/swiftui/Motion.swift templates/swiftui/LiveFace.swift \
  demo/DemoScene.swift demo/render.swift -o /tmp/render-demo
/tmp/render-demo /tmp/frames
ffmpeg -framerate 30 -i /tmp/frames/%04d.png -c:v libx264 -pix_fmt yuv420p -crf 20 demo/demo.mp4
```

## License

MIT. See `LICENSE`.
