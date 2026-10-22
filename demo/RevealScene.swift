// RevealScene.swift: a reward reveal, and the demo of SKILL.md section 5 (acting).
// A mystery silhouette floats in with a swirl and sparkles, its feet dangling, and leaves
// rising. A kid in a new team kit appears in the air, hovers, falls and squashes on landing. A
// ball rolls in from the right; the kid kicks it away and watches it go, turns to the viewer and
// waves hello, shuffles, grins and hops. One clock, a 9-second loop. Every acting channel is a
// `flow` of key poses plus idle life plus follow-through, so nothing ever freezes. The build is
// a toy-like avatar seen from a little above (see `build`). Render it at 60 fps.
//
// The kid follows duolingo-character-style for its shapes: a 100-wide tombstone head centred on
// (0, 0) with y growing down, pill eyes with no brows, capsule arms whose shoulders hide behind
// the torso, circle hands, flat colours from the guide's palette.
import SwiftUI

struct RevealScene: View {
    let t: Double
    /// Taller than the scene (a phone screen): the scene stays in the middle, the sky fills the rest.
    var height = 720.0
    /// Where the 720-tall stage starts inside that height; centred when nil.
    var stageTop: Double? = nil
    private var top: Double { stageTop ?? (height - Self.size.height) / 2 }
    static let size = CGSize(width: 720, height: 720)
    static let loopMs = 9000.0

    private enum Ink {
        static let bg = Color.white
        static let skyTop = Color(hex: 0x84D8FF)
        static let skyMid = Color(hex: 0xDDF4FF)
        static let cloud = Color(hex: 0xB5E6FF)
        static let floor = Color(hex: 0xD3ECFA)
        static let mystery = Color(hex: 0x84D8FF)
        static let mysteryMark = Color(hex: 0xDDF4FF)
        static let swirl = Color(hex: 0xBBF2FF)
        static let spark = Color(hex: 0x84D8FF)
        static let skin = Color(hex: 0xF5B092)
        static let feature = Color(hex: 0xD97856)
        static let hair = Color(hex: 0x4A2C1C)
        static let top = Color(hex: 0xFF4B4B)
        static let topShade = Color(hex: 0xEA2B2B)
        static let shorts = Color(hex: 0x1453A3)
        static let shoe = Color(hex: 0x33333B)
        static let white = Color.white
        static let pupil = Color(hex: 0x3C3C3C)
        static let mouth = Color(hex: 0xB03A3A)
        static let tongue = Color(hex: 0xF15A5A)
        static let ballShade = Color(hex: 0xD2E4E8)
    }

    // MARK: - Tokens

    /// Where the feet stand on screen, and kid units (head = 100 wide) to screen points.
    private let feet = CGPoint(x: 360, y: 620)
    private let kidScale = 1.45
    /// The build, seen from a little above, like a toy: the head is almost half the height, the
    /// torso is short and narrower than the head, the legs are short, the feet are round dark
    /// shoes under the socks, and the shadow is a wide oval because the floor shows. The feet
    /// stand in the lower half of the shadow.
    private let build = (torsoTop: 50.0, torsoBottom: 112.0, shoulders: 42.0, waist: 38.0, hip: 22.0, hipY: 132.0,
                        shoeBottom: 62.0, shadow: 140.0, shadowRatio: 0.32, shadowUp: 7.0)
    /// The kid's frame: the head centre is (0, 0); the soles are this far below it.
    private var floorY: Double { build.hipY + build.shoeBottom }
    /// Arms: shoulder (inside the torso), capsule thickness, hand radius, upper arm and forearm
    /// (similar lengths, one shared round elbow), and how much further a raised straight arm reaches.
    private let arm = (x: 34.0, y: 66.0, w: 26.0, hand: 13.0, upper: 30.0, fore: 28.0, reach: 12.0)
    /// The beats of the loop, in ms.
    private let beat = (mysteryIn: 250.0, swirl: 500.0, mysteryOut: 2100.0, drop: 2450.0, fall: 2850.0,
                        land: 3060.0, hop: 7560.0, hopEnd: 7940.0, out: 8500.0, gone: 8900.0)
    private let jump = (hover: 104.0, top: 116.0, hop: 28.0)

    private static let ink = FaceInk(white: .white, pupil: Ink.pupil, skin: Ink.skin, line: Ink.feature, lineWidth: 5)
    /// Blinks land on the head turns, as people do.
    private static let lid = blinks([3550, 4850, 5900, 8420])
    private static let cheek: Keys = [Key(0, 0), Key(7480, 0), Key(7580, 1, out: true), Key(8180, 1), Key(8340, 0), Key(loopMs, 0)]
    /// The open mouth's depth: wide on arrival and for the grin, a small open smile at rest.
    private static let mouth: Keys = [
        Key(0, 22), Key(2450, 22), Key(3060, 16), Key(3300, 14), Key(3600, 11), Key(4050, 9), Key(4150, 18), Key(4400, 20),
        Key(4600, 14), Key(4900, 16), Key(5100, 20), Key(6300, 18), Key(6700, 12),
        Key(7480, 10), Key(7580, 22, out: true), Key(8180, 22), Key(8360, 11), Key(8900, 11), Key(loopMs, 22),
    ]

