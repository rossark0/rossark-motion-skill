// LiveFace.swift: a living face for SwiftUI characters (iOS 17+, macOS 14+).
//
// Nothing ever swaps drawings: the pupil SLIDES, the eyelid LOWERS and RISES, the
// cheek pushes up for a happy squint, the mouth OPENS and CLOSES. One clock per
// character (`ChoreoClock`) drives every channel through keyframe tracks.
//
// Needs `Motion.swift` (the engine) in the same target.
//
// Usage (see SKILL.md, "SwiftUI"):
//   ChoreoClock(period: blink.period) { t in
//       ZStack {
//           CharacterArt()                       // eyes drawn as plain whites, no pupils
//           Canvas { ctx, _ in
//               var head = ctx                   // the head's own coordinates
//               head.translateBy(x: 120, y: 90)
//               head.scaleBy(x: 0.8, y: 0.8)
//               drawLiveEye(head, side: -1, eye: eyeL, ink: ink, choreo: blink, t: t)
//               drawLiveEye(head, side: 1, eye: eyeR, ink: ink, choreo: blink, t: t)
//               // then whatever covers the lids (nose, fringe)
//           }
//       }
//   }
import SwiftUI

/// One character's choreography. `lookX`/`lookY`: pupil offset in eye units.
/// `lid`: upper eyelid, 0 open to 1 closed (`lidRight` for a one-eyed blink or wink).
/// `cheek`: 0 to 1, a happy squint. `mouth`: open-mouth depth. `tilt`: head angle in degrees.
public struct Choreo: Sendable {
    public var period: Double
    public var lookX: Keys
    public var lookY: Keys
    public var lid: Keys
    public var lidRight: Keys?
    public var cheek: Keys?
    public var mouth: Keys?
    public var tilt: Keys?
    public init(
        period: Double, lookX: Keys, lookY: Keys, lid: Keys,
        lidRight: Keys? = nil, cheek: Keys? = nil, mouth: Keys? = nil, tilt: Keys? = nil
    ) {
        self.period = period
        self.lookX = lookX
        self.lookY = lookY
        self.lid = lid
        self.lidRight = lidRight
        self.cheek = cheek
        self.mouth = mouth
        self.tilt = tilt
    }
}

// MARK: - The clock

/// The character's clock: a `LoopClock` (in Motion.swift) of `choreo.period` ms.
public typealias ChoreoClock<Content: View> = LoopClock<Content>

// MARK: - Geometry and colours

/// A rounded pill (stadium) centred on (cx, cy).
public func pill(cx: CGFloat, cy: CGFloat, w: CGFloat, h: CGFloat) -> Path {
    Path(roundedRect: CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h), cornerRadius: min(w, h) / 2)
}

/// Where one eye sits, in the head's own coordinates.
public struct EyeGeometry: Sendable {
    public var cx: CGFloat, cy: CGFloat
    /// Size of the eye white (a pill).
    public var w: CGFloat, h: CGFloat
    /// Pupil size, and its top edge measured from the top of the eye white.
    public var pupilW: CGFloat, pupilH: CGFloat, pupilTop: CGFloat
    /// Radius of the highlight dot. 0 for none.
    public var shine: CGFloat
    public init(cx: CGFloat, cy: CGFloat, w: CGFloat, h: CGFloat, pupilW: CGFloat, pupilH: CGFloat, pupilTop: CGFloat, shine: CGFloat) {
        self.cx = cx; self.cy = cy; self.w = w; self.h = h
        self.pupilW = pupilW; self.pupilH = pupilH; self.pupilTop = pupilTop; self.shine = shine
    }
}

public struct FaceInk: Sendable {
    public var white: Color, pupil: Color
    /// The skin colour: eyelid and cheek are skin sliding over the white.
    public var skin: Color
    /// Lines: lash edge, closed eye, happy-squint arc.
    public var line: Color
    public var lineWidth: CGFloat
    public init(white: Color, pupil: Color, skin: Color, line: Color, lineWidth: CGFloat = 5) {
        self.white = white; self.pupil = pupil; self.skin = skin; self.line = line; self.lineWidth = lineWidth
    }
}

// MARK: - The live eye

