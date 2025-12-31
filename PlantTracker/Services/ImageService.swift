import UIKit

enum ImageService {
    /// Compress image to meet size requirements
    /// - Parameters:
    ///   - image: The UIImage to compress
    ///   - maxSizeBytes: Maximum size in bytes (default from Constants)
    /// - Returns: Compressed JPEG data, or nil if compression failed
    static func compressImage(
        _ image: UIImage,
        maxSizeBytes: Int = Constants.maxImageSizeBytes
    ) -> Data? {
        // First, resize if the image is too large
        let resizedImage = resizeImage(image, maxDimension: Constants.maxImageDimension)

        // Start with high quality compression
        var compressionQuality: CGFloat = Constants.imageCompressionQuality
        var imageData = resizedImage.jpegData(compressionQuality: compressionQuality)

        // Reduce quality until we're under the size limit
        while let data = imageData, data.count > maxSizeBytes && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
        }

        return imageData
    }

    /// Resize image if it exceeds max dimension
    /// - Parameters:
    ///   - image: The image to resize
    ///   - maxDimension: Maximum width or height
    /// - Returns: Resized image (or original if already small enough)
    static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxCurrentDimension = max(size.width, size.height)

        // If image is already small enough, return it
        if maxCurrentDimension <= maxDimension {
            return image
        }

        // Calculate new size maintaining aspect ratio
        let scale = maxDimension / maxCurrentDimension
        let newSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )

        // Render resized image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? image
    }

    /// Save image to documents directory
    /// - Parameters:
    ///   - image: The image to save
    ///   - filename: Filename (with extension)
    /// - Returns: File path if successful, nil otherwise
    static func saveImage(_ image: UIImage, filename: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            return nil
        }

        let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first

        guard let fileURL = documentsDirectory?.appendingPathComponent(filename) else {
            return nil
        }

        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }

    /// Load image from file path
    /// - Parameter path: File path
    /// - Returns: UIImage if found, nil otherwise
    static func loadImage(from path: String) -> UIImage? {
        UIImage(contentsOfFile: path)
    }

    /// Delete image at path
    /// - Parameter path: File path
    static func deleteImage(at path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }
}