    private static func blinks(_ at: [Double]) -> Keys {
        var keys = [Key(0, 0)]
        // Close in 110 ms, hold 40, reopen in 190 with ease-out: enough frames to read as one smooth
        // motion (a 70 ms close is two frames at 30 fps and flickers).
        for b in at { keys += [Key(b, 0), Key(b + 110, 1), Key(b + 150, 1), Key(b + 340, 0, out: true)] }
        return keys + [Key(loopMs, 0)]
    }

    var body: some View {
        Canvas { ctx, _ in
            ctx.fill(Path(CGRect(x: 0, y: 0, width: Self.size.width, height: height)), with: .color(Ink.bg))
            drawSky(ctx)
            var stage = ctx
            stage.translateBy(x: 0, y: top)
            drawMystery(stage)
            drawKidOnStage(stage)
        }
        .frame(width: Self.size.width, height: height)
    }

    // MARK: - Acting: smooth channels through key poses, plus idle life and follow-through

    /// One arm: `a` the upper arm's outward angle (0 hangs down), `e` the elbow bend
    /// (the forearm points at a + e; positive folds it up and out, negative in toward the body).
    private struct Arm { var a = 12.0, e = 0.0 }

    private struct Pose {
        var lift = 0.0, sx = 1.0, sy = 1.0, lean = 0.0
        /// The weight moving over one leg (hip shift), and the turn of head and chest, -1 to 1.
        var shift = 0.0, yaw = 0.0, head = 0.0
        var armL = Arm(), armR = Arm()
        /// Legs: outward angle in degrees.
        var legL = 3.0, legR = 3.0
        /// Levitating, 0 to 1: the legs hang limp, the toes point down, one knee folds a little.
        /// `pedal` (-1 to 1) slowly trades which leg is folded.
        var float = 0.0, pedal = 0.0
        /// The right foot's toe pointing through a kick, in degrees.
        var toeR = 0.0
    }

    /// The key poses: hover and fall, land, the ball rolls in and gets kicked, the kid watches it
    /// go, turns to the viewer and waves hello, shuffles, then the grin and the hop.
    private enum Act {
        static let sy: FlowKeys = [(0, 1), (2450, 1), (2850, 1), (2980, 1.1), (3060, 1.06), (3120, 0.8), (3220, 1.03),
                               (3360, 1), (7440, 1), (7530, 0.9), (7600, 1.08), (7880, 1.02), (7950, 0.88),
                               (8040, 1.03), (8160, 1), (9000, 1)]
        static let lean: FlowKeys = [(0, 0), (2450, 0), (2850, -2), (3060, 0), (3400, 0), (3850, -2), (4050, -4), (4150, -9),
                                 (4300, -5), (4550, 0), (5000, -3), (5500, 2), (6000, -2), (6400, 2), (6800, 0), (9000, 0)]
        static let shift: FlowKeys = [(0, 0), (3060, 0), (3350, 0), (3800, -4), (4050, -10), (4250, -8), (4550, 0),
                                  (5200, -4), (6300, -4), (6800, 0), (9000, 0)]
        static let yaw: FlowKeys = [(0, 0), (3350, 0), (3600, 0.45), (4050, 0.3), (4200, 0.55), (4600, 0.5), (4900, 0),
                                (5100, 0.15), (6300, 0.2), (6700, 0), (9000, 0)]
        static let head: FlowKeys = [(0, 0), (2450, -4), (3060, 0), (3400, 0), (3600, 6), (4050, 3), (4200, -6), (4600, -4),
                                 (4900, 0), (5100, 6), (6300, 4), (6700, 0), (7480, 0), (7620, 6), (8180, 2), (8360, 0),
                                 (9000, 0)]
        /// The eyes follow the ball: down to it as it rolls in, up after it once it is kicked, then
        /// back to the viewer for the hello.
        static let lookY: FlowKeys = [(0, -3), (3060, -3), (3400, 0), (3450, 0), (3650, 4), (4100, 4), (4250, -5), (4600, -4),
                                  (4850, 0), (8900, 0), (9000, -3)]
        static let lookX: FlowKeys = [(0, 0), (3450, 0), (3650, 3), (4100, 2), (4250, 5), (4600, 4), (4850, 0), (9000, 0)]
        /// The kick, added to the right leg: wind up across, stop at the top, swing out fast
        /// through the ball at 4100, follow through, come back down.
        static let kick: FlowKeys = [(0, 0), (3850, 0), (4050, -20), (4100, 22), (4160, 58), (4250, 52), (4500, 0), (9000, 0)]
        /// The kicking foot points its toe through the swing (degrees).
        static let toe: FlowKeys = [(0, 0), (3950, 0), (4100, 40), (4250, 35), (4500, 0), (9000, 0)]
        static let armRa: FlowKeys = [(0, 110), (2450, 110), (2850, 125), (2960, 150), (3060, 92), (3150, 84), (3300, 76),
                                  (3850, 22), (4050, 40), (4150, 18), (4300, 30), (4600, 20), (4900, 40), (5100, 62),
                                  (6300, 62), (6600, 30), (7000, 14), (7480, 14), (7620, 55), (8180, 42), (8360, 14),
                                  (8900, 14), (9000, 110)]
        static let armRe: FlowKeys = [(0, 0), (2450, 0), (3060, 0), (3300, 10), (3850, 10), (4050, 20), (4150, 30), (4300, 15),
                                  (4600, 10), (4900, 40), (5100, 108), (6300, 110), (6600, 30), (7000, 10), (7480, 10),
                                  (7620, 60), (8180, 40), (8360, 10), (8900, 10), (9000, 0)]
        static let armLa: FlowKeys = [(0, 110), (2450, 110), (2850, 125), (2960, 150), (3060, 92), (3150, 84), (3300, 78),
                                  (3850, 30), (4050, 55), (4150, 85), (4300, 60), (4600, 20), (5100, 20), (6300, 22),
                                  (6600, 18), (7000, 14), (7480, 14), (7620, 55), (8180, 42), (8360, 14), (8900, 14),
                                  (9000, 110)]
        static let armLe: FlowKeys = [(0, 0), (2450, 0), (3060, 0), (3300, 12), (3850, 10), (4050, 15), (4150, 25), (4300, 15),
                                  (4600, 10), (5100, -15), (6300, -18), (6600, 8), (7000, 10), (7480, 10), (7620, 60),
                                  (8180, 40), (8360, 10), (8900, 10), (9000, 0)]
    }

