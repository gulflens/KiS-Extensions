import SwiftUI
import UIKit

// MARK: - Profile Avatar

/// Crew avatar: shows the profile photo when set, otherwise initials derived
/// from the crew name, otherwise a person glyph. Pure presentation.
struct ProfileAvatar: View {
    let name: String
    let imageData: Data?
    var size: CGFloat = 36
    var showsRing: Bool = true

    private var initials: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "" }
        let letters = trimmed.split(separator: " ").prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    var body: some View {
        ZStack {
            if let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle().fill(AppColor.navy)
                if initials.isEmpty {
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.42, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                } else {
                    Text(initials)
                        .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            if showsRing {
                Circle().strokeBorder(AppColor.gold.opacity(0.6), lineWidth: size > 60 ? 2.5 : 1.5)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: AppSpacing.lg) {
        ProfileAvatar(name: "Ayman Maklad", imageData: nil, size: 80)
        ProfileAvatar(name: "", imageData: nil, size: 80)
        ProfileAvatar(name: "Sara", imageData: nil, size: 36)
    }
    .padding()
    .background(AppColor.background)
}
