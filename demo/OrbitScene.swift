// OrbitScene.swift: a round bird, eyes closed in bliss, floating while a ring of cards
// orbits around it in depth, with sparkles twinkling. One clock, an 8-second loop.
import SwiftUI

struct OrbitScene: View {
    let t: Double
    static let size = CGSize(width: 720, height: 720)
    static let loopMs = 8000.0

    private enum Ink {
        static let bg = Color(hex: 0x15191F)
        static let body = Color(hex: 0x4FB6E8)
        static let bodyShade = Color(hex: 0x3A9BD0)
        static let belly = Color(hex: 0x9ADCF7)
        static let face = Color(hex: 0x7FCDF2)
        static let line = Color(hex: 0x1D5E86)
        static let beak = Color(hex: 0xFFB13B)
        static let beakShade = Color(hex: 0xE8892A)
        static let feet = Color(hex: 0xE8892A)
        static let cardFront = Color(hex: 0xE6CCFF)
        static let cardBack = Color(hex: 0xB57BFF)
        static let cardEdge = Color(hex: 0xCDA6FF)
        static let star = Color(hex: 0xB57BFF)
        static let sparkle = Color(hex: 0x86C95F)
    }

    // MARK: - Tokens

    /// The ring: centre, radii, screen tilt, card size, cards and one turn per loop.
    private let ring = (cx: 360.0, cy: 384.0, rx: 252.0, ry: 66.0, tilt: -12.0, cardW: 74.0, cardH: 96.0, count: 8, turnMs: 4000.0)

    var body: some View {
        Canvas { ctx, _ in
            ctx.fill(Path(CGRect(origin: .zero, size: Self.size)), with: .color(Ink.bg))
            drawSparkles(ctx)
            let cards = cardStates()
            for c in cards where c.depth < 0 { drawCard(ctx, c) }
            drawBird(ctx)
            for c in cards where c.depth >= 0 { drawCard(ctx, c) }
        }
        .frame(width: Self.size.width, height: Self.size.height)
    }

    // MARK: - Cards in orbit

    private struct CardState { var x: Double; var y: Double; var depth: Double; var facing: Double; var scale: Double }

    /// Each card's place on the ring now. `depth` > 0 is in front; `facing` is how much of the
    /// face we see (1 square on, 0 edge-on at the sides). Sorted back to front.
    private func cardStates() -> [CardState] {
        let tiltR = ring.tilt * .pi / 180
        var out: [CardState] = []
        for i in 0..<ring.count {
            let theta = 2 * .pi * (Double(i) / Double(ring.count) + loop(t, period: ring.turnMs))
            let lx = ring.rx * cos(theta)
            let ly = ring.ry * sin(theta)
            let x = ring.cx + lx * cos(tiltR) - ly * sin(tiltR)
            let y = ring.cy + lx * sin(tiltR) + ly * cos(tiltR)
            out.append(CardState(x: x, y: y, depth: sin(theta), facing: abs(sin(theta)), scale: 1 + 0.08 * sin(theta)))
        }
        return out.sorted { $0.depth < $1.depth }
    }

    private func drawCard(_ ctx: GraphicsContext, _ c: CardState) {
        var g = ctx
        g.translateBy(x: c.x, y: c.y)
        g.rotate(by: .degrees(ring.tilt))
        g.scaleBy(x: c.scale * max(0.07, c.facing), y: c.scale)
        let rect = CGRect(x: -ring.cardW / 2, y: -ring.cardH / 2, width: ring.cardW, height: ring.cardH)
        let shape = Path(roundedRect: rect, cornerRadius: 14)
        if c.depth >= 0 {
            g.fill(shape, with: .color(Ink.cardFront))
            if c.facing > 0.25 { g.fill(fourPointStar(r: 17), with: .color(Ink.star)) }
        } else {
            g.fill(shape, with: .color(c.facing < 0.2 ? Ink.cardEdge : Ink.cardBack))
        }
    }

    // MARK: - The bird: floats, tilts a little, wings flutter, feet lag behind

