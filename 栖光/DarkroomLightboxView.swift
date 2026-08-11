//
//  DarkroomLightboxView.swift
//  栖光
//
//  Created by zhixin on 2026/8/6.
//

import SwiftUI
import PhotosUI

struct DarkroomLightboxView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotosPickerItem: PhotosPickerItem? = nil
    @State private var userImages: [UIImage] = []
    @State private var selectedIndex: Int = 0
    @State private var isNegativeMode: Bool = false // 正片 vs 冲洗负片
    @State private var lightboxColor: LightboxColorMode = .neutralWhite
    @State private var selectedFilmStock: FilmStock = .portra400
    @State private var isSaveSuccessAlertPresented = false

    // 经典胶卷厂牌风格
    enum FilmStock: String, CaseIterable, Identifiable {
        case portra400 = "KODAK PORTRA 400"
        case fujiPro = "FUJIFILM PRO 400H"
        case cinestill = "CINESTILL 800T"
        case ilford = "ILFORD HP5 PLUS"

        var id: String { rawValue }

        var frameColor: Color {
            switch self {
            case .portra400: return Color(red: 0.95, green: 0.72, blue: 0.20)
            case .fujiPro: return Color(red: 0.20, green: 0.75, blue: 0.55)
            case .cinestill: return Color(red: 0.90, green: 0.30, blue: 0.35)
            case .ilford: return Color(red: 0.85, green: 0.85, blue: 0.85)
            }
        }

        var filmCode: String {
            switch self {
            case .portra400: return "400-2 ▶ 12A"
            case .fujiPro: return "400H ▶ 24"
            case .cinestill: return "800T ▶ 08"
            case .ilford: return "HP5+ ▶ 19A"
            }
        }
    }

    enum LightboxColorMode: String, CaseIterable, Identifiable {
        case neutralWhite = "5500K 日光灯箱"
        case warmAmber = "3200K 暖黄观片"
        case darkroomRed = "暗房安全红光"

        var id: String { rawValue }

        var canvasBackground: Color {
            switch self {
            case .neutralWhite: return Color(red: 0.96, green: 0.96, blue: 0.94)
            case .warmAmber: return Color(red: 0.96, green: 0.90, blue: 0.82)
            case .darkroomRed: return Color(red: 0.40, green: 0.08, blue: 0.08)
            }
        }

        var glowColor: Color {
            switch self {
            case .neutralWhite: return Color.white.opacity(0.8)
            case .warmAmber: return Color(red: 1.0, green: 0.85, blue: 0.6).opacity(0.6)
            case .darkroomRed: return Color(red: 1.0, green: 0.2, blue: 0.2).opacity(0.5)
            }
        }
    }

    var body: some View {
        ZStack {
            // 暗房沉浸式黑底
            Color(red: 0.07, green: 0.07, blue: 0.08)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. 顶栏：返回、标题、导入图片
                headerBar

                // 2. 核心 35mm 胶片大画幅展台 (大画面高清晰预览)
                GeometryReader { geometry in
                    VStack {
                        Spacer(minLength: 0)

                        filmFrameCard
                            .frame(maxWidth: min(geometry.size.width - 32, 420))
                            .shadow(color: lightboxColor.glowColor, radius: 24, x: 0, y: 8)
                            .padding(.horizontal, 16)

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // 3. 底部胶卷多图切换轮播 (导入照片后支持侧滑多张)
                if userImages.count > 1 {
                    filmRollThumbnailBar
                        .padding(.bottom, 8)
                }

                // 4. 底部暗房专业调控面板
                controlPanel
            }
        }
        .navigationBarHidden(true)
        .hideTabBarOnRealDevice()
        .onChange(of: selectedPhotosPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            self.userImages.insert(uiImage, at: 0)
                            self.selectedIndex = 0
                        }
                    }
                }
            }
        }
        .alert("冲洗保存成功", isPresented: $isSaveSuccessAlertPresented) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("35mm 胶片照片已高清导出至手机相册")
        }
    }

    // MARK: - 顶栏
    private var headerBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text("底片灯箱")
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .foregroundStyle(.white)

                Text("35mm FILM LIGHTBOX")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45))
                    .tracking(1.5)
            }

            Spacer()

            PhotosPicker(selection: $selectedPhotosPickerItem, matching: .images) {
                HStack(spacing: 5) {
                    Image(systemName: "photo.badge.plus")
                    Text("导入照片")
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(red: 0.98, green: 0.82, blue: 0.10))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - 35mm 胶片主画面卡片
    private var filmFrameCard: some View {
        VStack(spacing: 0) {
            // 胶片顶边：齿孔 + 厂牌型号 + 膜号
            HStack {
                Text(selectedFilmStock.rawValue)
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(selectedFilmStock.frameColor)

                Spacer()

                // 上齿孔 (Sprocket Holes)
                HStack(spacing: 14) {
                    ForEach(0..<6, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(lightboxColor.canvasBackground.opacity(0.9))
                            .frame(width: 12, height: 16)
                    }
                }

                Spacer()

                Text(selectedFilmStock.filmCode)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(selectedFilmStock.frameColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black)

            // 照片主体区 (放大高保真渲染，不再挤在小地方)
            ZStack {
                lightboxColor.canvasBackground

                if let currentImage = currentActiveImage {
                    Image(uiImage: currentImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .modifier(InvertModifier(isInverted: isNegativeMode))
                } else {
                    // 无图片时的复古暗房占位图
                    ZStack {
                        Color(red: 0.14, green: 0.12, blue: 0.11)

                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 42, weight: .light))
                                .foregroundStyle(selectedFilmStock.frameColor.opacity(0.8))

                            Text("点击右上角「导入照片」")
                                .font(.system(size: 14, weight: .bold, design: .serif))
                                .foregroundStyle(.white.opacity(0.85))

                            Text("置于观片台体验 35mm 复古底片与冲洗感")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                    }
                    .frame(height: 240)
                }
            }
            .padding(10)
            .background(Color.black)

            // 胶片底边：底片标识 + 下齿孔
            HStack {
                Text("SAFETY FILM 35MM")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(selectedFilmStock.frameColor)

                Spacer()

                // 下齿孔 (Sprocket Holes)
                HStack(spacing: 14) {
                    ForEach(0..<6, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(lightboxColor.canvasBackground.opacity(0.9))
                            .frame(width: 12, height: 16)
                    }
                }

                Spacer()

                Text("栖光 · DARKROOM")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(selectedFilmStock.frameColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - 当前显示的图片
    private var currentActiveImage: UIImage? {
        if userImages.indices.contains(selectedIndex) {
            return userImages[selectedIndex]
        }
        return nil
    }

    // MARK: - 多张照片轮播卡槽条
    private var filmRollThumbnailBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(userImages.enumerated()), id: \.offset) { index, img in
                    Button {
                        withAnimation {
                            selectedIndex = index
                        }
                    } label: {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(selectedIndex == index ? Color(red: 0.98, green: 0.82, blue: 0.10) : Color.white.opacity(0.2), lineWidth: selectedIndex == index ? 2.5 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - 底部调控面板
    private var controlPanel: some View {
        VStack(spacing: 16) {
            // 第一排：胶片厂牌风格选择
            HStack(spacing: 8) {
                ForEach(FilmStock.allCases) { stock in
                    Button {
                        withAnimation {
                            selectedFilmStock = stock
                        }
                    } label: {
                        Text(stock.rawValue.components(separatedBy: " ").first ?? stock.rawValue)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(selectedFilmStock == stock ? Color.black : Color.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(selectedFilmStock == stock ? stock.frameColor : Color.white.opacity(0.10), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            // 第二排：冲洗模式 (正片 ↔ 负片) 与 保存卡片
            HStack(spacing: 14) {
                // 正片 vs 负片反相
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isNegativeMode.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isNegativeMode ? "moon.stars.fill" : "sun.max.fill")
                        Text(isNegativeMode ? "负片模式 (Inverted)" : "正片模式 (Normal)")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isNegativeMode ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isNegativeMode ? Color(red: 0.98, green: 0.82, blue: 0.10) : Color.white.opacity(0.15), in: Capsule())
                }
                .buttonStyle(.plain)

                // 保存胶片卡片至相册
                Button {
                    saveFilmFrameToPhotos()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.down")
                        Text("保存底片")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(red: 0.28, green: 0.55, blue: 0.42), in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(currentActiveImage == nil)
                .opacity(currentActiveImage == nil ? 0.5 : 1.0)
            }

            // 第三排：观片灯箱色温选择
            HStack(spacing: 12) {
                Text("观片灯箱色温")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))

                Spacer()

                ForEach(LightboxColorMode.allCases) { mode in
                    Button {
                        withAnimation {
                            lightboxColor = mode
                        }
                    } label: {
                        Circle()
                            .fill(mode.canvasBackground)
                            .frame(width: 22, height: 22)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: lightboxColor == mode ? 2.5 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 24)
        .background(Color(red: 0.11, green: 0.11, blue: 0.13))
    }

    // MARK: - 渲染导出胶片帧卡片至手机相册
    @MainActor
    private func saveFilmFrameToPhotos() {
        let exportView = filmFrameCard
            .frame(width: 380)
            .environment(\.colorScheme, .dark)

        let renderer = ImageRenderer(content: exportView)
        renderer.scale = 3.0

        if let image = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            isSaveSuccessAlertPresented = true
        }
    }
}

// MARK: - 图像颜色反相 Modifier (负片冲洗效果)
private struct InvertModifier: ViewModifier {
    let isInverted: Bool

    func body(content: Content) -> some View {
        if isInverted {
            content
                .colorInvert()
                .contrast(1.1)
                .saturation(0.9)
        } else {
            content
        }
    }
}