    private func pose(_ t: Double) -> Pose {
        var p = Pose()
        // Idle life runs the whole time the kid is on stage: never a frozen frame.
        let on = t >= beat.drop && t < beat.gone ? 1.0 : 0.0
        // Height: hovers with the legs dangling, falls with gravity, the hop.
        if t >= beat.drop && t < beat.fall {
            p.lift = jump.hover + (jump.top - jump.hover) * easeOut.value(at: (t - beat.drop) / (beat.fall - beat.drop))
        } else if t >= beat.fall && t < beat.land {
            let k = (t - beat.fall) / (beat.land - beat.fall)
            p.lift = jump.top * (1 - k * k)
        } else if t >= beat.hop && t < beat.hopEnd {
            let k = (t - beat.hop) / (beat.hopEnd - beat.hop)
            p.lift = jump.hop * 4 * k * (1 - k)
        }
        // Squash and stretch keep the volume; breathing on top.
        let s = flow(t, Act.sy)
        p.sx = 1 / pow(s, 0.6)
        p.sy = s * (1 + 0.014 * wave(t, period: 2250) * on)
        let swaying = seg(t, 5100, 5300) * (1 - seg(t, 6100, 6300))
        p.lean = flow(t, Act.lean) + (1.5 * wave(t, period: 4500, phase: 0.2) + 2.5 * wave(t, period: 1500) * swaying) * on
        p.shift = 0.6 * flow(t, Act.shift) + 1.2 * wave(t, period: 4500) * on
        p.yaw = flow(t, Act.yaw) + 0.06 * wave(t, period: 3000, phase: 0.1) * on
        // The head follows the body a beat later and the other way, on top of its own acting.
        p.head = flow(t, Act.head) - 0.45 * flow(t - 110, Act.lean) + 2 * wave(t, period: 4500, phase: 0.6) * on
        // Arms: the key poses, a small sway that never stops, flapping in the air, and a forearm
        // that trails the upper arm when it swings (follow-through).
        let flap = 8 * wave(t, period: 450) * (t >= beat.drop && t < beat.fall ? 1 : 0)
        func arm(_ ka: FlowKeys, _ ke: FlowKeys, phase: Double) -> Arm {
            let sway = 4 * wave(t, period: 3000, phase: phase) + 2 * wave(t, period: 1800, phase: phase + 0.3)
            let a = flow(t, ka) + sway * on + flap
            let trail = 0.45 * (flow(t - 90, ka) - flow(t, ka))
            let e = flow(t, ke) + 5 * wave(t, period: 2250, phase: phase + 0.6) * on + trail
            return Arm(a: a, e: e)
        }
        p.armR = arm(Act.armRa, Act.armRe, phase: 0)
        p.armR.e += 14 * wave(t, period: 750) * seg(t, 5100, 5250) * (1 - seg(t, 6150, 6300))
        p.armL = arm(Act.armLa, Act.armLe, phase: 0.5)
        // Legs: dangle in the air, splay on the squash, a little shuffle, the free leg on the weight shift.
        let air = t >= beat.drop && t < beat.land ? 1 - seg(t, beat.land - 80, beat.land) : 0
        let splay = max(0, 1 - s) * 50
        p.legR = 3 + air * (5 + 7 * wave(t, period: 600)) + splay + 9 * bell((t - 6650) / 260) + flow(t, Act.kick)
        p.toeR = flow(t, Act.toe)
        p.legL = 3 + air * (5 + 7 * wave(t, period: 600, phase: 0.35)) + splay + 9 * bell((t - 6870) / 260)
            + max(0, p.shift) * 0.9
        // Hanging in the air the feet dangle; they flatten just before touching down.
        p.float = t >= beat.drop && t < beat.land ? 1 - seg(t, beat.land - 160, beat.land - 20) : 0
        p.pedal = wave(t, period: 600)
        return p
    }

