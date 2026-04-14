//
//  CardCreatorView.swift
//  birthdayapp
//
//  Created by Preeti Dave on 4/12/26.
//

import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct CardCreatorView: View {
    @Query(sort: \Birthday.date) private var birthdays: [Birthday]
    @State private var selectedBirthday: Birthday?

    var body: some View {
        NavigationStack {
            Group {
                if birthdays.isEmpty {
                    emptyState
                } else if let birthday = selectedBirthday {
                    CardEditorView(birthday: birthday)
                } else {
                    birthdayPicker
                }
            }
            .navigationTitle("Birthday Cards 💌")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("💌")
                .font(.system(size: 80))
            Text("No Birthdays Yet")
                .font(.title2.bold())
            Text("Add birthdays first to create cards")
                .foregroundStyle(.secondary)
        }
    }

    private var birthdayPicker: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Choose a birthday to create a card")
                    .font(.headline)
                    .padding(.top)

                ForEach(birthdays.sorted { $0.daysUntilBirthday < $1.daysUntilBirthday }) { birthday in
                    Button {
                        withAnimation {
                            selectedBirthday = birthday
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Text(birthday.emoji)
                                .font(.system(size: 36))
                            VStack(alignment: .leading) {
                                Text(birthday.name)
                                    .font(.headline)
                                Text(birthday.date, format: .dateTime.month(.wide).day())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Shared card visuals

enum BirthdayCardEditorPalette {
    static let colors: [(name: String, colors: [Color])] = [
        ("Pink Sunset", [.pink, .orange]),
        ("Ocean Blue", [.blue, .cyan]),
        ("Purple Dream", [.purple, .pink]),
        ("Green Garden", [.green, .mint]),
        ("Golden Hour", [.yellow, .orange]),
        ("Midnight", [.indigo, .purple]),
    ]

    static func font(for index: Int) -> Font {
        switch index {
        case 1: return .system(.title2, design: .rounded, weight: .bold)
        case 2: return .system(.title2, design: .serif, weight: .bold)
        case 3: return .system(.title2, design: .monospaced, weight: .bold)
        default: return .system(.title2, weight: .bold)
        }
    }
}

struct BirthdayCardCanvas: View {
    let birthday: Birthday
    let message: String
    let colorIndex: Int
    let fontIndex: Int
    /// When set, shown full-bleed behind text with a dark overlay for contrast.
    var backgroundImage: UIImage?
    /// `ImageRenderer` needs a definite width; off-screen `maxWidth: .infinity` often rasterizes empty.
    var forImageExport: Bool = false

    private var cardColors: [(name: String, colors: [Color])] { BirthdayCardEditorPalette.colors }

    private var usesPhotoBackground: Bool { backgroundImage != nil }

    private var cardSide: CGFloat { 360 }

    var body: some View {
        ZStack {
            Group {
                if let uiImage = backgroundImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: cardColors[colorIndex].colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .frame(width: forImageExport ? cardSide : nil)
            .frame(maxWidth: forImageExport ? nil : .infinity)
            .frame(height: cardSide)
            .clipped()

            if usesPhotoBackground {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.55), Color.black.opacity(0.35)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 16) {
                Spacer()

                Text(birthday.emoji)
                    .font(.system(size: 60))
                    .birthdayCardLegibilityShadow(usesPhotoBackground)

                Text("Happy Birthday!")
                    .font(BirthdayCardEditorPalette.font(for: fontIndex))
                    .foregroundStyle(.white)
                    .birthdayCardLegibilityShadow(usesPhotoBackground)

                Text(birthday.name)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .birthdayCardLegibilityShadow(usesPhotoBackground)

                if !message.isEmpty {
                    Text(message)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .birthdayCardLegibilityShadow(usesPhotoBackground)
                }

                Spacer()

                Text("🎂 \(birthday.date, format: .dateTime.month(.wide).day()) 🎂")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.bottom, 20)
                    .birthdayCardLegibilityShadow(usesPhotoBackground)
            }
            .padding(.horizontal, 8)
        }
        .frame(width: forImageExport ? cardSide : nil)
        .frame(maxWidth: forImageExport ? nil : .infinity)
        .frame(height: cardSide)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(
            color: usesPhotoBackground ? Color.black.opacity(0.35) : (cardColors[colorIndex].colors.first?.opacity(0.3) ?? .clear),
            radius: forImageExport ? 0 : 10,
            y: forImageExport ? 0 : 5
        )
    }
}

/// Stable identity so `.sheet(item:)` passes a fresh `UIImage` into `UIActivityViewController`.
private struct ShareCardImagePayload: Identifiable {
    let id = UUID()
    let image: UIImage
}

// MARK: - Rasterize card for sharing

/// Renders the card off-screen in its own `UIWindow` so we never attach a snapshot view to the **key window**
/// (that could linger, confuse multitasking, or show up when leaving the app).
private enum BirthdayCardSnapshot {
    static let exportSize = CGSize(width: 360, height: 360)

    @MainActor
    static func makeShareImage(
        birthday: Birthday,
        message: String,
        colorIndex: Int,
        fontIndex: Int,
        backgroundPhoto: UIImage?
    ) -> UIImage? {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
        else { return nil }

        let exportView = BirthdayCardCanvas(
            birthday: birthday,
            message: message,
            colorIndex: colorIndex,
            fontIndex: fontIndex,
            backgroundImage: backgroundPhoto,
            forImageExport: true
        )
        .frame(width: exportSize.width, height: exportSize.height)
        .preferredColorScheme(.light)

        let hosting = UIHostingController(rootView: exportView)
        hosting.view.backgroundColor = .clear
        hosting.view.isOpaque = false

        let snapWindow = UIWindow(windowScene: scene)
        snapWindow.frame = CGRect(
            x: scene.screen.bounds.midX - exportSize.width / 2,
            y: scene.screen.bounds.maxY + exportSize.height,
            width: exportSize.width,
            height: exportSize.height
        )
        snapWindow.windowLevel = .normal
        snapWindow.isUserInteractionEnabled = false
        snapWindow.backgroundColor = .clear
        snapWindow.isOpaque = false
        snapWindow.rootViewController = hosting
        snapWindow.isHidden = false

        hosting.view.frame = CGRect(origin: .zero, size: exportSize)
        snapWindow.layoutIfNeeded()
        hosting.view.layoutIfNeeded()

        defer {
            snapWindow.isHidden = true
            snapWindow.rootViewController = nil
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scene.screen.scale
        format.opaque = false

        return UIGraphicsImageRenderer(size: exportSize, format: format).image { _ in
            hosting.view.drawHierarchy(in: CGRect(origin: .zero, size: exportSize), afterScreenUpdates: true)
        }
    }
}

private extension View {
    @ViewBuilder
    func birthdayCardLegibilityShadow(_ enabled: Bool) -> some View {
        if enabled {
            shadow(color: .black.opacity(0.55), radius: 6, x: 0, y: 2)
        } else {
            self
        }
    }
}

// MARK: - Card Editor

struct CardEditorView: View {
    @Bindable var birthday: Birthday
    @State private var message: String = ""
    @State private var selectedColorIndex = 0
    @State private var selectedFont = 0
    @State private var showSavedAlert = false
    @State private var sharePayload: ShareCardImagePayload?
    @State private var shareRenderFailed = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var backgroundPhoto: UIImage?

    private let fontNames = ["Default", "Rounded", "Serif", "Monospace"]

    private var cardColors: [(name: String, colors: [Color])] { BirthdayCardEditorPalette.colors }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                BirthdayCardCanvas(
                    birthday: birthday,
                    message: message,
                    colorIndex: selectedColorIndex,
                    fontIndex: selectedFont,
                    backgroundImage: backgroundPhoto
                )
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Message")
                        .font(.headline)
                    TextField("Happy Birthday! 🎉", text: $message, axis: .vertical)
                        .lineLimit(3...8)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Background")
                        .font(.headline)
                    Text("Pick a photo from your library. It fills the card behind your message.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        PhotosPicker(selection: $photoPickerItem, matching: .images, photoLibrary: .shared()) {
                            Label(backgroundPhoto == nil ? "Choose Photo" : "Change Photo", systemImage: "photo.on.rectangle.angled")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)
                        .tint(.pink)

                        if backgroundPhoto != nil {
                            Button("Remove") {
                                backgroundPhoto = nil
                                photoPickerItem = nil
                            }
                            .font(.subheadline.weight(.semibold))
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Card Color")
                        .font(.headline)
                        .padding(.horizontal)
                    Text("Used when no photo is selected.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0 ..< cardColors.count, id: \.self) { index in
                                Circle()
                                    .fill(
                                        LinearGradient(colors: cardColors[index].colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(.white, lineWidth: selectedColorIndex == index ? 3 : 0)
                                    )
                                    .opacity(backgroundPhoto == nil ? 1 : 0.45)
                                    .shadow(color: selectedColorIndex == index ? .pink.opacity(0.4) : .clear, radius: 4)
                                    .accessibilityLabel("Color \(cardColors[index].name)")
                                    .onTapGesture {
                                        withAnimation { selectedColorIndex = index }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Font Style")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(0 ..< fontNames.count, id: \.self) { index in
                                Text(fontNames[index])
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedFont == index ? Color.pink : Color(.systemGray5))
                                    )
                                    .foregroundStyle(selectedFont == index ? .white : .primary)
                                    .onTapGesture {
                                        withAnimation { selectedFont = index }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Button {
                    birthday.cardMessage = message
                    showSavedAlert = true
                } label: {
                    Label("Save Card", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.pink)
                        )
                        .foregroundStyle(.white)
                }
                .padding(.horizontal)

                Button {
                    birthday.cardMessage = message
                    renderAndShare()
                } label: {
                    Label("Share as Image", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.pink, lineWidth: 2)
                        )
                        .foregroundStyle(.pink)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .onAppear {
            message = birthday.cardMessage.isEmpty ? "Happy Birthday, \(birthday.name)! 🎉" : birthday.cardMessage
        }
        .alert("Card Saved! 🎉", isPresented: $showSavedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your birthday card for \(birthday.name) has been saved.")
        }
        .sheet(item: $sharePayload) { payload in
            ActivityView(items: [payload.image])
        }
        .alert("Couldn’t share", isPresented: $shareRenderFailed) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The card image couldn’t be created. Try again, or use Save and screenshot the card.")
        }
        .onChange(of: photoPickerItem) { _, newItem in
            Task {
                guard let newItem else { return }
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        backgroundPhoto = image
                    }
                }
            }
        }
    }

    private func renderAndShare() {
        birthday.cardMessage = message

        func rasterize() -> UIImage? {
            BirthdayCardSnapshot.makeShareImage(
                birthday: birthday,
                message: message,
                colorIndex: selectedColorIndex,
                fontIndex: selectedFont,
                backgroundPhoto: backgroundPhoto
            )
        }

        if let image = rasterize() {
            sharePayload = ShareCardImagePayload(image: image)
            return
        }

        DispatchQueue.main.async {
            if let image = rasterize() {
                sharePayload = ShareCardImagePayload(image: image)
            } else {
                shareRenderFailed = true
            }
        }
    }
}

#Preview {
    CardCreatorView()
        .modelContainer(for: [Birthday.self, PartyGuest.self, PartyTodo.self], inMemory: true)
}
