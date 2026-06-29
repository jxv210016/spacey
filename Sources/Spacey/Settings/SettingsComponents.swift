import SwiftUI

/// Shared scaffolding so every Settings pane looks identical: a coloured icon badge and
/// title/subtitle header sitting above a standard grouped `Form`. Panes supply only their
/// `Section`s, which keeps each pane short and guarantees uniform spacing, insets, and
/// scrolling behaviour.
struct SettingsPage<Content: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var tint: Color = .accentColor
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: title, subtitle: subtitle, systemImage: systemImage, tint: tint)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 2)

            Form { content() }
                .formStyle(.grouped)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.windowBackground)
    }
}

/// The icon-badge + title/subtitle row at the top of each pane.
struct PageHeader: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var tint: Color = .accentColor

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(tint.gradient, in: RoundedRectangle(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

/// A two-line labelled control, the single row idiom used across every pane so spacing and
/// typography stay consistent. The trailing closure holds the control (toggle, button, …).
struct SettingsRow<Trailing: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        LabeledContent {
            trailing()
        } label: {
            Text(title)
            if let subtitle {
                Text(subtitle)
            }
        }
    }
}
