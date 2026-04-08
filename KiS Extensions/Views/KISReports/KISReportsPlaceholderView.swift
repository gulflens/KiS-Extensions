import SwiftUI

struct KISReportsPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "KIS Reports",
            systemImage: "doc.text.magnifyingglass",
            description: Text("KIS report generation and viewing coming soon.")
        )
        .navigationTitle("KIS Reports")
    }
}
