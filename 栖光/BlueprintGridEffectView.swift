//
//  BlueprintGridEffectView.swift
//  栖光
//

import SwiftUI
import PhotosUI
import Photos

struct BlueprintGridEffectView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isLoadingPhoto = false
    @State private var saveMessage: String?
    @State private var effectMode: BlueprintEffectMode = .blue
    @State private var customHue = 0.56
    @State private var customTint = 0.35
    @State private var customSaturation = 0.75
    @State private var customGridStrength = 0.55

    private var isEditing: Bool { selectedImage != nil }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                Group {
                    if let selectedImage {
                        BlueprintGridCanvas(
                            image: selectedImage,
                            mode: effectMode,
                            customHue: customHue,
                            customTint: customTint,
                            customSaturation: customSaturation,
                            gridStrength: customGridStrength
                        )
                    } else {
                        Image("HomeSingle02")
                            .resizable()
                            .scaledToFit()
                    }
                }
                .frame(maxWidth: .infinity)
            }

            if isEditing {
                effectControls
            } else {
                photoButton
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .hideTabBarOnRealDevice()
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                await loadSelectedPhoto(from: newItem)
            }
        }
        .alert(saveMessage ?? "", isPresented: Binding(
            get: { saveMessage != nil },
            set: { if !$0 { saveMessage = nil } }
        )) {
            Button("好", role: .cancel) {
                saveMessage = nil
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if isEditing {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        selectedImage = nil
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("返回效果预览")
            }

            Text("蓝晒网格")
                .font(.system(size: isEditing ? 20 : 26, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            if isEditing {
                Button {
                    saveEffectPhoto()
                } label: {
                    Label("保存", systemImage: "square.and.arrow.down")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .frame(height: 40)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 21, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("关闭")
            }
        }
        .padding(.horizontal, isEditing ? 14 : 20)
        .padding(.vertical, isEditing ? 10 : 14)
        .background(Color.black)
    }

    private var photoButton: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            HStack(spacing: 10) {
                if isLoadingPhoto {
                    ProgressView()
                        .tint(.black)
                } else {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 18, weight: .semibold))
                }

                Text("上传照片")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLoadingPhoto)
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(Color.black)
    }

    private var effectControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Picker("效果", selection: $effectMode) {
                    ForEach(BlueprintEffectMode.allCases) { mode in
                        Text(mode.title)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 44, height: 32)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isLoadingPhoto)
                .accessibilityLabel("更换照片")
            }

            if effectMode == .custom {
                EffectSliderRow(title: "色相", value: $customHue, range: 0...1)
                EffectSliderRow(title: "染色", value: $customTint, range: 0...1)
                EffectSliderRow(title: "饱和", value: $customSaturation, range: 0...1.5)
                EffectSliderRow(title: "方格", value: $customGridStrength, range: 0...1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .animation(.easeOut(duration: 0.2), value: effectMode)
    }

    @MainActor
    private func loadSelectedPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }

        isLoadingPhoto = true
        defer {
            isLoadingPhoto = false
            selectedPhotoItem = nil
        }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            return
        }

        withAnimation(.easeOut(duration: 0.2)) {
            selectedImage = image
        }
    }

    @MainActor
    private func saveEffectPhoto() {
        guard let selectedImage else { return }

        let aspectRatio = max(selectedImage.size.width / selectedImage.size.height, 0.1)
        let outputWidth: CGFloat = 1280
        let exportView = BlueprintGridCanvas(
            image: selectedImage,
            mode: effectMode,
            customHue: customHue,
            customTint: customTint,
            customSaturation: customSaturation,
            gridStrength: customGridStrength
        )
            .frame(width: outputWidth, height: outputWidth / aspectRatio)

        let renderer = ImageRenderer(content: exportView)
        renderer.scale = 1

        guard let renderedImage = renderer.uiImage else {
            saveMessage = "效果生成失败"
            return
        }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            Task { @MainActor in
                guard status == .authorized || status == .limited else {
                    saveMessage = "没有相册保存权限"
                    return
                }

                UIImageWriteToSavedPhotosAlbum(renderedImage, nil, nil, nil)
                saveMessage = "已保存到相册"
            }
        }
    }
}

