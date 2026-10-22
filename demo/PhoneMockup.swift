// PhoneMockup.swift: an iPhone around a scene, on a white page, for the demo videos.
import SwiftUI

struct PhoneMockup<Screen: View>: View {
    static var size: CGSize { CGSize(width: 1080, height: 1080) }
    /// The screen in points; the scene is scaled to its width and fills its height.
    static var screen: CGSize { CGSize(width: 434, height: 940) }

    /// Dark status bar text on a light screen, white on a dark or coloured one.
    let darkStatus: Bool
    @ViewBuilder let content: Screen

    private let bezel = 12.0
    private let bodyRadius = 70.0
    private let screenRadius = 58.0
    private let island = CGSize(width: 128, height: 37)

    var body: some View {
        let s = Self.screen
        let phone = CGSize(width: s.width + bezel * 2, height: s.height + bezel * 2)
        ZStack {
            Color.white
            ZStack {
                // Side buttons: action and volume on the left, power on the right.
                ForEach(Array([(-1.0, 168.0, 34.0), (-1.0, 236.0, 64.0), (-1.0, 314.0, 64.0), (1.0, 260.0, 104.0)].enumerated()), id: \.offset) { _, b in
                    Capsule()
                        .fill(Color(hex: 0x2C2C30))
                        .frame(width: 7, height: b.2)
                        .offset(x: b.0 * (phone.width / 2 + 1), y: b.1 + b.2 / 2 - phone.height / 2)
                }
                RoundedRectangle(cornerRadius: bodyRadius, style: .continuous)
                    .fill(Color(hex: 0x111113))
                    .overlay(RoundedRectangle(cornerRadius: bodyRadius, style: .continuous)
                        .strokeBorder(Color(hex: 0x4A4A4F), lineWidth: 3))
                    .frame(width: phone.width, height: phone.height)
                    .shadow(color: .black.opacity(0.16), radius: 28, x: 20, y: 26)
                content
                    .frame(width: s.width, height: s.height, alignment: .topLeading)
                    .clipShape(RoundedRectangle(cornerRadius: screenRadius, style: .continuous))
                statusBar
                    .frame(width: s.width, height: s.height, alignment: .top)
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
    }

    /// 9:41, the Dynamic Island, signal, wifi and battery.
    private var statusBar: some View {
        let ear = (Self.screen.width - island.width) / 2
        return ZStack {
            Capsule().fill(Color.black).frame(width: island.width, height: island.height)
            HStack(spacing: 0) {
                Text("9:41")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: ear)
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    Image(systemName: "cellularbars")
                    Image(systemName: "wifi")
                    Image(systemName: "battery.100")
                }
                .font(.system(size: 14, weight: .semibold))
                .frame(width: ear)
            }
            .foregroundStyle(darkStatus ? Color.black : Color.white)
        }
        .frame(width: Self.screen.width, height: island.height)
        .padding(.top, 12)
    }
}
