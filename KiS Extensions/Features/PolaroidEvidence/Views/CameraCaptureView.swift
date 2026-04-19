import SwiftUI
#if canImport(UIKit)
import UIKit
import AVFoundation
#endif

// MARK: - CameraCaptureView

/// `UIImagePickerController` wrapped for SwiftUI. Camera and library share
/// one representable; the source type is chosen at presentation. Returns
/// the captured `UIImage` via `onCapture`; `onCancel` fires on dismiss
/// without a photo.
#if canImport(UIKit)
struct CameraCaptureView: UIViewControllerRepresentable {

    // MARK: Source

    enum Source {
        case camera
        case library

        var pickerType: UIImagePickerController.SourceType {
            switch self {
            case .camera: return .camera
            case .library: return .photoLibrary
            }
        }
    }

    // MARK: Inputs

    let source: Source
    let onCapture: (UIImage) -> Void
    let onCancel: () -> Void

    // MARK: Representable

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        let resolved: UIImagePickerController.SourceType = {
            #if targetEnvironment(simulator)
            // iOS Simulator reports camera as available but presents a stub
            // viewfinder that never produces an image. Always use library.
            if source == .camera { return .photoLibrary }
            #endif
            if source == .camera, !UIImagePickerController.isSourceTypeAvailable(.camera) {
                return .photoLibrary
            }
            return source.pickerType
        }()
        picker.sourceType = resolved
        if resolved == .camera {
            picker.cameraDevice = .rear
        }
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: Coordinator

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCaptureView

        init(_ parent: CameraCaptureView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            } else {
                parent.onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }
    }
}

// MARK: - Permission helpers

enum CameraPermission {
    case granted
    case denied
    case needsRequest

    static var current: CameraPermission {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return .granted
        case .denied, .restricted: return .denied
        case .notDetermined: return .needsRequest
        @unknown default: return .denied
        }
    }

    static func request() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }
}
#endif