/// Draws one living eye into `context`, which must already be in the head's coordinates.
/// The pupil and shine slide, clipped to the white. The lid and cheek are skin clipped to a
/// pill 2 units LARGER than the white: clipped to the exact white, the anti-aliased edge leaks
/// around a closed eye and reads as glasses. `side`: -1 the eye on the viewer's left, 1 the right.
public func drawLiveEye(
    _ context: GraphicsContext, side: CGFloat, eye: EyeGeometry, ink: FaceInk, choreo: Choreo, t: Double
) {
    let cx = eye.cx, cy = eye.cy, w = eye.w, h = eye.h
    let lid = CGFloat(track(t, side > 0 ? (choreo.lidRight ?? choreo.lid) : choreo.lid))
    let lx = CGFloat(track(t, choreo.lookX))
    let ly = CGFloat(track(t, choreo.lookY))
    let top = cy - h / 2 + eye.pupilTop + ly
    let lidH = h + 4

    // The pupil and its shine, inside the white.
    context.drawLayer { c in
        c.clip(to: pill(cx: cx, cy: cy, w: w, h: h))
        let pupil = CGRect(x: cx + lx - eye.pupilW / 2, y: top, width: eye.pupilW, height: eye.pupilH)
        c.fill(Path(roundedRect: pupil, cornerRadius: eye.pupilW / 2), with: .color(ink.pupil))
        if eye.shine > 0 {
            let s = CGPoint(x: cx + lx - eye.pupilW * 0.22, y: top + eye.shine + 1.6)
            c.fill(Path(ellipseIn: CGRect(x: s.x - eye.shine, y: s.y - eye.shine, width: eye.shine * 2, height: eye.shine * 2)),
                   with: .color(ink.white))
        }
    }

    // The skin that slides over it: the lid from the top, the cheek from the bottom.
    context.drawLayer { c in
        c.clip(to: pill(cx: cx, cy: cy, w: w + 2, h: h + 2))
        c.fill(Path(CGRect(x: cx - w / 2 - 2, y: cy - h / 2 - 2, width: w + 4, height: lid * lidH)), with: .color(ink.skin))
        // The lid's edge: shows as soon as it starts down, hides when the closed line takes over.
        let lashOn = min(1, lid / 0.06) * min(1, max(0, (0.95 - lid) / 0.08))
        if lashOn > 0 {
            let y = cy - h / 2 - 2 + lid * lidH
            var lash = Path()
            lash.move(to: CGPoint(x: cx - w / 2 - 2, y: y))
            lash.addLine(to: CGPoint(x: cx + w / 2 + 2, y: y))
            c.stroke(lash, with: .color(ink.line.opacity(lashOn)), lineWidth: ink.lineWidth * 0.6)
        }
        if let cheekKeys = choreo.cheek {
            let k = CGFloat(track(t, cheekKeys))
            c.fill(Path(CGRect(x: cx - w / 2 - 2, y: cy + h / 2 + 2 - k * lidH, width: w + 4, height: k * lidH)),
                   with: .color(ink.skin))
        }
    }

    // The closed eye: a line with the outer tip dropping, once the lid is nearly down.
    let closedOn = min(1, max(0, (lid - 0.88) / 0.12))
    if closedOn > 0 {
        var closed = Path()
        closed.move(to: CGPoint(x: cx - side * w * 0.37, y: cy))
        closed.addLine(to: CGPoint(x: cx + side * w * 0.13, y: cy))
        closed.addQuadCurve(to: CGPoint(x: cx + side * w * 0.37, y: cy + h * 0.17),
                            control: CGPoint(x: cx + side * w * 0.33, y: cy))
        context.stroke(closed, with: .color(ink.line.opacity(closedOn)),
                       style: StrokeStyle(lineWidth: ink.lineWidth, lineCap: .round, lineJoin: .round))
    }

    // The happy squint: an upward arc once the cheek is nearly up.
    if let cheekKeys = choreo.cheek {
        let happyOn = min(1, max(0, (CGFloat(track(t, cheekKeys)) - 0.86) / 0.14))
        if happyOn > 0 {
            var arc = Path()
            arc.move(to: CGPoint(x: cx - w * 0.4, y: cy - h * 0.1))
            arc.addQuadCurve(to: CGPoint(x: cx + w * 0.4, y: cy - h * 0.1), control: CGPoint(x: cx, y: cy - h * 0.7))
            context.stroke(arc, with: .color(ink.line.opacity(happyOn)),
                           style: StrokeStyle(lineWidth: ink.lineWidth, lineCap: .round))
        }
    }
}

// MARK: - The live mouth

/// Draws a living open mouth: the dark inside deepens and shallows, the tongue follows.
/// `x0`/`x1` are the corners, `top` the upper lip line, `tilt` how much higher the right
/// corner sits. It never fully closes: with the teeth on top it reads as talking.
public func drawLiveMouth(
    _ context: GraphicsContext, x0: CGFloat, x1: CGFloat, top: CGFloat, tilt: CGFloat = 0,
    mouth: Color, tongue: Color, teeth: Color? = nil, choreo: Choreo, t: Double, restDepth: CGFloat = 11
) {
    let d = choreo.mouth.map { CGFloat(track(t, $0)) } ?? restDepth
    let mid = (x0 + x1) / 2
    var dark = Path()
    dark.move(to: CGPoint(x: x0, y: top))
    dark.addLine(to: CGPoint(x: x1, y: top - tilt))
    dark.addQuadCurve(to: CGPoint(x: mid, y: top + d), control: CGPoint(x: x1 + 2, y: top + d))
    dark.addQuadCurve(to: CGPoint(x: x0, y: top), control: CGPoint(x: x0 - 2, y: top + d))
    dark.closeSubpath()
    context.fill(dark, with: .color(mouth))
    let r = min(d * 0.36, (x1 - x0) * 0.22)
    let ty = top + d - r - 1.5
    context.fill(Path(ellipseIn: CGRect(x: mid + 1 - r, y: ty - r, width: r * 2, height: r * 2)), with: .color(tongue))
    if let teeth {
        var tooth = Path()
        tooth.move(to: CGPoint(x: x0 + 1, y: top))
        tooth.addLine(to: CGPoint(x: x1 - 1, y: top - tilt))
        tooth.addLine(to: CGPoint(x: x1 - 1.5, y: top - tilt + 5))
        tooth.addLine(to: CGPoint(x: x0 + 1.5, y: top + 5))
        tooth.closeSubpath()
        context.fill(tooth, with: .color(teeth))
    }
}
