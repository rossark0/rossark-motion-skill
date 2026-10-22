// DemoScene.swift: the demo in the README, drawn with the SwiftUI templates.
//
// One clock (`t`, in ms) drives everything: a creature with live eyes that
// breathes and lets its ears follow through, snow in the window, steam from a
// mug, a candle flame, and a plant swaying. Every period divides 8000 ms, so the
// 8-second loop closes without a jump.
import SwiftUI

struct DemoScene: View {
    /// The clock, in ms.
    let t: Double

    static let size = CGSize(width: 800, height: 450)
    static let loopMs = 8000.0

    var body: some View {
        Canvas { ctx, _ in
            drawRoom(ctx)
            drawWindow(ctx)
            drawTable(ctx)
            drawMug(ctx)
            drawCandle(ctx)
            drawPlant(ctx)
            drawCreature(ctx)
        }
        .frame(width: Self.size.width, height: Self.size.height)
    }

    // MARK: - Palette

    private enum Ink {
        static let wall = Color(hex: 0x221E38)
        static let floor = Color(hex: 0x2D2848)
        static let frame = Color(hex: 0x3B3560)
        static let sky = Color(hex: 0x141836)
        static let moon = Color(hex: 0xF2EBD3)
        static let table = Color(hex: 0x5A4B82)
        static let tableEdge = Color(hex: 0x4A3D6E)
        static let mug = Color(hex: 0xE8DDF5)
        static let steam = Color(hex: 0xCFC6E8)
        static let candle = Color(hex: 0xF3E9D2)
        static let flame = Color(hex: 0xFFB547)
        static let flameCore = Color(hex: 0xFFF1B8)
        static let pot = Color(hex: 0xC9734F)
        static let leaf = Color(hex: 0x6FCF97)
        static let leafDark = Color(hex: 0x4CAF7D)
        static let body = Color(hex: 0x6C8CFF)
        static let belly = Color(hex: 0x9EB3FF)
        static let earInner = Color(hex: 0xFF9EB5)
        static let line = Color(hex: 0x2B2F5C)
        static let cheek = Color(hex: 0xFF8FB1)
    }

    // MARK: - Room

    private func drawRoom(_ ctx: GraphicsContext) {
        ctx.fill(Path(CGRect(origin: .zero, size: Self.size)), with: .color(Ink.wall))
        ctx.fill(Path(CGRect(x: 0, y: 390, width: 800, height: 60)), with: .color(Ink.floor))
    }

    // MARK: - Window with falling snow

    private let win = CGRect(x: 40, y: 50, width: 210, height: 200)

