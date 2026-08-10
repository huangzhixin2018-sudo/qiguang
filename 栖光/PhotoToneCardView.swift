//
//  PhotoToneCardView.swift
//  栖光
//
//  Created by zhixin on 2026/8/8.
//

import SwiftUI
import PhotosUI

struct PhotoToneCardView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var extractedColors: [ExtractedColorItem] = []
    @State private var activeColorIndex: Int = 0
    @State private var customTitle: String = "秋水共长天一色"
    @State private var isEditingTitle: Bool = false
    @State private var saveMessage: String? = nil

    private var activeBgColor: Color {
        if extractedColors.indices.contains(activeColorIndex) {
            return extractedColors[activeColorIndex].color
        }
        return Color(red: 0.70, green: 0.57, blue: 0.63)
    }
    
    private var activeHex: String {
        if extractedColors.indices.contains(activeColorIndex) {
            return extractedColors[activeColorIndex].hexString
        }
        return "#B491A0"
    }

    var body: some View {
        ZStack {
            // 1. 全屏自适应融合背景 (平滑色彩渐变与氛围过渡)
            activeBgColor
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.12), .clear, .black.opacity(0.25)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: activeBgColor)

            VStack(spacing: 0) {
                // 2. 顶部 Navigation Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(Color.white.opacity(0.2), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Text("取色卡片")
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .padding(.leading, 6)

                    Spacer()

                    HStack(spacing: 12) {
                        // 照片选择器
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 38, height: 38)
                                .background(Color.white.opacity(0.2), in: Circle())
                        }
                        .buttonStyle(.plain)

                        // 一键保存到相册
                        Button {
                            saveCardToAlbum()
                        } label: {
                            Image(systemName: "arrow.down.to.line")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 38, height: 38)
                                .background(Color.white.opacity(0.2), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)

                // 3. 核心色卡展示画布 Card Preview
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        cardCanvasView
                            .padding(.horizontal, 20)

                        // 4. 提取的主色卡板选择器
                        if !extractedColors.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("提取主色与氛围调")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.85))
                                    .padding(.horizontal, 22)

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
                                                            .foregroundStyle(.white)
                                                        Text(item.hexString)
                                                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                                                            .foregroundStyle(.white.opacity(0.8))
                                                    }
                                                }
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 10)
                                                .background(
                                                    isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.12),
                                                    in: Capsule()
                                                )
                                                .overlay(
                                                    Capsule()
                                                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 1.5)
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 22)
                                }
                            }
                        }

                        Text("轻按图片更换照片 · 轻按色卡自由切换页面背景色彩氛围")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.white.opacity(0.75))
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 10)
                }
            }

            // 保存提示 Toast
            if let msg = saveMessage {
                VStack {
                    Spacer()
                    Text(msg)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.black.opacity(0.75), in: Capsule())
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .task {
            createInitialDemoImage()
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

    // 核心海报卡片渲染 View
    private var cardCanvasView: some View {
        VStack(spacing: 0) {
            // 上半部分：极简诗意文案与时间色号标记
            VStack(spacing: 8) {
                if isEditingTitle {
                    TextField("输入画报诗意文案", text: $customTitle)
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .textFieldStyle(.plain)
                        .onSubmit { isEditingTitle = false }
                } else {
                    Text(customTitle)
                        .font(.system(size: 19, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .onTapGesture { isEditingTitle = true }
                }

                HStack(spacing: 8) {
                    Text(formattedCurrentTime())
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                    Text("·")
                    Text(activeHex)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(.white.opacity(0.75))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 26)
            .background(Color.white.opacity(0.12))

            // 下半部分：相框区域
            ZStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 330)
                        .clipped()
                } else {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 38))
                                .foregroundStyle(.white.opacity(0.85))
                            Text("点击选择照片 · 自适应背景与提取主色卡")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 330)
                        .background(Color.black.opacity(0.15))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
    }

    private func createInitialDemoImage() {
        let size = CGSize(width: 400, height: 400)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            let colors = [
                UIColor(red: 0.72, green: 0.52, blue: 0.60, alpha: 1.0).cgColor,
                UIColor(red: 0.88, green: 0.70, blue: 0.78, alpha: 1.0).cgColor
            ] as CFArray
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1]) {
                context.drawLinearGradient(gradient, start: CGPoint.zero, end: CGPoint(x: 400, y: 400), options: [])
            }
        }
        let demoImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let img = demoImage {
            Task {
                await processImage(img)
            }
        }
    }

    private func processImage(_ img: UIImage) async {
        selectedImage = img
        let palette = await ColorExtractor.extractPalette(from: img, count: 5)
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
                        colors: [.black.opacity(0.12), .clear, .black.opacity(0.25)],
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
