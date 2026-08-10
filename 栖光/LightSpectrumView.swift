//
//  LightSpectrumView.swift
//  栖光
//

import SwiftUI
import PhotosUI

/// 相框模版数据模型
struct FrameTemplate: Identifiable {
    let id = UUID()
    let title: String
    let tag: String
    let creator: String
    let creatorAvatar: String
    let publishDate: String
    let updateDate: String
    let initialStyle: PhotoFrameEditorView.TemplateStyle
    var isFavorite: Bool = false
}

struct LightSpectrumView: View {
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var selectedTemplateStyle: PhotoFrameEditorView.TemplateStyle = .blurWhiteBorder
    @State private var isShowingPhotoPicker = false
    @State private var isShowingEditor = false
    @State private var isLoadingPhoto = false
    @State private var photoLoadMessage: String? = nil

    @State private var templates: [FrameTemplate] = [
        FrameTemplate(
            title: "模糊背景加小白边",
            tag: "边框模板",
            creator: "Reed",
            creatorAvatar: "person.circle.fill",
            publishDate: "2025-06-12 21:56:18",
            updateDate: "2025-07-28 17:24:44",
            initialStyle: .blurWhiteBorder
        ),
        FrameTemplate(
            title: "Soda 极简拍立得",
            tag: "复古拍立得",
            creator: "栖光官方",
            creatorAvatar: "sparkles",
            publishDate: "2026-01-05 10:00:00",
            updateDate: "2026-08-01 12:30:00",
            initialStyle: .sodaPolaroid
        )
    ]

    var body: some View {
        ZStack {
            // 深色沉浸底色 (与截图一完全一致)
            Color(red: 0.1, green: 0.1, blue: 0.11)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    ForEach($templates) { $template in
                        TemplateCardView(
                            template: $template,
                            isLoading: isLoadingPhoto && selectedTemplateStyle == template.initialStyle,
                            onUseTap: {
                                selectedTemplateStyle = template.initialStyle
                                photoLoadMessage = nil
                                isShowingPhotoPicker = true
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }

            if isLoadingPhoto {
                ProgressView()
                    .tint(.white)
                    .padding(18)
                    .background(.black.opacity(0.72), in: Circle())
                    .transition(.scale.combined(with: .opacity))
            }

            if let photoLoadMessage {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text(photoLoadMessage)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.82), in: Capsule())
                    .padding(.bottom, 28)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationTitle("相框模板")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .photosPicker(isPresented: $isShowingPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                await loadSelectedPhoto(from: newItem)
            }
        }
        .navigationDestination(isPresented: $isShowingEditor) {
            if let selectedImage {
                PhotoFrameEditorView(
                    inputImage: selectedImage,
                    initialTemplateStyle: selectedTemplateStyle
                )
                .navigationBarBackButtonHidden(true)
            }
        }
        .hideTabBarOnRealDevice()
    }

    @MainActor
    private func loadSelectedPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isLoadingPhoto = true
        }
        defer {
            selectedPhotoItem = nil
            withAnimation(.easeOut(duration: 0.2)) {
                isLoadingPhoto = false
            }
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                showPhotoLoadMessage("照片读取失败，请换一张试试")
                return
            }

            selectedImage = image
            isShowingEditor = true
        } catch {
            showPhotoLoadMessage("无法打开这张照片")
        }
    }

    @MainActor
    private func showPhotoLoadMessage(_ message: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            photoLoadMessage = message
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation(.easeOut(duration: 0.2)) {
                photoLoadMessage = nil
            }
        }
    }
}

