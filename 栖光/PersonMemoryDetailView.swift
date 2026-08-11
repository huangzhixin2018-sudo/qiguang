import SwiftUI
import PhotosUI
import AVKit
import AVFoundation

private enum PersonMemoryDetailLayout {
    static let celebrityBackdropBase = Color(red: 0.965, green: 0.95, blue: 0.925)
    static let celebrityBackdropEdge = Color(red: 0.985, green: 0.955, blue: 0.948)

    static var celebrityBackdrop: LinearGradient {
        LinearGradient(
            colors: [celebrityBackdropBase, celebrityBackdropEdge],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func safeWidth(_ width: CGFloat, fallback: CGFloat = 390) -> CGFloat {
        guard width.isFinite, width > 0 else { return fallback }
        return width
    }
}

struct PersonMemoryDetailView: View {
    @State private var poster: PersonMemoryPoster
    var onDelete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var showPhotoPicker = false
    @State private var showVideoPicker = false
    @State private var showCoverPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var selectedCoverItem: PhotosPickerItem?
    @State private var attachmentMessage: String?

    @State private var selectedSection: CelebrityDetailSection = .record

    init(poster: PersonMemoryPoster, onDelete: (() -> Void)? = nil) {
        _poster = State(initialValue: poster)
        self.onDelete = onDelete
    }

    private var coverImageData: Data? {
        poster.coverImageData ?? poster.avatarImageData
    }

    private var mainContent: some View {
        GeometryReader { proxy in
            let safeWidth = PersonMemoryDetailLayout.safeWidth(proxy.size.width)

            ZStack(alignment: .bottom) {
                // 背景：点阵网格微纹理底版 (1:1 还原截图背景 Dot Grid)
                DotGridBackground()

                CelebrityMemoryDetailContentView(
                    poster: poster,
                    contentWidth: safeWidth,
                    topInset: proxy.safeAreaInsets.top,
                    selectedSection: $selectedSection,
                    onAddVideo: { showVideoPicker = true }
                )

                CelebrityFloatingControls(
                    topInset: proxy.safeAreaInsets.top,
                    selectedSection: selectedSection,
                    onBack: { dismiss() },
                    onAddPhoto: { showPhotoPicker = true },
                    onAddVideo: { showVideoPicker = true },
                    onChangeCover: { showCoverPicker = true },
                    onDelete: { showDeleteConfirmation = true }
                )
                .zIndex(10)
            }
        }
    }

    var body: some View {
        mainContent
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
        .confirmationDialog("确定要删除此画报吗？", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("删除画报", role: .destructive) {
                deleteCurrentPoster()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后，该回忆画报及收录的所有数据将无法找回。")
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .photosPicker(isPresented: $showVideoPicker, selection: $selectedVideoItem, matching: .videos)
        .photosPicker(isPresented: $showCoverPicker, selection: $selectedCoverItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                await handleSelectedPhoto(newItem)
            }
        }
        .onChange(of: selectedVideoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                await handleSelectedVideo(newItem)
            }
        }
        .onChange(of: selectedCoverItem) { _, newItem in
            guard let newItem else { return }
            Task {
                await handleSelectedCover(newItem)
            }
        }
        .alert("提示", isPresented: Binding(
            get: { attachmentMessage != nil },
            set: { if !$0 { attachmentMessage = nil } }
        )) {
            Button("好", role: .cancel) {
                attachmentMessage = nil
            }
        } message: {
            Text(attachmentMessage ?? "")
        }
        .hideTabBarOnRealDevice()
        } // GeometryReader

    private func deleteCurrentPoster() {
        MemoryPosterManager.shared.deletePoster(id: poster.id)
        onDelete?()
        dismiss()
    }

    private func handleSelectedCover(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            attachmentMessage = "封面照片更换失败，请重新选择。"
            selectedCoverItem = nil
            return
        }

        poster.coverImageData = data
        MemoryPosterManager.shared.updatePosterCover(id: poster.id, imageData: data)
        attachmentMessage = "封面照片已更换。"
        selectedCoverItem = nil
    }

    private func handleSelectedPhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            attachmentMessage = "照片添加失败，请重新选择。"
            selectedPhotoItem = nil
            return
        }

