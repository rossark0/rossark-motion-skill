// GardenScene.swift: a small garden, and a second demo of SKILL.md section 5 (acting).
// A girl waters a sprout. It grows in steps that flow into each other: the stem stretches, the
// leaves unfurl one after another, a bud swells and the flower opens petal by petal. A butterfly
// wanders in, her eyes follow it, it lands on the flower, and she grins and hops. When it flies
// off, the petals drift down one by one and the plant settles back into the sprout. One clock, a
// 10-second loop. Every acting channel is a `flow` of key poses plus idle life plus
// follow-through, so nothing ever freezes. Render it at 60 fps.
//
// The girl is drawn in the same flat style as the kid in RevealScene: a 100-wide tombstone head
// centred on (0, 0) with y growing down, pill eyes with no brows, capsule arms whose shoulders
// hide behind the torso, circle hands, flat colours with at most one shade.
import SwiftUI

struct GardenScene: View {
    let t: Double
    /// Taller than the scene (a phone screen): the stage stays put, the sky and the meadow fill the rest.
    var height = 720.0
    /// Where the 720-tall stage starts inside that height; centred when nil.
    var stageTop: Double? = nil
    private var top: Double { stageTop ?? (height - Self.size.height) / 2 }
    static let size = CGSize(width: 720, height: 720)
    static let loopMs = 10000.0

    private enum Ink {
        static let skyTop = Color(hex: 0xA9E4FF)
        static let skyLow = Color(hex: 0xE8F8FF)
        static let cloud = Color.white
        static let hillFar = Color(hex: 0xD6F0BF)
        static let hillNear = Color(hex: 0xC9EBAE)
        static let ground = Color(hex: 0xE3F6D1)
        static let shadow = Color(hex: 0xCDEAB4)
        static let grass = Color(hex: 0x9CD481)
        static let skin = Color(hex: 0xD9966E)
        static let feature = Color(hex: 0xA65E3E)
        static let freckle = Color(hex: 0xBF7853)
        static let hair = Color(hex: 0x2B2433)
        static let shirt = Color(hex: 0xFF7A6B)
        static let stripe = Color(hex: 0xFFD2CB)
        static let denim = Color(hex: 0x4A90E2)
        static let denimShade = Color(hex: 0x3A78C2)
        static let button = Color(hex: 0xFFD84D)
        static let boot = Color(hex: 0x37AD74)
        static let bootRim = Color(hex: 0x5CC892)
        static let sole = Color(hex: 0x23704B)
        static let hat = Color(hex: 0xFFC6D3)
        static let brim = Color(hex: 0xF7AFC2)
        static let band = Color(hex: 0xFF7A6B)
        static let daisyEye = Color(hex: 0xFFD84D)
        static let can = Color(hex: 0x3BB8C7)
        static let canShade = Color(hex: 0x2B9AA9)
        static let pot = Color(hex: 0xE57F5E)
        static let potShade = Color(hex: 0xCC6849)
        static let potRim = Color(hex: 0xF29676)
        static let soilDry: UInt32 = 0x8A6552
        static let soilWet: UInt32 = 0x573C30
        static let stem = Color(hex: 0x5CB862)
        static let leaf = Color(hex: 0x6CCB72)
        static let vein = Color(hex: 0x4EA756)
        static let petal = Color(hex: 0xC9A3FF)
        static let petalShade = Color(hex: 0xB283F7)
        static let center = Color(hex: 0xFFCF4A)
        static let sparkle = Color(hex: 0xFFD84D)
        static let wing = Color(hex: 0xFFA24C)
        static let wingEdge = Color(hex: 0x3B3452)
        static let heart = Color(hex: 0xFF7A9A)
        static let water = Color(hex: 0x6EC3FF)
        static let white = Color.white
        static let pupil = Color(hex: 0x3C3C3C)
        static let mouth = Color(hex: 0xB03A3A)
        static let tongue = Color(hex: 0xF15A5A)
    }

    // MARK: - Tokens

    /// Where the girl's feet stand, and girl units (head = 100 wide) to stage points.
    private let feet = CGPoint(x: 285, y: 620)
    private let girlScale = 1.32
    /// The same toy-like build as the kid, seen from a little above.
    private let build = (torsoTop: 50.0, torsoBottom: 112.0, shoulders: 42.0, waist: 38.0, hip: 22.0, hipY: 132.0,
                        shoeBottom: 62.0, shadow: 140.0, shadowRatio: 0.32, shadowUp: 7.0)
    private var floorY: Double { build.hipY + build.shoeBottom }
    private let arm = (x: 34.0, y: 66.0, w: 26.0, hand: 13.0, upper: 30.0, fore: 28.0, reach: 12.0)
    /// The happy hop's height (stage units).
    private let jump = 26.0
    /// The beats of the loop, in ms.
    private let beat = (pour: 1900.0, pourEnd: 2820.0, bud: 4850.0, bloom: 5300.0, enter: 5700.0, land: 6900.0,
                        hop: 7150.0, hopEnd: 7490.0, takeoff: 7900.0, gone: 9100.0, wilt: 9000.0)
    /// The pot: centre, bottom, the rim line, the body's widths at the top and the bottom, and the lip.
    private let pot = (x: 470.0, base: 636.0, rim: 546.0, top: 106.0, bottom: 80.0, lip: 122.0)
    private var soilY: Double { pot.rim + 2 }
    /// The plant: the sprout's height and the full stem's, where the true leaves grow (stem
    /// units from the soil), when each one unfurls and when it folds away again (top one first).
    private let plant = (sprout: 18.0, full: 176.0, leaves: [52.0, 92.0, 128.0],
                         unfurl: [3550.0, 4200.0, 4500.0], fold: [9330.0, 9175.0, 9030.0])
    /// The watering can in its own frame, where the hand grips the top of the handle at (0, 0):
    /// the spout runs from the body's lower front up and out to the rose.
    private let can = (spoutFrom: CGPoint(x: 20, y: 40), spoutTip: CGPoint(x: 58, y: 4))
    /// Water: drops leave the rose every `every` ms, at `speed` units a second, under `g`.
    private let water = (every: 45.0, speed: 70.0, g: 1300.0)

    private static let ink = FaceInk(white: .white, pupil: Ink.pupil, skin: Ink.skin, line: Ink.feature, lineWidth: 5)
    /// Blinks land on the head turns.
    private static let lid = blinks([900, 3500, 6150, 8950])
    private static let cheek: Keys = [Key(0, 0), Key(6950, 0), Key(7050, 1, out: true), Key(7700, 1), Key(7880, 0), Key(loopMs, 0)]
    /// The open mouth: a small smile at rest, pursed while pouring, a "wow" at the bloom, the grin.
    private static let mouth: Keys = [
        Key(0, 11), Key(1500, 11), Key(1800, 8), Key(2850, 8), Key(3200, 12), Key(5200, 12), Key(5400, 24, out: true),
        Key(5900, 20), Key(6200, 13), Key(6950, 11), Key(7050, 22, out: true), Key(7700, 22), Key(7900, 14), Key(9600, 11),
        Key(loopMs, 11),
    ]