    // MARK: - Sky: fades in behind the kid, with drifting clouds and twinkles

    private func drawSky(_ ctx: GraphicsContext) {
        let on = seg(t, 2500, 3000) * (1 - seg(t, beat.out, 8950, easeOut: false))
        guard on > 0 else { return }
        var s = ctx
        s.opacity = on
        // The gradient reaches white just above the feet, whatever the screen's height.
        let dy = top
        s.fill(Path(CGRect(x: 0, y: 0, width: Self.size.width, height: height)),
               with: .linearGradient(Gradient(stops: [.init(color: Ink.skyTop, location: 0),
                                                      .init(color: Ink.skyMid, location: (dy + 360) / height),
                                                      .init(color: Ink.bg, location: (dy + 576) / height)]),
                                     startPoint: .zero, endPoint: CGPoint(x: 0, y: height)))
        let clouds: [(x: Double, y: Double, r: Double)] = [
            (-10, 300, 96), (66, 236, 62), (-4, 176, 58), (730, 340, 104), (654, 276, 66), (706, 196, 56),
        ]
        for (i, c) in clouds.enumerated() {
            let dx = 8 * wave(t, period: Self.loopMs, phase: Double(i) * 0.17)
            s.fill(Path(ellipseIn: CGRect(x: c.x + dx - c.r, y: c.y - c.r, width: c.r * 2, height: c.r * 2)), with: .color(Ink.cloud))
        }
        let stars: [(x: Double, y: Double, r: Double)] = [
            (150, 190, 10), (580, 230, 9), (230, 90, 7), (480, 120, 11), (90, 330, 8), (640, 360, 7), (330, 60, 6),
        ]
        for (i, st) in stars.enumerated() {
            let p = loop(t, period: 1800, phase: seeded(i, salt: 2)) / 0.45
            guard p < 1 else { continue }
            var g = s
            g.translateBy(x: st.x, y: st.y)
            g.scaleBy(x: bell(p), y: bell(p))
            g.fill(fourPointStar(r: st.r), with: .color(Ink.white))
        }
    }

    // MARK: - The mystery: a silhouette with a question mark, a swirl and sparkles

    private func drawMystery(_ ctx: GraphicsContext) {
        guard t < beat.drop else { return }
        let inK = seg(t, beat.mysteryIn, beat.mysteryIn + 450)
        let outK = seg(t, beat.mysteryOut, beat.mysteryOut + 250, easeOut: false)
        let on = inK * (1 - outK)
        let scale = (0.92 + 0.08 * inK) * kidScale
        // It floats, measured on the reference: rises in from 30% of its height below and slows,
        // drifts down 5% and back up, and leaves rising while it fades.
        // `hover` is the height of the feet above the floor; the shadow shrinks as it rises.
        let hover = 70 - flow(t, [(beat.mysteryIn, 120), (900, 0), (1650, 18), (2350, -60)])
        let shadowK = 1 - min(1, max(0, hover) / 220)

        drawMysterySparks(ctx)
        var shade = ctx
        shade.opacity = on
        let mw = build.shadow * kidScale * shadowK
        shade.fill(Path(ellipseIn: CGRect(x: feet.x - mw / 2, y: feet.y - build.shadowUp * kidScale - mw * build.shadowRatio / 2,
                                          width: mw, height: mw * build.shadowRatio)), with: .color(Ink.floor))
        drawSwirl(ctx, front: false)
        var m = ctx
        m.opacity = on
        m.translateBy(x: feet.x, y: feet.y - hover)
        m.scaleBy(x: scale, y: scale)
        m.translateBy(x: 0, y: -floorY)
        var levitating = Pose()
        levitating.float = 1
        levitating.pedal = wave(t, period: 2400)
        levitating.legL = -2 + 3 * wave(t, period: 1800, phase: 0.2)
        levitating.legR = -2 + 3 * wave(t, period: 1800, phase: 0.55)
        levitating.armL = Arm(a: 16 + 3 * wave(t, period: 2400, phase: 0.1), e: 6)
        levitating.armR = Arm(a: 16 + 3 * wave(t, period: 2400, phase: 0.6), e: 6)
        drawKid(m, pose: levitating, flat: Ink.mystery)
        m.draw(Text("?").font(.system(size: 46, weight: .heavy, design: .rounded)).foregroundColor(Ink.mysteryMark),
               at: CGPoint(x: 0, y: 82))
        drawSwirl(ctx, front: true)
    }

