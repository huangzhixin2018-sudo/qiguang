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
    @State private var userImage: UIImage? = nil
    @State private var isPositiveMode: Bool = false // 负片 vs 正片切换
    @State private var lightboxColorMode: LightboxColor = .warmWhite
    @State private var loupePosition: CGPoint = CGPoint(x: 180, y: 260)
    @State private var isLoupeActive: Bool = true

    enum LightboxColor {
        case warmWhite
        case darkroomRed
        case cyanBlue

        var name: String {
            switch self {
            case .warmWhite: return "3500K 观片灯"
            case .darkroomRed: return "安全红光"
            case .cyanBlue: return "日照冷光"
            }
        }

        var color: Color {
            switch self {
            case .warmWhite: return Color(red: 0.98, green: 0.96, blue: 0.90)
            case .darkroomRed: return Color(red: 0.90, green: 0.15, blue: 0.12)
            case .cyanBlue: return Color(red: 0.85, green: 0.93, blue: 0.98)
            }
        }
    }

    var body: some View {
        ZStack {
            // 暗房背景底衬
            Color(red: 0.05, green: 0.05, blue: 0.07)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶栏控制区
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("🎞️ 底片灯箱")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)

                    Spacer()

                    PhotosPicker(selection: $selectedPhotosPickerItem, matching: .images) {
                        HStack(spacing: 4) {
                            Image(systemName: "photo.badge.plus")
                            Text("导入照片")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(red: 0.98, green: 0.82, blue: 0.10))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.12), in: Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                // 核心透光发光观察台 (Lightbox Surface)
                GeometryReader { _ in
                    ZStack {
                        // 1. 发光透光玻璃底板 (Grid Lines & Backlight Glow)
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(lightboxColorMode.color)
                            .shadow(color: lightboxColorMode.color.opacity(0.4), radius: 24, x: 0, y: 0)
                            .overlay(
                                // 透光网格刻度线
                                GridCanvas()
                                    .opacity(0.15)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                            )

                        // 2. 35mm 胶片底片放置区
                        ScrollView([.horizontal, .vertical], showsIndicators: false) {
                            VStack(spacing: 24) {
                                FilmStripView(
                                    title: "KODAK PORTRA 400 · 35mm",
                                    frameNumber: "▶ 12A",
                                    userImage: userImage,
                                    isPositiveMode: isPositiveMode
                                )

                                FilmStripView(
                                    title: "FUJIFILM SUPERIA 100",
                                    frameNumber: "▶ 13",
                                    userImage: nil,
                                    isPositiveMode: isPositiveMode
                                )
                            }
                            .padding(24)
                        }

                        // 3. 可拖拽暗房观察放大镜 (Loupe Glass Magnifier)
                        if isLoupeActive {
                            MagnifierLoupeView(
                                position: loupePosition,
                                isPositive: isPositiveMode,
                                userImage: userImage,
                                lightColor: lightboxColorMode.color
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        loupePosition = value.location
                                    }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }

                // 底部控制面板
                VStack(spacing: 14) {
                    // 模式切换与放大镜开关
                    HStack(spacing: 16) {
                        // 负片 ↔ 正片切换
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                isPositiveMode.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: isPositiveMode ? "sun.max.fill" : "moon.stars.fill")
                                Text(isPositiveMode ? "正片模式 (Slide)" : "反相负片 (Negative)")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(isPositiveMode ? .black : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(isPositiveMode ? Color(red: 0.98, green: 0.82, blue: 0.10) : Color.white.opacity(0.15), in: Capsule())
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        // 放大镜开关
                        Button {
                            withAnimation {
                                isLoupeActive.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "magnifyingglass")
                                Text(isLoupeActive ? "放大镜: 开" : "放大镜: 关")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(isLoupeActive ? Color.white.opacity(0.25) : Color.white.opacity(0.1), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    // 观片灯颜色选择
                    HStack(spacing: 12) {
                        Text("观片灯光")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))

                        Spacer()

                        ForEach([LightboxColor.warmWhite, LightboxColor.darkroomRed, LightboxColor.cyanBlue], id: \.name) { mode in
                            Button {
                                withAnimation {
                                    lightboxColorMode = mode
                                }
                            } label: {
                                Circle()
                                    .fill(mode.color)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: lightboxColorMode.name == mode.name ? 2.5 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color(red: 0.10, green: 0.10, blue: 0.13))
            }
        }
        .navigationBarHidden(true)
        .hideTabBarOnRealDevice()
        .onChange(of: selectedPhotosPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.userImage = uiImage
                    }
                }
            }
        }
    }
}

