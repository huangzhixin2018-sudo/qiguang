//
//  PhotoFrameEditorView.swift
//  栖光
//

import SwiftUI
import Photos

struct PhotoFrameEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let inputImage: UIImage
    var initialTemplateStyle: TemplateStyle = .blurWhiteBorder

    enum TemplateStyle {
        case blurWhiteBorder // 竞品 1.5px 细白边 + 模糊背景
        case sodaPolaroid     // Soda 极简拍立得白框
    }

    // 编辑器交互状态
    @State private var templateStyle: TemplateStyle = .blurWhiteBorder
    @State private var watermarkText: String = "iPhone 17"
    @State private var blurRadius: CGFloat = 35.0
    @State private var darkOverlayOpacity: Double = 0.15
    @State private var strokeWidth: CGFloat = 1.5

    @State private var isShowingEXIFSheet = false
    @State private var isShowingWatermarkSheet = false
    @State private var isShowingSaveToast = false
    @State private var selectedTool: EditorTool? = nil

    enum EditorTool: String, CaseIterable, Identifiable {
        case palette = "配色"
        case background = "背景"
        case size = "尺寸"
        case ratio = "比例"
        case text = "加文本"
        case watermark = "加标识"
        case photo = "加图"
        case signature = "加签名"
        case sticker = "贴纸"

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .palette: return "paintpalette"
            case .background: return "square.dashed"
            case .size: return "arrow.up.left.and.arrow.down.right"
            case .ratio: return "crop"
            case .text: return "textformat"
            case .watermark: return "camera"
            case .photo: return "photo.badge.plus"
            case .signature: return "signature"
            case .sticker: return "face.smiling"
            }
        }
    }

    var body: some View {
        ZStack {
            // 全局深暗深灰底色 (完全复刻竞品工作台背景色)
            Color(red: 0.08, green: 0.08, blue: 0.09)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. 顶部 Header 栏 (返回 + 保存模版/导出)
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        saveToPhotoLibrary()
                    } label: {
                        HStack(spacing: 4) {
                            Text("保存模版")
                                .font(.system(size: 15, weight: .bold))

                            Image(systemName: "crown.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(red: 0.98, green: 0.75, blue: 0.2))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.45, green: 0.35, blue: 0.95), Color(red: 0.62, green: 0.45, blue: 0.98)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.top, 52)
                .padding(.bottom, 14)

                // 2. 中央画布呈现区 (复刻截图二)
                ZStack(alignment: .trailing) {
                    ScrollView([.vertical, .horizontal], showsIndicators: false) {
                        VStack {
                            Spacer(minLength: 20)

                            // 核心相框合成画板
                            PhotoCanvasCore(
                                image: inputImage,
                                templateStyle: templateStyle,
                                watermarkText: watermarkText,
                                blurRadius: blurRadius,
                                darkOverlayOpacity: darkOverlayOpacity,
                                strokeWidth: strokeWidth
                            )
                            .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)

                            Spacer(minLength: 20)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    // 右侧浮动功能小工具栏 (EXIF / 锁定 / 素材)
                    VStack(spacing: 12) {
                        Button {
                            isShowingEXIFSheet = true
                        } label: {
                            VStack(spacing: 2) {
                                HStack(spacing: 2) {
                                    Text("EXIF")
                                        .font(.system(size: 10, weight: .black, design: .monospaced))
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 5, height: 5)
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        Button {
                            // 锁定
                        } label: {
                            VStack(spacing: 3) {
                                Image(systemName: "questionmark.circle")
                                    .font(.system(size: 13))
                                Text("锁定")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        Button {
                            // 素材
                        } label: {
                            VStack(spacing: 2) {
                                Text("素材")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.trailing, 14)
                }

                // 3. 底部图层指示与控制工作台 (Toolbar - 1:1 复制截图二)
                VStack(spacing: 10) {
                    HStack {
                        Spacer()
                        Button {
                            // 图层控制
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "square.3.layers.3d")
                                    .font(.system(size: 14))
                                Text("图层")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.15), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)

                    // 横向滚动的工具项 (配色/背景/尺寸/比例/加文本/加标识/加图/加头像/加签名/贴纸)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 22) {
                            ForEach(EditorTool.allCases) { tool in
                                Button {
                                    selectedTool = tool
                                    if tool == .watermark {
                                        isShowingWatermarkSheet = true
                                    }
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: tool.iconName)
                                            .font(.system(size: 20, weight: .regular))
                                            .foregroundStyle(selectedTool == tool ? Color(red: 0.6, green: 0.45, blue: 0.98) : .white)

                                        Text(tool.rawValue)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(selectedTool == tool ? .white : .gray)
                                    }
                                    .frame(width: 52)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 16)
                }
                .background(Color(red: 0.12, green: 0.12, blue: 0.13))
            }

            // 保存成功 Toast
            if isShowingSaveToast {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("相框卡片已成功保存至手机相册")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .background(Color.black.opacity(0.85), in: Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 14, x: 0, y: 6)
                    .padding(.bottom, 90)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            templateStyle = initialTemplateStyle
        }
        .sheet(isPresented: $isShowingEXIFSheet) {
            EXIFDetailSheet()
                .presentationDetents([.height(300)])
                .presentationCornerRadius(24)
        }
        .sheet(isPresented: $isShowingWatermarkSheet) {
            WatermarkEditorSheet(watermarkText: $watermarkText)
                .presentationDetents([.height(260)])
                .presentationCornerRadius(24)
        }
    }

    /// 保存至相册
    private func saveToPhotoLibrary() {
        let exportView = PhotoCanvasCore(
            image: inputImage,
            templateStyle: templateStyle,
            watermarkText: watermarkText,
            blurRadius: blurRadius,
            darkOverlayOpacity: darkOverlayOpacity,
            strokeWidth: strokeWidth
        )
        .frame(width: 380)

        let renderer = ImageRenderer(content: exportView)
        renderer.scale = 2.0

        guard let uiImage = renderer.uiImage else { return }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            if status == .authorized || status == .limited {
                UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isShowingSaveToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                        withAnimation { isShowingSaveToast = false }
                    }
                }
            }
        }
    }
}

/// 核心相框画布组件 (精确还原竞品：高品质暗调模糊背景 + 100% 高清清晰原图 + 1.5px 纯白亮边框 + 设备水印)
struct PhotoCanvasCore: View {
    let image: UIImage
    let templateStyle: PhotoFrameEditorView.TemplateStyle
    let watermarkText: String
    let blurRadius: CGFloat
    let darkOverlayOpacity: Double
    let strokeWidth: CGFloat

    var body: some View {
        ZStack(alignment: .center) {
            // 1. 最外层：仅背景大图进行高斯羽化模糊 (带暗色遮罩，突出内层清晰原图)
            ZStack {
                GeometryReader { geo in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .blur(radius: max(blurRadius, 30))
                        .overlay(Color.black.opacity(0.3))
                        .clipped()
                }
            }
            .allowsHitTesting(false)

            // 2. 内层：白边紧贴照片四周，白边内部 100% 为清晰原图 (绝无半点缝隙与模糊)
            if templateStyle == .blurWhiteBorder {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .overlay(
                        // 1.5px 纯白亮边框紧紧包覆照片本体
                        Rectangle()
                            .stroke(Color.white, lineWidth: 1.5)
                    )
                    .overlay(alignment: .bottom) {
                        // 设备水印 (居中浮在照片底部)
                        if !watermarkText.isEmpty {
                            Text(watermarkText)
                                .font(.system(size: 11, weight: .regular, design: .default))
                                .foregroundStyle(.white.opacity(0.95))
                                .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 1)
                                .padding(.bottom, 10)
                        }
                    }
                    .padding(.all, 24)
            } else {
                // Soda 极简拍立得风格 (原图高清展示)
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 26, height: 26)
                            Text("Soda")
                                .font(.system(size: 8, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        Text("Soda Official")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.black)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
                    .padding(.bottom, 10)

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .padding(.horizontal, 14)

                    HStack {
                        HStack(spacing: 14) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Color(red: 0.92, green: 0.25, blue: 0.25))

                            Image(systemName: "bubble.right")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(.black)

                            Image(systemName: "paperplane")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(.black)
                        }

                        Spacer()

                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.black)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 14)
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .padding(.all, 32)
            }
        }
        .frame(width: 330)
        .aspectRatio(1.0, contentMode: .fit)
        .clipped()
    }
}