    /// A ring that spirals up around the silhouette once, its back half behind it.
    private func drawSwirl(_ ctx: GraphicsContext, front: Bool) {
        let p = (t - beat.swirl) / 700
        guard p > 0, p < 1 else { return }
        let head = -Double.pi / 2 + p * 2 * .pi * 1.15
        let cy = feet.y - 70 - (30 + 160 * easeOut.value(at: p)) * kidScale
        let tilt = -12.0 * .pi / 180
        var g = ctx
        g.opacity = bell(p)
        let n = 16
        for i in 0..<n {
            let a0 = head - 2.0 + 2.0 * Double(i) / Double(n)
            let a1 = head - 2.0 + 2.0 * Double(i + 1) / Double(n)
            guard (sin((a0 + a1) / 2) > 0) == front else { continue }
            var piece = Path()
            for (j, a) in [a0, a1].enumerated() {
                let lx = 105 * kidScale * cos(a), ly = 24 * kidScale * sin(a)
                let pt = CGPoint(x: feet.x + lx * cos(tilt) - ly * sin(tilt), y: cy + lx * sin(tilt) + ly * cos(tilt))
                if j == 0 { piece.move(to: pt) } else { piece.addLine(to: pt) }
            }
            g.stroke(piece, with: .color(Ink.swirl), style: StrokeStyle(lineWidth: 3 + 9 * Double(i) / Double(n), lineCap: .round))
        }
    }

    /// A burst outward as the silhouette arrives, then a few twinkles while it waits.
    private func drawMysterySparks(_ ctx: GraphicsContext) {
        let center = CGPoint(x: feet.x, y: feet.y - 70 - 120 * kidScale)
        for i in 0..<16 {
            let burst = i < 10
            let start = burst ? 560 + seeded(i, salt: 2) * 350 : 1200 + seeded(i, salt: 4) * 800
            let p = (t - start) / 700
            guard p > 0, p < 1 else { continue }
            let a = seeded(i, salt: 1) * 2 * .pi
            let r = (95 + seeded(i, salt: 3) * 45 + (burst ? 35 * easeOut.value(at: p) : 0)) * kidScale
            var g = ctx
            g.translateBy(x: center.x + cos(a) * r, y: center.y + sin(a) * r * 1.3)
            g.scaleBy(x: bell(p), y: bell(p))
            switch i % 3 {
            case 0: g.fill(fourPointStar(r: 10 + seeded(i, salt: 5) * 8), with: .color(Ink.spark))
            case 1: g.fill(Path(ellipseIn: CGRect(x: -5, y: -5, width: 10, height: 10)), with: .color(Ink.spark))
            default:
                g.rotate(by: .radians(a + .pi / 2))
                g.fill(pill(cx: 0, cy: 0, w: 8, h: 24), with: .color(Ink.spark))
            }
        }
    }

    // MARK: - The kid on stage: drops in, lands, acts, grins, leaves

    private func drawKidOnStage(_ ctx: GraphicsContext) {
        guard t >= beat.drop, t < beat.gone else { return }
        let appear = seg(t, beat.drop, beat.drop + 120)
        let leave = seg(t, beat.out, beat.gone, easeOut: false)
        let p = pose(t)
        let ground = 1 - min(1, p.lift / 250)

        var shade = ctx
        shade.opacity = appear * (1 - leave)
        let sw = build.shadow * kidScale * ground * p.sx
        shade.fill(Path(ellipseIn: CGRect(x: feet.x + p.shift * 0.4 * kidScale - sw / 2,
                                          y: feet.y - build.shadowUp * kidScale - sw * build.shadowRatio / 2,
                                          width: sw, height: sw * build.shadowRatio)), with: .color(Ink.floor))

        var k = ctx
        k.opacity = appear * (1 - leave)
        k.translateBy(x: feet.x, y: feet.y - p.lift)
        k.rotate(by: .degrees(p.lean))
        let s = (0.94 + 0.06 * appear) * (1 - 0.03 * leave) * kidScale
        k.scaleBy(x: p.sx * s, y: p.sy * s)
        k.translateBy(x: 0, y: -floorY)
        drawKid(k, pose: p, flat: nil)
        drawBall(ctx)
    }

    // MARK: - The ball: rolls in from off the right edge, gets kicked, flies off spinning

    /// Radius, where it starts (off screen, even inside the phone) and stops by the right foot
    /// (stage units), when it enters, arrives and is kicked, the launch speed (units a second),
    /// gravity and spin (radians a second).
    private let ball = (r: 36.0, startX: 810.0, stopX: 440.0, enter: 3350.0, arrive: 4000.0, kick: 4100.0,
                        vx: 900.0, vy: 760.0, g: 1500.0, spin: 16.0)

