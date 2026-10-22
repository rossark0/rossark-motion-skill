// ChefScene.swift: a chef flips a pancake, twice. The first flip is clean: the pan dips, flicks,
// the pancake turns over in the air and lands with a puff of steam, and he gives a proud little
// nod. The second goes too high: it sails past his eyes, lands on his hat, wobbles there, slides
// off and drops into the pan he raises to catch it. A relieved grin and a shrug. One clock, a
// 9.6-second loop. Every acting channel is a `flow` of key poses plus idle life plus
// follow-through; the pancake is a prop with real contact (it leaves and lands exactly where the
// pan or the hat is at that moment), and the eyes track it. Render it at 60 fps.
//
// The chef uses the same shapes as the kid in RevealScene: a 100-wide tombstone head centred on
// (0, 0) with y growing down, pill eyes, capsule arms whose shoulders hide behind the torso,
// circle hands, flat colours with at most one shade. He stands behind a stove, so the counter
// hides his legs.
import SwiftUI

struct ChefScene: View {
    let t: Double
    /// Taller than the scene (a phone screen): the wall fills the top, the stove the bottom.
    var height = 720.0
    /// Where the 720-tall stage starts inside that height; centred when nil.
    var stageTop: Double? = nil
    private var top: Double { stageTop ?? (height - Self.size.height) / 2 }
    static let size = CGSize(width: 720, height: 720)
    static let loopMs = 9600.0

    private enum Ink {
        static let wall = Color(hex: 0xFFE7BF)
        static let tile = Color(hex: 0xF6D6A2)
        static let wood = Color(hex: 0xD99A5B)
        static let woodDark = Color(hex: 0xBF7F45)
        static let steel = Color(hex: 0xAEB8C4)
        static let steelDark = Color(hex: 0x8C98A6)
        static let jar = Color(hex: 0xDDF1F4)
        static let flour = Color.white
        static let pasta = Color(hex: 0xF7C548)
        static let lidRed = Color(hex: 0xF0645A)
        static let lidBlue = Color(hex: 0x5FB0E8)
        static let leaf = Color(hex: 0x58C27D)
        static let pot = Color(hex: 0xE58A55)
        static let counterTop = Color(hex: 0xF3C27E)
        static let counterLip = Color(hex: 0xE2A862)
        static let stove = Color(hex: 0x33B2A6)
        static let stoveDark = Color(hex: 0x27978D)
        static let knob = Color(hex: 0xFFF3DC)
        static let glass = Color(hex: 0x1F5E5A)
        static let glow = Color(hex: 0xE9893B)
        static let glowCore = Color(hex: 0xF8B55A)
        static let ring = Color(hex: 0x34343D)
        static let ringIn = Color(hex: 0x4A4A55)
        static let flame = Color(hex: 0x4E9EFF)
        static let flameCore = Color(hex: 0xBFE3FF)
        static let pan = Color(hex: 0x3A3F4B)
        static let panSide = Color(hex: 0x2A2E37)
        static let panIn = Color(hex: 0x4D5464)
        static let grip = Color(hex: 0xB8743E)
        static let cakeA = Color(hex: 0xF8CB69)
        static let cakeB = Color(hex: 0xDE9440)
        static let cakeBIn = Color(hex: 0xEDAE58)
        static let cakeEdge = Color(hex: 0xC97F34)
        static let bubble = Color(hex: 0xFCE09A)
        static let steam = Color(hex: 0xE4EBF2)
        static let skin = Color(hex: 0xF2B994)
        static let feature = Color(hex: 0xD27E58)
        static let blush = Color(hex: 0xF79A86)
        static let hair = Color(hex: 0x5B3A28)
        static let white = Color.white
        static let shade = Color(hex: 0xE3E8EE)
        static let button = Color(hex: 0xC9D2DC)
        static let scarf = Color(hex: 0xFF5A4E)
        static let scarfDark = Color(hex: 0xE5443A)
        static let pen = Color(hex: 0x4F8FE8)
        static let pupil = Color(hex: 0x3C3C3C)
        static let mouth = Color(hex: 0xB03A3A)
        static let tongue = Color(hex: 0xF15A5A)
    }

    // MARK: - Tokens

    /// The chef's head centre on stage, and chef units (head = 100 wide) to stage points.
    private let anchor = CGPoint(x: 360, y: 300)
    private let chefScale = 1.45
    /// The build, seen from a little above: a big head right on the collar, a short torso narrower
    /// than the head. The body leans around the waist, which the counter hides.
    private let build = (torsoTop: 50.0, torsoBottom: 112.0, shoulders: 42.0, waist: 38.0, waistY: 112.0)
    /// Arms: shoulder (inside the torso), sleeve thickness, hand radius, upper arm and forearm
    /// (similar lengths, one shared round elbow).
    private let arm = (x: 36.0, y: 66.0, sleeve: 24.0, hand: 14.0, upper: 30.0, lower: 28.0)
    /// The counter's top seen from above (back and front edge, stage y) and the burner on it.
    private let counter = (back: 440.0, front: 478.0, lip: 10.0)
    private let burner = (x: 355.0, y: 462.0, w: 100.0, h: 30.0)
    /// The pan (stage units): rim radius, how flat the floor makes it look from above, the depth
    /// of its wall, and where the hand holds the handle (from the pan's centre).
    private let pan = (r: 58.0, ratio: 0.34, wall: 10.0, grip: CGPoint(x: 105, y: -4), handleW: 13.0)
    /// The pancake: radius, the camera's tilt (a flat disc shows sin(tilt) of its height), thickness.
    private let cake = (r: 40.0, tilt: asin(0.34), thick: 7.0)
    /// The beats of the loop, in ms: the two tosses, the landings, the slide off the hat.
    private let beat = (toss1: 2100.0, catch1: 2930.0, toss2: 4900.0, onHat: 5700.0, slide: 6500.0, drop: 6750.0,
                        catch2: 7250.0)
    /// Gravity for the pancake, stage units a second squared.
    private let gravity = 2450.0