    private func drawBird(_ ctx: GraphicsContext) {
        let bob = 5 * wave(t, period: 4000)
        let tilt = 3 * wave(t, period: 8000, phase: 0.1)
        var bird = ctx
        bird.translateBy(x: 360, y: 330 + bob)
        bird.rotate(by: .degrees(tilt))

        // Feet: hang from the hips and swing a touch after the body (follow-through).
        for (i, x) in [-16.0, 16.0].enumerated() {
            var leg = bird
            leg.translateBy(x: x, y: 108)
            leg.rotate(by: .degrees(7 * wave(t, period: 4000, phase: -0.12 - 0.05 * Double(i))))
            leg.fill(Path(roundedRect: CGRect(x: -9, y: -6, width: 18, height: 42), cornerRadius: 9), with: .color(Ink.feet))
            leg.fill(Path(roundedRect: CGRect(x: -9, y: 22, width: 26, height: 16), cornerRadius: 8), with: .color(Ink.feet))
        }
        // Wings: open wide, fluttering around the shoulders.
        for side in [-1.0, 1.0] {
            var wing = bird
            wing.translateBy(x: side * 88, y: 10)
            wing.rotate(by: .degrees(side * (-18 + 6 * wave(t, period: 2000, phase: side > 0 ? 0 : 0.08))))
            wing.fill(Path(ellipseIn: CGRect(x: side > 0 ? -10 : -86, y: -26, width: 96, height: 52)), with: .color(Ink.bodyShade))
        }
        // Body, head tufts, belly, face.
        bird.fill(Path(roundedRect: CGRect(x: -110, y: -110, width: 220, height: 225), cornerRadius: 104), with: .color(Ink.body))
        for side in [-1.0, 1.0] {
            var tuft = bird
            tuft.translateBy(x: side * 58, y: -96)
            tuft.rotate(by: .degrees(side * 22 + 3 * wave(t, period: 4000, phase: -0.1)))
            tuft.fill(Path(ellipseIn: CGRect(x: -20, y: -26, width: 40, height: 40)), with: .color(Ink.body))
        }
        bird.fill(Path(ellipseIn: CGRect(x: -66, y: 18, width: 132, height: 88)), with: .color(Ink.belly))
        bird.fill(Path(roundedRect: CGRect(x: -92, y: -64, width: 184, height: 86), cornerRadius: 43), with: .color(Ink.face))
        // Eyes closed in bliss: two calm arcs.
        for side in [-1.0, 1.0] {
            var arc = Path()
            arc.move(to: CGPoint(x: side * 44 - 24, y: -26))
            arc.addQuadCurve(to: CGPoint(x: side * 44 + 24, y: -26), control: CGPoint(x: side * 44, y: 2))
            bird.stroke(arc, with: .color(Ink.line), style: StrokeStyle(lineWidth: 7, lineCap: .round))
        }
        // Beak.
        bird.fill(Path(roundedRect: CGRect(x: -17, y: -12, width: 34, height: 26), cornerRadius: 12), with: .color(Ink.beakShade))
        bird.fill(Path(roundedRect: CGRect(x: -17, y: -16, width: 34, height: 20), cornerRadius: 10), with: .color(Ink.beak))
    }

    // MARK: - Sparkles: each appears and disappears once per loop, at its own seeded time

    private func drawSparkles(_ ctx: GraphicsContext) {
        let spots: [(x: Double, y: Double, r: Double, dots: Bool)] = [
            (190, 170, 12, true), (560, 160, 14, true), (130, 560, 20, false),
            (600, 600, 22, false), (210, 650, 12, false), (520, 250, 9, false), (95, 300, 9, false),
        ]
        for (i, s) in spots.enumerated() {
            let start = seeded(i, salt: 7) * Self.loopMs
            let p = loop(t - start, period: Self.loopMs) / (1600 / Self.loopMs)
            guard p < 1 else { continue }
            let k = bell(p)
            var g = ctx
            g.translateBy(x: s.x, y: s.y)
            g.scaleBy(x: k, y: k)
            if s.dots {
                for a in 0..<4 {
                    let ang = Double(a) * .pi / 2
                    let d = s.r
                    g.fill(Path(ellipseIn: CGRect(x: cos(ang) * d - 3, y: sin(ang) * d - 3, width: 6, height: 6)), with: .color(Ink.sparkle))
                }
            } else {
                g.fill(fourPointStar(r: s.r), with: .color(Ink.sparkle))
            }
        }
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
