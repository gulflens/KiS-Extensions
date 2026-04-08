import SwiftUI

struct TimelinePlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Timeline",
            systemImage: "calendar.day.timeline.leading",
            description: Text("Flight timeline and scheduling features coming soon.")
        )
        .navigationTitle("Timeline")
    }
}