    private static func blinks(_ at: [Double]) -> Keys {
        var keys = [Key(0, 0)]
        // Close in 110 ms, hold 40, reopen in 190 with ease-out.
        for b in at { keys += [Key(b, 0), Key(b + 110, 1), Key(b + 150, 1), Key(b + 340, 0, out: true)] }
        return keys + [Key(loopMs, 0)]
    }

    var body: some View {
        Canvas { ctx, _ in
            drawLand(ctx)
            var stage = ctx
            stage.translateBy(x: 0, y: top)
            drawPot(stage)
            drawPlant(stage)
            drawGirlOnStage(stage)
            drawWater(stage)
            drawSparkles(stage)
            drawFallingPetals(stage)
            drawButterfly(stage)
            drawHearts(stage)
        }
        .frame(width: Self.size.width, height: height)
    }

    // MARK: - Acting: smooth channels through key poses, plus idle life and follow-through

    /// One arm: `a` the upper arm's outward angle (0 hangs down), `e` the elbow bend.
    private struct Arm { var a = 12.0, e = 0.0 }

    private struct Pose {
        var lift = 0.0, sx = 1.0, sy = 1.0, lean = 0.0
        var shift = 0.0, yaw = 0.0, head = 0.0
        var armL = Arm(), armR = Arm()
        var legL = 3.0, legR = 3.0
        /// The can's tilt in degrees; positive pours.
        var tilt = 0.0
        /// Follow-through for the pigtails and the hat: how far the head turned in the last moment
        /// (degrees), and how far it dropped (stage units).
        var hairSwing = 0.0, hairUp = 0.0
    }

    /// The key poses: a glance at the sprout, the pour, watching it grow, "wow" at the bloom,
    /// following the butterfly in, the grin and the hop, waving it goodbye, the petals falling.
    private enum Act {
        static let sy: FlowKeys = [(0, 1), (1350, 1), (1500, 0.97), (1650, 1.02), (1800, 1), (7000, 1), (7100, 0.9),
                                   (7180, 1.07), (7420, 1.02), (7500, 0.88), (7600, 1.03), (7730, 1), (10000, 1)]
        static let lean: FlowKeys = [(0, 0), (1250, 0), (1500, -3), (1850, 4), (2850, 4), (3300, 0), (4300, -1), (5300, -3),
                                     (5900, -1), (6400, 2), (6900, 1), (7100, 0), (7650, 0), (8300, -3), (9000, -2), (9600, 0),
                                     (10000, 0)]
        static let shift: FlowKeys = [(0, 0), (1300, 0), (1850, 6), (2850, 6), (3400, 0), (6300, 2), (7000, 0), (8300, -5),
                                      (9300, 0), (10000, 0)]
        static let yaw: FlowKeys = [(0, 0.15), (1300, 0.15), (1850, 0.4), (2850, 0.4), (3400, 0.25), (5600, 0.25), (6000, 0.38),
                                    (6800, 0.4), (7050, 0.08), (7650, 0.05), (8300, -0.3), (9000, -0.25), (9600, 0.15),
                                    (10000, 0.15)]
        static let head: FlowKeys = [(0, 0), (300, 0), (600, 5), (1200, 4), (1500, 0), (1900, 6), (2850, 5), (3400, 2), (4600, -1),
                                     (5300, -4), (5900, -3), (6300, 4), (6800, 6), (7050, 0), (7650, -3), (8300, -6), (9000, -3),
                                     (9600, 0), (10000, 0)]
        /// The eyes: down to the sprout, on the water, up the stem as it grows, on the butterfly
        /// all the way in and all the way out, down to the falling petals.
        static let lookX: FlowKeys = [(0, 0), (300, 0), (550, 3), (1200, 3), (1400, 1), (1800, 3), (5600, 3), (5900, 5),
                                      (6400, 4.5), (6900, 3), (7050, -0.4), (7650, -0.25), (8100, -2), (8600, -5), (9100, -4),
                                      (9350, 1.5), (9700, 0), (10000, 0)]
        static let lookY: FlowKeys = [(0, 1), (300, 1), (550, 5), (1200, 5), (1400, 2), (1800, 5), (3300, 5), (3800, 3),
                                      (4600, 1), (5300, 0), (5600, 0), (5900, -5), (6300, -4), (6800, 0), (6900, 1), (7050, 0),
                                      (7650, 0), (8100, -4), (8700, -7), (9100, -2), (9350, 4), (9700, 2), (10000, 1)]
        /// The right arm carries the can: a small pull back, up and out over the pot, back down.
        static let armRa: FlowKeys = [(0, 16), (1250, 16), (1500, 8), (1900, 92), (2850, 90), (3250, 40), (3600, 16), (7000, 16),
                                      (7150, 20), (7400, 24), (7650, 16), (10000, 16)]
        static let armRe: FlowKeys = [(0, 8), (1250, 8), (1500, 14), (1900, 36), (2850, 36), (3250, 18), (3600, 8), (7000, 8),
                                      (7200, 22), (7650, 8), (10000, 8)]
        /// The free arm: out for balance while pouring, "wow", up in the hop, goodbye.
        static let armLa: FlowKeys = [(0, 12), (1300, 12), (1900, 28), (2850, 26), (3400, 12), (5200, 12), (5450, 48), (5850, 42),
                                      (6200, 12), (7000, 12), (7200, 128), (7500, 120), (7800, 28), (8200, 36), (8400, 104),
                                      (9000, 104), (9350, 14), (10000, 12)]
        static let armLe: FlowKeys = [(0, -4), (1300, -4), (1900, -10), (2850, -10), (3400, -4), (5200, -4), (5450, 70), (5850, 64),
                                      (6200, -4), (7000, -4), (7200, 12), (7500, 18), (7800, 6), (8200, 18), (8400, 80), (9000, 80),
                                      (9350, 0), (10000, -4)]
        /// The can's tilt: a small pull back (anticipation), the pour, back level.
        static let tilt: FlowKeys = [(0, 0), (1300, 0), (1500, -12), (1900, 50), (2850, 48), (3200, 0), (10000, 0)]
        /// The plant, 0 the sprout to 1 full grown: two pushes with a slow stretch between, and
        /// back down once the petals have fallen.
        static let grow: FlowKeys = [(0, 0), (3150, 0), (3700, 0.4), (4000, 0.47), (4600, 0.88), (4900, 1), (9000, 1), (9900, 0),
                                     (10000, 0)]
    }

    private func lift(_ t: Double) -> Double {
        guard t >= beat.hop, t < beat.hopEnd else { return 0 }
        let k = (t - beat.hop) / (beat.hopEnd - beat.hop)
        return jump * 4 * k * (1 - k)
    }

    /// A damped swing after a jolt at `at`: one quick back-and-forth that dies out.
    private func swing(_ t: Double, at: Double, amp: Double, period: Double = 600) -> Double {
        guard t > at else { return 0 }
        let s = t - at
        return amp * sin(2 * .pi * s / period) * exp(-s / (period * 0.5))
    }