        poster.avatarImageData = data
        MemoryPosterManager.shared.updatePosterPhoto(id: poster.id, imageData: data)
        attachmentMessage = "照片已添加。"
        selectedPhotoItem = nil
    }

    private func handleSelectedVideo(_ item: PhotosPickerItem) async {
        let fileName = "memory_video_\(poster.id.uuidString).mov"
        let targetURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)

        do {
            if let movie = try await item.loadTransferable(type: VideoTransferable.self) {
                try? FileManager.default.removeItem(at: targetURL)
                try FileManager.default.copyItem(at: movie.url, to: targetURL)
                poster.videoFileName = fileName
                MemoryPosterManager.shared.updatePosterVideo(id: poster.id, fileName: fileName)
                attachmentMessage = "视频已成功添加！"
            } else if let data = try await item.loadTransferable(type: Data.self) {
                try? FileManager.default.removeItem(at: targetURL)
                try data.write(to: targetURL, options: .atomic)
                poster.videoFileName = fileName
                MemoryPosterManager.shared.updatePosterVideo(id: poster.id, fileName: fileName)
                attachmentMessage = "视频已成功添加！"
            } else {
                attachmentMessage = "视频读取失败，请重新选择。"
            }
        } catch {
            attachmentMessage = "视频保存失败：\(error.localizedDescription)"
        }

        selectedVideoItem = nil
    }
}

private struct StandardMemoryDetailContentView: View {
    let poster: PersonMemoryPoster
    let safeWidth: CGFloat
    let coverImageData: Data?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // 1. 顶部作品/画报大图 (全屏无边框展示 + 渐变过渡)
                ZStack(alignment: .bottomLeading) {
                    if let data = coverImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: safeWidth, height: 480)
                            .clipped()
                            .mask(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: .black, location: 0.0),
                                        .init(color: .black, location: 0.65),
                                        .init(color: .clear, location: 1.0)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else {
                        ZStack {
                            LinearGradient(
                                colors: [poster.category.defaultAccent.opacity(0.85), poster.category.defaultAccent.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            Image(systemName: poster.category.defaultIcon)
                                .font(.system(size: 90))
                                .foregroundStyle(.white.opacity(0.35))
                        }
                        .frame(width: safeWidth, height: 480)
                        .mask(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .black, location: 0.0),
                                    .init(color: .black, location: 0.65),
                                    .init(color: .clear, location: 1.0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }

                    // 2. 作品/画报标题 (悬浮在渐变过渡区域)
                    VStack(alignment: .leading, spacing: 10) {
                        // 类别标签
                        HStack(spacing: 4) {
                            Image(systemName: poster.category.defaultIcon)
                                .font(.system(size: 11, weight: .bold))
                            Text(poster.category.rawValue)
                                .font(.system(size: 12, weight: .bold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(poster.category.defaultAccent.opacity(0.15))
                        .foregroundStyle(poster.category.defaultAccent)
                        .clipShape(Capsule())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(poster.cardTitle)
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundStyle(Color.black)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)

                            Text(poster.tagline.isEmpty ? "最好的时光记录" : poster.tagline)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.gray)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .frame(height: 480)
                .clipShape(RoundedRectangle(cornerRadius: 0))

                // 3. 2x3 圆角网格卡片矩阵 (1:1 纯正截图排版：大粗体数字 + 浅灰标签)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    DetailStatBlockTile(number: "19", label: "点赞")
                    DetailStatBlockTile(number: "203", label: "做同款")
                    DetailStatBlockTile(number: "8年3个月", label: "相识时长")
                    DetailStatBlockTile(number: "56次", label: "记录打卡")
                    DetailStatBlockTile(number: "10月24日", label: "生日")
                    DetailStatColumnTile(number: "ENFP", label: "MBTI 人格")
                }
                .padding(.horizontal, 20)

                // 4. 底部微弱说明文字 (1:1 还原截图 disclaimer)
                Text("画报版本和当前记录版本不同，可能会出现部分细节不一致的情况。")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.gray.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.top, 6)
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

private struct CelebrityFloatingControls: View {
    let topInset: CGFloat
    let selectedSection: CelebrityDetailSection
    let onBack: () -> Void
    let onAddPhoto: () -> Void
    let onAddVideo: () -> Void
    let onChangeCover: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 48, height: 48)
                        .background(Color.black.opacity(0.28), in: Circle())
                        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 10) {
                    // 仅当当前选中标签需要添加功能时显示加号按钮 (记录标签隐藏添加按钮)
                    if selectedSection != .record {
                        Button {
                            switch selectedSection {
                            case .record:
                                break
                            case .event, .ticket, .picture:
                                onAddPhoto() // 选中票根、照片或事件时，点击直接选择照片/海报！
                            case .video:
                                onAddVideo() // 选中视频时，点击直接选择视频！
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Color.white)
                                .frame(width: 48, height: 48)
                                .background(Color.black.opacity(0.28), in: Circle())
                                .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                    }

                    Menu {
                        Button(action: onChangeCover) {
                            Label("更换封面照片", systemImage: "rectangle.on.rectangle")
                        }
                        Button(role: .destructive, action: onDelete) {
                            Label("删除此画报", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.white)
                            .frame(width: 48, height: 48)
                            .background(Color.black.opacity(0.28), in: Circle())
                            .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, topInset + 10)

            Spacer()
        }
        .ignoresSafeArea(.container, edges: .top)
    }
}

// 1:1 还原截图：2x3 大粗体数字 + 浅灰标签 统计矩阵块
private struct DetailStatBlockTile: View {
    let number: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(number)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(Color.black)

            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(red: 0.55, green: 0.55, blue: 0.58))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 96)
        .background(Color(red: 0.94, green: 0.94, blue: 0.95))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct DetailStatColumnTile: View {
    let number: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(number)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(Color.black)

            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(red: 0.55, green: 0.55, blue: 0.58))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 96)
        .background(Color(red: 0.94, green: 0.94, blue: 0.95))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - 明星/偶像画报排版
private enum CelebrityDetailSection: String, CaseIterable, Identifiable {
    case record
    case event
    case ticket
    case picture
    case video