/// 模版预览卡片组件 (完美 1:1 复刻截图一：大图预览 + 模版信息 + 收藏 / 编辑预设 / 使用 按钮)
private struct TemplateCardView: View {
    @Binding var template: FrameTemplate
    let isLoading: Bool
    let onUseTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 1. 顶部模版展示大图 (截图一：暗色框架 + 照片 + 1.5px 纯白描边 + 模糊外框)
            ZStack {
                Color(red: 0.16, green: 0.16, blue: 0.18)

                if template.initialStyle == .blurWhiteBorder {
                    // 1.5px 细白边样板
                    ZStack(alignment: .bottom) {
                        LinearGradient(
                            colors: [Color(white: 0.22), Color(white: 0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .blur(radius: 20)
                        .overlay(Color.black.opacity(0.35))

                        ZStack(alignment: .bottom) {
                            ZStack {
                                LinearGradient(
                                    colors: [Color(white: 0.2), Color(white: 0.08)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                VStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 34))
                                        .foregroundStyle(.white.opacity(0.9))
                                    Text("MONOCHROME ART")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                            }
                            .frame(height: 160)
                            .frame(maxWidth: .infinity)

                            Text("iPhone 15 Pro")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundStyle(.white.opacity(0.85))
                                .padding(.bottom, 8)
                        }
                        .overlay(
                            Rectangle()
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                        .padding(.all, 24)
                    }
                } else {
                    // Soda 极简拍立得样板
                    ZStack {
                        LinearGradient(
                            colors: [Color(red: 0.25, green: 0.35, blue: 0.45), Color(red: 0.12, green: 0.15, blue: 0.22)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .blur(radius: 20)

                        VStack(spacing: 0) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 14, height: 14)
                                Text("Soda Official")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.black)
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.top, 8)

                            ZStack {
                                Color(white: 0.92)
                                Image(systemName: "sparkles")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.gray.opacity(0.6))
                            }
                            .frame(height: 110)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 8)

                            HStack(spacing: 8) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.red)
                                Image(systemName: "bubble.right")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.black)
                                Spacer()
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.black)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                        }
                        .background(Color.white)
                        .cornerRadius(6)
                        .padding(.all, 24)
                    }
                }

                // Pro 黄金角标
                VStack {
                    HStack {
                        Spacer()
                        Text("Pro")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(red: 0.98, green: 0.75, blue: 0.2), in: RoundedRectangle(cornerRadius: 4))
                    }
                    Spacer()
                }
                .padding(10)
            }
            .frame(height: 280)
            .cornerRadius(12)
            .clipped()

            // 2. 模版信息区 (标题、作者、发布时间 - 1:1 复制截图一)
            VStack(alignment: .leading, spacing: 10) {
                Text(template.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)

                Divider()
                    .overlay(Color.white.opacity(0.12))

                HStack {
                    Text(template.tag)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(red: 0.75, green: 0.68, blue: 0.98))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.3, green: 0.25, blue: 0.45).opacity(0.6), in: RoundedRectangle(cornerRadius: 6))

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("创作者：")
                            .foregroundStyle(.gray)
                        Image(systemName: template.creatorAvatar)
                            .foregroundStyle(.white)
                        Text(template.creator)
                            .foregroundStyle(.white)
                    }
                    .font(.system(size: 14))

                    Text("允许二次创作：是")
                        .font(.system(size: 14))
                        .foregroundStyle(.gray)

                    Text("发布时间：\(template.publishDate)")
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)

                    Text("最近更新：\(template.updateDate)")
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)
                }
            }
            .padding(.horizontal, 4)

            // 3. 底部操作按键行 (收藏 / 编辑预设 / 使用 - 1:1 复制截图一)
            HStack {
                Button {
                    withAnimation { template.isFavorite.toggle() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: template.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(template.isFavorite ? .yellow : .white)
                        Text("收藏")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        // 编辑预设
                    } label: {
                        Text("编辑预设")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)

                    Button {
                        onUseTap()
                    } label: {
                        HStack(spacing: 6) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.72)
                            } else {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 13, weight: .bold))
                            }

                            Text(isLoading ? "读取中" : "使用")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(minWidth: 78)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.50, green: 0.42, blue: 0.88), Color(red: 0.70, green: 0.52, blue: 0.86)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                }
            }
            .padding(.top, 6)
        }
        .padding(16)
        .background(Color(red: 0.14, green: 0.14, blue: 0.15))
        .cornerRadius(18)
    }
}
