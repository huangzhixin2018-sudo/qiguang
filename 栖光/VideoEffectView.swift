//
//  VideoEffectView.swift
//  栖光
//
//  Created by zhixin on 2026/8/6.
//

import SwiftUI
import PhotosUI
import AVKit
import UniformTypeIdentifiers

struct VideoEffectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var player: AVPlayer?
    @State private var selectedFilter: VideoFilter = .vhs8mm
    @State private var playbackSpeed: Float = 1.0
    @State private var effectIntensity = 0.72
    @State private var isPlaying = false
    @State private var isImporting = false
    @State private var importError: String?

    enum VideoFilter: String, CaseIterable, Identifiable {
        case vhs8mm
        case retroVHS
        case classicNoir
        case warmSunset

        var id: String { rawValue }

        var title: String {
            switch self {
            case .vhs8mm: return "8mm"
            case .retroVHS: return "VCR"
            case .classicNoir: return "银盐"
            case .warmSunset: return "港风"
            }
        }

        var subtitle: String {
            switch self {
            case .vhs8mm: return "KODAK 50D"
            case .retroVHS: return "HI8 1998"
            case .classicNoir: return "MONO 400"
            case .warmSunset: return "TUNGSTEN"
            }
        }

        var icon: String {
            switch self {
            case .vhs8mm: return "camera.aperture"
            case .retroVHS: return "recordingtape"
            case .classicNoir: return "circle.lefthalf.filled"
            case .warmSunset: return "sun.haze.fill"
            }
        }

        var accent: Color {
            switch self {
            case .vhs8mm: return Color(red: 0.95, green: 0.69, blue: 0.22)
            case .retroVHS: return Color(red: 0.25, green: 0.78, blue: 0.80)
            case .classicNoir: return Color(white: 0.88)
            case .warmSunset: return Color(red: 0.93, green: 0.32, blue: 0.22)
            }
        }

        var saturation: Double {
            switch self {
            case .vhs8mm: return 0.82
            case .retroVHS: return 0.74
            case .classicNoir: return 0
            case .warmSunset: return 1.12
            }
        }

        var contrast: Double {
            switch self {
            case .vhs8mm: return 1.08
            case .retroVHS: return 1.03
            case .classicNoir: return 1.24
            case .warmSunset: return 1.08
            }
        }

        var thumbnailSeed: Int {
            switch self {
            case .vhs8mm: return 17
            case .retroVHS: return 31
            case .classicNoir: return 47
            case .warmSunset: return 61
            }
        }
    }

    var body: some View {
        ZStack {
            Color(red: 0.055, green: 0.058, blue: 0.062)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ProjectionStage(
                    player: player,
                    filter: selectedFilter,
                    intensity: effectIntensity,
                    isPlaying: isPlaying,
                    isImporting: isImporting
                )
                .aspectRatio(4.0 / 3.0, contentMode: .fit)
                .frame(maxWidth: 720)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                controlDeck
            }
        }
        .navigationBarHidden(true)
        .hideTabBarOnRealDevice()
        .preferredColorScheme(.dark)
        .onChange(of: selectedVideoItem) { _, newItem in
            loadVideo(from: newItem)
        }
        .onDisappear {
            player?.pause()
            isPlaying = false
        }
        .alert("无法导入视频", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(importError ?? "请稍后重试")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("视频滤镜")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

                Text(selectedFilter.subtitle)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(selectedFilter.accent.opacity(0.9))
            }

            Spacer()

            PhotosPicker(selection: $selectedVideoItem, matching: .videos) {
                Image(systemName: player == nil ? "plus" : "arrow.triangle.2.circlepath")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.black)
                    .frame(width: 40, height: 40)
                    .background(selectedFilter.accent, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(isImporting)
            .help(player == nil ? "导入视频" : "更换视频")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private var controlDeck: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                if let player {
                    PlaybackScrubber(player: player, accent: selectedFilter.accent)

                    HStack(spacing: 18) {
                        Button {
                            skip(seconds: -5)
                        } label: {
                            Image(systemName: "gobackward.5")
                                .frame(width: 40, height: 40)
                        }

                        Button {
                            togglePlayPause()
                        } label: {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 19, weight: .bold))
                                .foregroundStyle(.black)
                                .frame(width: 48, height: 48)
                                .background(selectedFilter.accent, in: Circle())
                        }

                        Button {
                            skip(seconds: 5)
                        } label: {
                            Image(systemName: "goforward.5")
                                .frame(width: 40, height: 40)
                        }

                        Spacer()

                        Menu {
                            ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { speed in
                                Button(String(format: "%.1fx", speed)) {
                                    setSpeed(Float(speed))
                                }
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Text(String(format: "%.1fx", playbackSpeed))
                                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .frame(height: 36)
                            .padding(.horizontal, 12)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .foregroundStyle(.white.opacity(0.82))
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 11) {
                    HStack {
                        Text("胶片机型")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.72))

                        Spacer()

                        Text(selectedFilter.subtitle)
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(selectedFilter.accent.opacity(0.9))
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(VideoFilter.allCases) { filter in
                                FilterSelectorTile(
                                    filter: filter,
                                    isSelected: filter == selectedFilter
                                ) {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        selectedFilter = filter
                                    }
                                }
                            }
                        }
                    }
                }

                HStack(spacing: 14) {
                    Image(systemName: "dial.medium")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(selectedFilter.accent)

                    Text("质感")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))

                    Slider(value: $effectIntensity, in: 0...1)
                        .tint(selectedFilter.accent)

                    Text("\(Int(effectIntensity * 100))")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(width: 26, alignment: .trailing)
                }
                .frame(height: 36)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.075, green: 0.078, blue: 0.084))
    }

    private func loadVideo(from item: PhotosPickerItem?) {
        guard let item else { return }
        isImporting = true
        importError = nil

        Task {
            do {
                guard let movie = try await item.loadTransferable(type: MovieTransferable.self) else {
                    throw VideoImportError.noMovie
                }

                await MainActor.run {
                    player?.pause()
                    let newPlayer = AVPlayer(url: movie.url)
                    newPlayer.actionAtItemEnd = .pause
                    player = newPlayer
                    newPlayer.playImmediately(atRate: playbackSpeed)
                    isPlaying = true
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    importError = "视频文件没有成功载入，请重新选择。"
                }
            }
        }
    }

    private func togglePlayPause() {
        guard let player else { return }
        if isPlaying {
            player.pause()
        } else {
            if player.currentItem?.duration.seconds == player.currentTime().seconds {
                player.seek(to: .zero)
            }
            player.playImmediately(atRate: playbackSpeed)
        }
        isPlaying.toggle()
    }

    private func skip(seconds: Double) {
        guard let player else { return }
        let duration = player.currentItem?.duration.seconds ?? 0
        let target = min(max(player.currentTime().seconds + seconds, 0), duration)
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
    }

    private func setSpeed(_ speed: Float) {
        playbackSpeed = speed
        if isPlaying {
            player?.rate = speed
        }
    }
}