    var id: String { rawValue }

    var title: String {
        switch self {
        case .record: return "记录"
        case .event: return "事件"
        case .ticket: return "票根"
        case .picture: return "照片"
        case .video: return "视频"
        }
    }
}

private struct CelebrityMemoryDetailContentView: View {
    let poster: PersonMemoryPoster
    let contentWidth: CGFloat
    let topInset: CGFloat
    @Binding var selectedSection: CelebrityDetailSection
    let onAddVideo: () -> Void

    private var displayName: String {
        let trimmed = poster.cardTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "喜欢的人" : trimmed
    }

    private var memoryDescription: String {
        let trimmed = poster.tagline.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "我最喜欢的一个人" : trimmed
    }

    private var heroHeight: CGFloat {
        max(480, min(560, contentWidth * 1.18))
    }

    private var sectionWidth: CGFloat {
        max(1, contentWidth - 40)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                CelebrityHeroSection(
                    poster: poster,
                    width: contentWidth,
                    height: heroHeight + topInset,
                    name: displayName,
                    description: memoryDescription
                )
                .padding(.top, -topInset)

                VStack(alignment: .leading, spacing: 26) {
                    CelebritySectionTabs(selection: $selectedSection)
                        .frame(width: sectionWidth, alignment: .leading)

                    Group {
                        switch selectedSection {
                        case .record:
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                                DetailStatBlockTile(number: poster.constellation.isEmpty ? "双子座" : poster.constellation, label: "星座")
                                DetailStatBlockTile(number: poster.zodiac.isEmpty ? "肖龙" : poster.zodiac, label: "生肖")
                                DetailStatBlockTile(number: poster.solarDate.isEmpty ? "专属记录" : poster.solarDate, label: "公历生日")
                                DetailStatBlockTile(number: poster.lunarDate.isEmpty ? "相伴时光" : poster.lunarDate, label: "农历生日")
                                DetailStatBlockTile(number: poster.category.rawValue, label: "画报类别")
                                DetailStatColumnTile(number: poster.mbti.isEmpty ? "ENFP" : poster.mbti, label: "MBTI 人格")
                            }
                        case .event:
                            CelebrityEventSection(poster: poster)
                        case .ticket:
                            CelebrityPhotoSection(poster: poster)
                        case .picture:
                            CelebrityPictureSection(poster: poster, width: sectionWidth)
                        case .video:
                            CelebrityVideoSection(poster: poster, onAddVideo: onAddVideo)
                        }
                    }
                    .frame(width: sectionWidth, alignment: .topLeading)
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 44)
            }
            .frame(width: contentWidth, alignment: .topLeading)
        }
        .frame(width: contentWidth)
        .background(PersonMemoryDetailLayout.celebrityBackdrop)
        .ignoresSafeArea(.container, edges: .top)
    }
}

