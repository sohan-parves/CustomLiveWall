import SwiftUI

struct SettingsView: View {

    @EnvironmentObject private var manager: WallpaperManager

    @State private var selectedTab: SettingsTab = .gallery
    @State private var loop = WallpaperStorage.shared.loopVideo
    @State private var pauseOnBattery = WallpaperStorage.shared.pauseOnBattery
    @State private var pauseOnLock = WallpaperStorage.shared.pauseOnLock
    @State private var launchAtLogin = WallpaperStorage.shared.launchAtLogin
    @State private var audioMuted = WallpaperStorage.shared.audioMuted
    @State private var webURLString: String = WallpaperStorage.shared.selectedWebURL?.absoluteString ?? ""
    @State private var showStatusMessage = false
    @State private var statusMessage = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                SettingsWindowTitleBar()
                    .background(Color(nsColor: .windowBackgroundColor))

                NavigationSplitView {
                    List(selection: $selectedTab) {
                        Section("Wallpaper") {
                            Label(SettingsTab.gallery.title, systemImage: SettingsTab.gallery.icon)
                                .tag(SettingsTab.gallery)
                            Label(SettingsTab.importSource.title, systemImage: SettingsTab.importSource.icon)
                                .tag(SettingsTab.importSource)
                        }

                        Section("Preferences") {
                            Label(SettingsTab.playback.title, systemImage: SettingsTab.playback.icon)
                                .tag(SettingsTab.playback)
                            Label(SettingsTab.system.title, systemImage: SettingsTab.system.icon)
                                .tag(SettingsTab.system)
                        }
                    }
                    .listStyle(.sidebar)
                    .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 240)
                } detail: {
                    VStack(spacing: 0) {
                        headerBar
                        Divider()
                        detailContent
                    }
                    .background(Color(nsColor: .windowBackgroundColor))
                }
            }

            if showStatusMessage {
                statusToast
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(minWidth: 760, minHeight: 680)
        .background(SettingsWindowConfigurator())
        .onAppear {
            syncFromStorage()
        }
    }

    private var headerBar: some View {
        HStack(spacing: 16) {
            AppBrandIconView(size: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text("CustomLiveWall")
                    .font(.title2.weight(.semibold))

                HStack(spacing: 8) {
                    Circle()
                        .fill(manager.isPlaying ? .green : .orange)
                        .frame(width: 8, height: 8)

                    Text(manager.isPlaying ? "Playing" : "Paused")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.tertiary)

                    Text(sourceDescription(manager.currentSource))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button(action: togglePlayback) {
                Label(
                    manager.isPlaying ? "Pause" : "Play",
                    systemImage: manager.isPlaying ? "pause.fill" : "play.fill"
                )
            }
            .buttonStyle(.borderedProminent)
            .tint(manager.isPlaying ? .orange : .green)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    @ViewBuilder
    private var detailContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch selectedTab {
                case .gallery:
                    gallerySection
                case .importSource:
                    importSection
                case .playback:
                    playbackSection
                case .system:
                    systemSection
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var gallerySection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeader(
                title: "Wallpaper Gallery",
                subtitle: "Choose a built-in sample or one of your imported videos. The selected wallpaper plays immediately."
            )

            if !manager.importedWallpapers.isEmpty {
                galleryGroup(title: "Your Imports") {
                    ForEach(manager.importedWallpapers.map { WallpaperGalleryItem.imported($0) }) { item in
                        GalleryWallpaperCard(
                            item: item,
                            isSelected: manager.isGalleryItemSelected(item),
                            onSelect: { selectGalleryItem(item) },
                            onRemove: {
                                if case .imported(let imported) = item {
                                    removeImportedWallpaper(imported)
                                }
                            }
                        )
                    }
                }
            }

            galleryGroup(title: "Built-in Samples") {
                ForEach(SampleWallpaperCatalog.samples.map { WallpaperGalleryItem.sample($0) }) { item in
                    GalleryWallpaperCard(
                        item: item,
                        isSelected: manager.isGalleryItemSelected(item),
                        onSelect: { selectGalleryItem(item) }
                    )
                }
            }
        }
    }

    private func galleryGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 16)], spacing: 16) {
                content()
            }
        }
    }

    private var importSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeader(
                title: "Custom Wallpaper",
                subtitle: "Import your own video file or load a web-based wallpaper."
            )

            SettingsPanel {
                Button(action: {
                    selectedTab = .gallery
                    chooseVideo()
                }) {
                    Label("Choose Video File", systemImage: "film.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            SettingsPanel {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Web Wallpaper URL", systemImage: "globe")
                        .font(.headline)

                    Text("Enter a webpage URL that renders your animated wallpaper.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        TextField("https://example.com/wallpaper.html", text: $webURLString)
                            .textFieldStyle(.roundedBorder)

                        Button("Load", action: loadWebURL)
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }

    private var playbackSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeader(
                title: "Playback",
                subtitle: "Control how your live wallpaper behaves while you work."
            )

            SettingsPanel {
                Toggle(isOn: $loop) {
                    settingsRow(
                        title: "Loop Video",
                        subtitle: "Restart automatically when the clip ends",
                        icon: "repeat"
                    )
                }
                .onChange(of: loop) { _, newValue in
                    WallpaperStorage.shared.loopVideo = newValue
                    manager.refreshAllWindows()
                    showStatus("Loop \(newValue ? "enabled" : "disabled")")
                }

                Divider()

                Toggle(isOn: $audioMuted) {
                    settingsRow(
                        title: "Mute Audio",
                        subtitle: "Silence wallpaper sound on all displays",
                        icon: audioMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"
                    )
                }
                .onChange(of: audioMuted) { _, newValue in
                    manager.setMuted(newValue)
                    showStatus("Audio \(newValue ? "muted" : "unmuted")")
                }

                Divider()

                Toggle(isOn: $pauseOnBattery) {
                    settingsRow(
                        title: "Pause on Battery",
                        subtitle: "Save power when running on battery",
                        icon: "battery.100percent"
                    )
                }
                .onChange(of: pauseOnBattery) { _, newValue in
                    WallpaperStorage.shared.pauseOnBattery = newValue
                    showStatus("Battery pause \(newValue ? "enabled" : "disabled")")
                }

                Divider()

                Toggle(isOn: $pauseOnLock) {
                    settingsRow(
                        title: "Pause on Lock",
                        subtitle: "Stop playback when the screen locks or sleeps",
                        icon: "lock.fill"
                    )
                }
                .onChange(of: pauseOnLock) { _, newValue in
                    WallpaperStorage.shared.pauseOnLock = newValue
                    showStatus("Lock pause \(newValue ? "enabled" : "disabled")")
                }
            }

            SettingsPanel {
                HStack {
                    Label("Connected Displays", systemImage: "display.2")
                    Spacer()
                    Text("\(NSScreen.screens.count)")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.blue)
                }

                Divider()

                Button(action: applyToAllDisplays) {
                    Label("Refresh All Displays", systemImage: "arrow.clockwise.circle.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var systemSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeader(
                title: "System",
                subtitle: "Startup and app preferences."
            )

            SettingsPanel {
                Toggle(isOn: $launchAtLogin) {
                    settingsRow(
                        title: "Launch at Login",
                        subtitle: "Start CustomLiveWall automatically when you sign in",
                        icon: "arrowshape.up.circle.fill"
                    )
                }
                .onChange(of: launchAtLogin) { _, newValue in
                    WallpaperStorage.shared.launchAtLogin = newValue
                    LoginItemManager.shared.setEnabled(newValue)
                    showStatus("Launch at login \(newValue ? "enabled" : "disabled")")
                }
            }

            SettingsPanel {
                VStack(alignment: .leading, spacing: 8) {
                    Label("About", systemImage: "info.circle.fill")
                        .font(.headline)

                    Text("CustomLiveWall brings cinematic motion to your desktop with minimal battery impact.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Version 1.0")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
        }
    }

    private var statusToast: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(statusMessage)
                .font(.subheadline)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.green.opacity(0.25), lineWidth: 1)
        )
        .padding(20)
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.weight(.semibold))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func settingsRow(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 22)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func syncFromStorage() {
        loop = WallpaperStorage.shared.loopVideo
        pauseOnBattery = WallpaperStorage.shared.pauseOnBattery
        pauseOnLock = WallpaperStorage.shared.pauseOnLock
        launchAtLogin = WallpaperStorage.shared.launchAtLogin
        audioMuted = WallpaperStorage.shared.audioMuted
        manager.setMuted(audioMuted)
    }

    private func selectGalleryItem(_ item: WallpaperGalleryItem) {
        manager.selectGalleryItem(item)
        showStatus("\(item.name) is now playing")
    }

    private func removeImportedWallpaper(_ imported: ImportedWallpaper) {
        let name = imported.displayName
        manager.removeImportedWallpaper(imported)
        showStatus("Removed \(name) from gallery")
    }

    private func chooseVideo() {
        let parentWindow = NSApp.keyWindow ?? NSApp.windows.first { $0.title == "CustomLiveWall Settings" }
        WallpaperPicker.pickVideo(relativeTo: parentWindow) { url in
            guard let url else { return }
            if manager.importVideo(from: url) != nil {
                selectedTab = .gallery
                showStatus("Added to gallery: \(url.deletingPathExtension().lastPathComponent)")
            } else {
                showStatus("Could not import video")
            }
        }
    }

    private func loadWebURL() {
        guard !webURLString.isEmpty else { return }
        guard let url = URL(string: webURLString) else {
            showStatus("Invalid URL")
            return
        }
        WallpaperStorage.shared.selectedWebURL = url
        manager.selectAndPlay(.web(url))
        showStatus("Web wallpaper loaded")
    }

    private func togglePlayback() {
        if manager.isPlaying {
            manager.stop()
            showStatus("Wallpaper paused")
        } else {
            manager.start()
            showStatus("Wallpaper playing")
        }
    }

    private func applyToAllDisplays() {
        manager.refreshAllWindows()
        showStatus("Applied to all displays")
    }

    private func sourceDescription(_ source: WallpaperSource) -> String {
        switch source {
        case .bundledVideo(let name, let ext):
            if let sample = SampleWallpaperCatalog.samples.first(where: { $0.resourceName == name && $0.ext == ext }) {
                return sample.name
            }
            return "\(name).\(ext)"
        case .video(let url):
            if let imported = manager.importedWallpapers.first(where: { ImportedWallpaperStore.shared.resolveURL(for: $0) == url }) {
                return imported.displayName
            }
            return url.lastPathComponent
        case .web(let url):
            return url.host ?? url.absoluteString
        }
    }

    private func showStatus(_ message: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            statusMessage = message
            showStatusMessage = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showStatusMessage = false
            }
        }
    }
}

