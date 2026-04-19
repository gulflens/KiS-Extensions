import SwiftUI
#if canImport(UIKit)
import UIKit

// MARK: - ShareSheet

/// Thin SwiftUI wrapper around `UIActivityViewController`. Used by the
/// library bulk action bar to share original photos out of the app.
struct ShareSheet: UIViewControllerRepresentable {

    let items: [Any]
    let onComplete: () -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            onComplete()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
