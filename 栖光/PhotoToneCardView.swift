//
//  PhotoToneCardView.swift
//  栖光
//
//  Created by zhixin on 2026/8/8.
//

import SwiftUI
import PhotosUI

/// 排版结构视觉枚举
enum CardLayoutStyle: String, CaseIterable, Identifiable {
    case colorBlockAbove = "色块在上"
    case magazinePoster = "杂志海报"
    case glassPalette = "玻璃色卡"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .colorBlockAbove: return "rectangle.topthird.inset.filled"
        case .magazinePoster: return "rectangle.inset.filled"
        case .glassPalette: return "circle.grid.3x3.circle.fill"
        }
    }
}

struct PhotoToneCardView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedLayoutStyle: CardLayoutStyle = .colorBlockAbove
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var extractedColors: [ExtractedColorItem] = []
    @State private var activeColorIndex: Int = 0
    @State private var customTitle: String = "连南瑶族 · 清远"
    @State private var isEditingTitle: Bool = false
    @State private var saveMessage: String? = nil

    /// 当前提取的核心背景色（无图时默认纯白）
    private var activeBgColor: Color {
        if selectedImage != nil, extractedColors.indices.contains(activeColorIndex) {
            return extractedColors[activeColorIndex].color
        }
        return Color.white
    }
    
    /// 当前吸色 Hex 码
    private var activeHex: String {
        if selectedImage != nil, extractedColors.indices.contains(activeColorIndex) {
            return extractedColors[activeColorIndex].hexString
        }
        return "#FFFFFF"
    }

    /// 判断背景是否属于浅色调
    private var isLightBg: Bool {
        if selectedImage == nil || extractedColors.isEmpty {
            return true
        }
        let uiColor = extractedColors[activeColorIndex].uiColor
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        return luminance > 0.65
    }

    var body: some View {
        ZStack {
            // 1. 背景色（未选图时为极简纯白）
            activeBgColor
                .overlay(
                    LinearGradient(
                        colors: isLightBg
                            ? [Color.black.opacity(0.02), Color.clear, Color.black.opacity(0.04)]
                            : [Color.black.opacity(0.12), Color.clear, Color.black.opacity(0.25)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: activeBgColor)

            VStack(spacing: 0) {
                // 2. 顶部 Navigation Header
                navigationHeaderView

                // 3. 主界面逻辑（未选图时展示 3 大排版视觉卡片；选图后展示对应排版与色卡面板）
                if selectedImage == nil {
                    initialTemplateSelectionView
                } else {
                    editorView
                }
            }

            // Toast 提示
            if let msg = saveMessage {
                toastView(message: msg)
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImg = UIImage(data: data) {
                    await processImage(uiImg)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .hideTabBarOnRealDevice()
    }

    // MARK: - Header

    private var navigationHeaderView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isLightBg ? Color.primary : Color.white)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

            Text("取色卡片")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(isLightBg ? Color.primary : Color.white)
                .padding(.leading, 6)

            Spacer()

            HStack(spacing: 12) {
                // 照片选择器
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(isLightBg ? Color.primary : Color.white)
                        .frame(width: 38, height: 38)
                        .background(isLightBg ? Color.black.opacity(0.06) : Color.white.opacity(0.2), in: Circle())
                }
                .buttonStyle(.plain)

                // 保存海报
                if selectedImage != nil {
                    Button {
                        saveCardToAlbum()
                    } label: {
                        Image(systemName: "arrow.down.to.line")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(isLightBg ? Color.primary : Color.white)
                            .frame(width: 38, height: 38)
                            .background(isLightBg ? Color.black.opacity(0.06) : Color.white.opacity(0.2), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    // MARK: - 1. 初始排版选择页面（参考截图视觉）

    private var initialTemplateSelectionView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                VStack(spacing: 6) {
                    Text("选择排版结构 · 即刻开启吸色海报")
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundStyle(Color.primary)
                    Text("轻按下方任意样式卡片拉起相册选图")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.secondary)
                }
                .padding(.top, 12)

                // 3 大视觉排版选择卡片（横向滑动/自适应组）
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 18) {
                        ForEach(CardLayoutStyle.allCases) { style in
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                templateCardPreviewItem(for: style)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded {
                                selectedLayoutStyle = style
                            })
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 8)
                }

                Spacer(minLength: 40)
            }
        }
    }

    // 缩略图卡片绘制
    private func templateCardPreviewItem(for style: CardLayoutStyle) -> some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(red: 0.94, green: 0.92, blue: 0.88))
                    .frame(width: 210, height: 310)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)

                // 根据风格渲染微缩内容
                switch style {
                case .colorBlockAbove:
                    VStack(spacing: 0) {
                        VStack(spacing: 4) {
                            Spacer()
                            Text("连南瑶族 · 清远")
                                .font(.system(size: 11, weight: .bold, design: .serif))
                                .foregroundStyle(Color.black.opacity(0.65))
                            Text("2:45 PM · #D8CDBC")
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.black.opacity(0.4))
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 125)
                        .background(Color(red: 0.86, green: 0.82, blue: 0.75))

                        demoHouseImage
                            .frame(height: 185)
                    }

                case .magazinePoster:
                    VStack(spacing: 8) {
                        VStack(spacing: 2) {
                            Text("连南瑶族 · 清远")
                                .font(.system(size: 11, weight: .bold, design: .serif))
                                .foregroundStyle(Color.white)
                            Text("2:45 PM · #D8CDBC")
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.8))
                        }
                        .padding(.top, 14)

                        demoHouseImage
                            .frame(height: 225)
                            .padding(.horizontal, 14)
                            .padding(.bottom, 12)
                    }

                case .glassPalette:
                    ZStack(alignment: .bottom) {
                        demoHouseImage
                            .frame(height: 310)

                        // 玻璃色卡浮层
                        VStack(spacing: 6) {
                            HStack(spacing: 10) {
                                Circle().fill(Color(red: 0.90, green: 0.86, blue: 0.80)).frame(width: 24, height: 24)
                                Circle().fill(Color(red: 0.55, green: 0.52, blue: 0.45)).frame(width: 24, height: 24)
                                Circle().fill(Color(red: 0.85, green: 0.65, blue: 0.70)).frame(width: 24, height: 24)
                            }
                            HStack(spacing: 10) {
                                Circle().fill(Color(red: 0.25, green: 0.25, blue: 0.25)).frame(width: 24, height: 24)
                                Circle().fill(Color(red: 0.80, green: 0.20, blue: 0.20)).frame(width: 24, height: 24)
                                Circle().fill(Color(red: 0.45, green: 0.15, blue: 0.15)).frame(width: 24, height: 24)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal, 14)
                        .padding(.bottom, 16)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1.5)
            )

            Text(style.rawValue)
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundStyle(Color.primary)
        }
    }

    // 经典建筑范例缩略图
    private var demoHouseImage: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.82, green: 0.78, blue: 0.72), Color(red: 0.65, green: 0.58, blue: 0.50)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 6) {
                Image(systemName: "house.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.white.opacity(0.85))
                Image(systemName: "photo")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .clipped()
    }

    // MARK: - 2. 编辑与色卡详情页面（选图后呈现）

    private var editorView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                // 顶部排版结构快捷切换 Bar
                HStack(spacing: 10) {
                    ForEach(CardLayoutStyle.allCases) { style in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                selectedLayoutStyle = style
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: style.iconName)
                                    .font(.system(size: 12, weight: .semibold))
                                Text(style.rawValue)
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                selectedLayoutStyle == style
                                    ? (isLightBg ? Color.black : Color.white)
                                    : (isLightBg ? Color.black.opacity(0.06) : Color.white.opacity(0.12)),
                                in: Capsule()
                            )
                            .foregroundStyle(
                                selectedLayoutStyle == style
                                    ? (isLightBg ? Color.white : Color.black)
                                    : (isLightBg ? Color.primary : Color.white)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)

                // 色卡海报 Canvas
                cardCanvasView
                    .padding(.horizontal, 20)

                // 提取色板选择区
                if !extractedColors.isEmpty {
                    colorPaletteSelectorView
                }

                Text("轻按下方的色卡自由切换背景与海报主色调 · 轻按文字修改文案")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(isLightBg ? Color.secondary : Color.white.opacity(0.75))
                    .padding(.top, 2)
            }
            .padding(.vertical, 10)
        }
    }

    // 画板 Canvas 渲染
    @ViewBuilder
    private var cardCanvasView: some View {
        Group {
            switch selectedLayoutStyle {
            case .colorBlockAbove:
                VStack(spacing: 0) {
                    cardHeaderInfoBlock
                    cardPhotoBlock(height: 330)
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            case .magazinePoster:
                VStack(spacing: 12) {
                    cardHeaderInfoBlock
                        .padding(.top, 8)

                    cardPhotoBlock(height: 300)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 14)
                }
                .background(
                    isLightBg ? Color.black.opacity(0.04) : Color.white.opacity(0.15),
                    in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                )

            case .glassPalette:
                ZStack(alignment: .bottom) {
                    cardPhotoBlock(height: 390)

                    // 玻璃色卡 Style：照片上叠悬浮毛玻璃吸色点阵
                    VStack(spacing: 12) {
                        if isEditingTitle {
                            TextField("输入诗意文案", text: $customTitle)
                                .font(.system(size: 16, weight: .bold, design: .serif))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color.primary)
                                .textFieldStyle(.plain)
                                .onSubmit { isEditingTitle = false }
                        } else {
                            Text(customTitle)
                                .font(.system(size: 16, weight: .bold, design: .serif))
                                .foregroundStyle(Color.primary)
                                .onTapGesture { isEditingTitle = true }
                        }

                        // 6 色或提取色块网格/横排
                        HStack(spacing: 12) {
                            ForEach(extractedColors.indices, id: \.self) { idx in
                                let item = extractedColors[idx]
                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                        activeColorIndex = idx
                                    }
                                } label: {
                                    Circle()
                                        .fill(item.color)
                                        .frame(width: 26, height: 26)
                                        .overlay(
                                            Circle().stroke(activeColorIndex == idx ? Color.black : Color.white.opacity(0.6), lineWidth: activeColorIndex == idx ? 2 : 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
        }
        .shadow(color: Color.black.opacity(isLightBg ? 0.08 : 0.16), radius: 16, x: 0, y: 8)
    }

    // 文案 Block
    private var cardHeaderInfoBlock: some View {
        VStack(spacing: 6) {
            if isEditingTitle {
                TextField("输入画报诗意文案", text: $customTitle)
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isLightBg ? Color.primary : Color.white)
                    .textFieldStyle(.plain)
                    .onSubmit { isEditingTitle = false }
            } else {
                Text(customTitle)
                    .font(.system(size: 19, weight: .bold, design: .serif))
                    .foregroundStyle(isLightBg ? Color.primary : Color.white)
                    .onTapGesture { isEditingTitle = true }
            }

            HStack(spacing: 8) {
                Text(formattedCurrentTime())
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                Text("·")
                Text(activeHex)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(isLightBg ? Color.secondary : Color.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            selectedLayoutStyle == .colorBlockAbove
                ? (isLightBg ? Color.black.opacity(0.04) : Color.white.opacity(0.12))
                : Color.clear
        )
    }

    // 照片区域 Block
    private func cardPhotoBlock(height: CGFloat) -> some View {
        ZStack {
            if let image = selectedImage {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: height)
                        .clipped()
                }
                .buttonStyle(.plain)
            }
        }
    }

    // 底部提取色卡切换器
    private var colorPaletteSelectorView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("提取主色调（轻按切换）")
                .font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundStyle(isLightBg ? Color.primary.opacity(0.7) : Color.white.opacity(0.85))
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(extractedColors.indices, id: \.self) { idx in
                        let item = extractedColors[idx]
                        let isSelected = activeColorIndex == idx
                        
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                activeColorIndex = idx
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 18, height: 18)
                                    .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.nameHint)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(isLightBg && !isSelected ? Color.primary : Color.white)
                                    Text(item.hexString)
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundStyle((isLightBg && !isSelected ? Color.primary : Color.white).opacity(0.8))
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                isSelected
                                    ? (isLightBg ? Color.black.opacity(0.85) : Color.white.opacity(0.3))
                                    : (isLightBg ? Color.black.opacity(0.06) : Color.white.opacity(0.12)),
                                in: Capsule()
                            )
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? (isLightBg ? Color.black : Color.white) : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func toastView(message: String) -> some View {
        VStack {
            Spacer()
            Text(message)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.75), in: Capsule())
                .padding(.bottom, 40)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Logic

    private func processImage(_ img: UIImage) async {
        selectedImage = img
        let palette = await ColorExtractor.extractPalette(from: img, count: 6)
        withAnimation {
            extractedColors = palette
            activeColorIndex = 0
        }
    }

    private func formattedCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }

    private var exportableCardCanvas: some View {
        ZStack {
            activeBgColor
                .overlay(
                    LinearGradient(
                        colors: isLightBg
                            ? [Color.black.opacity(0.02), Color.clear, Color.black.opacity(0.04)]
                            : [Color.black.opacity(0.12), Color.clear, Color.black.opacity(0.25)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            cardCanvasView
                .padding(24)
        }
        .frame(width: 380)
    }

    private func saveCardToAlbum() {
        let renderer = ImageRenderer(content: exportableCardCanvas)
        renderer.scale = 3.0
        if let image = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            withAnimation {
                saveMessage = "已保存色卡海报到相册"
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { saveMessage = nil }
            }
        }
    }
}

#Preview {
    PhotoToneCardView()
}