    private func drawBall(_ ctx: GraphicsContext) {
        guard t >= ball.enter, t < ball.kick + 700 else { return }
        let ground = feet.y - ball.r
        var x = ball.stopX, y = ground, angle = 0.0, sx = 1.0, sy = 1.0
        if t < ball.kick {
            // Rolling: it comes in already moving and slows to a stop by the foot. A ball that
            // rolls without slipping turns by the distance over its radius.
            let k = min(1, (t - ball.enter) / (ball.arrive - ball.enter))
            x = ball.startX + (ball.stopX - ball.startX) * easeOut.value(at: k)
            angle = (x - ball.startX) / ball.r
        } else {
            // Kicked: a throw (a straight line plus gravity), spinning, squashed for a moment at contact.
            let s = (t - ball.kick) / 1000
            x = ball.stopX + ball.vx * s
            y = ground - ball.vy * s + ball.g * s * s / 2
            angle = (ball.stopX - ball.startX) / ball.r + ball.spin * s
            let contact = 1 - seg(t, ball.kick, ball.kick + 90)
            sx = 1 - 0.16 * contact
            sy = 1 + 0.12 * contact
        }
        // Its shadow stays on the floor and shrinks as the ball rises.
        let low = 1 - min(1, (ground - y) / 160)
        if low > 0 {
            let bw = ball.r * 2.2 * low
            ctx.fill(Path(ellipseIn: CGRect(x: x - bw / 2, y: feet.y - bw * build.shadowRatio / 2, width: bw, height: bw * build.shadowRatio)),
                     with: .color(Ink.floor))
        }
        var b = ctx
        b.translateBy(x: x, y: y)
        b.scaleBy(x: sx, y: sy)
        let disc = Path(ellipseIn: CGRect(x: -ball.r, y: -ball.r, width: ball.r * 2, height: ball.r * 2))
        // One shade step on the side away from the light; it stays put while the ball turns.
        b.fill(disc, with: .color(Ink.ballShade))
        var lit = b
        lit.clip(to: disc)
        lit.fill(Path(ellipseIn: CGRect(x: -ball.r * 1.14, y: -ball.r * 1.14, width: ball.r * 1.9, height: ball.r * 1.9)),
                 with: .color(Ink.white))
        // The patches turn with the ball: a rounded pentagon in the middle, five more cut by the edge.
        var skin = b
        skin.clip(to: disc)
        skin.rotate(by: .radians(angle))
        skin.fill(pentagon(center: .zero, radius: ball.r * 0.36, turn: 0), with: .color(Ink.pupil))
        for i in 0..<5 {
            let a = Double(i) / 5 * 2 * .pi - .pi / 2
            skin.fill(pentagon(center: CGPoint(x: cos(a) * ball.r, y: sin(a) * ball.r), radius: ball.r * 0.34, turn: a + .pi),
                      with: .color(Ink.pupil))
        }
    }

    private func pentagon(center: CGPoint, radius: Double, turn: Double) -> Path {
        roundedPolygon((0..<5).map { i in
            let a = turn + Double(i) / 5 * 2 * .pi - .pi / 2
            return CGPoint(x: center.x + cos(a) * radius, y: center.y + sin(a) * radius)
        }, r: radius * 0.25)
    }

    // MARK: - The kid, in the head frame. `flat` paints every part one colour with no face.

    private func drawKid(_ c: GraphicsContext, pose: Pose, flat: Color?) {
        func paint(_ g: GraphicsContext, _ path: Path, _ color: Color, eo: Bool = false) {
            g.fill(path, with: .color(flat ?? color), style: FillStyle(eoFill: eo))
        }
        func capsules(_ g: GraphicsContext, _ pts: [CGPoint], _ w: Double, _ color: Color) {
            var p = Path()
            p.addLines(pts)
            g.stroke(p, with: .color(flat ?? color), style: StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round))
        }
        let yaw = pose.yaw

        // Short legs hang from the hips, which carry the weight shift; the feet stay under the body.
        // Seen from above, each foot is a round dark shoe, its top tucked under the sock.
        for (side, angle) in [(-1.0, pose.legL), (1.0, pose.legR)] {
            var leg = c
            leg.translateBy(x: side * build.hip + pose.shift, y: build.hipY)
            leg.rotate(by: .degrees(-side * angle + pose.shift))
            // Levitating, one knee folds a little (that leg reads shorter) and the foot hangs: the
            // shoe gets narrower and longer, toes down.
            let tuck = pose.float * 8 * (0.5 + 0.5 * side * pose.pedal)
            var shoe = leg
            shoe.translateBy(x: 0, y: 46 - tuck)
            shoe.rotate(by: .degrees(side > 0 ? pose.toeR : 0))
            shoe.scaleBy(x: 1 - 0.3 * pose.float, y: 1 + 0.35 * pose.float)
            paint(shoe, Path(roundedRect: CGRect(x: -15 + side * 2, y: -4, width: 30, height: 20), cornerRadius: 10), Ink.shoe)
            capsules(leg, [.zero, CGPoint(x: 0, y: 24 - tuck)], 20, Ink.skin)
            paint(leg, Path(roundedRect: CGRect(x: -12.5, y: 16 - tuck, width: 25, height: 33), cornerRadius: 9), Ink.top)
            paint(leg, Path(CGRect(x: -12.5, y: 21 - tuck, width: 25, height: 5)), Ink.white)
        }

        // Everything above the legs rides on the hips.
        var up = c
        up.translateBy(x: pose.shift, y: 0)
        paint(up, Path(roundedRect: CGRect(x: -40, y: 104, width: 80, height: 34), cornerRadius: 12), Ink.shorts)