    private func pose(_ t: Double) -> Pose {
        var p = Pose()
        p.lift = lift(t)
        // Squash and stretch keep the volume; breathing on top.
        let s = flow(t, Act.sy)
        p.sx = 1 / pow(s, 0.6)
        p.sy = s * (1 + 0.014 * wave(t, period: 2500))
        p.lean = flow(t, Act.lean) + 1.5 * wave(t, period: 5000, phase: 0.2)
        p.shift = 0.6 * flow(t, Act.shift) + 1.2 * wave(t, period: 5000)
        p.yaw = flow(t, Act.yaw) + 0.06 * wave(t, period: 2500, phase: 0.1)
        // The head follows the body a beat later and the other way, on top of its own acting.
        p.head = flow(t, Act.head) - 0.45 * flow(t - 110, Act.lean) + 2 * wave(t, period: 5000, phase: 0.6)
        // Arms: the key poses, a small sway that never stops, and a forearm that trails the upper arm.
        func arm(_ ka: FlowKeys, _ ke: FlowKeys, phase: Double, sway k: Double) -> Arm {
            let sway = 4 * wave(t, period: 2500, phase: phase) + 2 * wave(t, period: 2000, phase: phase + 0.3)
            let trail = 0.45 * (flow(t - 90, ka) - flow(t, ka))
            return Arm(a: flow(t, ka) + sway * k, e: flow(t, ke) + 5 * wave(t, period: 2500, phase: phase + 0.6) * k + trail)
        }
        p.armR = arm(Act.armRa, Act.armRe, phase: 0, sway: 0.5)
        p.armL = arm(Act.armLa, Act.armLe, phase: 0.5, sway: 1)
        p.armL.e += 14 * wave(t, period: 500) * seg(t, 8400, 8550) * (1 - seg(t, 8850, 9000))
        // Legs: splay on the squash; the free leg eases out on the weight shift.
        let splay = max(0, 1 - s) * 50
        p.legR = 3 + splay + max(0, -p.shift) * 0.9
        p.legL = 3 + splay + max(0, p.shift) * 0.9
        // The can hangs from the hand, so it lags it: it swings back when the arm lifts, trembles
        // a little while pouring and swings on the hop.
        let pouring = seg(t, beat.pour, beat.pour + 100) * (1 - seg(t, beat.pourEnd, beat.pourEnd + 100))
        p.tilt = flow(t - 70, Act.tilt) + 0.3 * (flow(t - 150, Act.armRa) - flow(t - 40, Act.armRa))
            + 2.5 * wave(t, period: 500) * pouring + swing(t, at: beat.hop, amp: -10) + swing(t, at: beat.hopEnd, amp: 8)
        return p
    }

    /// The girl's frame on stage: feet, hop, lean, squash, then her own units with the head at (0, 0).
    private func frame(_ p: Pose) -> CGAffineTransform {
        CGAffineTransform(translationX: feet.x, y: feet.y - p.lift)
            .rotated(by: p.lean * .pi / 180)
            .scaledBy(x: p.sx * girlScale, y: p.sy * girlScale)
            .translatedBy(x: 0, y: -floorY)
    }

    /// One arm's elbow and hand (in the upper body's frame), and the forearm's direction.
    private func reach(side: Double, _ limb: Arm) -> (elbow: CGPoint, hand: CGPoint, dir: CGPoint) {
        let a = limb.a * .pi / 180, f = (limb.a + limb.e) * .pi / 180
        let straight = min(1, max(0, 1 - abs(limb.e) / 40))
        let extra = arm.reach * min(1, max(0, (limb.a - 100) / 50)) * straight
        let from = CGPoint(x: side * arm.x, y: arm.y)
        let elbow = CGPoint(x: from.x + side * sin(a) * arm.upper, y: from.y + cos(a) * arm.upper)
        let uf = CGPoint(x: side * sin(f), y: cos(f))
        return (elbow, CGPoint(x: elbow.x + uf.x * (arm.fore + extra), y: elbow.y + uf.y * (arm.fore + extra)), uf)
    }

    /// Where the can's rose is on stage at time `t`, and which way the water leaves it (radians).
    private func rose(_ t: Double) -> (at: CGPoint, dir: Double) {
        let p = pose(t)
        let grip = reach(side: 1, p.armR).hand
        let m = frame(p).translatedBy(x: p.shift, y: 0).translatedBy(x: grip.x, y: grip.y).rotated(by: (p.tilt - p.lean) * .pi / 180)
        let d = atan2(can.spoutTip.y - can.spoutFrom.y, can.spoutTip.x - can.spoutFrom.x)
        return (can.spoutTip.applying(m), d + p.tilt * .pi / 180)
    }

    // MARK: - The land: sky, clouds, hills and a meadow with swaying tufts

    private func drawLand(_ ctx: GraphicsContext) {
        let horizon = top + 490
        ctx.fill(Path(CGRect(x: 0, y: 0, width: Self.size.width, height: height)),
                 with: .linearGradient(Gradient(colors: [Ink.skyTop, Ink.skyLow]), startPoint: .zero, endPoint: CGPoint(x: 0, y: horizon)))
        let clouds: [(x: Double, y: Double, s: Double)] = [(220, 150, 1), (520, 90, 0.8), (640, 230, 0.7), (90, 260, 0.75)]
        for (i, c) in clouds.enumerated() {
            var g = ctx
            g.translateBy(x: c.x + 10 * wave(t, period: Self.loopMs, phase: Double(i) * 0.27), y: top + c.y)
            g.scaleBy(x: c.s, y: c.s)
            for b in [(-30.0, 0.0, 24.0), (0.0, -14.0, 30.0), (32.0, -2.0, 22.0)] {
                g.fill(Path(ellipseIn: CGRect(x: b.0 - b.2, y: b.1 - b.2, width: b.2 * 2, height: b.2 * 2)), with: .color(Ink.cloud))
            }
            g.fill(Path(roundedRect: CGRect(x: -56, y: -4, width: 112, height: 26), cornerRadius: 13), with: .color(Ink.cloud))
        }
        ctx.fill(Path(ellipseIn: CGRect(x: -260, y: horizon - 52, width: 760, height: 150)), with: .color(Ink.hillFar))
        ctx.fill(Path(ellipseIn: CGRect(x: 300, y: horizon - 38, width: 700, height: 130)), with: .color(Ink.hillNear))
        ctx.fill(Path(CGRect(x: 0, y: horizon, width: Self.size.width, height: height - horizon)), with: .color(Ink.ground))
        // Tufts sway around their roots, each on its own phase: nothing in sync.
        let tufts: [(x: Double, y: Double, s: Double, daisy: Bool)] = [
            (196, 522, 0.6, true), (556, 514, 0.55, false), (372, 506, 0.45, false), (176, 702, 1, false),
            (566, 694, 0.9, true), (338, 766, 1.1, false), (470, 806, 0.95, true), (232, 836, 0.9, false),
        ]
        for (i, f) in tufts.enumerated() {
            var g = ctx
            g.translateBy(x: f.x, y: top + f.y)
            g.scaleBy(x: f.s, y: f.s)
            g.rotate(by: .degrees(4 * wave(t, period: 2500, phase: seeded(i, salt: 21)) + 2 * wave(t, period: 1250, phase: seeded(i, salt: 22))))
            for (dx, h, lean) in [(-7.0, 22.0, -18.0), (0.0, 30.0, 4.0), (7.0, 20.0, 22.0)] {
                var blade = g
                blade.translateBy(x: dx, y: 0)
                blade.rotate(by: .degrees(lean))
                blade.fill(roundedTriangle(CGPoint(x: -4, y: 0), CGPoint(x: 4, y: 0), CGPoint(x: 0, y: -h), r: 2), with: .color(Ink.grass))
            }
            if f.daisy {
                var d = g
                d.translateBy(x: 0, y: -34)
                drawDaisy(d, r: 4)
            }
        }
    }

