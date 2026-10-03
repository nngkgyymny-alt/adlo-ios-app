import Foundation

/// Real contact info. The phone number and client email were previously
/// pulled from the sales site's vCard/GMB listing alone (`+16562360205`,
/// `clients@...`), which turned out to be the wrong pairing for an app
/// used by already-engaged prospects/clients: that number is a
/// per-language SEO/Google-My-Business tracking line
/// (`PHONE_I18N`/`GMB_PHONE_EN` in `adlo-diy/tools/site-backup/
/// build_sales_site.py`), and `clients@` doesn't appear anywhere else in
/// any of the firm's own properties. `(813) 335-4938` is the number used
/// pervasively across `adlo-case-estimator`'s entire client-facing booking
/// flow (header, about, estimate result, onboarding) and is what
/// `adlo-cross`'s `FIRM_PHONE_TEL` uses; `clientrelations@
/// americandreamlawoffice.com` is the address `build_sales_site.py`
/// explicitly documents as "the firm's actual public client-facing
/// address (per Ahmad, 2026-09-21) — not intake@, which ... was never
/// meant to be public" and is also the vCard's own EMAIL field — and is
/// what `adlo-cross`'s `emailAddress` uses for clients. Matching those
/// instead, not the vCard/GMB pairing.
enum FirmContact {
    static let firmName = "American Dream Law Office"
    static let phoneNumber = "+18133354938"
    static let phoneDisplay = "(813) 335-4938"
    /// Same number as voice calls — adlo-cross's `whatsappFirm()` reuses
    /// `FIRM_PHONE_TEL` rather than a separate WhatsApp-specific line, and
    /// no separate WhatsApp number appears anywhere else in the firm's
    /// properties either.
    static let whatsappNumber = "18133354938"
    /// Track-specific inbox — new/potential clients (`AccountType.prospect`)
    /// go to intake, existing clients (`AccountType.client`) go to the
    /// firm's real public client-facing address (see enum doc comment).
    static func contactEmail(for accountType: AccountType) -> String {
        switch accountType {
        case .client: return "clientrelations@americandreamlawoffice.com"
        case .prospect: return "intake@americandreamlawoffice.com"
        }
    }
    static let address = "10936 N 56th St, Suite 201, Temple Terrace, FL 33617"
    /// Opens turn-by-turn directions in the user's preferred maps app via a
    /// Google Maps search URL (works even without the Google Maps app
    /// installed — it falls back to a browser) — matches adlo-cross's
    /// `openDirections`.
    static var directionsURL: String {
        let query = "American Dream Law Office PLLC \(address)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return "https://www.google.com/maps/search/?api=1&query=\(query)"
    }
    static let website = "https://americandreamlawoffice.com"
    static let consultationURL = "https://www.americandreamlawoffice.com/consultation/"
    /// One combined team page for the whole firm — attorneys, paralegals,
    /// legal assistants, and office staff all appear together
    /// (`/our-firm/{slug}/` per person in `build_sales_site.py`). There's no
    /// separate "legal staff" vs. "intake staff" page on the real site, so
    /// both tracks point here rather than to an invented split.
    static let teamURL = "https://americandreamlawoffice.com/our-firm/"
    /// EOIR has no public API — only this lookup website (A-Number, no login).
    /// The app links out to it directly rather than attempting to scrape it.
    static let eoirStatusURL = "https://acis.eoir.justice.gov/en/"
    /// Matches the `openingHours` in `adlo-case-estimator`'s LegalService
    /// structured data (`Mo-Fr 09:00-17:00`).
    static let officeHours = "Mon–Fri, 9:00 AM – 5:00 PM ET"

    struct SocialLink: Identifiable {
        let name: String
        let url: String
        /// No official SF Symbol exists for any of these brands' logos —
        /// this is a generic external-link glyph, not a stand-in for the
        /// real brand mark.
        let systemImage = "arrow.up.forward.app"
        var id: String { name }
    }

    /// Matches `SOCIAL_LINKS` in `adlo-diy/tools/site-backup/build_sales_site.py`
    /// (the sales site's own "Follow Us" footer) — same accounts, same order.
    static let socialLinks: [SocialLink] = [
        SocialLink(name: "YouTube", url: "https://www.youtube.com/channel/UCSe2eLA-Bgf50upNxthD2fg"),
        SocialLink(name: "Instagram", url: "https://www.instagram.com/americandreamlawoffice/"),
        SocialLink(name: "Facebook", url: "https://www.facebook.com/1413258232335199"),
        SocialLink(name: "TikTok", url: "https://www.tiktok.com/@adloimmigration"),
        SocialLink(name: "Threads", url: "https://www.threads.net/@americandreamlawoffice"),
        SocialLink(name: "LinkedIn", url: "https://www.linkedin.com/company/10245091/"),
    ]
}
