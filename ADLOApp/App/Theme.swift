import SwiftUI

/// ADLO's brand palette, matching the CSS custom properties in
/// `adlo-case-estimator/src/app/globals.css` — the live site's own source of
/// truth — so the app's colors match americandreamlawoffice.com exactly.
/// There is no "gold" in the real brand; red is the site's actual CTA/accent
/// color (e.g. its floating "Call Now" button).
enum Theme {
    static let navy = Color(hex: 0x1C2B46)
    static let navyDark = Color(hex: 0x121E31)
    static let teal = Color(hex: 0x00436E)
    static let red = Color(hex: 0xEE2110)
    static let redDark = Color(hex: 0xCC1A0D)
    static let offWhite = Color(hex: 0xFCFCFC)
    static let gray1 = Color(hex: 0xF4F4F4)
    static let gray2 = Color(hex: 0xE9E9E9)
    static let gray3 = Color(hex: 0x86898F)
    static let textColor = Color(hex: 0x343434)

    /// Primary CTA/accent color — the site's red, not the old off-brand gold.
    static let accent = red
    /// Semantic "needs attention" color (e.g. an outstanding document) —
    /// deliberately separate from `accent` so a pending item doesn't read as
    /// an error the way red would.
    static let warning = Color.orange
    static let background = offWhite
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
