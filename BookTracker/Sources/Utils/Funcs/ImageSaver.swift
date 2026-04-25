import UIKit

final class ImageSaver: NSObject {
    private var completion: ((Bool) -> Void)?

    func save(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        let opaqueImage = makeOpaque(image)
        self.completion = completion
        UIImageWriteToSavedPhotosAlbum(opaqueImage, self, #selector(didFinishSaving), nil)
    }

    private func makeOpaque(_ image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(at: .zero)
        }
    }

    @objc private func didFinishSaving(_ image: UIImage, error: Error?, context: UnsafeMutableRawPointer?) {
        completion?(error == nil)
        completion = nil
    }
}
