//
//  LightSpectrumView.swift
//  栖光
//

import SwiftUI
import PhotosUI

struct LightSpectrumView: View {
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var selectedTemplateStyle: PhotoFrameEditorView.TemplateStyle = .blurWhiteBorder
    @State private var isShowingPhotoPicker = false
    @State private var isShowingEditor = false
    @State private var isLoadingPhoto = false
    @State private var photoLoadMessage: String?

    var body: some View {
        Color.white
            .ignoresSafeArea()
            .navigationTitle("相框模板")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
            .toolbar(.visible, for: .navigationBar)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    templateButton(
                        title: "模糊背景加小白边",
                        iconName: "square.on.square",
                        style: .blurWhiteBorder
                    )

                    templateButton(
                        title: "Soda 极简拍立得",
                        iconName: "rectangle.portrait",
                        style: .sodaPolaroid
                    )
                }
            }
            .overlay {
                if isLoadingPhoto {
                    ProgressView()
                }
            }
            .overlay(alignment: .bottom) {
                if let photoLoadMessage {
                    Label(photoLoadMessage, systemImage: "exclamationmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.82), in: Capsule())
                        .padding(.bottom, 28)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .photosPicker(
                isPresented: $isShowingPhotoPicker,
                selection: $selectedPhotoItem,
                matching: .images
            )
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

    private func templateButton(
        title: String,
        iconName: String,
        style: PhotoFrameEditorView.TemplateStyle
    ) -> some View {
        Button {
            selectedTemplateStyle = style
            photoLoadMessage = nil
            isShowingPhotoPicker = true
        } label: {
            Label(title, systemImage: iconName)
                .labelStyle(.iconOnly)
        }
        .tint(.primary)
        .disabled(isLoadingPhoto)
        .accessibilityLabel(title)
    }

    @MainActor
    private func loadSelectedPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }

        isLoadingPhoto = true
        defer {
            selectedPhotoItem = nil
            isLoadingPhoto = false
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