    private func drawDaisy(_ g: GraphicsContext, r: Double) {
        for i in 0..<5 {
            let a = Double(i) / 5 * 2 * .pi - .pi / 2
            g.fill(Path(ellipseIn: CGRect(x: cos(a) * r * 1.2 - r, y: sin(a) * r * 1.2 - r, width: r * 2, height: r * 2)), with: .color(Ink.white))
        }
        g.fill(Path(ellipseIn: CGRect(x: -r * 0.8, y: -r * 0.8, width: r * 1.6, height: r * 1.6)), with: .color(Ink.daisyEye))
    }

    // MARK: - The pot and the soil, which darkens where the water lands and dries again

    private func drawPot(_ ctx: GraphicsContext) {
        let sw = 136.0
        ctx.fill(Path(ellipseIn: CGRect(x: pot.x - sw / 2, y: pot.base - 6 - sw * build.shadowRatio / 2, width: sw, height: sw * build.shadowRatio)),
                 with: .color(Ink.shadow))
        let body = roundedPolygon([CGPoint(x: pot.x - pot.top / 2, y: pot.rim + 8), CGPoint(x: pot.x + pot.top / 2, y: pot.rim + 8),
                                   CGPoint(x: pot.x + pot.bottom / 2, y: pot.base), CGPoint(x: pot.x - pot.bottom / 2, y: pot.base)], r: 10)
        ctx.fill(body, with: .color(Ink.pot))
        var shade = ctx
        shade.clip(to: body)
        shade.fill(Path(CGRect(x: pot.x + pot.top / 2 - 28, y: pot.rim, width: 40, height: pot.base - pot.rim)), with: .color(Ink.potShade))
        // The lip: a band and its top, seen from a little above; the inner wall shows at the back.
        ctx.fill(Path(roundedRect: CGRect(x: pot.x - pot.lip / 2, y: pot.rim, width: pot.lip, height: 22), cornerRadius: 8),
                 with: .color(Ink.potRim))
        ctx.fill(Path(ellipseIn: CGRect(x: pot.x - pot.lip / 2, y: pot.rim - 11, width: pot.lip, height: 22)), with: .color(Ink.potRim))
        ctx.fill(Path(ellipseIn: CGRect(x: pot.x - 55, y: pot.rim - 8, width: 110, height: 16)), with: .color(Ink.potShade))
        let wet = seg(t, beat.pour + 100, beat.pourEnd + 100) * (1 - seg(t, beat.wilt, 9900, easeOut: false))
        ctx.fill(Path(ellipseIn: CGRect(x: pot.x - 50, y: pot.rim - 4, width: 100, height: 12)), with: .color(mix(Ink.soilDry, Ink.soilWet, wet)))
    }

    private func mix(_ a: UInt32, _ b: UInt32, _ k: Double) -> Color {
        func c(_ v: UInt32, _ s: UInt32) -> Double { Double((v >> s) & 0xFF) / 255 }
        return Color(red: c(a, 16) + (c(b, 16) - c(a, 16)) * k, green: c(a, 8) + (c(b, 8) - c(a, 8)) * k,
                     blue: c(a, 0) + (c(b, 0) - c(a, 0)) * k)
    }

    // MARK: - The plant: a stem that bends from the soil, leaves that unfurl, a bud, the flower

    private struct Stem { var base: CGPoint, ctrl: CGPoint, tip: CGPoint, len: Double }

    private func stem(_ t: Double) -> Stem {
        let g = flow(t, Act.grow)
        let len = plant.sprout + (plant.full - plant.sprout) * g
        // It sways from the soil on two waves; the butterfly's landing dips it, its takeoff kicks it.
        let a = (2.5 * wave(t, period: 2500) + 1.5 * wave(t, period: 5000, phase: 0.3)) * (0.4 + 0.6 * g)
            + swing(t, at: beat.land, amp: 5, period: 800) + swing(t, at: beat.takeoff, amp: -7, period: 700)
        let r = a * .pi / 180
        let base = CGPoint(x: pot.x, y: soilY)
        let tip = CGPoint(x: base.x + sin(r) * len, y: base.y - cos(r) * len)
        // The bend: the middle swings less than the tip, and a grown stem curves a little.
        let ctrl = CGPoint(x: base.x + sin(r * 0.35) * len * 0.55 - 6 * g, y: base.y - cos(r * 0.35) * len * 0.55)
        return Stem(base: base, ctrl: ctrl, tip: tip, len: len)
    }

    /// The point `h` up the stem, and the stem's angle there (degrees, 0 straight up).
    private func along(_ s: Stem, _ h: Double) -> (pt: CGPoint, angle: Double) {
        let u = min(1, max(0, h / max(1, s.len))), a = 1 - u
        let pt = CGPoint(x: a * a * s.base.x + 2 * a * u * s.ctrl.x + u * u * s.tip.x,
                         y: a * a * s.base.y + 2 * a * u * s.ctrl.y + u * u * s.tip.y)
        let dx = 2 * a * (s.ctrl.x - s.base.x) + 2 * u * (s.tip.x - s.ctrl.x)
        let dy = 2 * a * (s.ctrl.y - s.base.y) + 2 * u * (s.tip.y - s.ctrl.y)
        return (pt, atan2(dx, -dy) * 180 / .pi)
    }

