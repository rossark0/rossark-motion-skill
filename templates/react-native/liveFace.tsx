// liveFace.tsx: a living face for SVG characters (react-native-svg + react-native-reanimated 3/4).
//
// Nothing ever swaps drawings: the pupil SLIDES, the eyelid LOWERS and RISES, the
// cheek pushes up for a happy squint, the mouth OPENS and CLOSES. One clock per
// character drives every channel through keyframe tracks.
//
// Needs `motion.ts` (the engine) next to it.
//
// Usage (see SKILL.md, "Characters"):
//   1. Draw your character's eyes as plain whites, with no pupils.
//   2. Inside the same <G> transform as the head, draw two <LiveEye> on top,
//      then anything that must cover the eyelids (nose, hair, glasses).
//   3. One `useChoreoClock(choreo.period, live)` per character.
import React from 'react';
import Animated, { useAnimatedProps, type SharedValue } from 'react-native-reanimated';
import { Circle, ClipPath, Defs, G, Line, Path, Rect } from 'react-native-svg';
import { track, useLoopClock, type Keys } from './motion';

export { track, type Key, type Keys } from './motion';

const ARect = Animated.createAnimatedComponent(Rect);
const APath = Animated.createAnimatedComponent(Path);
const ACircle = Animated.createAnimatedComponent(Circle);
const ALine = Animated.createAnimatedComponent(Line);

/**
 * One character's choreography. `lookX`/`lookY`: pupil offset in eye units.
 * `lid`: upper eyelid, 0 open to 1 closed (`lidRight` for a one-eyed blink or wink).
 * `cheek`: 0 to 1, the cheek rising into a happy squint. `mouth`: open-mouth depth.
 * `tilt`: head rotation in degrees (applied by you, on the head layer).
 */
export type Choreo = {
  period: number;
  lookX: Keys;
  lookY: Keys;
  lid: Keys;
  lidRight?: Keys;
  cheek?: Keys;
  mouth?: Keys;
  tilt?: Keys;
};

/** The character's clock: a loop of `period` ms, frozen at 0 when `live` is false. */
export const useChoreoClock = useLoopClock;

/** A rounded pill (stadium) path centred on (cx, cy). */
export function pill(cx: number, cy: number, w: number, h: number): string {
  const r = Math.min(w, h) / 2;
  const x = cx - w / 2;
  const y = cy - h / 2;
  return `M${x + r} ${y}H${x + w - r}A${r} ${r} 0 0 1 ${x + w} ${y + r}V${y + h - r}A${r} ${r} 0 0 1 ${x + w - r} ${y + h}H${x + r}A${r} ${r} 0 0 1 ${x} ${y + h - r}V${y + r}A${r} ${r} 0 0 1 ${x + r} ${y}Z`;
}

/** Where one eye sits, in the head's own coordinates. */
export type EyeGeometry = {
  /** Centre of the eye white. */
  cx: number;
  cy: number;
  /** Size of the eye white (a pill). */
  w: number;
  h: number;
  /** Pupil size, and its top edge measured from the top of the eye white. */
  pupilW: number;
  pupilH: number;
  pupilTop: number;
  /** Radius of the highlight dot. 0 for none. */
  shine: number;
};

export type FaceInk = {
  white: string;
  pupil: string;
  /** The skin colour: eyelid and cheek are skin sliding over the white. */
  skin: string;
  /** Lines: lash edge, closed eye, happy-squint arc. */
  line: string;
  lineWidth?: number;
};

/**
 * A living eye. Pupil and shine slide, clipped to the white. The lid and cheek
 * are skin clipped to a pill 2 units LARGER than the white: clipped to the exact
 * white, the anti-aliased white edge leaks around a closed eye and reads as
 * glasses. The closed-eye line appears only when the lid is nearly down.
 */
