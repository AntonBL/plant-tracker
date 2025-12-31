import Foundation

enum Constants {
    /// Base URL for the GCP Cloud Function proxy
    /// Deployed Cloud Function URL from GCP
    static let proxyBaseURL = "https://plant-proxy-ozg2qzyl6q-uc.a.run.app"

    /// Maximum image size for upload (5MB)
    static let maxImageSizeBytes = 5 * 1024 * 1024

    /// JPEG compression quality (0.0-1.0)
    static let imageCompressionQuality: CGFloat = 0.8

    /// Maximum image dimension (width or height)
    static let maxImageDimension: CGFloat = 1920

    /// Default watering cadence in days
    static let defaultWateringCadenceDays = 7
}