    private func drawPlant(_ ctx: GraphicsContext) {
        let s = stem(t)
        var path = Path()
        path.move(to: s.base)
        path.addQuadCurve(to: s.tip, control: s.ctrl)
        ctx.stroke(path, with: .color(Ink.stem), style: StrokeStyle(lineWidth: 8, lineCap: .round))
        // The seed leaves stay low on the stem.
        let low = along(s, min(14, s.len - 3))
        for side in [-1.0, 1.0] {
            let sway = 5 * wave(t - 100, period: 2500, phase: side * 0.1)
            drawLeaf(ctx, at: low.pt, angle: low.angle + side * 58 + sway, length: 20, width: 24, vein: false)
        }
        // True leaves unfurl one after another as the stem passes them: they open out from the
        // stem, then widen (unroll); each lags the stem's sway a little more than the one below.
        for (i, h) in plant.leaves.enumerated() {
            let side = i % 2 == 0 ? -1.0 : 1.0
            let fit = min(1, max(0, (s.len - h - 4) / 14))
            let open = seg(t, plant.unfurl[i], plant.unfurl[i] + 520) * (1 - seg(t, plant.fold[i], plant.fold[i] + 300, easeOut: false)) * fit
            guard open > 0.01 else { continue }
            let unroll = seg(t, plant.unfurl[i] + 120, plant.unfurl[i] + 640) * (1 - seg(t, plant.fold[i], plant.fold[i] + 260, easeOut: false))
            let at = along(s, h)
            let lag = 6 * wave(t - 140 * Double(i + 1), period: 2500)
            drawLeaf(ctx, at: at.pt, angle: at.angle + side * (12 + 46 * open) + lag, length: 46 * (0.25 + 0.75 * open),
                     width: 28 * (0.15 + 0.85 * unroll * fit), vein: true)
        }
        drawFlower(ctx, s)
    }