        // Arms behind the torso, so the shoulder never shows: upper arm and forearm share one round
        // elbow, the hand is a circle, a short wide sleeve caps the shoulder.
        for (side, limb) in [(-1.0, pose.armL), (1.0, pose.armR)] {
            let a = limb.a * .pi / 180, f = (limb.a + limb.e) * .pi / 180
            let straight = min(1, max(0, 1 - abs(limb.e) / 40))
            let reach = arm.reach * min(1, max(0, (limb.a - 100) / 50)) * straight
            let from = CGPoint(x: side * arm.x, y: arm.y)
            let elbow = CGPoint(x: from.x + side * sin(a) * arm.upper, y: from.y + cos(a) * arm.upper)
            let uf = CGPoint(x: side * sin(f), y: cos(f))
            let hand = CGPoint(x: elbow.x + uf.x * (arm.fore + reach), y: elbow.y + uf.y * (arm.fore + reach))
            capsules(up, [from, elbow, CGPoint(x: hand.x - uf.x * 8, y: hand.y - uf.y * 8)], arm.w, Ink.skin)
            paint(up, Path(ellipseIn: CGRect(x: hand.x - arm.hand, y: hand.y - arm.hand, width: arm.hand * 2, height: arm.hand * 2)), Ink.skin)
            capsules(up, [from, CGPoint(x: from.x + side * sin(a) * 16, y: from.y + cos(a) * 16)], arm.w + 10, Ink.top)
        }

        // The jersey: short, narrowing a little toward the waist; the head sits right on the collar.
        // Turning slides the stripes, collar and crest.
        let torso = roundedPolygon([CGPoint(x: -build.shoulders, y: build.torsoTop), CGPoint(x: build.shoulders, y: build.torsoTop),
                                    CGPoint(x: build.waist, y: build.torsoBottom), CGPoint(x: -build.waist, y: build.torsoBottom)], r: 18)
        paint(up, torso, Ink.top)
        if flat == nil {
            var chest = up
            chest.clip(to: torso)
            for x in [-24.0, -5.0, 14.0] {
                chest.fill(Path(CGRect(x: x + 5 * yaw, y: build.torsoTop, width: 10, height: build.torsoBottom - build.torsoTop)),
                           with: .color(Ink.topShade))
            }
            chest.fill(pill(cx: 4 * yaw, cy: build.torsoTop + 3, w: 30, h: 10), with: .color(Ink.topShade))
            chest.fill(Path(ellipseIn: CGRect(x: 13 + 7 * yaw, y: 60, width: 12, height: 12)), with: .color(Ink.white))
        }