private enum BlueprintEffectMode: String, CaseIterable, Identifiable {
    case original
    case blue
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .original: return "原色"
        case .blue: return "蓝调"
        case .custom: return "自定义"
        }
    }
}

private struct EffectSliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 34, alignment: .leading)

            Slider(value: $value, in: range)
                .tint(.black)
        }
    }
}

private struct BlueprintGridCanvas: View {
    let image: UIImage
    let mode: BlueprintEffectMode
    let customHue: Double
    let customTint: Double
    let customSaturation: Double
    let gridStrength: Double

    private var imageRatio: CGFloat {
        max(image.size.width / image.size.height, 0.1)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                switch mode {
                case .original:
                    effectImage(in: proxy.size)

                    BlueprintGridTexture(
                        strength: 0.65,
                        color: Color.black
                    )
                    .blendMode(.multiply)

                case .blue:
                    Color(red: 0.56, green: 0.78, blue: 0.91)

                    effectImage(in: proxy.size)
                        .saturation(0)
                        .contrast(1.22)
                        .brightness(0.10)
                        .colorMultiply(Color(red: 0.58, green: 0.80, blue: 0.94))

                    Color(red: 0.34, green: 0.68, blue: 0.88)
                        .opacity(0.16)
                        .blendMode(.screen)

                    BlueprintGridTexture(
                        strength: 1,
                        color: Color(red: 0.16, green: 0.38, blue: 0.54)
                    )
                        .blendMode(.multiply)

                case .custom:
                    effectImage(in: proxy.size)
                        .saturation(customSaturation)
                        .contrast(1.08)

                    Color(
                        hue: customHue,
                        saturation: 0.58,
                        brightness: 0.88
                    )
                    .opacity(customTint * 0.62)
                    .blendMode(.color)

                    BlueprintGridTexture(
                        strength: gridStrength,
                        color: Color.black
                    )
                        .blendMode(.multiply)
                }
            }
        }
        .aspectRatio(imageRatio, contentMode: .fit)
        .clipped()
        .drawingGroup()
    }

    private func effectImage(in size: CGSize) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .clipped()
    }
}

private struct BlueprintGridTexture: View {
    let strength: Double
    let color: Color

    var body: some View {
        Canvas { context, size in
            let gridSpacing = max(5, size.width / 90)
            var grid = Path()

            var x: CGFloat = 0
            while x <= size.width {
                grid.move(to: CGPoint(x: x, y: 0))
                grid.addLine(to: CGPoint(x: x, y: size.height))
                x += gridSpacing
            }

            var y: CGFloat = 0
            while y <= size.height {
                grid.move(to: CGPoint(x: 0, y: y))
                grid.addLine(to: CGPoint(x: size.width, y: y))
                y += gridSpacing
            }

            context.stroke(
                grid,
                with: .color(color.opacity(0.32 * strength)),
                lineWidth: max(0.45, size.width / 2600)
            )

            let grainSpacing = max(4, size.width / 110)
            var grain = Path()
            var grainY: CGFloat = 0

            while grainY <= size.height {
                var grainX: CGFloat = 0
                while grainX <= size.width {
                    let hash = Int(grainX * 17 + grainY * 31) % 11
                    if hash < 3 {
                        let dotSize = max(0.6, size.width / 1800)
                        grain.addEllipse(in: CGRect(x: grainX, y: grainY, width: dotSize, height: dotSize))
                    }
                    grainX += grainSpacing
                }
                grainY += grainSpacing
            }

            context.fill(
                grain,
                with: .color(color.opacity(0.30 * strength))
            )
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    NavigationStack {
        BlueprintGridEffectView()
    }
}
