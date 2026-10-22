// Motion.swift: the motion engine for living illustrations in SwiftUI (iOS 17+, macOS 14+).
//
// Everything that moves reads a clock: `LoopClock` for idle life, `OneShotClock`
// for a scene that tells an action. Values come from keyframe tracks and a few
// shaping helpers, computed from the clock's time `t` (ms) on every frame.
import SwiftUI

// MARK: - Curves

/// Things that travel (gaze, sway, a head turning, a lid closing): a strong ease-in-out.
let easeInOut = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.77, y: 0), endControlPoint: UnitPoint(x: 0.175, y: 1))
/// Things that open or arrive (a mouth, a lid reopening, a prop appearing): a strong ease-out.
let easeOut = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.23, y: 1), endControlPoint: UnitPoint(x: 0.32, y: 1))

/// The same curves for one-off SwiftUI animations (never a spring with bounce).
public extension Animation {
    static func travel(_ duration: Double) -> Animation { .timingCurve(0.77, 0, 0.175, 1, duration: duration) }
    static func open(_ duration: Double) -> Animation { .timingCurve(0.23, 1, 0.32, 1, duration: duration) }
}

// MARK: - Tracks and shaping

/// A keyframe: time (ms), value, and whether the segment ARRIVING here eases out (default: ease-in-out).
public struct Key: Sendable {
    public let ms: Double
    public let value: Double
    public let easeOut: Bool
    public init(_ ms: Double, _ value: Double, out easeOut: Bool = false) {
        self.ms = ms
        self.value = value
        self.easeOut = easeOut
    }
}

public typealias Keys = [Key]

/// The value of a track at time `t` (ms). The last key should equal the first, so loops never jump.
public func track(_ t: Double, _ keys: Keys) -> Double {
    guard let first = keys.first else { return 0 }
    if t <= first.ms { return first.value }
    for i in 1..<keys.count {
        let k1 = keys[i]
        if t <= k1.ms {
            let k0 = keys[i - 1]
            let span = k1.ms - k0.ms
            let p = span > 0 ? (t - k0.ms) / span : 1
            let e = (k1.easeOut ? easeOut : easeInOut).value(at: p)
            return k0.value + (k1.value - k0.value) * e
        }
    }
    return keys[keys.count - 1].value
}

/// Key poses for `flow`: (ms, value), sorted by time.
public typealias FlowKeys = [(Double, Double)]

/// A smooth track through key poses, for acting (a body, arms, a head turn).
/// `track` eases in and out of EVERY key, so the motion stops at each one: fine for one move
/// (a blink, a lid), but a chain of poses then reads as stop-and-go, like a robot. `flow` passes
/// through the keys with a continuous speed and never overshoots one (a monotone cubic).
/// Repeat a value to hold, and layer idle life on top of the hold.
public func flow(_ t: Double, _ k: FlowKeys) -> Double {
    let n = k.count
    if t <= k[0].0 { return k[0].1 }
    if t >= k[n - 1].0 { return k[n - 1].1 }
    var i = 0
    while k[i + 1].0 < t { i += 1 }
    func slope(_ j: Int) -> Double { (k[j + 1].1 - k[j].1) / (k[j + 1].0 - k[j].0) }
    func tangent(_ j: Int) -> Double {
        guard j > 0, j < n - 1 else { return 0 }
        let a = slope(j - 1), b = slope(j)
        guard a * b > 0 else { return 0 }
        let h0 = k[j].0 - k[j - 1].0, h1 = k[j + 1].0 - k[j].0
        let w0 = 2 * h1 + h0, w1 = h1 + 2 * h0
        return (w0 + w1) / (w0 / a + w1 / b)
    }
    let h = k[i + 1].0 - k[i].0
    let s = (t - k[i].0) / h
    let s2 = s * s, s3 = s2 * s
    return (2 * s3 - 3 * s2 + 1) * k[i].1 + (s3 - 2 * s2 + s) * h * tangent(i)
        + (-2 * s3 + 3 * s2) * k[i + 1].1 + (s3 - s2) * h * tangent(i + 1)
}

/// 0 → 1 inside the window [a, b] of a clock (eased), 0 before it, 1 after. One beat of a scene.
public func seg(_ t: Double, _ a: Double, _ b: Double, easeOut useEaseOut: Bool = true) -> Double {
    if t <= a { return 0 }
    if t >= b { return 1 }
    let p = (t - a) / (b - a)
    return (useEaseOut ? easeOut : easeInOut).value(at: p)
}

/// A smooth back-and-forth from -1 to 1. `phase` (0 to 1) offsets one item from the next.
public func wave(_ t: Double, period: Double, phase: Double = 0) -> Double {
    sin((t / period + phase) * .pi * 2)
}

/// Progress through a loop, 0 to 1, with a phase (for drifting or falling items).
public func loop(_ t: Double, period: Double, phase: Double = 0) -> Double {
    let p = (t / period + phase).truncatingRemainder(dividingBy: 1)
    return p < 0 ? p + 1 : p
}

/// 0 at both ends of a loop and 1 in the middle: fade in and out (steam, sparkles, ripples).
public func bell(_ p: Double) -> Double {
    sin(.pi * min(1, max(0, p)))
}

/// A stable pseudo-random number in [0, 1) for item `i`: variety that is the same every frame.
public func seeded(_ i: Int, salt: Double = 0) -> Double {
    let x = sin(Double(i) * 12.9898 + salt * 78.233) * 43758.5453
    return x - floor(x)
}

// MARK: - Clocks

/// A looping clock from 0 to `period` ms. Frozen at 0 with Reduce Motion, or when `paused`
/// (off screen, app in the background). Frame 0 must be a good drawing on its own.
public struct LoopClock<Content: View>: View {
    let period: Double
    var paused: Bool
    let content: (Double) -> Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()

    public init(period: Double, paused: Bool = false, @ViewBuilder content: @escaping (Double) -> Content) {
        self.period = period
        self.paused = paused
        self.content = content
    }

    public var body: some View {
        let still = paused || reduceMotion
        TimelineView(.animation(minimumInterval: nil, paused: still)) { context in
            let t = still ? 0 : (context.date.timeIntervalSince(start) * 1000).truncatingRemainder(dividingBy: period)
            content(t)
        }
    }
}

/// A clock that plays ONCE from 0 to `duration` ms when `play` turns true, then holds at the end
/// (a scene that tells an action, a chart drawing itself on). With Reduce Motion it shows the end
/// straight away: the final frame carries the meaning, so it must read on its own.
public struct OneShotClock<Content: View>: View {
    let duration: Double
    let play: Bool
    let content: (Double) -> Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startedAt: Date?

    public init(duration: Double, play: Bool, @ViewBuilder content: @escaping (Double) -> Content) {
        self.duration = duration
        self.play = play
        self.content = content
    }

    public var body: some View {
        Group {
            if !play {
                content(0)
            } else if reduceMotion {
                content(duration)
            } else {
                TimelineView(.animation(minimumInterval: nil, paused: isDone)) { context in
                    let elapsed = startedAt.map { context.date.timeIntervalSince($0) * 1000 } ?? 0
                    content(min(duration, elapsed))
                }
            }
        }
        .onChange(of: play, initial: true) { _, now in
            startedAt = now ? Date() : nil
        }
    }

    private var isDone: Bool {
        guard let startedAt else { return false }
        return Date().timeIntervalSince(startedAt) * 1000 >= duration
    }
}