// MARK: - 画报：事件节点模块 (基于真实画报数据渲染)
private struct CelebrityEventSection: View {
    let poster: PersonMemoryPoster

    var body: some View {
        if poster.avatarImageData == nil && poster.coverImageData == nil {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.04))
                        .frame(width: 64, height: 64)
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(Color.gray)
                }
                Text("暂无记录事件")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.gray)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        } else {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let data = poster.coverImageData ?? poster.avatarImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        LinearGradient(
                            colors: [
                                Color(red: 0.18, green: 0.16, blue: 0.15),
                                Color(red: 0.28, green: 0.25, blue: 0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .frame(height: 210)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                LinearGradient(
                    stops: [
                        .init(color: Color.black.opacity(0.05), location: 0.0),
                        .init(color: Color.black.opacity(0.40), location: 0.45),
                        .init(color: Color.black.opacity(0.88), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(poster.solarDate.isEmpty ? "创建专属记忆" : poster.solarDate)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .tracking(0.6)
                        .foregroundStyle(Color.white.opacity(0.82))

                    Text(poster.cardTitle.isEmpty ? poster.name : poster.cardTitle)
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundStyle(Color.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                .padding(22)
            }
            .frame(height: 210)
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        }
    }
}

// MARK: - 明星画报：照片展示模块
private struct CelebrityPictureSection: View {
    let poster: PersonMemoryPoster
    let width: CGFloat

    var body: some View {
        VStack(spacing: 16) {
            if let data = poster.avatarImageData, let uiImage = UIImage(data: data) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: 320)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)

                    HStack {
                        Text(poster.cardTitle.isEmpty ? "精彩时刻照片" : poster.cardTitle)
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .foregroundStyle(Color.black.opacity(0.85))
                        Spacer()
                        Text("独家回忆")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.gray)
                    }
                    .padding(.horizontal, 4)
                }
            } else {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.04))
                            .frame(width: 64, height: 64)
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundStyle(Color.gray)
                    }
                    Text("暂无相册照片")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.gray)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
    }
}

// MARK: - 明星画报：真实视频模块 (彻底去除模拟照片，真视频加载与播放)
private struct CelebrityVideoSection: View {
    let poster: PersonMemoryPoster
    let onAddVideo: () -> Void

    private var localVideoURL: URL? {
        guard let name = poster.videoFileName else { return nil }
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    var body: some View {
        VStack(spacing: 24) {
            if let videoURL = localVideoURL {
                // 🌟 真实上传成功的视频播放窗口
                VStack(spacing: 16) {
                    ZStack {
                        LocalVideoPlayerView(url: videoURL)
                            .frame(height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)

                        // 32pt 膨胀复古 CRT 描边
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.black.opacity(0.15), Color.black.opacity(0.04)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }

                    // 更换视频按钮
                    Button(action: onAddVideo) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .font(.system(size: 14, weight: .bold))
                            Text("更换视频")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(Color.black.opacity(0.75))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                // 🌟 彻底清除模拟图片！显示真实视频上传引导卡片 (Clean Empty State)
                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.35, green: 0.55, blue: 0.75).opacity(0.12))
                            .frame(width: 76, height: 76)

                        Image(systemName: "video.badge.plus")
                            .font(.system(size: 34, weight: .medium))
                            .foregroundStyle(Color(red: 0.35, green: 0.55, blue: 0.75))
                    }
                    .padding(.top, 14)

                    VStack(spacing: 6) {
                        Text("尚未选择回忆视频")
                            .font(.system(size: 18, weight: .bold, design: .serif))
                            .foregroundStyle(Color.black)

                        Text("完全兼容手机相册中的横屏(16:9)或竖屏(9:16)视频")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    Button(action: onAddVideo) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text("上传手机真实视频")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.85)) // 莫兰迪暖红强调色
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 6)
            }
        }
    }
}