    private static let ink = FaceInk(white: .white, pupil: Ink.pupil, skin: Ink.skin, line: Ink.feature, lineWidth: 5)
    /// Butter blinks on the turns, plus a flinch when the pancake hits the hat and a focused squint
    /// before the big toss.
    private static let lid: Keys = {
        func blink(_ b: Double) -> Keys { [Key(b, 0), Key(b + 110, 1), Key(b + 150, 1), Key(b + 340, 0, out: true)] }
        var keys = [Key(0, 0)] + blink(900) + blink(3150)
        keys += [Key(4550, 0), Key(4700, 0.28), Key(4880, 0.28), Key(5050, 0, out: true)]
        keys += [Key(5700, 0), Key(5770, 0.85), Key(5830, 0.85), Key(6010, 0, out: true)]
        return keys + blink(6250) + blink(8800) + [Key(loopMs, 0)]
    }()
    /// A smug half-squint after the first flip, the full happy squint after the catch.
    private static let cheek: Keys = [Key(0, 0), Key(3130, 0), Key(3290, 0.42, out: true), Key(3650, 0.42), Key(3850, 0),
                                      Key(7330, 0), Key(7470, 1, out: true), Key(8100, 1), Key(8300, 0), Key(loopMs, 0)]
    /// The open mouth's depth: a small smile at rest, a grin, an "O" of surprise, a big relieved grin.
    private static let mouth: Keys = [
        Key(0, 8), Key(1900, 6), Key(2150, 12), Key(2830, 10), Key(3130, 10), Key(3290, 18, out: true), Key(3650, 16),
        Key(3950, 8), Key(4600, 5), Key(4950, 10), Key(5200, 12), Key(5400, 20, out: true), Key(5700, 20), Key(5770, 12),
        Key(6000, 14), Key(6400, 10), Key(6600, 18), Key(7250, 16), Key(7420, 24, out: true), Key(8100, 22), Key(8400, 9),
        Key(loopMs, 8),
    ]

    var body: some View {
        Canvas { ctx, _ in
            ctx.fill(Path(CGRect(x: 0, y: 0, width: Self.size.width, height: height)), with: .color(Ink.wall))
            var stage = ctx
            stage.translateBy(x: 0, y: top)
            drawKitchen(stage)
            let p = pose(t)
            drawChef(stage, p)
            drawCounter(stage)
            drawBurner(stage)
            let c = cakeState(t)
            drawPan(stage)
            if c.mode == .pan { drawCake(stage, c) }
            drawHands(stage, p)
            if c.mode != .pan { drawCake(stage, c) }
            drawSteam(stage)
        }
        .frame(width: Self.size.width, height: height)
    }

    // MARK: - Acting: smooth channels through key poses, plus idle life and follow-through

    /// One arm: `a` the upper arm's outward angle (0 hangs down), `e` the elbow bend
    /// (the forearm points at a + e; positive folds it up and out, negative in toward the body).
    private struct Arm { var a = 20.0, e = 0.0 }

    private struct Pose {
        var lift = 0.0, sx = 1.0, sy = 1.0, lean = 0.0, shift = 0.0, yaw = 0.0
        /// Head: tilt in degrees and a bob down (positive) in chef units.
        var head = 0.0, headDy = 0.0
        var browL = 0.0, browR = 0.0, widen = 0.0, mouthW = 28.0
        var armL = Arm()
        /// The hat: its squash and its tilt, both on top of the head.
        var hatSy = 1.0, hatTilt = 0.0
    }

    /// The key poses. The pan leads the right arm (the hand follows the handle); the left arm,
    /// body and face act around it.
    private enum Act {
        // Body: dips before each toss (knees bending behind the counter), rises with it, ducks
        // when the pancake hits the hat, bounces with relief.
        static let lift: FlowKeys = [(0, 0), (1700, 0), (1950, -9), (2050, -6), (2110, 4), (2250, 2), (2830, 0), (2930, -5),
                                     (3080, 0), (3230, 1), (3430, 0), (4400, 0), (4750, -12), (4850, -9), (4920, 6),
                                     (5100, 3), (5600, 0), (5700, 0), (5780, -7), (5950, 0), (6500, 0), (6750, -2),
                                     (7250, -6), (7450, 6), (7650, 0), (7850, 3), (8050, 0), (9600, 0)]
        static let sy: FlowKeys = [(0, 1), (1700, 1), (1950, 0.96), (2110, 1.04), (2300, 1), (4400, 1), (4750, 0.95),
                                   (4920, 1.05), (5150, 1), (5700, 1), (5780, 0.95), (5950, 1), (7100, 1), (7250, 0.96),
                                   (7450, 1.03), (7650, 1), (9600, 1)]
        static let lean: FlowKeys = [(0, 0), (1700, 0), (1950, -3), (2110, 2), (2450, -1), (2930, 1), (3130, -2), (3430, 0),
                                     (4400, 0), (4750, -4), (4920, 3), (5300, -2), (5700, 1), (6000, 0), (6500, 0),
                                     (6900, 3), (7250, 5), (7500, -2), (8000, 2), (8400, 0), (9600, 0)]
        static let shift: FlowKeys = [(0, 0), (1600, 0), (2100, 2), (2930, -2), (3430, 0), (4500, -3), (5000, 3), (5700, 0),
                                      (6800, 4), (7250, 7), (7800, 0), (9600, 0)]
        static let yaw: FlowKeys = [(0, 0.12), (1700, 0.12), (2100, 0.04), (3030, 0.08), (3230, -0.06), (3700, -0.06),
                                    (3950, 0.12), (4800, 0.12), (5000, 0), (6000, 0), (6250, -0.06), (6450, 0), (7000, 0.18),
                                    (7300, 0.12), (7450, -0.08), (8100, -0.08), (8500, 0.12), (9600, 0.12)]
        static let head: FlowKeys = [(0, 0), (1700, 0), (2000, -2), (2450, -5), (2930, 2), (3180, 6), (3500, 5), (3800, 0),
                                     (4600, -2), (5000, -3), (5700, 3), (5900, -2), (6250, -6), (6500, -3), (7250, 3),
                                     (7500, 8), (8100, 6), (8500, 0), (9600, 0)]
        /// The proud nod (down, up, down a little), and the duck when the pancake lands on the hat.
        static let headDy: FlowKeys = [(0, 0), (3080, 0), (3210, 4), (3360, -1), (3510, 2.5), (3730, 0), (5700, 0),
                                       (5770, 5), (6000, 1), (6400, 0), (9600, 0)]
        /// Where he looks: 1 at the pancake, 0 at the viewer.
        static let attention: FlowKeys = [(0, 1), (3030, 1), (3180, 0), (3750, 0), (3950, 1), (5950, 1), (6150, 0),
                                          (6450, 0), (6520, 1), (7300, 1), (7450, 0), (8400, 0), (8700, 1), (9600, 1)]
        /// Surprise opens the eyes wider; the brows go up, or down and in to focus.
        static let widen: FlowKeys = [(0, 0), (5150, 0), (5350, 1), (5700, 1), (5770, 0.2), (5950, 0.8), (6400, 0.6),
                                      (6550, 1), (7250, 0.8), (7400, 0), (9600, 0)]
        static let brow: FlowKeys = [(0, 0), (1700, 0), (1950, -0.5), (2150, 0.2), (3030, 0), (4400, 0), (4750, -0.8),
                                     (4950, 0), (5200, 0.2), (5350, 1), (5700, 1), (5770, 0.3), (5950, 0.8), (6400, 0.6),
                                     (6550, 1), (7250, 0.9), (7450, 0.6), (8100, 0.4), (8500, 0), (9600, 0)]
        /// One brow up after the first flip: smug.
        static let smug: FlowKeys = [(0, 0), (3080, 0), (3230, 0.9), (3600, 0.8), (3850, 0), (9600, 0)]
        static let mouthW: FlowKeys = [(0, 28), (2100, 28), (2200, 22), (2830, 24), (3130, 30), (3650, 32), (3950, 28),
                                       (5200, 26), (5400, 16), (5700, 16), (5770, 22), (6000, 18), (6400, 20), (6600, 15),
                                       (7250, 16), (7420, 34), (8100, 34), (8400, 28), (9600, 28)]
        /// The free arm: resting on the counter, out for balance on each toss, a little "voila"
        /// after the first, up by the face in surprise, out for the catch, a palm-up shrug.
        static let armLa: FlowKeys = [(0, 35), (1700, 35), (1950, 45), (2100, 62), (2450, 55), (2930, 48), (3130, 45),
                                      (3650, 45), (3950, 35), (4400, 35), (4750, 50), (4920, 78), (5200, 70), (5350, 150),
                                      (5700, 150), (5770, 160), (6000, 150), (6400, 140), (6600, 80), (7000, 62),
                                      (7250, 70), (7450, 30), (8100, 30), (8400, 35), (9600, 35)]
        static let armLe: FlowKeys = [(0, -25), (1700, -25), (1950, -10), (2100, 20), (2450, 25), (2930, 15), (3130, 40),
                                      (3290, 95), (3650, 90), (3950, -25), (4400, -25), (4750, -5), (4920, 30), (5200, 25),
                                      (5350, 15), (5700, 15), (5770, 25), (6000, 15), (6400, 20), (6600, 15), (7000, 10),
                                      (7250, 10), (7450, 75), (8100, 75), (8400, -20), (9600, -25)]
        /// The pan, in stage points: rests over the burner, dips and flicks for each toss, waits under
        /// the falling pancake, absorbs the catch, reaches up and right for the one that fell off the hat.
        static let panX: FlowKeys = [(0, 355), (1700, 355), (1950, 350), (2050, 352), (2130, 356), (2400, 358), (2930, 358),
                                     (3130, 356), (3330, 355), (4400, 355), (4750, 350), (4850, 352), (4930, 356),
                                     (5300, 357), (5700, 356), (6400, 356), (6800, 370), (7250, 378), (7500, 375),
                                     (8300, 360), (8800, 355), (9600, 355)]
        static let panY: FlowKeys = [(0, 432), (1700, 432), (1950, 437), (2050, 434), (2130, 402), (2400, 396), (2750, 402),
                                     (2930, 410), (3030, 424), (3180, 428), (3330, 420), (3600, 424), (3850, 432),
                                     (4400, 432), (4750, 437), (4850, 434), (4930, 378), (5200, 385), (5600, 410),
                                     (6400, 415), (6800, 400), (7100, 390), (7250, 395), (7400, 412), (7700, 420),
                                     (8300, 428), (8800, 432), (9600, 432)]
        static let panRoll: FlowKeys = [(0, 0), (1700, 0), (1950, -6), (2050, -4), (2100, 10), (2250, 4), (2930, 0),
                                        (2980, -4), (3130, 0), (4600, 0), (4750, -9), (4850, -6), (4900, 14), (5100, 5),
                                        (5600, 0), (7100, -3), (7250, 0), (7300, -6), (7500, 0), (9600, 0)]
    }

