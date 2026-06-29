import SwiftUI

/// Appearance preferences: how the menu-bar item presents the current Space, with a live
/// preview of the chosen style.
struct AppearanceSettingsTab: View {
    @ObservedObject var appearance: AppearanceSettings

    var body: some View {
        SettingsPage(
            title: "Appearance",
            subtitle: "How Spacey looks in the menu bar.",
            systemImage: "paintbrush.fill",
            tint: .indigo
        ) {
            Section {
                SettingsRow(
                    title: "Menu bar item",
                    subtitle: "What the Spacey icon shows for the current Space."
                ) {
                    Picker("", selection: $appearance.menuBarStyle) {
                        ForEach(MenuBarStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .fixedSize()
                }

                LabeledContent {
                    preview
                } label: {
                    Text("Preview")
                }
            }

            Section {
                SettingsRow(
                    title: "Suggest icons from names",
                    subtitle: "Pick an icon and color automatically based on a Space’s name, until you choose your own."
                ) {
                    Toggle("", isOn: $appearance.suggestIcons)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }
        }
    }

    /// A small mock of the menu-bar item in the currently selected style.
    private var preview: some View {
        HStack(spacing: 4) {
            if appearance.menuBarStyle.showsIcon {
                Image(systemName: "rectangle.3.group")
            }
            if appearance.menuBarStyle.showsName {
                Text("Work")
            }
        }
        .font(.callout)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
    }
}