private struct ProjectionStage: View {
    let player: AVPlayer?
    let filter: VideoEffectView.VideoFilter
    let intensity: Double
    let isPlaying: Bool
    let isImporting: Bool

    var body: some View {
        ZStack {
            Color.black

            if let player {
                SilentVideoPlayer(player: player)
                    .saturation(filter.saturation)
                    .contrast(1 + ((filter.contrast - 1) * intensity))
                    .brightness(filter == .classicNoir ? -0.025 * intensity : 0)
                    .scaleEffect(filter == .retroVHS ? 1.012 : 1.0)

                AnimatedFilmEffect(
                    filter: filter,
                    intensity: intensity,
                    isPlaying: isPlaying,
                    player: player
                )
                .allowsHitTesting(false)
            } else {
                ProjectorIdleView(isImporting: isImporting)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.55), radius: 20, x: 0, y: 10)
        .accessibilityLabel(player == nil ? "未导入视频" : "视频预览")
    }
}

private struct SilentVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspect
        controller.view.backgroundColor = .black
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        controller.player = player
    }
}

private struct ProjectorIdleView: View {
    let isImporting: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 18.0)) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                Color(red: 0.025, green: 0.026, blue: 0.028)

                LinearGradient(
                    colors: [
                        Color(red: 0.32, green: 0.27, blue: 0.19).opacity(0.18),
                        Color.clear,
                        Color.black.opacity(0.32)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                FilmGrainCanvas(seed: Int(phase * 18), intensity: 0.42)
                    .opacity(0.55)

                VStack(spacing: 12) {
                    if isImporting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "play.rectangle.on.rectangle")
                            .font(.system(size: 31, weight: .light))
                            .foregroundStyle(Color.white.opacity(0.82))

                        Text("NO FILM LOADED")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.48))
                    }
                }
            }
        }
    }
}