    private func pose(_ t: Double) -> Pose {
        var p = Pose()
        // Breathing, a slow sway of the weight and a head that drifts: never a frozen frame.
        let s = flow(t, Act.sy)
        p.sy = s * (1 + 0.012 * wave(t, period: 2400))
        p.sx = 1 / pow(s, 0.6)
        p.lift = flow(t, Act.lift) + 1.2 * wave(t, period: 2400, phase: 0.25)
        p.lean = flow(t, Act.lean) + 1.2 * wave(t, period: 4800, phase: 0.2)
        p.shift = flow(t, Act.shift) + 1.5 * wave(t, period: 4800)
        p.yaw = flow(t, Act.yaw) + 0.05 * wave(t, period: 3200, phase: 0.1)
        // The head rights itself a beat after the body leans, on top of its own acting.
        p.head = flow(t, Act.head) - 0.45 * flow(t - 110, Act.lean) + 1.8 * wave(t, period: 4800, phase: 0.6)
        p.headDy = flow(t, Act.headDy)
        let brow = flow(t, Act.brow) + 0.08 * wave(t, period: 3200, phase: 0.4)
        p.browL = brow
        p.browR = brow + flow(t, Act.smug) + 0.06 * wave(t, period: 2400, phase: 0.1)
        p.widen = flow(t, Act.widen)
        p.mouthW = flow(t, Act.mouthW)
        // The free arm: key poses, a small sway that never stops, a forearm that trails the upper
        // arm, and a little bounce in the palm-up shrug.
        let a = flow(t, Act.armLa) + 3 * wave(t, period: 3200, phase: 0.5) + 2 * wave(t, period: 1920, phase: 0.8)
        let trail = 0.45 * (flow(t - 90, Act.armLa) - flow(t, Act.armLa))
        let shrug = 6 * wave(t, period: 600) * seg(t, 7450, 7600) * (1 - seg(t, 7950, 8100))
        p.armL = Arm(a: a, e: flow(t, Act.armLe) + 4 * wave(t, period: 2400, phase: 0.1) + trail + shrug)
        // The hat follows the head a beat late, squashes and wobbles when the pancake lands on it,
        // sags a little under its weight, leans as it slides off and springs back when it leaves.
        p.hatTilt = 0.5 * (flow(t - 120, Act.head) - flow(t, Act.head))
        let carrying = seg(t, beat.onHat, beat.onHat + 120) * (1 - seg(t, beat.drop, beat.drop + 100))
        var squash = 0.03 * carrying
        let d = (t - beat.onHat) / 1000
        if d > 0, d < 0.9 {
            squash += 0.14 * exp(-5 * d) * cos(2 * .pi * 3.2 * d)
            p.hatTilt += 6 * exp(-4 * d) * sin(2 * .pi * 2.4 * d)
        }
        p.hatTilt += 4 * seg(t, beat.slide, beat.drop) * (1 - seg(t, beat.drop, beat.drop + 150))
        let d2 = (t - beat.drop) / 1000
        if d2 > 0, d2 < 0.8 { p.hatTilt -= 4 * exp(-5 * d2) * sin(2 * .pi * 2.4 * d2) }
        p.hatSy = 1 - squash
        return p
    }

    // MARK: - Transforms (shared by drawing and by the prop's contact points)

    /// Stage from chef units: the body leans and squashes around the waist.
    private func bodyM(_ p: Pose) -> CGAffineTransform {
        CGAffineTransform.identity
            .translatedBy(x: anchor.x, y: anchor.y + build.waistY * chefScale - p.lift)
            .rotated(by: p.lean * .pi / 180)
            .scaledBy(x: chefScale * p.sx, y: chefScale * p.sy)
            .translatedBy(x: 0, y: -build.waistY)
    }

