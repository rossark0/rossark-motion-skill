// render.swift: renders a demo scene to PNG frames (macOS 14+).
//
//   swiftc -parse-as-library -target arm64-apple-macos14 \
//     templates/swiftui/Motion.swift templates/swiftui/LiveFace.swift demo/*.swift -o /tmp/render-demo
//   /tmp/render-demo reveal /tmp/frames              # or: garden, chef, orbit
//   /tmp/render-demo reveal /tmp/frames phone        # inside an iPhone, on a square page
//   /tmp/render-demo reveal /tmp/frames phone fps=60 # smoother, for posting
//   /tmp/render-demo reveal /tmp/frames phone 0 40   # only these frames (to check before a full render)
//   ffmpeg -framerate 30 -i /tmp/frames/%04d.png -c:v libx264 -pix_fmt yuv420p -crf 20 demo/reveal.mp4
import Foundation
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

@MainActor
func scene(_ name: String, _ t: Double, phone: Bool) -> (view: AnyView, loopMs: Double) {
    switch name {
    case "orbit":
        return (AnyView(OrbitScene(t: t)), OrbitScene.loopMs)
    case "garden":
        guard phone else { return (AnyView(GardenScene(t: t)), GardenScene.loopMs) }
        // A little wider than the reveal, so the girl, the pot and the flower all fit; feet at 73%.
        let screen = PhoneMockup<EmptyView>.screen
        let k = screen.width / 720 * 1.8
        return (AnyView(PhoneMockup(darkStatus: true) {
            GardenScene(t: t, height: screen.height / k, stageTop: screen.height * 0.73 / k - 620)
                .scaleEffect(k, anchor: .topLeading)
                .offset(x: -(720 * k - screen.width) / 2)
        }), GardenScene.loopMs)
    case "chef":
        guard phone else { return (AnyView(ChefScene(t: t)), ChefScene.loopMs) }
        // Close on the chef: the counter hides the legs, so the stage sits low and the head is big.
        let screen = PhoneMockup<EmptyView>.screen
        let k = screen.width / 720 * 2.35
        return (AnyView(PhoneMockup(darkStatus: true) {
            ChefScene(t: t, height: screen.height / k, stageTop: 82)
                .scaleEffect(k, anchor: .topLeading)
                .offset(x: -(720 * k - screen.width) / 2)
        }), ChefScene.loopMs)
    default:
        guard phone else { return (AnyView(RevealScene(t: t)), RevealScene.loopMs) }
        // The 720-wide scene, as big as the screen allows, with the feet at 73% of the screen.
        let screen = PhoneMockup<EmptyView>.screen
        let k = screen.width / 720 * 1.85
        return (AnyView(PhoneMockup(darkStatus: true) {
            RevealScene(t: t, height: screen.height / k, stageTop: screen.height * 0.73 / k - 620)
                .scaleEffect(k, anchor: .topLeading)
                .offset(x: -(720 * k - screen.width) / 2)
        }), RevealScene.loopMs)
    }
}

@main
struct RenderDemo {
    @MainActor
    static func main() throws {
        var args = Array(CommandLine.arguments.dropFirst())
        let name = args.isEmpty ? "reveal" : args.removeFirst()
        let out = URL(fileURLWithPath: args.isEmpty ? "frames" : args.removeFirst())
        let phone = args.first == "phone"
        if phone { args.removeFirst() }
        var fps = 30.0
        if let i = args.firstIndex(where: { $0.hasPrefix("fps=") }) {
            fps = Double(args.remove(at: i).dropFirst(4)) ?? 30
        }
        try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        let loopMs = scene(name, 0, phone: phone).loopMs
        let picks = args.compactMap { Int($0) }
        let frames = picks.isEmpty ? Array(0..<Int(loopMs / 1000 * fps)) : picks
        for f in frames {
            let renderer = ImageRenderer(content: scene(name, Double(f) / fps * 1000, phone: phone).view)
            renderer.scale = 2
            guard let image = renderer.cgImage else { throw CocoaError(.fileWriteUnknown) }
            let url = out.appendingPathComponent(String(format: "%04d.png", f))
            guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
                throw CocoaError(.fileWriteUnknown)
            }
            CGImageDestinationAddImage(dest, image, nil)
            CGImageDestinationFinalize(dest)
        }
        print("rendered \(frames.count) frames of \(name) to \(out.path)")
    }
}
