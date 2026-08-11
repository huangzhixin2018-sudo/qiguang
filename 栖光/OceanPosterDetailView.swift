//
//  OceanPosterDetailView.swift
//  栖光
//

import SwiftUI
import PhotosUI
import Photos

struct OceanPosterDetailView: View {
    @Environment(\.dismiss) private var dismiss

    var title: String = "夏日画报"

    @State private var isFavorite = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isLoadingPhoto = false
    @State private var overlayText = ""
    @State private var stickerName: String?
    @State private var extractedPrimaryColor: ExtractedColorItem?
    @State private var customBackgroundColor: Color?
    @State private var isShowingTextEditor = false
    @State private var isShowingStickerPicker = false
    @State private var isShowingColorPicker = false
    @State private var saveMessage: String?

    private var isEditing: Bool { selectedImage != nil }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                Group {
                    if let selectedImage {
                        SummerEditorialCanvas(
                            image: selectedImage,
                            backgroundColor: activeBackgroundColor,
                            backgroundHex: activeBackgroundHex,
                            usesDarkForeground: usesDarkForeground,
                            overlayText: overlayText,
                            stickerName: stickerName
                        )
                    } else {
                        Image("HomeSingle01")
                            .resizable()
                            .scaledToFit()
                    }
                }
                .frame(maxWidth: .infinity)
            }

            if isEditing {
                editorToolbar
            } else {
                uploadButton
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
        .sheet(isPresented: $isShowingTextEditor) {
            TemplateTextEditor(text: $overlayText)
                .presentationDetents([.height(210)])
        }
        .sheet(isPresented: $isShowingStickerPicker) {
            TemplateStickerPicker(selectedSticker: $stickerName)
                .presentationDetents([.height(230)])
        }
        .sheet(isPresented: $isShowingColorPicker) {
            TemplateColorPicker(
                selectedColor: $customBackgroundColor,
                extractedColor: extractedPrimaryColor?.color
            )
            .presentationDetents([.height(260)])
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

    @ViewBuilder
    private var header: some View {
        if isEditing {
            HStack(spacing: 12) {
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
                .accessibilityLabel("返回模板预览")

                Text("编辑模板")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    saveTemplate()
                } label: {
                    Label("保存", systemImage: "square.and.arrow.down")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .frame(height: 40)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.black)
        } else {
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer(minLength: 12)

                Button {
                    isFavorite.toggle()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 21, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isFavorite ? "取消收藏" : "收藏")

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
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.black)
        }
    }

    private var uploadButton: some View {
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

    private var editorToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                TemplateToolButton(title: "文本", iconName: "textformat") {
                    isShowingTextEditor = true
                }

                TemplateToolButton(title: "贴图", iconName: "face.smiling") {
                    isShowingStickerPicker = true
                }

                Button {
                    isShowingColorPicker = true
                } label: {
                    TemplateColorToolLabel(
                        color: activeBackgroundColor,
                        hexString: activeBackgroundHex
                    )
                }
                .buttonStyle(.plain)

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    TemplateToolLabel(title: "媒体", iconName: "photo.badge.plus")
                }
                .buttonStyle(.plain)
                .disabled(isLoadingPhoto)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGray6))
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

        let primaryColor = await ColorExtractor.extractPalette(from: image, count: 1).first

        withAnimation(.easeOut(duration: 0.2)) {
            selectedImage = image
            extractedPrimaryColor = primaryColor
        }
    }

    @MainActor
    private func saveTemplate() {
        guard let selectedImage else { return }

        let exportView = SummerEditorialCanvas(
            image: selectedImage,
            backgroundColor: activeBackgroundColor,
            backgroundHex: activeBackgroundHex,
            usesDarkForeground: usesDarkForeground,
            overlayText: overlayText,
            stickerName: stickerName
        )
        .frame(width: 878, height: 1374)

        let renderer = ImageRenderer(content: exportView)
        renderer.scale = 1

        guard let renderedImage = renderer.uiImage else {
            saveMessage = "模板生成失败"
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

    private var activeBackgroundColor: Color {
        if let customBackgroundColor {
            return customBackgroundColor
        }
        return extractedPrimaryColor?.color ?? Color(red: 0.10, green: 0.16, blue: 0.11)
    }

    private var activeBackgroundHex: String {
        if let customBackgroundColor {
            return customBackgroundColor.toHex()
        }
        return extractedPrimaryColor?.hexString ?? "#1A291C"
    }

    private var usesDarkForeground: Bool {
        let color = customBackgroundColor.map { UIColor($0) } ?? extractedPrimaryColor?.uiColor ?? UIColor(red: 0.10, green: 0.16, blue: 0.11, alpha: 1)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return red * 0.299 + green * 0.587 + blue * 0.114 > 0.66
    }
}

private struct TemplateToolButton: View {
    let title: String
    let iconName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            TemplateToolLabel(title: title, iconName: iconName)
        }
        .buttonStyle(.plain)
    }
}