    /// Chef units from the head's frame: tilts where it meets the collar, bobs for the nod.
    private func headM(_ p: Pose) -> CGAffineTransform {
        CGAffineTransform.identity
            .translatedBy(x: p.shift, y: 56 + p.headDy)
            .rotated(by: p.head * .pi / 180)
            .translatedBy(x: 0, y: -56)
    }

    /// The head's frame from the hat's: it squashes and tilts on the band's bottom edge.
    private func hatM(_ p: Pose) -> CGAffineTransform {
        CGAffineTransform.identity
            .translatedBy(x: 0, y: -44)
            .rotated(by: p.hatTilt * .pi / 180)
            .scaledBy(x: 1 / pow(p.hatSy, 0.6), y: p.hatSy)
            .translatedBy(x: 0, y: 44)
    }

    private func panState(_ t: Double) -> (c: CGPoint, roll: Double) {
        // Shaking the pan at the start: quick little slides that the pancake trails.
        let shake = 4 * wave(t, period: 400) * seg(t, 250, 450) * (1 - seg(t, 1300, 1500))
        let x = flow(t, Act.panX) + shake + 1.2 * wave(t, period: 3200, phase: 0.3)
        let y = flow(t, Act.panY) + 1.0 * wave(t, period: 2400, phase: 0.5)
        return (CGPoint(x: x, y: y), flow(t, Act.panRoll) + 1.5 * wave(t, period: 1920, phase: 0.2))
    }

    private func rotate(_ v: CGPoint, _ deg: Double) -> CGPoint {
        let r = deg * .pi / 180
        return CGPoint(x: v.x * cos(r) - v.y * sin(r), y: v.x * sin(r) + v.y * cos(r))
    }

    // MARK: - The pancake: in the pan, in the air, on the hat

    private enum CakeMode { case pan, air, hat }
    private struct Cake {
        var p: CGPoint
        /// The flip around its horizontal axis (0: the pale side up, π: the brown side up).
        var theta: Double
        var rot: Double
        var squash: Double
        var mode: CakeMode
    }

    /// Where the pancake sits in the pan: it trails the pan when the pan moves (it slides).
    private func inPan(_ t: Double) -> (p: CGPoint, roll: Double) {
        let now = panState(t), before = panState(t - 90)
        let slide = max(-10, min(10, 0.6 * (before.c.x - now.c.x)))
        let o = rotate(CGPoint(x: slide, y: -3), now.roll)
        return (CGPoint(x: now.c.x + o.x, y: now.c.y + o.y), now.roll)
    }

    /// The top of the hat on stage, where the pancake sits, and the angle it sits at.
    private func onHat(_ t: Double, along: Double = 0) -> (p: CGPoint, rot: Double) {
        let p = pose(t)
        let m = hatM(p).concatenating(headM(p)).concatenating(bodyM(p))
        let pt = CGPoint(x: along, y: -178).applying(m)
        return (pt, p.hatTilt + p.head + p.lean)
    }

    private func cakeState(_ t: Double) -> Cake {
        // Squashes for a moment on each landing.
        var squash = 0.0
        for land in [beat.catch1, beat.onHat, beat.catch2] where t >= land && t < land + 140 {
            squash = 1 - seg(t, land, land + 140)
        }
        if t >= beat.toss1 && t < beat.catch1 {
            // A clean half flip: a throw from where the pan was to where the pan is, under gravity.
            let a = inPan(beat.toss1).p, b = inPan(beat.catch1).p
            let T = (beat.catch1 - beat.toss1) / 1000, s = (t - beat.toss1) / (beat.catch1 - beat.toss1)
            let h = gravity * T * T / 8
            let p = CGPoint(x: a.x + (b.x - a.x) * s, y: a.y + (b.y - a.y) * s - 4 * h * s * (1 - s))
            return Cake(p: p, theta: .pi * s, rot: 8 * sin(.pi * s), squash: 0, mode: .air)
        }
        if t >= beat.toss2 && t < beat.onHat {
            // Too much: a full flip, past his eyes, onto the top of the hat.
            let a = inPan(beat.toss2).p, b = onHat(beat.onHat).p
            let T = (beat.onHat - beat.toss2) / 1000, s = (t - beat.toss2) / (beat.onHat - beat.toss2)
            let h = gravity * T * T / 8
            let p = CGPoint(x: a.x + (b.x - a.x) * s, y: a.y + (b.y - a.y) * s - 4 * h * s * (1 - s))
            return Cake(p: p, theta: .pi + 2 * .pi * s, rot: -10 * sin(.pi * s), squash: 0, mode: .air)
        }
        if t >= beat.onHat && t < beat.drop {
            // On the hat: it rides the hat's wobble a moment late, then slides forward and right,
            // tipping toward us.
            let slide = seg(t, beat.slide, beat.drop, easeOut: false)
            let hat = onHat(t, along: 14 * slide)
            let lag = onHat(t - 80).rot - hat.rot
            return Cake(p: hat.p, theta: 3 * .pi + 0.5 * slide, rot: hat.rot + 0.6 * lag + 14 * slide, squash: squash,
                        mode: .hat)
        }
        if t >= beat.drop && t < beat.catch2 {
            // Off the hat: it falls from rest (no upward arc), turning the last half over, into the
            // pan that came up to meet it.
            let a = onHat(beat.drop, along: 14).p, b = inPan(beat.catch2).p
            let s = (t - beat.drop) / (beat.catch2 - beat.drop)
            let p = CGPoint(x: a.x + (b.x - a.x) * s, y: a.y + (b.y - a.y) * s * s)
            return Cake(p: p, theta: 3 * .pi + 0.5 + (.pi - 0.5) * s, rot: 14 * (1 - s), squash: 0, mode: .air)
        }
        let rest = inPan(t)
        let flipped = t >= beat.catch1 && t < beat.toss2
        return Cake(p: rest.p, theta: flipped ? .pi : 0, rot: rest.roll, squash: squash, mode: .pan)
    }

    // MARK: - The kitchen: tiles, hanging utensils that sway, a shelf with a plant

