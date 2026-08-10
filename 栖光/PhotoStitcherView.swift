//
//  PhotoStitcherView.swift
//  栖光
//
//  Created by zhixin on 2026/8/6.
//

import SwiftUI
import PhotosUI

struct PhotoStitcherView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPickerItems: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []
    @State private var stitchingMode: StitchMode = .vertical
    @State private var spacing: CGFloat = 8
    @State private var cornerRadius: CGFloat = 8
    @State private var backgroundColor: Color = .white
    @State private var isExporting: Bool = false
    @State private var showExportSuccessToast: Bool = false

    enum StitchMode: String, CaseIterable, Identifiable {
        case vertical = "竖向长图"
        case horizontal = "横向拼接"
        case grid = "网格宫格"

        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶栏控制
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(width: 40, height: 40)
                            .background(Color(.secondarySystemGroupedBackground), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("🖼️ 长图拼接")
                        .font(.system(size: 18, weight: .bold))

                    Spacer()

                    if !images.isEmpty {
                        Button {
                            exportStitchedImage()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.down")
                                Text("保存")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(.systemBackground))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color.primary, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    } else {
                        Spacer().frame(width: 40)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                // 核心展示与编辑区
                if images.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()

                        ZStack {
                            Circle()
                                .fill(Color.primary.opacity(0.06))
                                .frame(width: 100, height: 100)

                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 42))
                                .foregroundStyle(.primary.opacity(0.7))
                        }

                        VStack(spacing: 8) {
                            Text("批量选择图片/截图进行拼接")
                                .font(.system(size: 20, weight: .bold))

                            Text("支持竖向长图、横向拼接及宫格矩阵")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }

                        PhotosPicker(selection: $selectedPickerItems, maxSelectionCount: 30, matching: .images) {
                            HStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus")
                                Text("选择多张图片截图")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(.systemBackground))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Color.primary, in: Capsule())
                            .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.horizontal, 32)
                } else {
                    // 已选图片长图拼接预览区
                    ScrollView([.vertical, .horizontal], showsIndicators: true) {
                        StitchedCanvasView(
                            images: images,
                            mode: stitchingMode,
                            spacing: spacing,
                            cornerRadius: cornerRadius,
                            bgColor: backgroundColor
                        )
                        .padding(24)
                    }

                    // 底部调整工具栏
                    VStack(spacing: 16) {
                        // 1. 拼接模式切换
                        Picker("拼接模式", selection: $stitchingMode) {
                            ForEach(StitchMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        // 2. 拼缝与圆角微调
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("拼缝间距: \(Int(spacing))px")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                                Slider(value: $spacing, in: 0...32, step: 2)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("图片圆角: \(Int(cornerRadius))px")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                                Slider(value: $cornerRadius, in: 0...24, step: 2)
                            }
                        }

                        // 3. 底部重新选图与背景色
                        HStack {
                            PhotosPicker(selection: $selectedPickerItems, maxSelectionCount: 30, matching: .images) {
                                HStack(spacing: 4) {
                                    Image(systemName: "photo.badge.plus")
                                    Text("重新选图 (\(images.count)张)")
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            // 背景颜色切换
                            HStack(spacing: 10) {
                                Text("背景")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)

                                ForEach([Color.white, Color.black, Color(red: 0.95, green: 0.95, blue: 0.97)], id: \.description) { col in
                                    Button {
                                        backgroundColor = col
                                    } label: {
                                        Circle()
                                            .fill(col)
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.primary.opacity(0.3), lineWidth: backgroundColor == col ? 2 : 0.5)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(.secondarySystemGroupedBackground))
                }
            }

            // 保存成功 Toast
            if showExportSuccessToast {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("长图已成功保存至相册！")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 50)
            }
        }
        .navigationBarHidden(true)
        .hideTabBarOnRealDevice()
        .onChange(of: selectedPickerItems) { _, items in
            loadImages(from: items)
        }
    }

    private func loadImages(from items: [PhotosPickerItem]) {
        Task {
            var loaded: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    loaded.append(img)
                }
            }
            await MainActor.run {
                self.images = loaded
            }
        }
    }

    // 导出高质量合成长图
    private func exportStitchedImage() {
        guard !images.isEmpty else { return }
        isExporting = true

        let stitched = renderStitchedUIImage(
            images: images,
            mode: stitchingMode,
            spacing: spacing,
            cornerRadius: cornerRadius,
            bgColor: UIColor(backgroundColor)
        )

        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: stitched)
        } completionHandler: { success, _ in
            Task { @MainActor in
                self.isExporting = false
                if success {
                    withAnimation {
                        self.showExportSuccessToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation {
                            self.showExportSuccessToast = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 拼接画布 Render View
private struct StitchedCanvasView: View {
    let images: [UIImage]
    let mode: PhotoStitcherView.StitchMode
    let spacing: CGFloat
    let cornerRadius: CGFloat
    let bgColor: Color

    var body: some View {
        Group {
            switch mode {
            case .vertical:
                VStack(spacing: spacing) {
                    ForEach(Array(images.enumerated()), id: \.offset) { _, img in
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    }
                }
            case .horizontal:
                HStack(spacing: spacing) {
                    ForEach(Array(images.enumerated()), id: \.offset) { _, img in
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    }
                }
            case .grid:
                let columns = [GridItem(.flexible(), spacing: spacing), GridItem(.flexible(), spacing: spacing)]
                LazyVGrid(columns: columns, spacing: spacing) {
                    ForEach(Array(images.enumerated()), id: \.offset) { _, img in
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    }
                }
            }
        }
        .padding(spacing)
        .background(bgColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
    }
}

// MARK: - CoreGraphics Image Stitching Core Engine
private func renderStitchedUIImage(
    images: [UIImage],
    mode: PhotoStitcherView.StitchMode,
    spacing: CGFloat,
    cornerRadius: CGFloat,
    bgColor: UIColor
) -> UIImage {
    guard !images.isEmpty else { return UIImage() }

    switch mode {
    case .vertical:
        let targetWidth: CGFloat = 1080
        var totalHeight: CGFloat = spacing
        var scaledHeights: [CGFloat] = []

        for img in images {
            let aspect = img.size.height / max(img.size.width, 1)
            let h = targetWidth * aspect
            scaledHeights.append(h)
            totalHeight += h + spacing
        }

        let size = CGSize(width: targetWidth + (spacing * 2), height: totalHeight)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            bgColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            var currentY: CGFloat = spacing
            for (idx, img) in images.enumerated() {
                let h = scaledHeights[idx]
                let rect = CGRect(x: spacing, y: currentY, width: targetWidth, height: h)

                if cornerRadius > 0 {
                    let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
                    context.cgContext.saveGState()
                    path.addClip()
                    img.draw(in: rect)
                    context.cgContext.restoreGState()
                } else {
                    img.draw(in: rect)
                }

                currentY += h + spacing
            }
        }

    case .horizontal:
        let targetHeight: CGFloat = 1080
        var totalWidth: CGFloat = spacing
        var scaledWidths: [CGFloat] = []

        for img in images {
            let aspect = img.size.width / max(img.size.height, 1)
            let w = targetHeight * aspect
            scaledWidths.append(w)
            totalWidth += w + spacing
        }

        let size = CGSize(width: totalWidth, height: targetHeight + (spacing * 2))
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            bgColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            var currentX: CGFloat = spacing
            for (idx, img) in images.enumerated() {
                let w = scaledWidths[idx]
                let rect = CGRect(x: currentX, y: spacing, width: w, height: targetHeight)

                if cornerRadius > 0 {
                    let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
                    context.cgContext.saveGState()
                    path.addClip()
                    img.draw(in: rect)
                    context.cgContext.restoreGState()
                } else {
                    img.draw(in: rect)
                }

                currentX += w + spacing
            }
        }

    case .grid:
        let colCount = 2
        let cellWidth: CGFloat = 540
        let cellHeight: CGFloat = 540
        let rowCount = Int(ceil(Double(images.count) / Double(colCount)))

        let totalW = (cellWidth * CGFloat(colCount)) + (spacing * CGFloat(colCount + 1))
        let totalH = (cellHeight * CGFloat(rowCount)) + (spacing * CGFloat(rowCount + 1))

        let size = CGSize(width: totalW, height: totalH)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            bgColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            for (idx, img) in images.enumerated() {
                let row = idx / colCount
                let col = idx % colCount

                let x = spacing + CGFloat(col) * (cellWidth + spacing)
                let y = spacing + CGFloat(row) * (cellHeight + spacing)
                let rect = CGRect(x: x, y: y, width: cellWidth, height: cellHeight)

                if cornerRadius > 0 {
                    let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
                    context.cgContext.saveGState()
                    path.addClip()
                    img.draw(in: rect)
                    context.cgContext.restoreGState()
                } else {
                    img.draw(in: rect)
                }
            }
        }
    }
}