export function LiveEye({
  side,
  eye,
  ink,
  choreo,
  clock,
  id,
}: {
  /** -1 the eye on the viewer's left, 1 the right (mirrors the closed-eye line). */
  side: -1 | 1;
  eye: EyeGeometry;
  ink: FaceInk;
  choreo: Choreo;
  clock: SharedValue<number>;
  /** UNIQUE on screen: SVG clip ids are global. */
  id: string;
}) {
  const { cx, cy, w, h, pupilW: pw, pupilH: ph } = eye;
  const lidKeys = side === 1 && choreo.lidRight ? choreo.lidRight : choreo.lid;
  const top = cy - h / 2 + eye.pupilTop;
  const lidH = h + 4;
  const lw = ink.lineWidth ?? 5;

  const pupil = useAnimatedProps(() => ({
    x: cx + track(clock.value, choreo.lookX) - pw / 2,
    y: top + track(clock.value, choreo.lookY),
  }));
  const shine = useAnimatedProps(() => ({
    cx: cx + track(clock.value, choreo.lookX) - pw * 0.22,
    cy: top + track(clock.value, choreo.lookY) + eye.shine + 1.6,
  }));
  const lid = useAnimatedProps(() => ({ height: track(clock.value, lidKeys) * lidH }));
  // The lid's edge: shows as soon as it starts down, hides when the closed line takes over.
  const lash = useAnimatedProps(() => {
    const l = track(clock.value, lidKeys);
    const y = cy - h / 2 - 2 + l * lidH;
    const on = Math.min(1, l / 0.06) * Math.min(1, Math.max(0, (0.95 - l) / 0.08));
    return { y1: y, y2: y, strokeOpacity: on };
  });
  const closedD = `M${cx - side * w * 0.37} ${cy}H${cx + side * w * 0.13}Q${cx + side * w * 0.33} ${cy} ${cx + side * w * 0.37} ${cy + h * 0.17}`;
  const closed = useAnimatedProps(() => {
    const l = track(clock.value, lidKeys);
    return { strokeOpacity: Math.min(1, Math.max(0, (l - 0.88) / 0.12)) };
  });
  const cheek = useAnimatedProps(() => {
    const c = choreo.cheek ? track(clock.value, choreo.cheek) : 0;
    return { y: cy + h / 2 + 2 - c * lidH, height: c * lidH };
  });
  const happyD = `M${cx - w * 0.4} ${cy - h * 0.1}Q${cx} ${cy - h * 0.7} ${cx + w * 0.4} ${cy - h * 0.1}`;
  const happy = useAnimatedProps(() => {
    const c = choreo.cheek ? track(clock.value, choreo.cheek) : 0;
    return { strokeOpacity: Math.min(1, Math.max(0, (c - 0.86) / 0.14)) };
  });

  return (
    <G>
      <Defs>
        <ClipPath id={id}>
          <Path d={pill(cx, cy, w, h)} />
        </ClipPath>
        <ClipPath id={`${id}Skin`}>
          <Path d={pill(cx, cy, w + 2, h + 2)} />
        </ClipPath>
      </Defs>
      <G clipPath={`url(#${id})`}>
        <ARect animatedProps={pupil} width={pw} height={ph} rx={pw / 2} fill={ink.pupil} />
        {eye.shine > 0 ? <ACircle animatedProps={shine} r={eye.shine} fill={ink.white} /> : null}
      </G>
      <G clipPath={`url(#${id}Skin)`}>
        <ARect animatedProps={lid} x={cx - w / 2 - 2} y={cy - h / 2 - 2} width={w + 4} fill={ink.skin} />
        <ALine animatedProps={lash} x1={cx - w / 2 - 2} x2={cx + w / 2 + 2} stroke={ink.line} strokeWidth={lw * 0.6} />
        {choreo.cheek ? <ARect animatedProps={cheek} x={cx - w / 2 - 2} width={w + 4} fill={ink.skin} /> : null}
      </G>
      <APath animatedProps={closed} d={closedD} stroke={ink.line} strokeWidth={lw} strokeLinecap="round" strokeLinejoin="round" fill="none" />
      {choreo.cheek ? (
        <APath animatedProps={happy} d={happyD} stroke={ink.line} strokeWidth={lw} strokeLinecap="round" fill="none" />
      ) : null}
    </G>
  );
}

/**
 * A living open mouth: the dark inside deepens and shallows, the tongue follows.
 * `x0`/`x1` are the corners, `top` the upper lip line, `tilt` how much higher the
 * right corner sits. It never fully closes: with the teeth on top it reads as talking.
 */
export function LiveMouth({
  x0,
  x1,
  top,
  tilt = 0,
  ink,
  choreo,
  clock,
  restDepth = 11,
}: {
  x0: number;
  x1: number;
  top: number;
  tilt?: number;
  ink: { mouth: string; tongue: string; teeth?: string };
  choreo: Choreo;
  clock: SharedValue<number>;
  /** Depth used when the choreography has no `mouth` track. */
  restDepth?: number;
}) {
  const mid = (x0 + x1) / 2;
  const dark = useAnimatedProps(() => {
    const d = choreo.mouth ? track(clock.value, choreo.mouth) : restDepth;
    return {
      d: `M${x0} ${top}L${x1} ${top - tilt}Q${x1 + 2} ${top + d} ${mid} ${top + d}Q${x0 - 2} ${top + d} ${x0} ${top}Z`,
    };
  });
  const tongue = useAnimatedProps(() => {
    const d = choreo.mouth ? track(clock.value, choreo.mouth) : restDepth;
    const r = Math.min(d * 0.36, (x1 - x0) * 0.22);
    return { cy: top + d - r - 1.5, r };
  });
  return (
    <G>
      <APath animatedProps={dark} fill={ink.mouth} />
      <ACircle animatedProps={tongue} cx={mid + 1} fill={ink.tongue} />
      {ink.teeth ? (
        <Path
          d={`M${x0 + 1} ${top}L${x1 - 1} ${top - tilt}L${x1 - 1.5} ${top - tilt + 5}L${x0 + 1.5} ${top + 5}Z`}
          fill={ink.teeth}
        />
      ) : null}
    </G>
  );
}