    private func drawKitchen(_ ctx: GraphicsContext) {
        // A band of tiles behind the stove.
        for row in 0..<3 {
            for col in 0..<12 {
                let x = Double(col) * 40 + (row % 2 == 0 ? 0 : 20) + 120, y = 322 + Double(row) * 40
                ctx.fill(Path(roundedRect: CGRect(x: x, y: y, width: 36, height: 36), cornerRadius: 6), with: .color(Ink.tile))
            }
        }
        // A rail with three utensils on hooks. Each swings around its hook on its own period; the
        // long ones swing slower.
        ctx.fill(pill(cx: 236, cy: 70, w: 64, h: 10), with: .color(Ink.woodDark))
        let hooks: [(x: Double, period: Double, amp: Double)] = [(222, 4800, 4), (250, 2400, 6)]
        for (i, hk) in hooks.enumerated() {
            var u = ctx
            u.translateBy(x: hk.x, y: 72)
            u.rotate(by: .degrees(hk.amp * wave(t, period: hk.period, phase: seeded(i, salt: 3))))
            u.stroke(Path(ellipseIn: CGRect(x: -5, y: -4, width: 10, height: 12)), with: .color(Ink.steelDark), lineWidth: 3)
            switch i {
            case 0:  // ladle
                u.fill(pill(cx: 0, cy: 52, w: 9, h: 96), with: .color(Ink.steel))
                u.fill(Path(ellipseIn: CGRect(x: -17, y: 92, width: 34, height: 26)), with: .color(Ink.steelDark))
            case 2:  // whisk
                u.fill(pill(cx: 0, cy: 36, w: 10, h: 54), with: .color(Ink.wood))
                for w in [10.0, 18, 26] {
                    u.stroke(Path(ellipseIn: CGRect(x: -w / 2, y: 58, width: w, height: 52)), with: .color(Ink.steel), lineWidth: 3)
                }
            default:  // spatula
                u.fill(pill(cx: 0, cy: 40, w: 10, h: 64), with: .color(Ink.wood))
                u.fill(Path(roundedRect: CGRect(x: -15, y: 68, width: 30, height: 40), cornerRadius: 8), with: .color(Ink.woodDark))
            }
        }
        // A shelf with two jars and a plant whose leaves sway, each a beat after the last.
        ctx.fill(Path(roundedRect: CGRect(x: 452, y: 236, width: 100, height: 10), cornerRadius: 5), with: .color(Ink.woodDark))
        let jars: [(x: Double, h: Double, fill: Color, lid: Color)] = [(492, 62, Ink.flour, Ink.lidRed)]
        for j in jars {
            ctx.fill(Path(roundedRect: CGRect(x: j.x, y: 236 - j.h, width: 32, height: j.h), cornerRadius: 9), with: .color(Ink.jar))
            ctx.fill(Path(roundedRect: CGRect(x: j.x + 4, y: 236 - j.h * 0.6, width: 24, height: j.h * 0.6 - 4), cornerRadius: 6),
                     with: .color(j.fill))
            ctx.fill(Path(roundedRect: CGRect(x: j.x - 2, y: 236 - j.h - 8, width: 36, height: 11), cornerRadius: 5), with: .color(j.lid))
        }
        var plant = ctx
        plant.translateBy(x: 470, y: 214)
        for (i, ang) in [-28.0, 0, 26].enumerated() {
            var l = plant
            l.rotate(by: .degrees(ang + 4 * wave(t, period: 3200, phase: 0.15 * Double(i))))
            l.fill(Path(ellipseIn: CGRect(x: -8, y: -42, width: 16, height: 40)), with: .color(Ink.leaf))
        }
        plant.fill(topRound(x: -14, y: -4, w: 28, h: 26, r: 6), with: .color(Ink.pot))
    }

    // MARK: - The chef (behind the counter)

    private func armPoints(_ limb: Arm, side: Double, shift: Double) -> (from: CGPoint, elbow: CGPoint, hand: CGPoint) {
        let a = limb.a * .pi / 180, f = (limb.a + limb.e) * .pi / 180
        let from = CGPoint(x: side * arm.x + shift, y: arm.y)
        let elbow = CGPoint(x: from.x + side * sin(a) * arm.upper, y: from.y + cos(a) * arm.upper)
        let hand = CGPoint(x: elbow.x + side * sin(f) * arm.lower, y: elbow.y + cos(f) * arm.lower)
        return (from, elbow, hand)
    }

    /// The pan arm: the hand goes where the handle is, and the elbow finds its own place (two
    /// segments, elbow out). The prop leads; the arm follows, so the grip never slips.
    private func panArm(_ p: Pose) -> Arm {
        let ps = panState(t)
        let grip = rotate(pan.grip, ps.roll)
        let target = CGPoint(x: ps.c.x + grip.x, y: ps.c.y + grip.y).applying(bodyM(p).inverted())
        let fx = arm.x + p.shift, fy = arm.y
        let dx = target.x - fx, dy = target.y - fy
        let l1 = arm.upper, l2 = arm.lower
        let dist = max(0.001, (dx * dx + dy * dy).squareRoot())
        let d = min(l1 + l2 - 0.5, max(abs(l1 - l2) + 0.5, dist))
        let tx = dx / dist * d, ty = dy / dist * d
        let phi = atan2(tx, ty)
        let alpha = acos(max(-1, min(1, (l1 * l1 + d * d - l2 * l2) / (2 * l1 * d))))
        let a = phi + alpha
        let f = atan2(tx - sin(a) * l1, ty - cos(a) * l1)
        return Arm(a: a * 180 / .pi, e: (f - a) * 180 / .pi)
    }