    private func drawLeaf(_ ctx: GraphicsContext, at: CGPoint, angle: Double, length L: Double, width W: Double, vein: Bool) {
        var g = ctx
        g.translateBy(x: at.x, y: at.y)
        g.rotate(by: .degrees(angle))
        var p = Path()
        p.move(to: .zero)
        p.addQuadCurve(to: CGPoint(x: 0, y: -L), control: CGPoint(x: W, y: -L * 0.45))
        p.addQuadCurve(to: .zero, control: CGPoint(x: -W, y: -L * 0.55))
        p.closeSubpath()
        g.fill(p, with: .color(Ink.leaf))
        if vein {
            var v = Path()
            v.move(to: CGPoint(x: 0, y: -3))
            v.addQuadCurve(to: CGPoint(x: 0, y: -L * 0.72), control: CGPoint(x: W * 0.12, y: -L * 0.4))
            g.stroke(v, with: .color(Ink.vein), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        }
    }

    /// Petal i's direction around the flower (degrees, -90 up), back petals first.
    private func petalAngle(_ i: Int) -> Double { -90 + 60 * Double(i) }
    /// When each petal lets go, in a scattered order, after the butterfly takes off.
    private func petalFall(_ i: Int) -> Double { beat.takeoff + 160 * Double([4, 0, 2, 5, 1, 3][i]) }

    private func drawFlower(_ ctx: GraphicsContext, _ s: Stem) {
        let bud = seg(t, beat.bud, beat.bud + 500) * (1 - seg(t, beat.wilt, beat.wilt + 350, easeOut: false))
        guard bud > 0.01 else { return }
        let top = along(s, s.len)
        var f = ctx
        f.translateBy(x: top.pt.x, y: top.pt.y)
        f.rotate(by: .degrees(top.angle))
        // The bud swells, then stays as the green cup under the petals.
        f.fill(roundedTriangle(CGPoint(x: -12 * bud, y: 2), CGPoint(x: 12 * bud, y: 2), CGPoint(x: 0, y: -30 * bud), r: 8 * bud),
               with: .color(Ink.stem))
        var c = f
        c.translateBy(x: 0, y: -14)
        // Petals open one after another: each grows out from the centre with a small twist, and
        // keeps a little flutter of its own.
        for i in [1, 3, 5, 0, 2, 4] where t < petalFall(i) {
            let open = seg(t, beat.bloom + 90 * Double(i), beat.bloom + 90 * Double(i) + 520)
            guard open > 0 else { continue }
            var p = c
            p.rotate(by: .degrees(petalAngle(i) + 25 * (1 - open) + 1.5 * wave(t - 60 * Double(i), period: 1250)))
            let sc = 0.25 + 0.75 * open, d = 2 + 9 * open
            p.fill(Path(ellipseIn: CGRect(x: d, y: -12 * sc, width: 34 * sc, height: 24 * sc)),
                   with: .color(i % 2 == 0 ? Ink.petal : Ink.petalShade))
        }
        let heart = seg(t, beat.bloom - 50, beat.bloom + 350) * (1 - seg(t, beat.wilt, beat.wilt + 350, easeOut: false))
        if heart > 0 {
            c.fill(Path(ellipseIn: CGRect(x: -12 * heart, y: -12 * heart, width: 24 * heart, height: 24 * heart)), with: .color(Ink.center))
        }
    }

    // MARK: - Water: drops leave the rose in arcs, land on the soil and splash

    private func drawWater(_ ctx: GraphicsContext) {
        guard t >= beat.pour, t < beat.pourEnd + 900 else { return }
        var n = 0
        var te = beat.pour
        while te <= beat.pourEnd {
            defer { te += water.every; n += 1 }
            guard t >= te, t < te + 900 else { continue }
            let r = rose(te)
            for j in 0..<2 {
                let i = n * 2 + j
                // Two holes of the rose, a little spread, a little variety in speed.
                let o = (j == 0 ? -4.0 : 4.0) + (seeded(i, salt: 1) - 0.5) * 3
                let x0 = r.at.x - sin(r.dir) * o, y0 = r.at.y + cos(r.dir) * o
                let v = water.speed + 50 * seeded(i, salt: 2)
                let vx = cos(r.dir) * v + (seeded(i, salt: 3) - 0.5) * 24, vy = sin(r.dir) * v
                let land = soilY + 3 * seeded(i, salt: 4)
                let sLand = (-vy + (vy * vy + 2 * water.g * max(0, land - y0)).squareRoot()) / water.g
                let s = (t - te) / 1000
                if s < sLand {
                    var d = ctx
                    d.translateBy(x: x0 + vx * s, y: y0 + vy * s + water.g * s * s / 2)
                    d.rotate(by: .radians(atan2(vy + water.g * s, vx)))
                    d.fill(pill(cx: 0, cy: 0, w: 11, h: 6), with: .color(Ink.water))
                } else if s < sLand + 0.22 {
                    let p = (s - sLand) / 0.22
                    let xl = x0 + vx * sLand
                    for side in [-1.0, 1.0] {
                        let rr = 2.6 * (1 - 0.5 * p)
                        let cx = xl + side * 14 * p, cy = land - 16 * 4 * p * (1 - p)
                        ctx.fill(Path(ellipseIn: CGRect(x: cx - rr, y: cy - rr, width: rr * 2, height: rr * 2)), with: .color(Ink.water))
                    }
                }
            }
        }
    }

    // MARK: - Sparkles when the flower opens

    private func drawSparkles(_ ctx: GraphicsContext) {
        guard t > 5400, t < 6600 else { return }
        let s = stem(t)
        let c = along(s, s.len)
        let center = CGPoint(x: c.pt.x + sin(c.angle * .pi / 180) * 14, y: c.pt.y - cos(c.angle * .pi / 180) * 14)
        for i in 0..<7 {
            let start = 5550 + seeded(i, salt: 13) * 450
            let p = (t - start) / 650
            guard p > 0, p < 1 else { continue }
            let a = Double(i) / 7 * 2 * .pi + seeded(i, salt: 14)
            let r = 46 + 22 * seeded(i, salt: 15) + 16 * easeOut.value(at: p)
            var g = ctx
            g.translateBy(x: center.x + cos(a) * r, y: center.y + sin(a) * r * 0.9)
            g.scaleBy(x: bell(p), y: bell(p))
            g.fill(fourPointStar(r: 12 + 7 * seeded(i, salt: 16)), with: .color(Ink.sparkle))
        }
    }

    // MARK: - Falling petals: each lets go, flutters down with spin and sway, settles and fades

    private func drawFallingPetals(_ ctx: GraphicsContext) {
        for i in 0..<6 {
            let start = petalFall(i)
            let s = (t - start) / 1000
            guard s > 0 else { continue }
            let st = stem(start)
            let top = along(st, st.len)
            let m = CGAffineTransform(translationX: top.pt.x, y: top.pt.y).rotated(by: top.angle * .pi / 180)
                .translatedBy(x: 0, y: -14).rotated(by: petalAngle(i) * .pi / 180)
            let p0 = CGPoint(x: 28, y: 0).applying(m)
            let a0 = top.angle + petalAngle(i)
            let wind = -40 + 30 * seeded(i, salt: 7), phase = seeded(i, salt: 8) * 2 * .pi
            func x(_ s: Double) -> Double { p0.x + wind * s + 18 * (sin(2 * .pi * s / 0.8 + phase) - sin(phase)) }
            // It lands on the soil if it falls over the pot, on the meadow if not.
            let inPot = abs(x(0.8) - pot.x) < 44
            let land = inPot ? soilY + 2 * seeded(i, salt: 9) : 640 + 24 * seeded(i, salt: 9)
            let sLand = (-110 + (110 * 110 + 4 * 150 * max(0, land - p0.y)).squareRoot()) / (2 * 150)
            let sc = min(s, sLand)
            let fade = 1 - seg(t, start + sLand * 1000 + 100, start + sLand * 1000 + 300, easeOut: false)
            guard fade > 0 else { continue }
            var g = ctx
            g.opacity = fade
            g.translateBy(x: x(sc), y: p0.y + 110 * sc + 150 * sc * sc)
            let dir = seeded(i, salt: 10) < 0.5 ? -1.0 : 1.0
            g.rotate(by: .degrees(a0 + dir * 160 * sc + 18 * sin(2 * .pi * sc / 0.8 + phase) - 18 * sin(phase)))
            // Turning over as it falls: the petal's width flips through its edge.
            let flip = 0.3 + 0.7 * abs(cos(.pi * sc / 0.55))
            g.scaleBy(x: 1, y: flip)
            g.fill(Path(ellipseIn: CGRect(x: -17, y: -12, width: 34, height: 24)), with: .color(i % 2 == 0 ? Ink.petal : Ink.petalShade))
        }
    }

    // MARK: - The butterfly: wanders in, perches on the flower, flies off

    private func butterfly(_ t: Double) -> (pos: CGPoint, flying: Double, tilt: Double)? {
        guard t >= beat.enter, t < beat.gone else { return nil }
        let s = stem(t)
        let top = along(s, s.len)
        let r = top.angle * .pi / 180
        let perch = CGPoint(x: top.pt.x + sin(r) * 16, y: top.pt.y - cos(r) * 16 - 8)
        if t < beat.land {
            // In from beyond the screen's edge, wandering on two waves that die out at the perch.
            let k = (t - beat.enter) / (beat.land - beat.enter)
            let from = CGPoint(x: 700, y: 210)
            let x = from.x + (perch.x - from.x) * easeOut.value(at: k) + 26 * wave(t, period: 1250) * bell(k)
            let y = from.y + (perch.y - from.y) * easeInOut.value(at: k) + 30 * wave(t, period: 625, phase: 0.25) * bell(k)
            return (CGPoint(x: x, y: y), 1 - seg(t, beat.land - 160, beat.land + 40), -8 + 8 * wave(t, period: 1250, phase: 0.2))
        }
        if t < beat.takeoff { return (perch, 0, top.angle * 0.6) }
        // Off: up first, then away to the left, speeding up.
        let k = (t - beat.takeoff) / (beat.gone - beat.takeoff)
        let to = CGPoint(x: 90, y: 60)
        let x = perch.x + (to.x - perch.x) * pow(k, 1.6) + 20 * wave(t, period: 1250, phase: 0.4) * bell(k)
        let y = perch.y + (to.y - perch.y) * easeOut.value(at: k) + 24 * wave(t, period: 625) * bell(k)
        return (CGPoint(x: x, y: y), seg(t, beat.takeoff, beat.takeoff + 80), -18 + 8 * wave(t, period: 1250))
    }

    private func drawButterfly(_ ctx: GraphicsContext) {
        guard let b = butterfly(t) else { return }
        // Fast flaps in the air, slow open-and-close while it sits.
        let fast = 0.12 + 0.88 * (0.5 + 0.5 * wave(t, period: 200))
        let slow = 0.55 + 0.45 * (0.5 + 0.5 * wave(t, period: 1250))
        let open = b.flying * fast + (1 - b.flying) * slow
        var g = ctx
        g.translateBy(x: b.pos.x, y: b.pos.y)
        g.rotate(by: .degrees(b.tilt))
        for side in [-1.0, 1.0] {
            var w = g
            w.scaleBy(x: side * open, y: 1)
            w.fill(Path(ellipseIn: CGRect(x: 1, y: -25, width: 30, height: 27)), with: .color(Ink.wingEdge))
            w.fill(Path(ellipseIn: CGRect(x: 3, y: -21, width: 23, height: 20)), with: .color(Ink.wing))
            w.fill(Path(ellipseIn: CGRect(x: 1, y: -3, width: 21, height: 20)), with: .color(Ink.wingEdge))
            w.fill(Path(ellipseIn: CGRect(x: 3, y: 0, width: 15, height: 14)), with: .color(Ink.wing))
            for d in [(26.0, -17.0, 2.4), (28.5, -9.0, 1.8)] {
                w.fill(Path(ellipseIn: CGRect(x: d.0 - d.2, y: d.1 - d.2, width: d.2 * 2, height: d.2 * 2)), with: .color(Ink.white))
            }
        }
        g.fill(pill(cx: 0, cy: -2, w: 7, h: 26), with: .color(Ink.wingEdge))
        g.fill(Path(ellipseIn: CGRect(x: -4.5, y: -21, width: 9, height: 9)), with: .color(Ink.wingEdge))
        for side in [-1.0, 1.0] {
            var a = Path()
            a.move(to: CGPoint(x: side * 1.5, y: -19))
            a.addQuadCurve(to: CGPoint(x: side * 9, y: -31), control: CGPoint(x: side * 2, y: -29))
            g.stroke(a, with: .color(Ink.wingEdge), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
            g.fill(Path(ellipseIn: CGRect(x: side * 9 - 2, y: -33, width: 4, height: 4)), with: .color(Ink.wingEdge))
        }
    }

    // MARK: - Hearts on the grin

    private func drawHearts(_ ctx: GraphicsContext) {
        let spots: [(dx: Double, start: Double)] = [(-74, 7080), (8, 7220), (78, 7360)]
        let base = CGPoint(x: feet.x, y: feet.y - (floorY + 104) * girlScale)
        for (i, h) in spots.enumerated() {
            let p = (t - h.start) / 900
            guard p > 0, p < 1 else { continue }
            var g = ctx
            g.translateBy(x: base.x + h.dx + 6 * wave(t, period: 1000, phase: Double(i) * 0.3), y: base.y - 56 * easeOut.value(at: p))
            let sc = bell(p) * (0.85 + 0.3 * seeded(i, salt: 11))
            g.scaleBy(x: sc, y: sc)
            g.rotate(by: .degrees(-12 + 24 * seeded(i, salt: 12)))
            g.fill(heartShape(r: 11), with: .color(Ink.heart))
        }
    }

    // MARK: - The girl on stage

    private func drawGirlOnStage(_ ctx: GraphicsContext) {
        var p = pose(t)
        let past = pose(t - 140)
        p.hairSwing = (past.head + past.lean) - (p.head + p.lean)
        p.hairUp = lift(t - 90) - p.lift
        let ground = 1 - min(1, p.lift / 250)
        let sw = build.shadow * girlScale * ground * p.sx
        ctx.fill(Path(ellipseIn: CGRect(x: feet.x + p.shift * 0.4 * girlScale - sw / 2,
                                        y: feet.y - build.shadowUp * girlScale - sw * build.shadowRatio / 2,
                                        width: sw, height: sw * build.shadowRatio)), with: .color(Ink.shadow))
        var g = ctx
        g.concatenate(frame(p))
        drawGirl(g, pose: p)
    }

    // MARK: - The girl, in the head frame

    private func drawGirl(_ c: GraphicsContext, pose: Pose) {
        func capsules(_ g: GraphicsContext, _ pts: [CGPoint], _ w: Double, _ color: Color) {
            var p = Path()
            p.addLines(pts)
            g.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round))
        }
        let yaw = pose.yaw

        // Short legs in rain boots: a round dark sole, the boot's shaft and a lighter rim.
        for (side, angle) in [(-1.0, pose.legL), (1.0, pose.legR)] {
            var leg = c
            leg.translateBy(x: side * build.hip + pose.shift, y: build.hipY)
            leg.rotate(by: .degrees(-side * angle + pose.shift))
            leg.fill(Path(roundedRect: CGRect(x: -15 + side * 2, y: 42, width: 30, height: 20), cornerRadius: 10), with: .color(Ink.sole))
            capsules(leg, [.zero, CGPoint(x: 0, y: 24)], 20, Ink.skin)
            leg.fill(Path(roundedRect: CGRect(x: -13, y: 14, width: 26, height: 37), cornerRadius: 9), with: .color(Ink.boot))
            leg.fill(Path(roundedRect: CGRect(x: -14, y: 12, width: 28, height: 9), cornerRadius: 4.5), with: .color(Ink.bootRim))
        }

        var up = c
        up.translateBy(x: pose.shift, y: 0)
        up.fill(Path(roundedRect: CGRect(x: -40, y: 104, width: 80, height: 34), cornerRadius: 12), with: .color(Ink.denim))

        // Arms behind the torso: upper arm and forearm share one round elbow, a circle hand, a sleeve.
        for (side, limb) in [(-1.0, pose.armL), (1.0, pose.armR)] {
            let r = reach(side: side, limb)
            let from = CGPoint(x: side * arm.x, y: arm.y)
            capsules(up, [from, r.elbow, CGPoint(x: r.hand.x - r.dir.x * 8, y: r.hand.y - r.dir.y * 8)], arm.w, Ink.skin)
            up.fill(Path(ellipseIn: CGRect(x: r.hand.x - arm.hand, y: r.hand.y - arm.hand, width: arm.hand * 2, height: arm.hand * 2)),
                    with: .color(Ink.skin))
            let a = limb.a * .pi / 180
            capsules(up, [from, CGPoint(x: from.x + side * sin(a) * 16, y: from.y + cos(a) * 16)], arm.w + 10, Ink.shirt)
        }
        // The can hangs in front of the arm that carries it, and the hand closes over its handle.
        let grip = reach(side: 1, pose.armR).hand
        drawCan(up, grip: grip, angle: pose.tilt - pose.lean)
        up.fill(Path(ellipseIn: CGRect(x: grip.x - arm.hand, y: grip.y - arm.hand, width: arm.hand * 2, height: arm.hand * 2)),
                with: .color(Ink.skin))

        // A striped shirt under dungarees: the bib and its straps slide when she turns.
        let torso = roundedPolygon([CGPoint(x: -build.shoulders, y: build.torsoTop), CGPoint(x: build.shoulders, y: build.torsoTop),
                                    CGPoint(x: build.waist, y: build.torsoBottom), CGPoint(x: -build.waist, y: build.torsoBottom)], r: 18)
        up.fill(torso, with: .color(Ink.shirt))
        var chest = up
        chest.clip(to: torso)
        for y in [62.0, 80.0, 98.0] {
            chest.fill(Path(CGRect(x: -50, y: y, width: 100, height: 6)), with: .color(Ink.stripe))
        }
        let bx = 6 * yaw
        var straps = Path()
        straps.move(to: CGPoint(x: bx - 17, y: 84))
        straps.addLine(to: CGPoint(x: -27 + 3 * yaw, y: 46))
        straps.move(to: CGPoint(x: bx + 17, y: 84))
        straps.addLine(to: CGPoint(x: 27 + 3 * yaw, y: 46))
        chest.stroke(straps, with: .color(Ink.denim), lineWidth: 9)
        chest.fill(Path(roundedRect: CGRect(x: bx - 24, y: 78, width: 48, height: 40), cornerRadius: 10), with: .color(Ink.denim))
        chest.fill(Path(roundedRect: CGRect(x: bx - 11, y: 89, width: 22, height: 14), cornerRadius: 4), with: .color(Ink.denimShade))
        for side in [-1.0, 1.0] {
            chest.fill(Path(ellipseIn: CGRect(x: bx + side * 16 - 3.6, y: 81.4, width: 7.2, height: 7.2)), with: .color(Ink.button))
        }

        // Head, tilting where it meets the collar. Pigtails behind it, the bob and the hat on top.
        var h = up
        h.translateBy(x: 0, y: 56)
        h.rotate(by: .degrees(pose.head))
        h.translateBy(x: 0, y: -56)
        drawPigtails(h, pose: pose)
        h.fill(tomb(cx: 0, top: -66, w: 100, h: 122, r: 26), with: .color(Ink.skin))
        drawFace(h, yaw: yaw)
        // The bob is ONE outline around the face (no cutout), so no hairline can land on the eyes.
        h.fill(hairBob(window: -40 + 9 * yaw), with: .color(Ink.hair))
        for side in [-1.0, 1.0] {
            h.fill(pill(cx: side * 52 - 6 * yaw, cy: 22, w: 12, h: 10), with: .color(Ink.band))
        }
        drawHat(h, pose: pose)
    }