// MARK: - 视频播放器原生组件
private struct LocalVideoPlayerView: View {
    let url: URL
    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                let p = AVPlayer(url: url)
                p.actionAtItemEnd = .none
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: p.currentItem,
                    queue: .main
                ) { _ in
                    p.seek(to: .zero)
                    p.play()
                }
                p.play()
                self.player = p
            }
            .onDisappear {
                player?.pause()
                player = nil
            }
    }
}

// MARK: - 视频 Transferable 传输定义
private struct VideoTransferable: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
            try? FileManager.default.removeItem(at: tempURL)
            try FileManager.default.copyItem(at: received.file, to: tempURL)
            return Self(url: tempURL)
        }
    }
}

// MARK: - 明星画报：票根模块 (直接呈现极简复古缺口票根)
private struct CelebrityPhotoSection: View {
    let poster: PersonMemoryPoster

    var body: some View {
        ConcertTicketStubCard(poster: poster)
    }
}

// MARK: - 🎫 1:1 还原缺口锯齿纪念票根 (Concert & Movie Ticket Stub Component)
private struct TicketNotchedShape: Shape {
    var cornerRadius: CGFloat = 18
    var notchRadius: CGFloat = 9
    var notchYRatio: CGFloat = 0.67

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let ny = rect.height * notchYRatio
        let nr = notchRadius
        let cr = cornerRadius

        // Top-left
        path.move(to: CGPoint(x: rect.minX + cr, y: rect.minY))
        // Top edge
        path.addLine(to: CGPoint(x: rect.maxX - cr, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - cr, y: rect.minY + cr), radius: cr, startAngle: .degrees(270), endAngle: .degrees(360), clockwise: false)

        // Right edge down to notch
        path.addLine(to: CGPoint(x: rect.maxX, y: ny - nr))
        // Right notch (curving left into card)
        path.addArc(center: CGPoint(x: rect.maxX, y: ny), radius: nr, startAngle: .degrees(270), endAngle: .degrees(90), clockwise: true)

        // Right edge down to bottom-right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cr))
        path.addArc(center: CGPoint(x: rect.maxX - cr, y: rect.maxY - cr), radius: cr, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)

        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + cr, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + cr, y: rect.maxY - cr), radius: cr, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)

        // Left edge up to notch
        path.addLine(to: CGPoint(x: rect.minX, y: ny + nr))
        // Left notch (curving right into card)
        path.addArc(center: CGPoint(x: rect.minX, y: ny), radius: nr, startAngle: .degrees(90), endAngle: .degrees(270), clockwise: true)

        // Left edge up to top-left
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cr))
        path.addArc(center: CGPoint(x: rect.minX + cr, y: rect.minY + cr), radius: cr, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)

        path.closeSubpath()
        return path
    }
}

private struct ConcertTicketStubCard: View {
    let poster: PersonMemoryPoster

    private var eventTitle: String {
        let name = poster.cardTitle.isEmpty ? poster.name : poster.cardTitle
        return "\(name) 专属纪念票根"
    }

    private var eventDate: String {
        poster.solarDate.isEmpty ? "珍藏时刻" : poster.solarDate
    }