    private func drawChef(_ ctx: GraphicsContext, _ p: Pose) {
        var c = ctx
        c.concatenate(bodyM(p))
        func capsules(_ g: GraphicsContext, _ pts: [CGPoint], _ w: Double, _ color: Color) {
            var path = Path()
            path.addLines(pts)
            g.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round))
        }
        // Arms behind the torso, so the shoulder never shows: long white sleeves, one round elbow.
        // The forearms and hands are drawn again in front of the counter.
        for (side, limb) in [(-1.0, p.armL), (1.0, panArm(p))] {
            let pts = armPoints(limb, side: side, shift: p.shift)
            capsules(c, [pts.from, pts.elbow, pts.hand], arm.sleeve, Ink.white)
        }
        var up = c
        up.translateBy(x: p.shift, y: 0)
        let yaw = p.yaw
        // The jacket: short, narrowing a little to the waist, double-breasted buttons and a pocket
        // with a pen that slide as he turns.
        let torso = roundedPolygon([CGPoint(x: -build.shoulders, y: build.torsoTop), CGPoint(x: build.shoulders, y: build.torsoTop),
                                    CGPoint(x: build.waist, y: build.torsoBottom), CGPoint(x: -build.waist, y: build.torsoBottom)], r: 18)
        up.fill(torso, with: .color(Ink.white))
        var chest = up
        chest.clip(to: torso)
        for bx in [-11.0, 11.0] {
            for by in [72.0, 88.0] {
                chest.fill(Path(ellipseIn: CGRect(x: bx + 6 * yaw - 3.5, y: by - 3.5, width: 7, height: 7)), with: .color(Ink.button))
            }
        }
        chest.fill(pill(cx: 27 + 7 * yaw, cy: 72, w: 4, h: 14), with: .color(Ink.pen))
        chest.fill(Path(roundedRect: CGRect(x: 18 + 7 * yaw, y: 74, width: 17, height: 14), cornerRadius: 4), with: .color(Ink.shade))
        // The neckerchief's knot peeks out under the chin.
        let kx = 5 * yaw
        up.fill(roundedPolygon([CGPoint(x: kx - 16, y: 52), CGPoint(x: kx + 16, y: 52), CGPoint(x: kx, y: 74)], r: 6), with: .color(Ink.scarf))
        up.fill(Path(ellipseIn: CGRect(x: kx - 7, y: 54, width: 14, height: 12)), with: .color(Ink.scarfDark))

        var h = c
        h.concatenate(headM(p))
        drawHead(h, p)
    }

    private func drawHead(_ h: GraphicsContext, _ p: Pose) {
        let yaw = p.yaw
        let look = gaze(t)
        // Looking up or down slides the face (2.5D pitch), a little behind the eyes.
        let dy = 5 * look.pitch
        for side in [-1.0, 1.0] {
            h.fill(Path(ellipseIn: CGRect(x: side * 50 - 9 * yaw - 11, y: -6 - 3 * look.pitch, width: 22, height: 22)), with: .color(Ink.skin))
        }
        h.fill(tomb(cx: 0, top: -66, w: 100, h: 122, r: 26), with: .color(Ink.skin))
        drawFace(h, p, look: look, dy: dy)
        // The hat: a tall puff and a band, white with one shade. The puff overlaps itself (no edge
        // lands on another), and the band hides the top of the head.
        var hat = h
        hat.concatenate(hatM(p))
        for lobe in [(x: -38.0, y: -102.0, r: 34.0), (x: 38, y: -104, r: 33), (x: 2, y: -132, r: 42)] {
            hat.fill(Path(ellipseIn: CGRect(x: lobe.x - lobe.r, y: lobe.y - lobe.r, width: lobe.r * 2, height: lobe.r * 2)),
                     with: .color(Ink.white))
        }
        hat.fill(Path(CGRect(x: -52, y: -112, width: 104, height: 50)), with: .color(Ink.white))
        hat.fill(pill(cx: -20 + 3 * yaw, cy: -96, w: 7, h: 30), with: .color(Ink.shade))
        hat.fill(pill(cx: 18 + 3 * yaw, cy: -98, w: 7, h: 26), with: .color(Ink.shade))
        hat.fill(Path(roundedRect: CGRect(x: -54, y: -80, width: 108, height: 36), cornerRadius: 12), with: .color(Ink.shade))
    }

    /// Where the eyes look (pupil offset, eye units) and how far the face pitches, from where the
    /// pancake is a moment ago: the eyes track it, the face follows a little later.
    private func gaze(_ t: Double) -> (x: Double, y: Double, pitch: Double) {
        func aim(_ t: Double) -> (x: Double, y: Double) {
            let p = pose(t)
            let eye = CGPoint(x: 0, y: -6).applying(headM(p).concatenating(bodyM(p)))
            let c = cakeState(t).p
            return ((c.x - eye.x) / 22, (c.y - eye.y) / 26)
        }
        let att = flow(t, Act.attention)
        let now = aim(t - 50), late = aim(t - 140)
        let x = max(-6, min(6, now.x)) * att
        let y = max(-7, min(8, now.y)) * att
        let pitch = max(-1, min(1, late.y / 7)) * att
        return (x + 0.6 * wave(t, period: 3200, phase: 0.7) * (1 - att), y, pitch)
    }

    private func drawFace(_ h: GraphicsContext, _ p: Pose, look: (x: Double, y: Double, pitch: Double), dy: Double) {
        let yaw = p.yaw
        let dx = 10 * yaw
        let lid = track(t, Self.lid)
        let face = Choreo(period: Self.loopMs, lookX: [Key(0, look.x + 5 * yaw)], lookY: [Key(0, look.y)],
                          lid: [Key(0, lid)], cheek: [Key(0, max(track(t, Self.cheek), 0.18 * lid))], mouth: Self.mouth)
        // Rosy cheeks, then the eyes: surprise opens them wider and shrinks the pupils.
        for side in [-1.0, 1.0] {
            h.fill(Path(ellipseIn: CGRect(x: side * 31 + dx - 9, y: 10 + dy, width: 18, height: 10)), with: .color(Ink.blush))
        }
        let w = 28 * (1 + 0.1 * p.widen), eh = 36 * (1 + 0.16 * p.widen)
        let pw = 12 * (1 - 0.12 * p.widen), ph = 18 * (1 - 0.12 * p.widen)
        for side in [-1.0, 1.0] {
            let cx = side * 19 + dx, cy = -6 + dy
            h.fill(pill(cx: cx, cy: cy, w: w, h: eh), with: .color(Ink.white))
            drawLiveEye(h, side: side,
                        eye: EyeGeometry(cx: cx, cy: cy, w: w, h: eh, pupilW: pw, pupilH: ph, pupilTop: (eh - ph) / 2 - 1, shine: 2.6),
                        ink: Self.ink, choreo: face, t: t)
        }
        // Brows: up in surprise, down and in to focus.
        for (side, b) in [(-1.0, p.browL), (1.0, p.browR)] {
            var g = h
            g.translateBy(x: side * 20 + dx, y: -33 + dy - 5 * max(0, b) + 2 * max(0, -b) - 0.12 * p.widen * 6)
            g.rotate(by: .degrees(-side * 16 * max(0, -b) + side * 4 * max(0, b)))
            g.fill(pill(cx: 0, cy: 0, w: 22, h: 8), with: .color(Ink.hair))
        }
        // The mouth opens under the mustache; the nose sticks out the most, so it slides the most.
        let depth = track(t, Self.mouth)
        drawLiveMouth(h, x0: -p.mouthW / 2 + dx, x1: p.mouthW / 2 + dx, top: 31 + dy, tilt: 3, mouth: Ink.mouth,
                      tongue: Ink.tongue, teeth: Ink.white, choreo: face, t: t)
        let curl = max(track(t, Self.cheek), 0) - 0.5 * p.widen + 0.15 * wave(t, period: 1920, phase: 0.3)
        h.fill(mustache(cx: 12 * yaw, cy: 22 + dy - 0.12 * depth, curl: curl), with: .color(Ink.hair))
        h.fill(Path(ellipseIn: CGRect(x: 13 * yaw - 10, y: 1 + dy, width: 20, height: 18)), with: .color(Ink.feature))
    }

    /// A bushy mustache in one outline: two lobes from the middle, tips that curl up (curl > 0) or droop.
    private func mustache(cx: Double, cy: Double, curl: Double) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: cx, y: cy - 6))
        for side in [-1.0, 1.0] {
            let tip = CGPoint(x: cx + side * 34, y: cy - 6 - 6 * curl)
            if side < 0 {
                p.addQuadCurve(to: CGPoint(x: cx - 24, y: cy - 5), control: CGPoint(x: cx - 12, y: cy - 12))
                p.addQuadCurve(to: tip, control: CGPoint(x: cx - 32, y: cy - 2))
                p.addQuadCurve(to: CGPoint(x: cx - 14, y: cy + 9), control: CGPoint(x: cx - 32, y: cy + 10))
                p.addQuadCurve(to: CGPoint(x: cx, y: cy + 4), control: CGPoint(x: cx - 6, y: cy + 9))
            } else {
                p.addQuadCurve(to: CGPoint(x: cx + 14, y: cy + 9), control: CGPoint(x: cx + 6, y: cy + 9))
                p.addQuadCurve(to: tip, control: CGPoint(x: cx + 32, y: cy + 10))
                p.addQuadCurve(to: CGPoint(x: cx + 24, y: cy - 5), control: CGPoint(x: cx + 32, y: cy - 2))
                p.addQuadCurve(to: CGPoint(x: cx, y: cy - 6), control: CGPoint(x: cx + 12, y: cy - 12))
            }
        }
        p.closeSubpath()
        return p
    }

    /// The forearms and hands again, in front of the counter and the pan: the right hand closes
    /// over the handle.
    private func drawHands(_ ctx: GraphicsContext, _ p: Pose) {
        var c = ctx
        c.concatenate(bodyM(p))
        for (side, limb) in [(-1.0, p.armL), (1.0, panArm(p))] {
            let pts = armPoints(limb, side: side, shift: p.shift)
            var fore = Path()
            fore.addLines([pts.elbow, pts.hand])
            c.stroke(fore, with: .color(Ink.white), style: StrokeStyle(lineWidth: arm.sleeve, lineCap: .round))
            // A cuff band at the wrist, then the round hand.
            let dx = pts.hand.x - pts.elbow.x, dy = pts.hand.y - pts.elbow.y, l = max(0.001, (dx * dx + dy * dy).squareRoot())
            var cuff = Path()
            cuff.addLines([CGPoint(x: pts.hand.x - dx / l * 13, y: pts.hand.y - dy / l * 13),
                           CGPoint(x: pts.hand.x - dx / l * 7, y: pts.hand.y - dy / l * 7)])
            c.stroke(cuff, with: .color(Ink.shade), style: StrokeStyle(lineWidth: arm.sleeve, lineCap: .butt))
            c.fill(Path(ellipseIn: CGRect(x: pts.hand.x - arm.hand, y: pts.hand.y - arm.hand, width: arm.hand * 2, height: arm.hand * 2)),
                   with: .color(Ink.skin))
        }
    }

    // MARK: - The stove: a butcher-block top, an oven with knobs, a burner with a live flame

    private func drawCounter(_ ctx: GraphicsContext) {
        let bottom = height - top + 10
        ctx.fill(Path(CGRect(x: 0, y: counter.back, width: Self.size.width, height: counter.front - counter.back)),
                 with: .color(Ink.counterTop))
        ctx.fill(Path(CGRect(x: 0, y: counter.front, width: Self.size.width, height: counter.lip)), with: .color(Ink.counterLip))
        ctx.fill(Path(CGRect(x: 0, y: counter.front + counter.lip, width: Self.size.width, height: bottom - counter.front)),
                 with: .color(Ink.stove))
        // Knobs; the burner's own knob turns up the gas for each flip.
        for (i, x) in [282.0, 330, 390, 438].enumerated() {
            ctx.fill(Path(ellipseIn: CGRect(x: x - 9, y: 492, width: 18, height: 18)), with: .color(Ink.knob))
            var k = ctx
            k.translateBy(x: x, y: 501)
            k.rotate(by: .degrees(Double(i) * 50 - 60 + (i == 1 ? 70 * flare(t) : 0)))
            k.fill(pill(cx: 0, cy: -4, w: 3.5, h: 8), with: .color(Ink.stoveDark))
        }
        // The oven door, its handle, and a warm glow in the window that breathes.
        ctx.fill(Path(roundedRect: CGRect(x: 220, y: 514, width: 280, height: 210), cornerRadius: 18), with: .color(Ink.stoveDark))
        ctx.fill(pill(cx: 360, cy: 524, w: 200, h: 8), with: .color(Ink.knob))
        let window = Path(roundedRect: CGRect(x: 250, y: 536, width: 220, height: 130), cornerRadius: 14)
        ctx.fill(window, with: .color(Ink.glass))
        var glow = ctx
        glow.clip(to: window)
        let b = 1 + 0.06 * wave(t, period: 2400, phase: 0.3) + 0.03 * wave(t, period: 1600)
        glow.fill(Path(ellipseIn: CGRect(x: 360 - 92 * b, y: 568 - 30 * b, width: 184 * b, height: 60 * b)), with: .color(Ink.glow))
        glow.fill(Path(ellipseIn: CGRect(x: 360 - 50 * b, y: 570 - 15 * b, width: 100 * b, height: 30 * b)), with: .color(Ink.glowCore))
        ctx.fill(Path(roundedRect: CGRect(x: 266, y: 544, width: 54, height: 9), cornerRadius: 4.5), with: .color(Ink.stove))
    }

    /// 0 to 1: the gas turned up for a flip, and back down after the landing.
    private func flare(_ t: Double) -> Double {
        seg(t, 1750, 2000) * (1 - seg(t, beat.catch1, beat.catch1 + 400))
            + seg(t, 4450, 4750) * (1 - seg(t, 5600, 6000))
    }

    private func drawBurner(_ ctx: GraphicsContext) {
        let b = burner
        ctx.fill(Path(ellipseIn: CGRect(x: b.x - b.w / 2, y: b.y - b.h / 2, width: b.w, height: b.h)), with: .color(Ink.ring))
        ctx.fill(Path(ellipseIn: CGRect(x: b.x - 34, y: b.y - 10, width: 68, height: 20)), with: .color(Ink.ringIn))
        // The flame: petals round the ring, each flickering on two waves of its own.
        for i in 0..<12 {
            let a = Double(i) / 12 * 2 * .pi
            let x = b.x + 40 * cos(a), y = b.y + 11 * sin(a)
            let flick = 1 + 0.18 * wave(t, period: 400, phase: seeded(i, salt: 1)) + 0.12 * wave(t, period: 640, phase: seeded(i, salt: 2))
            let hgt = 15 * flick * (1 + 0.45 * flare(t))
            ctx.fill(petal(x: x, y: y, w: 10, h: hgt), with: .color(Ink.flame))
            ctx.fill(petal(x: x, y: y, w: 5, h: hgt * 0.55), with: .color(Ink.flameCore))
        }
    }

    private func petal(x: Double, y: Double, w: Double, h: Double) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: x, y: y - h))
        p.addQuadCurve(to: CGPoint(x: x + w / 2, y: y - 2), control: CGPoint(x: x + w / 2, y: y - h * 0.4))
        p.addQuadCurve(to: CGPoint(x: x - w / 2, y: y - 2), control: CGPoint(x: x, y: y + w * 0.5))
        p.addQuadCurve(to: CGPoint(x: x, y: y - h), control: CGPoint(x: x - w / 2, y: y - h * 0.4))
        p.closeSubpath()
        return p
    }

    // MARK: - The pan and the pancake

    private func drawPan(_ ctx: GraphicsContext) {
        let ps = panState(t)
        var g = ctx
        g.translateBy(x: ps.c.x, y: ps.c.y)
        g.rotate(by: .degrees(ps.roll))
        let r = pan.r, rh = r * pan.ratio
        // The handle, its wooden grip under the hand.
        var handle = Path()
        handle.addLines([CGPoint(x: r - 6, y: 0), CGPoint(x: pan.grip.x - 30, y: pan.grip.y)])
        g.stroke(handle, with: .color(Ink.pan), style: StrokeStyle(lineWidth: pan.handleW, lineCap: .round))
        var wood = Path()
        wood.addLines([CGPoint(x: pan.grip.x - 32, y: pan.grip.y), CGPoint(x: pan.grip.x + 8, y: pan.grip.y)])
        g.stroke(wood, with: .color(Ink.grip), style: StrokeStyle(lineWidth: pan.handleW + 3, lineCap: .round))
        // The wall below the rim, the rim, the cooking surface.
        g.fill(Path(ellipseIn: CGRect(x: -r, y: pan.wall - rh, width: r * 2, height: rh * 2)), with: .color(Ink.panSide))
        g.fill(Path(CGRect(x: -r, y: 0, width: r * 2, height: pan.wall)), with: .color(Ink.panSide))
        g.fill(Path(ellipseIn: CGRect(x: -r, y: -rh, width: r * 2, height: rh * 2)), with: .color(Ink.pan))
        g.fill(Path(ellipseIn: CGRect(x: -r + 6, y: -rh + 4, width: r * 2 - 12, height: rh * 2 - 6)), with: .color(Ink.panIn))
    }

    private func drawCake(_ ctx: GraphicsContext, _ c: Cake) {
        // A flat disc seen from a little above shows sin(tilt) of its height; flipping it about its
        // horizontal axis turns that into sin(tilt + theta): it thins to its edge, then shows the other side.
        let ratio = sin(cake.tilt + c.theta)
        let paleUp = ratio > 0
        let r = cake.r, rh = max(1.5, r * abs(ratio))
        var g = ctx
        g.translateBy(x: c.p.x, y: c.p.y)
        g.rotate(by: .degrees(c.rot))
        g.scaleBy(x: 1 + 0.14 * c.squash, y: 1 - 0.28 * c.squash)
        g.fill(Path(ellipseIn: CGRect(x: -r, y: -rh + cake.thick * 0.5, width: r * 2, height: rh * 2 + cake.thick * 0.5)),
               with: .color(Ink.cakeEdge))
        let face = Path(ellipseIn: CGRect(x: -r, y: -rh - cake.thick * 0.3, width: r * 2, height: rh * 2))
        g.fill(face, with: .color(paleUp ? Ink.cakeA : Ink.cakeB))
        var surface = g
        surface.translateBy(x: 0, y: -cake.thick * 0.3)
        surface.scaleBy(x: 1, y: abs(ratio) / sin(cake.tilt))
        if paleUp {
            for i in 0..<5 {
                let bx = (seeded(i, salt: 6) - 0.5) * 48, by = (seeded(i, salt: 7) - 0.5) * 16
                let br = 2.5 + seeded(i, salt: 8) * 2
                surface.fill(Path(ellipseIn: CGRect(x: bx - br, y: by - br * 0.6, width: br * 2, height: br * 1.2)), with: .color(Ink.bubble))
            }
        } else {
            surface.fill(Path(ellipseIn: CGRect(x: -26, y: -8, width: 52, height: 16)), with: .color(Ink.cakeBIn))
        }
    }

    // MARK: - Steam: wisps that rise from the pancake in the pan, and puffs on each landing

    private func drawSteam(_ ctx: GraphicsContext) {
        // Wisps leave from the pancake's edges and curl outward as they rise, so they frame the face
        // instead of crossing it. A cool off-white, so they show on the white jacket too.
        let period = 1920.0
        for i in 0..<5 {
            let p = loop(t, period: period, phase: seeded(i, salt: 11))
            let life = 0.75
            guard p < life else { continue }
            let q = p / life
            var born = t - p * period
            if born < 0 { born += Self.loopMs }
            let state = cakeState(born)
            guard state.mode == .pan else { continue }
            let side = i % 2 == 0 ? -1.0 : 1.0
            let x0 = state.p.x + side * (14 + seeded(i, salt: 12) * 22)
            let rise = easeOut.value(at: q)
            let y = state.p.y - 8 - 46 * rise
            var wisp = Path()
            for k in 0...6 {
                let s = Double(k) / 6
                let pt = CGPoint(x: x0 + side * 22 * rise * (0.6 + 0.4 * s) + 4 * sin(s * 3.4 + q * 4 + Double(i)),
                                 y: y - 20 * s)
                if k == 0 { wisp.move(to: pt) } else { wisp.addLine(to: pt) }
            }
            var g = ctx
            g.opacity = bell(q)
            g.stroke(wisp, with: .color(Ink.steam), style: StrokeStyle(lineWidth: 6.5 - 2.5 * q, lineCap: .round, lineJoin: .round))
        }
        // A puff on each landing: a few small clouds that swell, rise and fade.
        for land in [beat.catch1, beat.onHat, beat.catch2] {
            let q = (t - land) / 480
            guard q > 0, q < 1 else { continue }
            let at = cakeState(land + 1).p
            var g = ctx
            g.opacity = 0.9 * bell(q)
            // Out to the sides, at the pancake's level, never up over the face.
            for k in 0..<6 {
                let side = k % 2 == 0 ? -1.0 : 1.0
                let d = (40 + 34 * easeOut.value(at: q)) * (0.75 + 0.5 * seeded(k, salt: 10))
                let rr = (3 + 5 * easeOut.value(at: q)) * (0.8 + 0.4 * seeded(k, salt: 13))
                let cx = at.x + side * d, cy = at.y - 4 - 10 * seeded(k, salt: 9) - 6 * q
                g.fill(Path(ellipseIn: CGRect(x: cx - rr, y: cy - rr, width: rr * 2, height: rr * 2)), with: .color(Ink.steam))
            }
        }
    }

    // MARK: - Shapes

    /// A tombstone: a half-circle top, straight sides, bottom corners of radius r.
    private func tomb(cx: Double, top: Double, w: Double, h: Double, r: Double) -> Path {
        let R = w / 2, yb = top + h
        let q = min(r, R, h - R)
        var p = Path()
        p.move(to: CGPoint(x: cx - R, y: top + R))
        p.addArc(center: CGPoint(x: cx, y: top + R), radius: R, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: cx + R, y: yb - q))
        p.addQuadCurve(to: CGPoint(x: cx + R - q, y: yb), control: CGPoint(x: cx + R, y: yb))
        p.addLine(to: CGPoint(x: cx - R + q, y: yb))
        p.addQuadCurve(to: CGPoint(x: cx - R, y: yb - q), control: CGPoint(x: cx - R, y: yb))
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
}