/// EXIF 数据弹出面板
private struct EXIFDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 4)
                .padding(.top, 12)

            HStack {
                Text("EXIF 摄影参数")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                }
            }

            VStack(spacing: 12) {
                EXIFRow(label: "相机型号", value: "iPhone 17 Pro Max")
                EXIFRow(label: "镜头焦段", value: "24mm f/1.78")
                EXIFRow(label: "快门速度", value: "1/120s")
                EXIFRow(label: "感光度 ISO", value: "ISO 50")
            }
            .padding(.horizontal, 8)

            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

private struct EXIFRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(.primary)
        }
    }
}

/// 设备水印自定义编辑 Sheet
private struct WatermarkEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var watermarkText: String

    let presets = ["iPhone 17", "iPhone 15 Pro", "Shot on Leica", "Hasselblad", "FUJIFILM X100V", "Sony A7M4"]

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 4)
                .padding(.top, 12)

            HStack {
                Text("编辑水印标识")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Button("完成") { dismiss() }
                    .font(.system(size: 15, weight: .bold))
            }

            TextField("自定义水印文字", text: $watermarkText)
                .font(.system(size: 16))
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { preset in
                        Button {
                            watermarkText = preset
                        } label: {
                            Text(preset)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(watermarkText == preset ? .white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(watermarkText == preset ? Color.black : Color(.systemGray5), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
    }
}