    private var eventLocation: String {
        poster.tagline.isEmpty ? "栖光回忆记录" : poster.tagline
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 编辑部极简纸质缺口票根 - 清晰象牙暖白表面，在暖沙渐变底色上立体清晰，兼具高辨识度与极简协调美感
            ZStack(alignment: .topLeading) {
                // 1. 票根缺口外壳 Shape - 纯净象牙暖白纸质 (与渐变暖沙底色对比极高、清晰可辨)
                TicketNotchedShape(cornerRadius: 18, notchRadius: 9, notchYRatio: 0.70)
                    .fill(Color(red: 0.99, green: 0.985, blue: 0.975))
                    .shadow(color: Color(red: 0.15, green: 0.10, blue: 0.05).opacity(0.06), radius: 12, x: 0, y: 5)

                // 2. 票根边缘线条 - 香槟铜微光细描边
                TicketNotchedShape(cornerRadius: 18, notchRadius: 9, notchYRatio: 0.70)
                    .stroke(Color(red: 0.82, green: 0.74, blue: 0.65).opacity(0.50), lineWidth: 1)

                VStack(spacing: 0) {
                    // 上半部分：海报 + 大号标题与大号地址
                    HStack(alignment: .top, spacing: 14) {
                        // 缩略海报图
                        ZStack {
                            if let data = poster.avatarImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 74, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            } else {
                                ZStack {
                                    Color(red: 0.94, green: 0.92, blue: 0.90)
                                    Image(systemName: "music.mic")
                                        .font(.system(size: 30, weight: .medium))
                                        .foregroundStyle(Color(red: 0.60, green: 0.50, blue: 0.40))
                                }
                                .frame(width: 74, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }

                        // 右侧复古黑体/衬线排版 (高清晰度深炭黑标题，琥珀暖棕地址)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(eventTitle)
                                .font(.system(size: 19, weight: .bold, design: .serif))
                                .foregroundStyle(Color(red: 0.12, green: 0.12, blue: 0.14))
                                .lineLimit(2)
                                .lineSpacing(4)
                                .minimumScaleFactor(0.82)

                            Spacer(minLength: 8)

                            HStack(spacing: 5) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color(red: 0.58, green: 0.42, blue: 0.30))
                                Text(eventLocation)
                                    .font(.system(size: 14.5, weight: .medium))
                                    .foregroundStyle(Color(red: 0.58, green: 0.42, blue: 0.30))
                                    .lineLimit(1)
                            }
                        }
                        .frame(height: 100, alignment: .topLeading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 14)

                    // 中间撕裂虚线分隔线 (Perforation Dashed Line) - 优雅香槟褐色虚线
                    LineShape()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(Color(red: 0.80, green: 0.75, blue: 0.70))
                        .frame(height: 1)
                        .padding(.horizontal, 22)

                    // 下半部分：日期时间 (字重为 regular，非粗体)
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.clock")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(Color(red: 0.55, green: 0.32, blue: 0.26))
                            Text(eventDate)
                                .font(.system(size: 14.5, weight: .regular))
                                .foregroundStyle(Color(red: 0.45, green: 0.26, blue: 0.22))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
            }
            .frame(height: 178)
        }
    }
}

private struct CelebrityHeroSection: View {
    let poster: PersonMemoryPoster
    let width: CGFloat
    let height: CGFloat
    let name: String
    let description: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let data = poster.coverImageData ?? poster.avatarImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            poster.category.defaultAccent.opacity(0.28),
                            PersonMemoryDetailLayout.celebrityBackdropBase
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "star.fill")
                        .font(.system(size: 110, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.42))
                }
                .frame(width: width, height: height)
            }

            LinearGradient(
                stops: [
                    .init(color: Color.black.opacity(0.18), location: 0),
                    .init(color: Color.black.opacity(0.02), location: 0.34),
                    .init(color: PersonMemoryDetailLayout.celebrityBackdropBase.opacity(0.12), location: 0.58),
                    .init(color: PersonMemoryDetailLayout.celebrityBackdropBase.opacity(0.88), location: 0.86),
                    .init(color: PersonMemoryDetailLayout.celebrityBackdropBase, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(name)
                    .font(.system(size: 40, weight: .black, design: .serif))
                    .foregroundStyle(Color.black)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)

                Text(description)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.74))
                    .lineLimit(3)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
        }
        .frame(width: width, height: height)
    }
}

private struct CelebritySectionTabs: View {
    @Binding var selection: CelebrityDetailSection

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(CelebrityDetailSection.allCases) { section in
                    let isSelected = section == selection
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            selection = section
                        }
                    } label: {
                        Text(section.title)
                            .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? Color.white : Color.black.opacity(0.65))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background(
                                isSelected ? Color.black : Color.white.opacity(0.75)
                            )
                            .clipShape(Capsule())
                            .shadow(color: isSelected ? Color.black.opacity(0.10) : Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

private struct LineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