    /// Pigtails hang from the ties and trail the head: they swing when it turns, fly up a little
    /// when she drops and settle with a small swing when she lands.
    private func drawPigtails(_ h: GraphicsContext, pose: Pose) {
        let drop = max(-12, min(20, pose.hairUp))
        for side in [-1.0, 1.0] {
            var g = h
            g.translateBy(x: side * 50 - 6 * pose.yaw, y: 20)
            let out = 24 + 1.1 * drop + 3 * wave(t, period: 2500, phase: side * 0.15) + swing(t, at: beat.hopEnd, amp: 10)
            g.rotate(by: .degrees(-side * out + 0.9 * pose.hairSwing))
            g.fill(Path(ellipseIn: CGRect(x: -14, y: -2, width: 28, height: 38)), with: .color(Ink.hair))
        }
    }

    /// A sun hat: the brim seen from a little above, the crown sitting on its back half, a band
    /// with a daisy. It trails the head's turns and lifts a little when she drops.
    private func drawHat(_ h: GraphicsContext, pose: Pose) {
        var g = h
        g.translateBy(x: 0, y: -62 - 0.35 * max(0, pose.hairUp))
        g.rotate(by: .degrees(0.4 * pose.hairSwing))
        let dx = 3 * pose.yaw
        g.fill(Path(ellipseIn: CGRect(x: -82 + 2 * dx, y: -15, width: 164, height: 30)), with: .color(Ink.brim))
        g.fill(tomb(cx: 1.5 * dx, top: -50, w: 96, h: 46, r: 0), with: .color(Ink.hat))
        g.fill(pill(cx: 1.5 * dx, cy: -9, w: 96, h: 12), with: .color(Ink.band))
        var d = g
        d.translateBy(x: 26 + 3 * dx, y: -10)
        d.rotate(by: .degrees(3 * wave(t, period: 2500, phase: 0.4)))
        drawDaisy(d, r: 4.6)
    }