// MARK: - 透光刻度网格 Canvas
private struct GridCanvas: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 24
            var path = Path()

            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }

            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }

            context.stroke(path, with: .color(.black), lineWidth: 0.5)
        }
    }
}

// MARK: - 35mm 胶片底片卡槽条 (Film Strip)
private struct FilmStripView: View {
    let title: String
    let frameNumber: String
    let userImage: UIImage?
    let isPositiveMode: Bool

    var body: some View {
        VStack(spacing: 0) {
            // 顶部胶片齿孔与厂牌字
            HStack {
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.95, green: 0.70, blue: 0.20))

                Spacer()

                // 齿孔
                HStack(spacing: 12) {
                    ForEach(0..<8, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white)
                            .frame(width: 8, height: 12)
                    }
                }

                Spacer()

                Text(frameNumber)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.95, green: 0.70, blue: 0.20))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black)

            // 照片画廊内容
            HStack(spacing: 12) {
                ForEach([0, 1, 2], id: \.self) { index in
                    ZStack {
                        if let userImage = userImage, index == 0 {
                            Image(uiImage: userImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 140, height: 100)
                                .clipped()
                                .modifier(InvertModifier(isInverted: !isPositiveMode))
                        } else {
                            // 预设高质感底片占位图
                            ZStack {
                                LinearGradient(colors: [Color(red: 0.25, green: 0.20, blue: 0.15), Color(red: 0.15, green: 0.10, blue: 0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)

                                VStack(spacing: 4) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 20))
                                        .foregroundStyle(Color(red: 0.95, green: 0.70, blue: 0.20).opacity(0.8))
                                    Text("FRAME #0\(index + 1)")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                            }
                            .frame(width: 140, height: 100)
                            .modifier(InvertModifier(isInverted: !isPositiveMode))
                        }
                    }
                    .border(Color.black, width: 3)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black)

            // 底部胶片齿孔
            HStack {
                Text("SAFETY FILM")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.95, green: 0.70, blue: 0.20))

                Spacer()

                HStack(spacing: 12) {
                    ForEach(0..<8, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white)
                            .frame(width: 8, height: 12)
                    }
                }

                Spacer()

                Text("35mm")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.95, green: 0.70, blue: 0.20))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// MARK: - 条件反相色彩 Modifier
private struct InvertModifier: ViewModifier {
    let isInverted: Bool

    func body(content: Content) -> some View {
        if isInverted {
            content.colorInvert()
        } else {
            content
        }
    }
}

// MARK: - 可拖拽暗房观察放大镜 (Loupe Magnifier View)
private struct MagnifierLoupeView: View {
    let position: CGPoint
    let isPositive: Bool
    let userImage: UIImage?
    let lightColor: Color

    var body: some View {
        ZStack {
            // 放大镜金属外框
            Circle()
                .stroke(
                    LinearGradient(colors: [.white, .gray, .black], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 6
                )
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 6)

            // 放大画面容器
            ZStack {
                Circle()
                    .fill(lightColor)

                if let userImage = userImage {
                    Image(uiImage: userImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 160, height: 160)
                        .scaleEffect(1.8)
                        .modifier(InvertModifier(isInverted: !isPositive))
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "microscope")
                            .font(.system(size: 28))
                            .foregroundStyle(Color(red: 0.95, green: 0.70, blue: 0.20))
                        Text("2.5X LOUPE")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .clipShape(Circle())
            .frame(width: 110, height: 110)

            // 手柄指针
            Rectangle()
                .fill(LinearGradient(colors: [.gray, .black], startPoint: .top, endPoint: .bottom))
                .frame(width: 10, height: 40)
                .offset(y: 70)
                .rotationEffect(.degrees(-35))
        }
        .frame(width: 120, height: 120)
        .position(position)
    }
}