private struct AnimatedFilmEffect: View {
    let filter: VideoEffectView.VideoFilter
    let intensity: Double
    let isPlaying: Bool
    let player: AVPlayer

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: !isPlaying)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let frame = Int(time * 24)

            GeometryReader { proxy in
                ZStack {
                    colorTreatment(time: time)

                    switch filter {
                    case .vhs8mm:
                        FilmGrainCanvas(seed: frame, intensity: intensity)
                        FilmDustCanvas(seed: frame, intensity: intensity)
                        gateVignette
                        filmMetadata

                    case .retroVHS:
                        VHSScanlineCanvas(intensity: intensity)
                        trackingBand(time: time, height: proxy.size.height)
                        vhsMetadata

                    case .classicNoir:
                        FilmGrainCanvas(seed: frame, intensity: intensity * 0.86)
                            .blendMode(.screen)
                        FilmDustCanvas(seed: frame, intensity: intensity * 0.48)
                        gateVignette.opacity(0.74)

                    case .warmSunset:
                        FilmGrainCanvas(seed: frame, intensity: intensity * 0.32)
                        edgeLightLeak(time: time, width: proxy.size.width)
                        gateVignette.opacity(0.42)
                    }
                }
                .opacity(0.22 + intensity * 0.78)
                .offset(
                    x: filter == .vhs8mm ? sin(time * 17) * 0.7 * intensity : 0,
                    y: filter == .vhs8mm ? cos(time * 13) * 0.55 * intensity : 0
                )
            }
        }
    }

    @ViewBuilder
    private func colorTreatment(time: TimeInterval) -> some View {
        switch filter {
        case .vhs8mm:
            Color(red: 0.96, green: 0.65, blue: 0.25)
                .opacity((0.035 + sin(time * 19) * 0.012) * intensity)
                .blendMode(.screen)
        case .retroVHS:
            LinearGradient(
                colors: [Color.cyan.opacity(0.055), Color.clear, Color.red.opacity(0.045)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .blendMode(.screen)
        case .classicNoir:
            Color.white.opacity((0.018 + sin(time * 11) * 0.009) * intensity)
                .blendMode(.screen)
        case .warmSunset:
            LinearGradient(
                colors: [Color(red: 0.94, green: 0.23, blue: 0.14).opacity(0.10), Color.clear, Color(red: 0.96, green: 0.70, blue: 0.28).opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.screen)
        }
    }

    private var gateVignette: some View {
        RadialGradient(
            colors: [Color.clear, Color.clear, Color.black.opacity(0.78)],
            center: .center,
            startRadius: 60,
            endRadius: 310
        )
    }

    private var filmMetadata: some View {
        VStack {
            HStack {
                Text("8MM  50D")
                Spacer()
                Text("24 FPS")
            }
            Spacer()
        }
        .font(.system(size: 9, weight: .semibold, design: .monospaced))
        .foregroundStyle(.white.opacity(0.62))
        .padding(11)
    }

    private var vhsMetadata: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
                Text("PLAY")
                Spacer()
                Text("SP")
            }
            Spacer()
            Text(vhsTimecode)
        }
        .font(.system(size: 10, weight: .semibold, design: .monospaced))
        .foregroundStyle(.white.opacity(0.86))
        .shadow(color: .black, radius: 1)
        .padding(12)
    }

    private var vhsTimecode: String {
        let seconds = max(player.currentTime().seconds, 0)
        let minutes = Int(seconds) / 60
        let remainder = Int(seconds) % 60
        return String(format: "98.08.06  %02d:%02d", minutes, remainder)
    }

    private func trackingBand(time: TimeInterval, height: CGFloat) -> some View {
        let travel = max(height + 52, 1)
        let y = CGFloat((time * 42).truncatingRemainder(dividingBy: Double(travel))) - 26

        return Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.clear, Color.white.opacity(0.18), Color.cyan.opacity(0.12), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 32)
            .offset(y: y - height / 2)
            .blur(radius: 1.2)
    }

    private func edgeLightLeak(time: TimeInterval, width: CGFloat) -> some View {
        let offset = CGFloat(sin(time * 0.42)) * width * 0.18

        return HStack(spacing: 0) {
            LinearGradient(
                colors: [Color.red.opacity(0.62), Color.orange.opacity(0.24), Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width * 0.42)
            Spacer(minLength: 0)
        }
        .offset(x: offset - width * 0.08)
        .blur(radius: 12)
        .blendMode(.screen)
    }
}

private struct FilmGrainCanvas: View {
    let seed: Int
    let intensity: Double

    var body: some View {
        Canvas { context, size in
            let count = 190
            for index in 0..<count {
                let x = unitValue(index &* 47 &+ seed &* 19) * size.width
                let y = unitValue(index &* 89 &+ seed &* 31) * size.height
                let side = 0.55 + unitValue(index &* 23 &+ seed) * 1.35
                let opacity = (0.08 + unitValue(index &* 71 &+ seed &* 7) * 0.30) * intensity
                context.fill(
                    Path(CGRect(x: x, y: y, width: side, height: side)),
                    with: .color(index.isMultiple(of: 3) ? Color.black.opacity(opacity) : Color.white.opacity(opacity))
                )
            }
        }
        .blendMode(.overlay)
    }

    private func unitValue(_ value: Int) -> CGFloat {
        let mixed = UInt(bitPattern: value &* 73 &+ 41)
        return CGFloat(mixed % 997) / 997
    }
}