    /// The watering can, hanging from the grip (the top of its handle), tilted by `angle`.
    private func drawCan(_ c: GraphicsContext, grip: CGPoint, angle: Double) {
        var g = c
        g.translateBy(x: grip.x, y: grip.y)
        g.rotate(by: .degrees(angle))
        var spout = Path()
        spout.move(to: can.spoutFrom)
        spout.addLine(to: can.spoutTip)
        g.stroke(spout, with: .color(Ink.canShade), style: StrokeStyle(lineWidth: 9, lineCap: .round))
        var rose = g
        rose.translateBy(x: can.spoutTip.x, y: can.spoutTip.y)
        rose.rotate(by: .radians(atan2(can.spoutTip.y - can.spoutFrom.y, can.spoutTip.x - can.spoutFrom.x)))
        rose.fill(Path(roundedRect: CGRect(x: -2, y: -10, width: 9, height: 20), cornerRadius: 4.5), with: .color(Ink.can))
        var handle = Path()
        handle.move(to: CGPoint(x: -20, y: 18))
        handle.addQuadCurve(to: CGPoint(x: 18, y: 16), control: CGPoint(x: -2, y: -16))
        g.stroke(handle, with: .color(Ink.canShade), style: StrokeStyle(lineWidth: 7, lineCap: .round))
        let body = Path(roundedRect: CGRect(x: -24, y: 14, width: 48, height: 38), cornerRadius: 10)
        g.fill(body, with: .color(Ink.can))
        var shade = g
        shade.clip(to: body)
        shade.fill(Path(CGRect(x: 10, y: 14, width: 20, height: 40)), with: .color(Ink.canShade))
        g.fill(Path(roundedRect: CGRect(x: -26, y: 12, width: 52, height: 8), cornerRadius: 4), with: .color(Ink.canShade))
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
            // Freckles ride on the cheeks.
            for f in [(26.0, 15.0), (21.0, 19.0), (31.0, 20.0)] {
                h.fill(Path(ellipseIn: CGRect(x: side * f.0 + dx - 1.9, y: f.1 - 1.9, width: 3.8, height: 3.8)), with: .color(Ink.freckle))
            }
        }
        let nx = 13 * yaw
        h.fill(pill(cx: 2 + nx, cy: -2, w: 8, h: 20), with: .color(Ink.feature))
        h.fill(Path(ellipseIn: CGRect(x: -4.5 + nx, y: 2, width: 13, height: 13)), with: .color(Ink.feature))
        drawLiveMouth(h, x0: -15 + dx, x1: 17 + dx, top: 25, tilt: 5, mouth: Ink.mouth, tongue: Ink.tongue, teeth: Ink.white,
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

    /// The bob as one outline: a half-circle top, sides down to the jaw, and the face's opening
    /// starting at `window`, 80 wide, its top edge swept lower on the left like a fringe.
    private func hairBob(window x0: Double) -> Path {
        let R = 55.0, cy = -19.0, bottom = 26.0, q = 14.0, w = 80.0, r = 16.0, topL = -31.0, topR = -38.0
        var p = Path()
        p.move(to: CGPoint(x: -R, y: cy))
        p.addArc(center: CGPoint(x: 0, y: cy), radius: R, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: R, y: bottom - q))
        p.addQuadCurve(to: CGPoint(x: R - q, y: bottom), control: CGPoint(x: R, y: bottom))
        p.addLine(to: CGPoint(x: x0 + w, y: bottom))
        p.addLine(to: CGPoint(x: x0 + w, y: topR + r))
        p.addQuadCurve(to: CGPoint(x: x0 + w - r, y: topR), control: CGPoint(x: x0 + w, y: topR))
        p.addQuadCurve(to: CGPoint(x: x0 + r, y: topL), control: CGPoint(x: x0 + w * 0.42, y: topR + 7))
        p.addQuadCurve(to: CGPoint(x: x0, y: topL + r), control: CGPoint(x: x0, y: topL))
        p.addLine(to: CGPoint(x: x0, y: bottom))
        p.addLine(to: CGPoint(x: -R + q, y: bottom))
        p.addQuadCurve(to: CGPoint(x: -R, y: bottom - q), control: CGPoint(x: -R, y: bottom))
        p.closeSubpath()
        return p
    }

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

    private func heartShape(r: Double) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: r * 0.9))
        p.addCurve(to: CGPoint(x: -r, y: -r * 0.2), control1: CGPoint(x: -r * 0.3, y: r * 0.55), control2: CGPoint(x: -r, y: r * 0.3))
        p.addCurve(to: CGPoint(x: 0, y: -r * 0.45), control1: CGPoint(x: -r, y: -r * 0.85), control2: CGPoint(x: -r * 0.15, y: -r * 0.9))
        p.addCurve(to: CGPoint(x: r, y: -r * 0.2), control1: CGPoint(x: r * 0.15, y: -r * 0.9), control2: CGPoint(x: r, y: -r * 0.85))
        p.addCurve(to: CGPoint(x: 0, y: r * 0.9), control1: CGPoint(x: r, y: r * 0.3), control2: CGPoint(x: r * 0.3, y: r * 0.55))
        p.closeSubpath()
        return p
    }
}
