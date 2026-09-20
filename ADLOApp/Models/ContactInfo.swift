import Foundation

enum FirmContact {
    static let firmName = "American Dream Law Office"
    static let phoneNumber = "+18135551234"
    static let phoneDisplay = "(813) 555-1234"
    static let whatsappNumber = "18135551234"
    static let email = "info@americandreamlawoffice.com"
    static let address = "123 Immigration Way, Tampa, FL 33602"
    static let website = "https://americandreamlawoffice.com"
    static let consultationURL = "https://www.americandreamlawoffice.com/consultation/"
    /// EOIR has no public API — only this lookup website (A-Number, no login).
    /// The app links out to it directly rather than attempting to scrape it.
    static let eoirStatusURL = "https://acis.eoir.justice.gov/en/"
    static let officeHours = "Mon–Fri, 9:00 AM – 6:00 PM ET"
}