private enum SettingsTab: Hashable {
    case gallery
    case importSource
    case playback
    case system

    var title: String {
        switch self {
        case .gallery: return "Gallery"
        case .importSource: return "Import"
        case .playback: return "Playback"
        case .system: return "System"
        }
    }

    var icon: String {
        switch self {
        case .gallery: return "photo.on.rectangle.angled"
        case .importSource: return "square.and.arrow.down"
        case .playback: return "play.circle"
        case .system: return "gearshape"
        }
    }
}

private struct GalleryWallpaperCard: View {
    let item: WallpaperGalleryItem
    let isSelected: Bool
    let onSelect: () -> Void
    var onRemove: (() -> Void)? = nil

    @State private var thumbnail: NSImage?
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Group {
                    if let thumbnail {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            LinearGradient(
                                colors: [.blue.opacity(0.35), .purple.opacity(0.35)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            Image(systemName: item.icon)
                                .font(.system(size: 28))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                }
                .frame(height: 120)
                .clipped()

                if isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            Label("Active", systemImage: "checkmark.circle.fill")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                        Spacer()
                    }
                    .padding(8)
                }

                if let onRemove, isHovering {
                    VStack {
                        HStack {
                            Button(action: onRemove) {
                                Image(systemName: "trash.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(7)
                                    .background(.red.opacity(0.85), in: Circle())
                            }
                            .buttonStyle(.plain)
                            .help("Remove from gallery")
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(12)
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? Color.accentColor : Color(nsColor: .separatorColor), lineWidth: isSelected ? 2 : 0.5)
        )
        .shadow(color: .black.opacity(isSelected ? 0.12 : 0.05), radius: isSelected ? 10 : 4, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture(perform: onSelect)
        .onHover { isHovering = $0 }
        .task(id: item.id) {
            thumbnail = await loadThumbnail()
        }
    }

    private func loadThumbnail() async -> NSImage? {
        switch item {
        case .sample(let sample):
            return await VideoThumbnailGenerator.bundledThumbnail(
                resourceName: sample.resourceName,
                ext: sample.ext
            )
        case .imported(let imported):
            guard let url = ImportedWallpaperStore.shared.resolveURL(for: imported) else { return nil }
            return await VideoThumbnailGenerator.thumbnail(for: url)
        }
    }
}

private struct SettingsPanel<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.6), lineWidth: 0.5)
        )
    }
}
