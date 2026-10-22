// motion.ts: the motion engine for living illustrations (react-native-reanimated 3/4).
//
// Everything that moves reads a clock: a looping clock for idle life, a one-shot
// clock for a scene that tells an action. Values come from keyframe tracks and a
// few shaping helpers, all worklets, so they run on the UI thread.
import { useEffect } from 'react';
import { Easing, cancelAnimation, useSharedValue, withRepeat, withTiming, type SharedValue } from 'react-native-reanimated';

// ⚠️ Keep curves at the TOP of the module. A worklet captures what it references
// when it is created; constants declared further down are undefined inside it.
/** Things that travel (gaze, sway, a head turning, a lid closing). */
export const EASE_IN_OUT = Easing.bezierFn(0.77, 0, 0.175, 1);
/** Things that open or arrive (a mouth, a lid reopening, a prop appearing). */
export const EASE_OUT = Easing.bezierFn(0.23, 1, 0.32, 1);
/** Only for things leaving or falling away. Never for something the eye is waiting on. */
export const EASE_IN = Easing.bezierFn(0.55, 0, 1, 0.45);

/** A keyframe: time (ms), value, and the curve of the segment ARRIVING here ('out', or ease-in-out by default). */
export type Key = readonly [number, number, 'out'?];
export type Keys = readonly Key[];

/** The value of a track at time `t`. The last key should equal the first, so loops never jump. */
export function track(t: number, keys: Keys): number {
  'worklet';
  if (t <= keys[0][0]) return keys[0][1];
  for (let i = 1; i < keys.length; i++) {
    const k1 = keys[i];
    if (t <= k1[0]) {
      const k0 = keys[i - 1];
      const span = k1[0] - k0[0];
      const p = span > 0 ? (t - k0[0]) / span : 1;
      const e = k1[2] === 'out' ? EASE_OUT(p) : EASE_IN_OUT(p);
      return k0[1] + (k1[1] - k0[1]) * e;
    }
  }
  return keys[keys.length - 1][1];
}

/** A key pose for `flow`: time (ms) and value, sorted by time. */
export type FlowKey = readonly [number, number];

/**
 * A smooth track through key poses, for acting (a body, arms, a head turn).
 * `track` eases in and out of EVERY key, so the motion stops at each one: fine for one
 * move (a blink, a lid), but a chain of poses then reads as stop-and-go, like a robot.
 * `flow` passes through the keys with a continuous speed and never overshoots one
 * (a monotone cubic). Repeat a value to hold, and layer idle life on top of the hold.
 */
export function flow(t: number, k: readonly FlowKey[]): number {
  'worklet';
  const n = k.length;
  if (t <= k[0][0]) return k[0][1];
  if (t >= k[n - 1][0]) return k[n - 1][1];
  let i = 0;
  while (k[i + 1][0] < t) i++;
  function slope(j: number): number {
    return (k[j + 1][1] - k[j][1]) / (k[j + 1][0] - k[j][0]);
  }
  function tangent(j: number): number {
    if (j === 0 || j === n - 1) return 0;
    const a = slope(j - 1);
    const b = slope(j);
    if (a * b <= 0) return 0;
    const h0 = k[j][0] - k[j - 1][0];
    const h1 = k[j + 1][0] - k[j][0];
    const w0 = 2 * h1 + h0;
    const w1 = h1 + 2 * h0;
    return (w0 + w1) / (w0 / a + w1 / b);
  }
  const h = k[i + 1][0] - k[i][0];
  const s = (t - k[i][0]) / h;
  const s2 = s * s;
  const s3 = s2 * s;
  return (
    (2 * s3 - 3 * s2 + 1) * k[i][1] +
    (s3 - 2 * s2 + s) * h * tangent(i) +
    (-2 * s3 + 3 * s2) * k[i + 1][1] +
    (s3 - s2) * h * tangent(i + 1)
  );
}

/** 0 → 1 inside the window [a, b] of a clock (eased), 0 before it, 1 after. One beat of a scene. */
export function seg(t: number, a: number, b: number, curve: 'out' | 'inOut' = 'out'): number {
  'worklet';
  if (t <= a) return 0;
  if (t >= b) return 1;
  const p = (t - a) / (b - a);
  return curve === 'out' ? EASE_OUT(p) : EASE_IN_OUT(p);
}

/** A smooth back-and-forth from -1 to 1. `phase` (0 to 1) offsets one item from the next. */
export function wave(t: number, period: number, phase = 0): number {
  'worklet';
  return Math.sin((t / period + phase) * Math.PI * 2);
}

/** Progress through a loop, 0 to 1, with a phase (for drifting or falling items). */
export function loop(t: number, period: number, phase = 0): number {
  'worklet';
  const p = (t / period + phase) % 1;
  return p < 0 ? p + 1 : p;
}

/** 0 at both ends of a loop and 1 in the middle: fade in and out (steam, sparkles, ripples). */
export function bell(p: number): number {
  'worklet';
  return Math.sin(Math.PI * Math.min(1, Math.max(0, p)));
}

/** A stable pseudo-random number in [0, 1) for item `i`: variety that is the same every render. */
export function seeded(i: number, salt = 0): number {
  'worklet';
  const x = Math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return x - Math.floor(x);
}

/**
 * A looping clock from 0 to `period` ms. Frozen at 0 when `live` is false
 * (reduced motion, off screen, hidden): frame 0 must be a good drawing.
 */
export function useLoopClock(period: number, live: boolean): SharedValue<number> {
  const clock = useSharedValue(0);
  useEffect(() => {
    cancelAnimation(clock);
    // withRepeat restarts from the CURRENT value: always reset first.
    clock.value = 0;
    if (!live) return;
    clock.value = withRepeat(withTiming(period, { duration: period, easing: Easing.linear }), -1);
    return () => cancelAnimation(clock);
  }, [live, period, clock]);
  return clock;
}

/**
 * A clock that plays ONCE from 0 to `duration` ms when `play` turns true, and
 * holds at the end (a scene that tells an action, a chart drawing itself on).
 * With reduced motion it jumps straight to the end: the final frame is the one
 * that carries meaning, so it must read on its own.
 */
export function useOneShotClock(duration: number, play: boolean, reduced: boolean): SharedValue<number> {
  const clock = useSharedValue(reduced ? duration : 0);
  useEffect(() => {
    cancelAnimation(clock);
    if (!play) {
      clock.value = 0;
      return;
    }
    if (reduced) {
      clock.value = duration;
      return;
    }
    clock.value = 0;
    clock.value = withTiming(duration, { duration, easing: Easing.linear });
    return () => cancelAnimation(clock);
  }, [play, reduced, duration, clock]);
  return clock;
}