private struct FilmDustCanvas: View {
    let seed: Int
    let intensity: Double

    var body: some View {
        Canvas { context, size in
            for index in 0..<12 {
                let life = positiveModulo(seed &+ index &* 17, modulus: 47)
                guard life < 5 else { continue }

                let x = CGFloat(positiveModulo(index &* 137 &+ seed &* 11, modulus: 991)) / 991 * size.width
                let y = CGFloat(positiveModulo(index &* 71 &+ seed &* 7, modulus: 983)) / 983 * size.height
                let radius = 0.7 + CGFloat(index % 3)
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius)),
                    with: .color(Color.white.opacity(0.34 * intensity))
                )
            }

            if positiveModulo(seed, modulus: 89) < 2 {
                let x = CGFloat(positiveModulo(seed &* 29, modulus: 947)) / 947 * size.width
                var scratch = Path()
                scratch.move(to: CGPoint(x: x, y: size.height * 0.08))
                scratch.addLine(to: CGPoint(x: x + 1.2, y: size.height * 0.92))
                context.stroke(scratch, with: .color(Color.white.opacity(0.30 * intensity)), lineWidth: 0.7)
            }
        }
        .blendMode(.screen)
    }

    private func positiveModulo(_ value: Int, modulus: UInt) -> Int {
        Int(UInt(bitPattern: value) % modulus)
    }
}

private struct VHSScanlineCanvas: View {
    let intensity: Double

    var body: some View {
        Canvas { context, size in
            var y: CGFloat = 0
            while y < size.height {
                let line = Path(CGRect(x: 0, y: y, width: size.width, height: 1))
                context.fill(line, with: .color(Color.black.opacity(0.18 * intensity)))
                y += 4
            }
        }
        .blendMode(.multiply)
    }
}

private struct FilterSelectorTile: View {
    let filter: VideoEffectView.VideoFilter
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 7) {
                ZStack {
                    FilterThumbnail(filter: filter)

                    Image(systemName: filter.icon)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white.opacity(0.86))
                }
                .frame(width: 104, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? filter.accent : Color.white.opacity(0.12), lineWidth: isSelected ? 2 : 1)
                }

                HStack {
                    Text(filter.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    if isSelected {
                        Circle()
                            .fill(filter.accent)
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .frame(width: 104)
        }
        .buttonStyle(.plain)
    }
}

private struct FilterThumbnail: View {
    let filter: VideoEffectView.VideoFilter

    var body: some View {
        ZStack {
            switch filter {
            case .vhs8mm:
                LinearGradient(colors: [Color(red: 0.52, green: 0.36, blue: 0.18), Color(red: 0.13, green: 0.16, blue: 0.13)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .retroVHS:
                LinearGradient(colors: [Color(red: 0.08, green: 0.28, blue: 0.32), Color(red: 0.30, green: 0.12, blue: 0.24)], startPoint: .leading, endPoint: .trailing)
            case .classicNoir:
                LinearGradient(colors: [Color(white: 0.58), Color(white: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .warmSunset:
                LinearGradient(colors: [Color(red: 0.72, green: 0.16, blue: 0.12), Color(red: 0.92, green: 0.58, blue: 0.20)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }

            FilmGrainCanvas(seed: filter.thumbnailSeed, intensity: 0.45)
                .opacity(0.7)
        }
    }
}

private struct PlaybackScrubber: View {
    let player: AVPlayer
    let accent: Color

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { _ in
            let duration = validSeconds(player.currentItem?.duration.seconds)
            let current = min(validSeconds(player.currentTime().seconds), duration)

            HStack(spacing: 10) {
                Text(timeString(current))
                    .frame(width: 38, alignment: .leading)

                Slider(
                    value: Binding(
                        get: { current },
                        set: { value in
                            player.seek(
                                to: CMTime(seconds: value, preferredTimescale: 600),
                                toleranceBefore: .zero,
                                toleranceAfter: .zero
                            )
                        }
                    ),
                    in: 0...max(duration, 1)
                )
                .tint(accent)

                Text(timeString(duration))
                    .frame(width: 38, alignment: .trailing)
            }
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(.white.opacity(0.55))
        }
        .frame(height: 20)
    }

    private func validSeconds(_ value: Double?) -> Double {
        guard let value, value.isFinite, value >= 0 else { return 0 }
        return value
    }

    private func timeString(_ seconds: Double) -> String {
        String(format: "%02d:%02d", Int(seconds) / 60, Int(seconds) % 60)
    }
}

private enum VideoImportError: Error {
    case noMovie
}

private struct MovieTransferable: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(received.file.pathExtension)
            try FileManager.default.copyItem(at: received.file, to: destination)
            return MovieTransferable(url: destination)
        }
    }
}