    private func drawWindow(_ ctx: GraphicsContext) {
        ctx.fill(Path(roundedRect: win.insetBy(dx: -10, dy: -10), cornerRadius: 14), with: .color(Ink.frame))
        ctx.drawLayer { c in
            c.clip(to: Path(roundedRect: win, cornerRadius: 6))
            c.fill(Path(win), with: .color(Ink.sky))
            c.fill(Path(ellipseIn: CGRect(x: win.maxX - 62, y: win.minY + 18, width: 34, height: 34)), with: .color(Ink.moon))
            // Snow: each flake its own seeded phase, size and drift; 1× or 2× speed so the loop closes.
            for i in 0..<38 {
                let speed = seeded(i) < 0.5 ? 1.0 : 2.0
                let p = loop(t, period: Self.loopMs / speed, phase: seeded(i, salt: 1))
                let x = win.minX + seeded(i, salt: 2) * win.width + 5 * wave(t, period: 2000 * speed, phase: seeded(i, salt: 3))
                let y = win.minY - 6 + p * (win.height + 12)
                let r = 1.2 + seeded(i, salt: 4) * 1.8
                c.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(.white.opacity(0.9)))
            }
        }
        // The window cross.
        ctx.fill(Path(CGRect(x: win.midX - 4, y: win.minY, width: 8, height: win.height)), with: .color(Ink.frame))
        ctx.fill(Path(CGRect(x: win.minX, y: win.midY - 4, width: win.width, height: 8)), with: .color(Ink.frame))
    }

    // MARK: - Table, mug and steam, candle

    private func drawTable(_ ctx: GraphicsContext) {
        ctx.fill(Path(CGRect(x: 490, y: 300, width: 14, height: 90)), with: .color(Ink.tableEdge))
        ctx.fill(Path(CGRect(x: 746, y: 300, width: 14, height: 90)), with: .color(Ink.tableEdge))
        ctx.fill(Path(roundedRect: CGRect(x: 470, y: 288, width: 310, height: 16), cornerRadius: 6), with: .color(Ink.table))
    }

    private func drawMug(_ ctx: GraphicsContext) {
        // Steam: three wisps rising out of phase, fading in and out (opacity only to appear and disappear).
        for i in 0..<3 {
            let p = loop(t, period: 2000, phase: Double(i) / 3)
            let x = 512 + Double(i) * 11
            let y0 = 236 - p * 18
            var wisp = Path()
            wisp.move(to: CGPoint(x: x, y: y0 + 16))
            wisp.addCurve(to: CGPoint(x: x, y: y0), control1: CGPoint(x: x - 6, y: y0 + 10), control2: CGPoint(x: x + 6, y: y0 + 6))
            ctx.stroke(wisp, with: .color(Ink.steam.opacity(0.85 * bell(p))), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        ctx.fill(Path(roundedRect: CGRect(x: 496, y: 250, width: 54, height: 40), cornerRadius: 8), with: .color(Ink.mug))
        var handle = Path()
        handle.addArc(center: CGPoint(x: 552, y: 268), radius: 10, startAngle: .degrees(-80), endAngle: .degrees(80), clockwise: false)
        ctx.stroke(handle, with: .color(Ink.mug), lineWidth: 6)
    }

    private func drawCandle(_ ctx: GraphicsContext) {
        let base = CGPoint(x: 616, y: 240)
        // The glow grows a few percent, slowly (light, not dimming).
        let glow = 46 * (1 + 0.04 * wave(t, period: 2000))
        ctx.fill(Path(ellipseIn: CGRect(x: base.x - glow, y: base.y - 14 - glow, width: glow * 2, height: glow * 2)),
                 with: .radialGradient(Gradient(colors: [Ink.flame.opacity(0.28), Ink.flame.opacity(0)]),
                                       center: CGPoint(x: base.x, y: base.y - 14), startRadius: 0, endRadius: glow))
        ctx.fill(Path(roundedRect: CGRect(x: 604, y: 240, width: 24, height: 50), cornerRadius: 4), with: .color(Ink.candle))
        // Flicker: a lean and a stretch on two waves of different periods; the core on a third.
        let lean = 3 * wave(t, period: 800) + 1.5 * wave(t, period: 1600, phase: 0.3)
        let stretch = 1 + 0.05 * wave(t, period: 1000, phase: 0.2)
        var flame = ctx
        flame.translateBy(x: base.x, y: base.y)
        flame.rotate(by: .degrees(lean))
        flame.scaleBy(x: 1, y: stretch)
        flame.fill(teardrop(width: 16, height: 30), with: .color(Ink.flame))
        var core = flame
        core.rotate(by: .degrees(1.5 * wave(t, period: 1333.3333, phase: 0.6)))
        core.fill(teardrop(width: 8, height: 16), with: .color(Ink.flameCore))
    }

    /// A flame shape standing on (0, 0), pointing up.
    private func teardrop(width w: CGFloat, height h: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: -h))
        p.addCurve(to: CGPoint(x: 0, y: 0), control1: CGPoint(x: w * 0.9, y: -h * 0.45), control2: CGPoint(x: w * 0.55, y: 0))
        p.addCurve(to: CGPoint(x: 0, y: -h), control1: CGPoint(x: -w * 0.55, y: 0), control2: CGPoint(x: -w * 0.9, y: -h * 0.45))
        return p
    }

    // MARK: - Plant: sway around the base, tips later and further

    private func drawPlant(_ ctx: GraphicsContext) {
        let base = CGPoint(x: 712, y: 246)
        let stems: [(angle: Double, length: Double)] = [(-28, 62), (-8, 84), (12, 74), (32, 56)]
        for (i, stem) in stems.enumerated() {
            let sway = (2.2 + Double(i) * 0.5) * wave(t, period: 4000, phase: 0.06 * Double(i))
            var c = ctx
            c.translateBy(x: base.x, y: base.y)
            c.rotate(by: .degrees(stem.angle + sway))
            var s = Path()
            s.move(to: .zero)
            s.addQuadCurve(to: CGPoint(x: 0, y: -stem.length), control: CGPoint(x: 6, y: -stem.length / 2))
            c.stroke(s, with: .color(Ink.leafDark), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            // The leaf at the tip follows through: a little more sway, a little later.
            var leaf = c
            leaf.translateBy(x: 0, y: -stem.length)
            leaf.rotate(by: .degrees(2.5 * wave(t, period: 4000, phase: 0.06 * Double(i) + 0.12)))
            leaf.fill(Path(ellipseIn: CGRect(x: -11, y: -26, width: 22, height: 30)), with: .color(Ink.leaf))
        }
        var pot = Path()
        pot.move(to: CGPoint(x: 686, y: 244))
        pot.addLine(to: CGPoint(x: 738, y: 244))
        pot.addLine(to: CGPoint(x: 730, y: 288))
        pot.addLine(to: CGPoint(x: 694, y: 288))
        pot.closeSubpath()
        ctx.fill(pot, with: .color(Ink.pot))
    }

    // MARK: - The creature: breathing, ears following through, live eyes

    /// Looks at the window, blinks, looks at the mug, smiles with its eyes, blinks twice.
    private static let choreo = Choreo(
        period: 8000,
        lookX: [Key(0, 0), Key(1200, 0), Key(1700, -7), Key(2900, -7), Key(3400, 0), Key(4300, 0), Key(4800, 7), Key(5900, 7), Key(6400, 0), Key(8000, 0)],
        lookY: [Key(0, 2), Key(1200, 2), Key(1700, -5), Key(2900, -5), Key(3400, 2), Key(4300, 2), Key(4800, 5), Key(5900, 5), Key(6400, 2), Key(8000, 2)],
        lid: [Key(0, 0), Key(3700, 0), Key(3790, 1), Key(3840, 1), Key(3990, 0, out: true),
              Key(7300, 0), Key(7390, 1), Key(7540, 0, out: true), Key(7640, 0), Key(7730, 1), Key(7880, 0, out: true), Key(8000, 0)],
        cheek: [Key(0, 0), Key(6400, 0), Key(6700, 1, out: true), Key(7000, 1), Key(7200, 0), Key(8000, 0)]
    )

    private func drawCreature(_ ctx: GraphicsContext) {
        let breath = -2.5 * (wave(t, period: 4000, phase: -0.25) + 1) / 2
        // The shadow stays on the floor.
        ctx.fill(Path(ellipseIn: CGRect(x: 225, y: 384, width: 150, height: 14)), with: .color(.black.opacity(0.25)))

        var body = ctx
        body.translateBy(x: 0, y: breath)
        // Ears: rotate around their roots, a touch later than the breath (follow-through).
        for side in [-1.0, 1.0] {
            var ear = body
            ear.translateBy(x: 300 + side * 46, y: 214)
            ear.rotate(by: .degrees(side * 10 + 5 * wave(t, period: 4000, phase: -0.1 + side * 0.05)))
            ear.fill(roundedTriangle(w: 40, h: 44), with: .color(Ink.body))
            ear.fill(roundedTriangle(w: 20, h: 24), with: .color(Ink.earInner))
        }
        body.fill(Path(roundedRect: CGRect(x: 215, y: 200, width: 170, height: 192), cornerRadius: 80), with: .color(Ink.body))
        body.fill(Path(ellipseIn: CGRect(x: 250, y: 300, width: 100, height: 80)), with: .color(Ink.belly))

        // The head's own coordinates: (0, 0) between the eyes.
        var head = body
        head.translateBy(x: 300, y: 262)
        let whiteL = EyeGeometry(cx: -32, cy: 0, w: 34, h: 44, pupilW: 15, pupilH: 22, pupilTop: 9, shine: 3)
        let whiteR = EyeGeometry(cx: 32, cy: 0, w: 34, h: 44, pupilW: 15, pupilH: 22, pupilTop: 9, shine: 3)
        for eye in [whiteL, whiteR] {
            head.fill(pill(cx: eye.cx, cy: eye.cy, w: eye.w, h: eye.h), with: .color(.white))
        }
        let ink = FaceInk(white: .white, pupil: Color(hex: 0x1B1B2E), skin: Ink.body, line: Ink.line, lineWidth: 4)
        drawLiveEye(head, side: -1, eye: whiteL, ink: ink, choreo: Self.choreo, t: t)
        drawLiveEye(head, side: 1, eye: whiteR, ink: ink, choreo: Self.choreo, t: t)
        for side in [-1.0, 1.0] {
            head.fill(Path(ellipseIn: CGRect(x: side * 52 - 11, y: 30, width: 22, height: 12)), with: .color(Ink.cheek.opacity(0.7)))
        }
        var mouth = Path()
        mouth.move(to: CGPoint(x: -14, y: 38))
        mouth.addQuadCurve(to: CGPoint(x: 14, y: 38), control: CGPoint(x: 0, y: 50))
        head.stroke(mouth, with: .color(Ink.line), style: StrokeStyle(lineWidth: 4, lineCap: .round))
    }

    /// A soft triangle standing on (0, 0), pointing up.
    private func roundedTriangle(w: CGFloat, h: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: -w / 2, y: 6))
        p.addQuadCurve(to: CGPoint(x: 0, y: -h), control: CGPoint(x: -w * 0.35, y: -h * 0.6))
        p.addQuadCurve(to: CGPoint(x: w / 2, y: 6), control: CGPoint(x: w * 0.35, y: -h * 0.6))
        p.closeSubpath()
        return p
    }
}