        // Head, tilting where it meets the collar. Turning slides the face one way and the ears the
        // other; the far ear tucks behind the head.
        var h = up
        h.translateBy(x: 0, y: 56)
        h.rotate(by: .degrees(pose.head))
        h.translateBy(x: 0, y: -56)
        for side in [-1.0, 1.0] {
            paint(h, Path(ellipseIn: CGRect(x: side * 50 - 9 * yaw - 11, y: -9, width: 22, height: 22)), Ink.skin)
        }
        paint(h, tomb(cx: 0, top: -66, w: 100, h: 122, r: 26), Ink.skin)
        if flat == nil { drawFace(h, yaw: yaw) }
        // Hair: a cap down to above the ears and one quiff. The cap is ONE outline (an upside-down U
        // around the face), never a shape with a hole cut in it: any cutout edge that lands on
        // another edge leaves an anti-aliased hairline, here straight across the eyes.
        paint(h, hairCap(window: -39 + 9 * yaw), Ink.hair)
        let q = 5 * yaw
        paint(h, roundedTriangle(CGPoint(x: -30 + q, y: -70), CGPoint(x: 34 + q, y: -104), CGPoint(x: 48 + q, y: -58), r: 12), Ink.hair)
    }

    private func drawFace(_ h: GraphicsContext, yaw: Double) {
        // The lower lid rises a little to meet the upper one, so the eye closes nearer its middle.
        let lid = track(t, Self.lid)
        let face = Choreo(period: Self.loopMs, lookX: [Key(0, 5 * yaw + flow(t, Act.lookX))], lookY: [Key(0, flow(t, Act.lookY))],
                          lid: [Key(0, lid)], cheek: [Key(0, max(track(t, Self.cheek), 0.18 * lid))], mouth: Self.mouth)
        let dx = 10 * yaw
        for side in [-1.0, 1.0] {
            h.fill(pill(cx: side * 19.5 + dx, cy: -8, w: 30, h: 40), with: .color(Ink.white))
            drawLiveEye(h, side: side,
                        eye: EyeGeometry(cx: side * 19.5 + dx, cy: -8, w: 30, h: 40, pupilW: 13, pupilH: 20, pupilTop: 7, shine: 2.8),
                        ink: Self.ink, choreo: face, t: t)
        }
        // The nose sticks out, so it slides a little further than the eyes.
        let nx = 13 * yaw
        h.fill(pill(cx: 2 + nx, cy: -2, w: 8, h: 22), with: .color(Ink.feature))
        h.fill(Path(ellipseIn: CGRect(x: -4.5 + nx, y: 2.5, width: 13, height: 13)), with: .color(Ink.feature))
        drawLiveMouth(h, x0: -16 + dx, x1: 18 + dx, top: 24, tilt: 6, mouth: Ink.mouth, tongue: Ink.tongue, teeth: Ink.white,
                      choreo: face, t: t)
    }

    // MARK: - The style's shapes

    /// A tombstone: a half-circle top, straight sides, bottom corners of radius r.
    /// When h <= w/2 it is a cap: an arc cut flat at the bottom.
    private func tomb(cx: Double, top: Double, w: Double, h: Double, r: Double) -> Path {
        let R = w / 2, yb = top + h
        var p = Path()
        if h <= R {
            let half = (R * R - (R - h) * (R - h)).squareRoot()
            let a = asin((R - h) / R)
            p.move(to: CGPoint(x: cx - half, y: yb))
            p.addArc(center: CGPoint(x: cx, y: top + R), radius: R, startAngle: .radians(.pi + a), endAngle: .radians(-a), clockwise: false)
            p.closeSubpath()
            return p
        }
        let q = min(r, R, h - R)
        p.move(to: CGPoint(x: cx - R, y: top + R))
        p.addArc(center: CGPoint(x: cx, y: top + R), radius: R, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: cx + R, y: yb - q))
        p.addQuadCurve(to: CGPoint(x: cx + R - q, y: yb), control: CGPoint(x: cx + R, y: yb))
        p.addLine(to: CGPoint(x: cx - R + q, y: yb))
        p.addQuadCurve(to: CGPoint(x: cx - R, y: yb - q), control: CGPoint(x: cx - R, y: yb))
        p.closeSubpath()
        return p
    }

    /// The hair cap as one outline: a half-circle top, sideburns down to above the ears, and the
    /// face's opening (rounded at the top) starting at `window` and 78 wide.
    private func hairCap(window x0: Double) -> Path {
        let R = 55.0, cy = -19.0, bottom = -10.0, q = 8.0, top = -42.0, w = 78.0, r = 18.0
        var p = Path()
        p.move(to: CGPoint(x: -R, y: cy))
        p.addArc(center: CGPoint(x: 0, y: cy), radius: R, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: R, y: bottom - q))
        p.addQuadCurve(to: CGPoint(x: R - q, y: bottom), control: CGPoint(x: R, y: bottom))
        p.addLine(to: CGPoint(x: x0 + w, y: bottom))
        p.addLine(to: CGPoint(x: x0 + w, y: top + r))
        p.addQuadCurve(to: CGPoint(x: x0 + w - r, y: top), control: CGPoint(x: x0 + w, y: top))
        p.addLine(to: CGPoint(x: x0 + r, y: top))
        p.addQuadCurve(to: CGPoint(x: x0, y: top + r), control: CGPoint(x: x0, y: top))
        p.addLine(to: CGPoint(x: x0, y: bottom))
        p.addLine(to: CGPoint(x: -R + q, y: bottom))
        p.addQuadCurve(to: CGPoint(x: -R, y: bottom - q), control: CGPoint(x: -R, y: bottom))
        p.closeSubpath()
        return p
    }

    /// A rectangle with only its top corners rounded.
    private func topRound(x: Double, y: Double, w: Double, h: Double, r: Double) -> Path {
        let q = min(r, w / 2, h)
        var p = Path()
        p.move(to: CGPoint(x: x, y: y + h))
        p.addLine(to: CGPoint(x: x, y: y + q))
        p.addQuadCurve(to: CGPoint(x: x + q, y: y), control: CGPoint(x: x, y: y))
        p.addLine(to: CGPoint(x: x + w - q, y: y))
        p.addQuadCurve(to: CGPoint(x: x + w, y: y + q), control: CGPoint(x: x + w, y: y))
        p.addLine(to: CGPoint(x: x + w, y: y + h))
        p.closeSubpath()
        return p
    }

    /// The rounded triangle with corners a, b, c and corner radius r.
    private func roundedTriangle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint, r: Double) -> Path {
        roundedPolygon([a, b, c], r: r)
    }

    /// A polygon with every corner rounded (radius r).
    private func roundedPolygon(_ pts: [CGPoint], r: Double) -> Path {
        let n = pts.count
        var p = Path()
        for i in 0..<n {
            let pt = pts[i], prev = pts[(i + n - 1) % n], next = pts[(i + 1) % n]
            func toward(_ q: CGPoint) -> CGPoint {
                let dx = q.x - pt.x, dy = q.y - pt.y, l = max(0.001, (dx * dx + dy * dy).squareRoot())
                return CGPoint(x: pt.x + dx / l * r, y: pt.y + dy / l * r)
            }
            let s = toward(prev), e = toward(next)
            if i == 0 { p.move(to: s) } else { p.addLine(to: s) }
            p.addQuadCurve(to: e, control: pt)
        }
        p.closeSubpath()
        return p
    }

    /// A soft four-point star centred on (0, 0).
    private func fourPointStar(r: CGFloat) -> Path {
        var p = Path()
        let w = r * 0.32
        p.move(to: CGPoint(x: 0, y: -r))
        p.addQuadCurve(to: CGPoint(x: r, y: 0), control: CGPoint(x: w, y: -w))
        p.addQuadCurve(to: CGPoint(x: 0, y: r), control: CGPoint(x: w, y: w))
        p.addQuadCurve(to: CGPoint(x: -r, y: 0), control: CGPoint(x: -w, y: w))
        p.addQuadCurve(to: CGPoint(x: 0, y: -r), control: CGPoint(x: -w, y: -w))
        return p
    }
}
