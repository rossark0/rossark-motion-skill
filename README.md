# rossark-motion-skill

A Claude Code skill for bringing character illustrations to life: eyes whose pupils glide and lids blink, breathing, head tilts, and small scene props (steam, rain, a ticking clock, a buzzing phone). Calm, believable motion that never teleports and never bounces.

It's written for React Native (`react-native-svg` + `react-native-reanimated`), and the method works the same on the web.

## What's inside

| File | What it is |
|---|---|
| `SKILL.md` | The skill: rules, curves, the live face, choreography recipes, body/head/scene motion, performance pitfalls and a workflow. |
| `MOTION.md` | A notes file to copy into your project. Part 1 is the method in short form; Part 2 is where your project's specifics go (where the code is, the owner's rules, rig limits, how changes are checked). The skill reads it first. |
| `templates/liveFace.tsx` | A ready-to-copy live face: `LiveEye`, `LiveMouth`, keyframe `track`, `Choreo` and `useChoreoClock`. You give it the eye geometry and colours; nothing else is assumed. |

## Install

For all your projects:

```bash
git clone https://github.com/rossark0/rossark-motion-skill ~/.claude/skills/rossark-motion-skill
```

For one project only, clone it into that project's `.claude/skills/rossark-motion-skill` instead.

Then, in Claude Code, ask to animate an illustration, or type `/rossark-motion-skill`.

## First time in a project

1. Copy `MOTION.md` next to your illustrations (for example `src/art/MOTION.md`).
2. Fill in Part 2 as you go: the files, your rules (in your own words), what your rig can't do, and how you test.
3. If you don't have a live-face module yet, copy `templates/liveFace.tsx` into the project and set the eye geometry to match your character.

## The idea in one paragraph

Draw the character once, with plain eye whites. On top, in the head's coordinates, live eyes slide their pupils and lower their lids, and the cheeks push up for a happy squint. One looping clock per character feeds keyframe tracks (gaze, lid, cheek, mouth, tilt), eased with strong curves. The body breathes a unit or two, the head tilts a few degrees around the neck, and props loop quietly. Everything stops on a good-looking frame 0 when the user asks for reduced motion, and nothing runs off screen.

## License

MIT. See `LICENSE`.