private struct TemplateToolLabel: View {
    let title: String
    let iconName: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 24, weight: .regular))

            Text(title)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundStyle(.black)
        .frame(width: 84, height: 76)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct TemplateColorToolLabel: View {
    let color: Color
    let hexString: String

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 28, height: 28)
                .overlay {
                    Circle()
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                }

            Text("颜色")
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundStyle(.black)
        .frame(width: 84, height: 76)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityLabel("照片主色 \(hexString)")
    }
}

private struct TemplateTextEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var text: String

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("文本")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Button("完成") { dismiss() }
                    .font(.system(size: 15, weight: .semibold))
            }

            TextField("输入文字", text: $text)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Spacer()
        }
        .padding(20)
    }
}

private struct TemplateStickerPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSticker: String?

    private let stickers = ["heart.fill", "sparkles", "sun.max.fill", "star.fill"]

    var body: some View {
        VStack(spacing: 22) {
            HStack {
                Text("贴图")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Button("完成") { dismiss() }
                    .font(.system(size: 15, weight: .semibold))
            }

            HStack(spacing: 18) {
                Button {
                    selectedSticker = nil
                } label: {
                    Image(systemName: "nosign")
                        .font(.system(size: 23))
                        .frame(width: 50, height: 50)
                        .background(Color(.systemGray6), in: Circle())
                }
                .buttonStyle(.plain)

                ForEach(stickers, id: \.self) { sticker in
                    Button {
                        selectedSticker = sticker
                    } label: {
                        Image(systemName: sticker)
                            .font(.system(size: 23))
                            .frame(width: 50, height: 50)
                            .background(
                                selectedSticker == sticker ? Color.primary.opacity(0.14) : Color(.systemGray6),
                                in: Circle()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding(20)
    }
}

private struct SummerEditorialCanvas: View {
    let image: UIImage
    let backgroundColor: Color
    let backgroundHex: String
    let usesDarkForeground: Bool
    let overlayText: String
    let stickerName: String?

    private let templateRatio: CGFloat = 878.0 / 1374.0
    private let topSectionRatio: CGFloat = 668.0 / 878.0

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width

            VStack(spacing: 0) {
                ZStack {
                    backgroundColor

                    VStack(spacing: 18) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: width * 0.45, height: width * 0.34)
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

                        Text(backgroundHex)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(usesDarkForeground ? Color.black.opacity(0.72) : Color.white)
                    }
                }
                .frame(height: width * topSectionRatio)

                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: width / templateRatio - width * topSectionRatio)
                    .clipped()
                    .overlay(alignment: .topTrailing) {
                        if let stickerName {
                            Image(systemName: stickerName)
                                .font(.system(size: max(22, width * 0.06), weight: .semibold))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
                                .padding(24)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        VStack(spacing: 12) {
                            if !overlayText.isEmpty {
                                Text(overlayText)
                                    .font(.system(size: max(15, width * 0.038), weight: .semibold))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                            }

                            HStack {
                                Text("栖光")
                                Spacer()
                                Text("SUMMER")
                            }
                            .font(.system(size: max(10, width * 0.023), weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 18)
                    }
            }
        }
        .aspectRatio(templateRatio, contentMode: .fit)
    }
}

private struct TemplateColorPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedColor: Color?
    let extractedColor: Color?

    private let presetColors: [(name: String, color: Color)] = [
        ("天青蓝", Color(red: 0.62, green: 0.78, blue: 0.88)),
        ("燕麦沙", Color(red: 0.85, green: 0.81, blue: 0.75)),
        ("鼠尾草绿", Color(red: 0.74, green: 0.80, blue: 0.76)),
        ("陶土粉", Color(red: 0.84, green: 0.75, blue: 0.72)),
        ("极简墨黑", Color(red: 0.11, green: 0.12, blue: 0.11)),
        ("奶油纯白", Color(red: 0.96, green: 0.95, blue: 0.93))
    ]

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("底色配色方案")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                Spacer()
                Button("完成") { dismiss() }
                    .font(.system(size: 15, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 14) {
                if let extractedColor {
                    Button {
                        selectedColor = nil
                    } label: {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(extractedColor)
                                .frame(width: 24, height: 24)
                                .overlay(Circle().stroke(Color.black.opacity(0.1), lineWidth: 1))
                            Text("照片自动提色 (智能重置)")
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            if selectedColor == nil {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color.primary)
                            }
                        }
                        .padding(12)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(presetColors, id: \.name) { preset in
                            Button {
                                selectedColor = preset.color
                            } label: {
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(preset.color)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedColor == preset.color ? Color.primary : Color.black.opacity(0.12), lineWidth: selectedColor == preset.color ? 2 : 1)
                                        )

                                    Text(preset.name)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Spacer()
        }
        .padding(20)
    }
}

private extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var redVal: CGFloat = 0
        var greenVal: CGFloat = 0
        var blueVal: CGFloat = 0
        var alphaVal: CGFloat = 0
        uiColor.getRed(&redVal, green: &greenVal, blue: &blueVal, alpha: &alphaVal)
        return String(format: "#%02X%02X%02X", Int(redVal * 255), Int(greenVal * 255), Int(blueVal * 255))
    }
}

#Preview {
    NavigationStack {
        OceanPosterDetailView()
    }
}
