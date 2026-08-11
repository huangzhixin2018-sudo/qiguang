//
//  ContentView.swift
//  栖光
//
//  Created by zhixin on 2026/7/6.
//

import SwiftUI
import Combine
import PhotosUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "sparkles")
                }
                .tag(0)

            MemoriesView()
                .tabItem {
                    Label("回忆", systemImage: "clock")
                }
                .tag(1)

            StoriesView()
                .tabItem {
                    Label("故事", systemImage: "square.stack")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person")
                }
                .tag(3)
        }
    }
}


// MARK: - 艺术点阵网格背景 (Minimalist Editorial Dot Grid Canvas)
struct DotGridBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.985, green: 0.985, blue: 0.975)

            Canvas { context, size in
                let spacing: CGFloat = 32
                let dotSize: CGFloat = 4
                let startY: CGFloat = 8
                let cols = Int(size.width / spacing) + 2
                let rows = Int(size.height / spacing) + 2

                for col in 0..<cols {
                    for row in 0..<rows {
                        let rect = CGRect(
                            x: CGFloat(col) * spacing - dotSize / 2,
                            y: startY + CGFloat(row) * spacing - dotSize / 2,
                            width: dotSize,
                            height: dotSize
                        )
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(Color(red: 0.72, green: 0.72, blue: 0.70).opacity(0.34))
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct HomeCategoryItem: Identifiable, Hashable {
    let id: String
    let title: String
    let iconName: String
}

struct HomeView: View {
    @State private var selectedCategory: String = "发现"
    
    private let categories: [HomeCategoryItem] = [
        HomeCategoryItem(id: "发现", title: "发现", iconName: "sparkles"),
        HomeCategoryItem(id: "1", title: "单图", iconName: "square.fill"),
        HomeCategoryItem(id: "2", title: "双图", iconName: "rectangle.split.2x1.fill"),
        HomeCategoryItem(id: "3", title: "三图", iconName: "rectangle.split.3x1.fill"),
        HomeCategoryItem(id: "4", title: "四图", iconName: "square.grid.2x2.fill")
    ]

    private let shortcuts: [HomeShortcut] = [
        .yearAlbum
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                DotGridBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // 1. 顶部 Header (左侧 hello，右侧云朵按钮)
                        HStack(alignment: .center) {
                            Text("hello")
                                .font(.system(size: 48, weight: .bold, design: .serif))
                                .italic()
                                .foregroundStyle(Color(red: 0.34, green: 0.30, blue: 0.30))

                            Spacer()

                            Button {
                            } label: {
                                Image(systemName: "cloud.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(Color.primary.opacity(0.72))
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(Color.white.opacity(0.65), lineWidth: 1)
                                    }
                                    .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 6)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                        // 2. 分类胶囊控制栏（图标+精致文案，暗墨色选中态）
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(categories) { item in
                                    let isSelected = selectedCategory == item.id
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                            selectedCategory = item.id
                                        }
                                    } label: {
                                        HStack(spacing: 7) {
                                            Image(systemName: item.iconName)
                                                .font(.system(size: 12, weight: .semibold))

                                            Text(item.title)
                                                .font(.system(size: 14, weight: .bold, design: item.id == "发现" ? .serif : .default))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            isSelected ? Color(red: 0.18, green: 0.18, blue: 0.20) : Color.white,
                                            in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                                        )
                                        .foregroundStyle(
                                            isSelected
                                                ? Color.white
                                                : Color(red: 0.30, green: 0.28, blue: 0.28)
                                        )
                                        .shadow(color: Color.black.opacity(isSelected ? 0.10 : 0.03), radius: 6, x: 0, y: 3)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                                .stroke(isSelected ? Color(red: 0.18, green: 0.18, blue: 0.20) : Color.black.opacity(0.05), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 6)
                        }
                        .padding(.top, 16)

                        // 3. 条件渲染：
                        // “发现”：保持原本经典功能快捷网格
                        // “1”：单图排版模板集
                        // “2/3/4”：多图排版（预留待开发）
                        if selectedCategory == "发现" {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 14),
                                    GridItem(.flexible(), spacing: 14)
                                ],
                                alignment: .leading,
                                spacing: 14
                            ) {
                                ForEach(shortcuts) { shortcut in
                                    HomeShortcutButton(shortcut: shortcut)
                                }
                            }
                            .padding(.horizontal, 22)
                            .padding(.top, 24)
                        } else if selectedCategory == "1" {
                            // 1 张照片排版模板集
                            VStack(alignment: .leading, spacing: 16) {
                                Text("单图画报集")
                                    .font(.system(size: 22, weight: .bold, design: .serif))
                                    .foregroundStyle(Color(red: 0.22, green: 0.20, blue: 0.20))
                                    .padding(.horizontal, 22)
                                    .padding(.top, 20)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(alignment: .top, spacing: 14) {
                                        // 模板 1：海洋光影画报
                                        NavigationLink {
                                            OceanPosterDetailView(title: "夏日画报")
                                        } label: {
                                            singlePhotoTemplateCard
                                        }
                                        .buttonStyle(.plain)

                                        // 模板 2：蓝色双色调网屏效果
                                        NavigationLink {
                                            BlueprintGridEffectView()
                                        } label: {
                                            blueprintGridTemplateCard
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 22)
                                    .padding(.vertical, 6)
                                }
                            }
                        } else {
                            // 2, 3, 4：空白留白区
                            VStack {
                                Spacer(minLength: 120)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.bottom, 120)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var singlePhotoTemplateCard: some View {
        singleTemplatePreview(
            assetName: "HomeSingle01",
            accessibilityLabel: "单图模板一"
        )
    }

    private var blueprintGridTemplateCard: some View {
        singleTemplatePreview(
            assetName: "HomeSingle02",
            accessibilityLabel: "蓝晒网格效果"
        )
    }

    private func singleTemplatePreview(
        assetName: String,
        accessibilityLabel: String
    ) -> some View {
        Image(assetName)
            .resizable()
            .scaledToFill()
            .frame(width: 172, height: 258)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
            .accessibilityLabel(accessibilityLabel)
    }
}

private enum HomeShortcut: Identifiable {
    case yearAlbum

    var id: String { title }

    var title: String {
        switch self {
        case .yearAlbum: return "年度相册"
        }
    }

    var iconName: String {
        switch self {
        case .yearAlbum: return "archivebox"
        }
    }

    var color: Color {
        switch self {
        case .yearAlbum: return Color(red: 0.58, green: 0.44, blue: 0.35)
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .yearAlbum:
            YearsOrganizerView()
        }
    }
}

private struct HomeShortcutButton: View {
    let shortcut: HomeShortcut

    var body: some View {
        NavigationLink {
            shortcut.destination
        } label: {
            HStack(spacing: 12) {
                Image(systemName: shortcut.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(shortcut.color)
                    .frame(width: 36, height: 36)
                    .background(shortcut.color.opacity(0.10), in: Circle())

                Text(shortcut.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(Color.white.opacity(0.74), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.72), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}


enum MemoryCategory: String, CaseIterable, Identifiable, Codable {
    case family = "家人"
    case self_category = "自己"
    case pet = "宠物"
    case friend = "朋友"
    case celebrity = "明星"
    
    var id: String { rawValue }
    
    var defaultIcon: String {
        switch self {
        case .family: return "heart.fill"
        case .self_category: return "person.fill"
        case .pet: return "pawprint.fill"
        case .friend: return "figure.2.arms.open"
        case .celebrity: return "star.fill"
        }
    }
    
    var defaultAccent: Color {
        switch self {
        case .family: return Color(red: 0.85, green: 0.35, blue: 0.35)
        case .self_category: return Color(red: 0.35, green: 0.55, blue: 0.75)
        case .pet: return Color(red: 0.90, green: 0.65, blue: 0.25)
        case .friend: return Color(red: 0.45, green: 0.70, blue: 0.55)
        case .celebrity: return Color(red: 0.65, green: 0.45, blue: 0.75)
        }
    }
}

struct PersonMemoryPoster: Identifiable, Codable {
    var id = UUID()
    let name: String            // 左侧艺术大字称呼（如 "妈妈"）
    let cardTitle: String       // 右侧名片卡种名称（如 "陈晓静"、"王二蛋"、"豆豆"）
    let tagline: String         // 简短标语（如 "陪伴的时光"）
    var avatarImageData: Data? = nil // 自定义上传的真实头像图片
    var coverImageData: Data? = nil  // 详情页单独封面图片
    var videoFileName: String? = nil // 详情页追加的视频文件名
    var category: MemoryCategory = .friend
    let constellation: String   // 星座
    let zodiac: String          // 生肖
    let mbti: String            // MBTI
    let solarDate: String       // 公历/生日
    let lunarDate: String       // 农历
}

@MainActor
class MemoryPosterManager: ObservableObject {
    static let shared = MemoryPosterManager()
    
    @Published var posters: [PersonMemoryPoster] = []
    
    private let storageFileName = "memory_posters_v1.json"
    
    private var storageDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var fileURL: URL {
        storageDirectory.appendingPathComponent(storageFileName)
    }
    
    init() {
        loadPosters()
    }
    
    func loadPosters() {
        if let data = try? Data(contentsOf: fileURL) {
            if let decoded = try? JSONDecoder().decode([PersonMemoryPoster].self, from: data) {
                self.posters = decoded
            }
        }
    }
    
    func savePosters() {
        if let encoded = try? JSONEncoder().encode(posters) {
            try? encoded.write(to: fileURL)
        }
    }
    
    func addPoster(_ poster: PersonMemoryPoster) {
        posters.insert(poster, at: 0)
        savePosters()
    }
    
    func deletePoster(id: UUID) {
        posters.removeAll { $0.id == id }
        savePosters()
    }

    func updatePosterPhoto(id: UUID, imageData: Data) {
        guard let index = posters.firstIndex(where: { $0.id == id }) else { return }
        posters[index].avatarImageData = imageData
        savePosters()
    }

    func updatePosterCover(id: UUID, imageData: Data) {
        guard let index = posters.firstIndex(where: { $0.id == id }) else { return }
        posters[index].coverImageData = imageData
        savePosters()
    }

    func updatePosterVideo(id: UUID, fileName: String) {
        guard let index = posters.firstIndex(where: { $0.id == id }) else { return }
        posters[index].videoFileName = fileName
        savePosters()
    }
}

struct MemoriesView: View {
    @StateObject private var manager = MemoryPosterManager.shared

    // 莫兰迪低饱和度卡片软纸底色 (复刻最新截图：奶油暖米、淡雅松石青、暮色灰粉等)
    private let morandiBgColors: [Color] = [
        Color(red: 0.94, green: 0.92, blue: 0.88), // 奶油暖米
        Color(red: 0.88, green: 0.92, blue: 0.90), // 淡雅松石青
        Color(red: 0.92, green: 0.89, blue: 0.91), // 暮色灰粉
        Color(red: 0.90, green: 0.91, blue: 0.93)  // 烟云蓝灰
    ]

    @State private var isShowingCreateSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                // 1. 艺术点阵网格画板背景
                DotGridBackground()

                VStack(spacing: 0) {
                    // 2. 顶部标题 + 右侧新建按键
                    HStack(alignment: .center) {
                        Text("生命里的光")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundStyle(Color(red: 0.20, green: 0.18, blue: 0.16))

                        Spacer()

                        Button {
                            isShowingCreateSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(red: 0.25, green: 0.22, blue: 0.20))
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.85), in: Circle())
                                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    .padding(.bottom, 12)

                    if manager.posters.isEmpty {
                        Spacer()
                    } else {
                        // 3. 双列莫兰迪圆窗肖像画报卡 (Morandi Circle Portrait Cards)
                        ScrollView(showsIndicators: false) {
                            LazyVGrid(
                                columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
                                spacing: 16
                            ) {
                                ForEach(Array(manager.posters.enumerated()), id: \.element.id) { index, poster in
                                    let cardBg = morandiBgColors[index % morandiBgColors.count]
                                    NavigationLink {
                                        PersonMemoryDetailView(poster: poster) {
                                            manager.deletePoster(id: poster.id)
                                        }
                                    } label: {
                                        CirclePortraitCardView(poster: poster, cardBg: cardBg)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isShowingCreateSheet) {
                CreatePersonPosterSheet { newPoster in
                    manager.addPoster(newPoster)
                }
            }
        }
    }
}


// MARK: - 1:1 复刻最新截图：莫兰迪圆窗肖像画报卡片 (Circle Portrait Card View)
private struct CirclePortraitCardView: View {
    let poster: PersonMemoryPoster
    let cardBg: Color

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(poster.category.defaultAccent.opacity(0.12))

                if let data = poster.avatarImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                } else {
                    Image(systemName: poster.category.defaultIcon)
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(poster.category.defaultAccent)
                }
            }
            .frame(width: 110, height: 110)
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
            .padding(.top, 8)

            VStack(spacing: 4) {
                Text(poster.name)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(Color(red: 0.18, green: 0.16, blue: 0.15))

                Text(poster.tagline)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(red: 0.50, green: 0.46, blue: 0.42))
                    .lineLimit(1)
            }
            .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 3)
    }
}

private struct CreatePersonPosterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var tagline = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var selectedCategory: MemoryCategory = .friend

    let onCreate: (PersonMemoryPoster) -> Void

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // 1. 照片选择/上传区 (PhotosPicker)
                    VStack(spacing: 10) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.94, green: 0.92, blue: 0.88))
                                    .frame(width: 100, height: 100)

                                if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    VStack(spacing: 6) {
                                        Image(systemName: selectedCategory.defaultIcon)
                                            .font(.system(size: 28))
                                            .foregroundStyle(selectedCategory.defaultAccent)
                                    }
                                }
                            }
                            .overlay(
                                Circle()
                                    .stroke(Color(red: 0.82, green: 0.78, blue: 0.72), lineWidth: 1.5)
                            )
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                        }
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                }
                            }
                        }

                        Text("点击上传人物照片")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(red: 0.50, green: 0.46, blue: 0.42))
                    }
                    .padding(.top, 20)
                    
                    // 1.5 类别选择区 (横向胶囊)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("画报类别")
                            .font(.system(size: 14, weight: .semibold, design: .serif))
                            .foregroundStyle(Color(red: 0.22, green: 0.20, blue: 0.18))
                            .padding(.horizontal, 24)
                            
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(MemoryCategory.allCases) { category in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedCategory = category
                                        }
                                    } label: {
                                        Text(category.rawValue)
                                            .font(.system(size: 14, weight: .medium))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 9)
                                        .background(
                                            selectedCategory == category ? category.defaultAccent : Color(red: 0.95, green: 0.94, blue: 0.91)
                                        )
                                        .foregroundStyle(selectedCategory == category ? .white : Color(red: 0.45, green: 0.40, blue: 0.35))
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }

                    // 2. 极简表单：名称与描述语句
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("名称")
                                .font(.system(size: 14, weight: .semibold, design: .serif))
                                .foregroundStyle(Color(red: 0.22, green: 0.20, blue: 0.18))

                            TextField(selectedCategory == .celebrity ? "如：王一博" : "如：妈妈、陈晓静、豆豆", text: $name)
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background(Color(red: 0.95, green: 0.94, blue: 0.91), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("描述语句")
                                .font(.system(size: 14, weight: .semibold, design: .serif))
                                .foregroundStyle(Color(red: 0.22, green: 0.20, blue: 0.18))

                            TextField(selectedCategory == .celebrity ? "如：我最喜欢的一个人" : "如：陪伴的时光、相识第 520 天", text: $tagline)
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background(Color(red: 0.95, green: 0.94, blue: 0.91), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
            .background(
                LinearGradient(
                    colors: [Color(red: 0.98, green: 0.97, blue: 0.95), Color(red: 0.95, green: 0.94, blue: 0.91)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("新建回忆画报")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundStyle(Color(red: 0.45, green: 0.40, blue: 0.35))
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        let finalName = name.trimmingCharacters(in: .whitespaces).isEmpty ? "重要的人" : name
	                        let newPoster = PersonMemoryPoster(
	                            name: finalName,
	                            cardTitle: finalName,
	                            tagline: tagline.isEmpty ? (selectedCategory == .celebrity ? "我最喜欢的一个人" : "珍贵的回忆") : tagline,
	                            avatarImageData: selectedImageData,
	                            category: selectedCategory,
	                            constellation: "回忆",
	                            zodiac: "记忆",
	                            mbti: "喜欢",
	                            solarDate: "珍藏",
	                            lunarDate: "时光"
                        )
                        onCreate(newPoster)
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(red: 0.18, green: 0.16, blue: 0.15))
                }
            }
        }
    }
}


struct StoryDiaryEntry: Identifiable {
    let id = UUID()
    let date: Date
    let text: String
    let images: [UIImage]
}


/// 本地故事集与照片数据持久化管理器
@MainActor
struct StoryCollectionModel: Identifiable, Codable {
    var id = UUID()
    var title: String
    var theme: String // "magazine", "darkroom", "polaroid", "gallery", "timeline"
    var createdAt = Date()
    var coverImageData: Data? = nil
}

final class StoryDataManager: ObservableObject {
    static let shared = StoryDataManager()

    @Published var collections: [StoryCollectionModel] = []
    @Published var entries: [StoryDiaryEntry] = []

    private let collectionsListKey = "saved_story_collections_list_v2"
    private let oldCollectionsKey = "saved_story_collection_title"
    private let oldThemeKey = "saved_story_collection_theme"
    private let storiesDirName = "SavedStoryPhotos"
    private let metadataFileName = "entries_metadata.json"

    private struct PersistedEntry: Codable {
        let id: String
        let date: Date
        let text: String
        let imageFilenames: [String]
    }

    init() {
        loadCollections()
    }

    private var storageDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(storiesDirName)
    }

    func addCollection(title: String, theme: String = "magazine", coverImage: UIImage? = nil) {
        let imageData = coverImage?.jpegData(compressionQuality: 0.8)
        let newColl = StoryCollectionModel(title: title, theme: theme, coverImageData: imageData)
        self.collections.insert(newColl, at: 0)
        persistCollections()
    }

    func deleteCollection(id: UUID) {
        self.collections.removeAll { $0.id == id }
        persistCollections()
    }

    func updateCollection(id: UUID, title: String, theme: String) {
        if let idx = self.collections.firstIndex(where: { $0.id == id }) {
            self.collections[idx].title = title
            self.collections[idx].theme = theme
            persistCollections()
        }
    }

    /// 兼容旧调用的 saveCollection 方法
    func saveCollection(title: String, theme: String = "magazine") {
        if let first = collections.first {
            updateCollection(id: first.id, title: title, theme: theme)
        } else {
            addCollection(title: title, theme: theme)
        }
    }

    private func persistCollections() {
        if let data = try? JSONEncoder().encode(collections) {
            UserDefaults.standard.set(data, forKey: collectionsListKey)
        }
    }

    func addEntry(_ entry: StoryDiaryEntry) {
        self.entries.append(entry)
        persistAllEntries()
    }

    private func persistAllEntries() {
        let dir = storageDirectory
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        var persistedList: [PersistedEntry] = []

        for entry in entries {
            var filenames: [String] = []
            for (idx, img) in entry.images.enumerated() {
                let filename = "photo_\(entry.id.uuidString)_\(idx).jpg"
                let fileURL = dir.appendingPathComponent(filename)
                if !FileManager.default.fileExists(atPath: fileURL.path) {
                    if let data = img.jpegData(compressionQuality: 0.85) {
                        try? data.write(to: fileURL)
                    }
                }
                filenames.append(filename)
            }
            persistedList.append(PersistedEntry(
                id: entry.id.uuidString,
                date: entry.date,
                text: entry.text,
                imageFilenames: filenames
            ))
        }

        let jsonURL = dir.appendingPathComponent(metadataFileName)
        if let data = try? JSONEncoder().encode(persistedList) {
            try? data.write(to: jsonURL)
        }
    }

    private func loadCollections() {
        if let data = UserDefaults.standard.data(forKey: collectionsListKey),
           let list = try? JSONDecoder().decode([StoryCollectionModel].self, from: data) {
            self.collections = list
        } else if let oldTitle = UserDefaults.standard.string(forKey: oldCollectionsKey) {
            let oldTheme = UserDefaults.standard.string(forKey: oldThemeKey) ?? "magazine"
            let migrated = StoryCollectionModel(title: oldTitle, theme: oldTheme)
            self.collections = [migrated]
            persistCollections()
        }
    }

    func clearAllDataAndCache() -> Double {
        let cacheBytes = getStorageSizeInBytes()

        UserDefaults.standard.removeObject(forKey: collectionsListKey)
        UserDefaults.standard.removeObject(forKey: oldCollectionsKey)
        UserDefaults.standard.removeObject(forKey: oldThemeKey)
        self.collections = []
        self.entries = []

        let dir = storageDirectory
        if FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.removeItem(at: dir)
        }

        URLCache.shared.removeAllCachedResponses()
        let tmpDir = FileManager.default.temporaryDirectory
        if let tmpFiles = try? FileManager.default.contentsOfDirectory(at: tmpDir, includingPropertiesForKeys: nil) {
            for file in tmpFiles {
                try? FileManager.default.removeItem(at: file)
            }
        }

        return Double(cacheBytes) / (1024.0 * 1024.0)
    }

    func getStorageSizeInBytes() -> Int64 {
        var totalSize: Int64 = 0
        let dir = storageDirectory
        if let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in files {
                if let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) {
                    totalSize += Int64(size)
                }
            }
        }

        let tmpDir = FileManager.default.temporaryDirectory
        if let tmpFiles = try? FileManager.default.contentsOfDirectory(at: tmpDir, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in tmpFiles {
                if let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) {
                    totalSize += Int64(size)
                }
            }
        }

        return max(totalSize, 0)
    }
}


struct StoriesView: View {
    @ObservedObject private var dataManager = StoryDataManager.shared
    @State private var isShowingNewCollection = false

    // 栖光全屏纯色纸质背景 (Pure Warm Studio Canvas)
    private let pageBackgroundColor = Color(red: 0.95, green: 0.94, blue: 0.91)

    var body: some View {
        NavigationStack {
            ZStack {
                // 1. 纯色优雅纸艺画板背景
                pageBackgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 2. 顶部「故事」标题 + 右侧新建按键
                    HStack(alignment: .center) {
                        Text("故事")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundStyle(Color(red: 0.20, green: 0.18, blue: 0.16))

                        Spacer()

                        Button {
                            isShowingNewCollection = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(red: 0.25, green: 0.22, blue: 0.20))
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.85), in: Circle())
                                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    .padding(.bottom, 12)

                    if dataManager.collections.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "book.closed")
                                .font(.system(size: 44, weight: .light))
                                .foregroundStyle(Color(red: 0.65, green: 0.60, blue: 0.55))

                            Text("还没有记录故事")
                                .font(.system(size: 16, weight: .medium, design: .serif))
                                .foregroundStyle(Color(red: 0.45, green: 0.40, blue: 0.35))

                            Text("把照片与时光，串成独一无二的纪念册")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(Color(red: 0.60, green: 0.56, blue: 0.52))

                            Button {
                                isShowingNewCollection = true
                            } label: {
                                Text("开始创作")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 22)
                                    .padding(.vertical, 11)
                                    .background(Color(red: 0.35, green: 0.30, blue: 0.28))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 8)

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVGrid(
                                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                                spacing: 14
                            ) {
                                ForEach(Array(dataManager.collections.enumerated()), id: \.element.id) { index, item in
                                    StoryCollectionCardItem(collection: item, index: index)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $isShowingNewCollection) {
            NewCollectionSheet { title, theme, coverImg in
                dataManager.addCollection(title: title, theme: theme, coverImage: coverImg)
            }
        }
    }
}

private struct StoryCollectionCardItem: View {
    let collection: StoryCollectionModel
    var index: Int = 0
    @ObservedObject private var dataManager = StoryDataManager.shared

    private var coverImage: UIImage? {
        if let data = collection.coverImageData, let img = UIImage(data: data) {
            return img
        }
        return dataManager.entries.first?.images.first
    }

    var body: some View {
        NavigationLink {
            StoryDetailView(title: collection.title, coverImage: coverImage)
        } label: {
            UnfoldBreakoutCardView(title: collection.title, image: coverImage, index: index)
                .frame(height: 104)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                dataManager.deleteCollection(id: collection.id)
            } label: {
                Label("删除故事集", systemImage: "trash")
            }
        }
    }
}

// MARK: - 🎨 Unfold 招牌美学：横向卡片 + 右侧精致破框倾斜相纸
private struct UnfoldBreakoutCardView: View {
    let title: String
    let image: UIImage?
    let index: Int

    // 🎨 视觉色彩总监精调：低饱和高雅莫兰迪特种纸套色系（高亮度与纯度统一，双列平铺极具韵律感）
    private let cardBackgrounds: [Color] = [
        Color(red: 0.91, green: 0.86, blue: 0.81), // 暖燕麦 (Warm Oat Sand)
        Color(red: 0.82, green: 0.86, blue: 0.81), // 鼠尾草雾绿 (Sage Fog Olive)
        Color(red: 0.89, green: 0.82, blue: 0.79), // 柔淡陶土粉 (Soft Clay Rose)
        Color(red: 0.81, green: 0.85, blue: 0.89), // 暮霭烟熏蓝 (Muted Slate Sky)
        Color(red: 0.85, green: 0.82, blue: 0.87), // 冷香薰淡紫 (Quiet Heather Lavender)
        Color(red: 0.80, green: 0.86, blue: 0.84)  // 海盐淡青灰 (Seafoam Linen)
    ]

    private var rotationAngle: Double {
        let angles: [Double] = [-5.0, 4.5, -4.0, 5.5]
        return angles[index % angles.count]
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // 1. 底层圆角柔和特种纸底板
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackgrounds[index % cardBackgrounds.count])
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.black.opacity(0.04), lineWidth: 1)
                )

            // 2. 内容层：左深色主标题 + 右侧精致小相纸
            HStack(spacing: 0) {
                // 左侧纯中文主标题 (深炭黑衬线体，阅读质感极佳)
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundStyle(Color(red: 0.20, green: 0.18, blue: 0.16))
                        .lineSpacing(3)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(.leading, 14)
                .padding(.trailing, 6)

                Spacer(minLength: 0)

                // 右侧精致缩小版 3D 破框浮动相纸 (58pt x 76pt)
                ZStack {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 58, height: 76)
                            .clipped()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .stroke(Color.white, lineWidth: 2.0)
                            )
                            .shadow(color: .black.opacity(0.18), radius: 6, x: 2, y: 3)
                            .rotationEffect(.degrees(rotationAngle))
                    } else {
                        // 预设精致白边胶片纸
                        ZStack {
                            Color(red: 0.98, green: 0.97, blue: 0.95)
                            VStack(spacing: 3) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 15, weight: .light))
                                    .foregroundStyle(Color.black.opacity(0.35))
                                Text("栖光")
                                    .font(.system(size: 8.5, weight: .bold, design: .serif))
                                    .foregroundStyle(Color.black.opacity(0.40))
                            }
                        }
                        .frame(width: 58, height: 76)
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .stroke(Color.white, lineWidth: 2.0)
                        )
                        .shadow(color: .black.opacity(0.16), radius: 6, x: 2, y: 3)
                        .rotationEffect(.degrees(rotationAngle))
                    }
                }
                .padding(.trailing, 8)
                .offset(x: 2)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - 🎨 1:1 还原参考截图：立体收纳套/层叠信封与年鉴票根视图
private struct StackedEnvelopeFolderView: View {
    let title: String
    let theme: String
    let image: UIImage?
    let index: Int

    // 编辑部精选调和套色 (Unfold 美学：统一明度与低饱和低纯度，多卡片组合时极其和谐柔和)
    private let pocketColors: [Color] = [
        Color(red: 0.44, green: 0.52, blue: 0.58), // 暮霭雅灰蓝 (Muted Slate Blue)
        Color(red: 0.76, green: 0.56, blue: 0.52), // 复古陶土肉粉 (Warm Clay Rose)
        Color(red: 0.48, green: 0.55, blue: 0.48), // 鼠尾草灰绿 (Sage Olive Green)
        Color(red: 0.68, green: 0.58, blue: 0.52), // 燕麦暖驼棕 (Oatmeal Soft Taupe)
        Color(red: 0.56, green: 0.52, blue: 0.60), // 烟熏莫兰迪紫 (Smoky Heather Lavender)
        Color(red: 0.46, green: 0.56, blue: 0.56)  // 沉静海盐冷绿 (Quiet Seafoam Green)
    ]
    private let singleCardColor = Color(red: 0.96, green: 0.95, blue: 0.93)

    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. 抽出部分：直接展示完整的封面照片
            VStack(spacing: 0) {
                Group {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 135)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        // 无照片时的高高级米白色全幅卡片
                        ZStack {
                            singleCardColor
                            VStack(spacing: 6) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 22, weight: .light))
                                    .foregroundStyle(Color.black.opacity(0.35))
                                Text("栖光 · 故事集")
                                    .font(.system(size: 11, weight: .bold, design: .serif))
                                    .foregroundStyle(Color.black.opacity(0.45))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 135)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.horizontal, 6)
                .offset(y: 10)

                Spacer()
            }
            .padding(.top, 6)

            // 2. 正面经典 U 型圆弧弧口口袋 + 嵌入白色高质感标题
            ZStack(alignment: .center) {
                EnvelopePocketShape()
                    .fill(pocketColors[index % pocketColors.count])
                    .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: -2)

                // 嵌入在口袋纯正中央的中文优雅主标题 (18pt 粗衬线体)
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(Color.white.opacity(0.95))
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .offset(y: 6)
            }
            .frame(height: 78)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// 正面带 U 型凹口的信封口袋 Shape
private struct EnvelopePocketShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cutoutWidth: CGFloat = 48
        let cutoutDepth: CGFloat = 22
        let midX = rect.midX

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))

        // 左上角平滑切到 U 型凹口
        path.addLine(to: CGPoint(x: midX - cutoutWidth / 2, y: rect.minY))

        // U 型圆弧凹口
        path.addCurve(
            to: CGPoint(x: midX + cutoutWidth / 2, y: rect.minY),
            control1: CGPoint(x: midX - cutoutWidth / 4, y: rect.minY + cutoutDepth),
            control2: CGPoint(x: midX + cutoutWidth / 4, y: rect.minY + cutoutDepth)
        )

        // 凹口右侧延伸到右上角
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))

        path.closeSubpath()
        return path
    }
}
// 支持 5 大主题选择及封面图片上传的新建故事集弹窗
private struct NewCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var collectionName = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedCoverImage: UIImage? = nil
    @FocusState private var isNameFocused: Bool
    let onCreate: (String, String, UIImage?) -> Void

    private var trimmedName: String {
        collectionName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(.systemGray5))
                .frame(width: 46, height: 5)
                .padding(.top, 14)

            ZStack {
                Text("新故事集")
                    .font(.system(size: 20, weight: .semibold))

                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .background(Color(.systemGray6), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("故事集名称")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)

                        TextField("例如：长白山滑雪之旅", text: $collectionName)
                            .font(.system(size: 22, weight: .semibold))
                            .padding(.horizontal, 16)
                            .frame(height: 54)
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .focused($isNameFocused)
                    }

                    // 上传封面照片区块
                    VStack(alignment: .leading, spacing: 8) {
                        Text("封面照片 (可选)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)

                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            HStack(spacing: 14) {
                                if let img = selectedCoverImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("已选择封面图片")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(.primary)
                                        Text("点击重新挑选或更换照片")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                    }
                                } else {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color(.systemGray5))
                                            .frame(width: 50, height: 50)

                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: 20))
                                            .foregroundStyle(Color.primary)
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("上传封面照片")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(.primary)
                                        Text("照片将精美抽取呈现在信封封面上")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color(.tertiaryLabel))
                            }
                            .padding(12)
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let img = UIImage(data: data) {
                                    await MainActor.run {
                                        self.selectedCoverImage = img
                                    }
                                }
                            }
                        }
                    }

                                    Button {
                        guard !trimmedName.isEmpty else { return }
                        onCreate(trimmedName, "magazine", selectedCoverImage)
                        dismiss()
                    } label: {
                        Text("创建故事集")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(trimmedName.isEmpty ? Color(.systemGray4) : Color.primary, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(trimmedName.isEmpty)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .presentationDetents([.fraction(0.52), .medium])
        .presentationCornerRadius(36)
        .onAppear {
            isNameFocused = true
        }
    }
}


// MARK: - 独立年度照片整理页：YearsOrganizerView (精装大书特刊美学)
struct YearsOrganizerView: View {
    private let sampleYears: [(year: String, photoCount: Int, videoCount: Int, color: Color)] = [
        ("2026", 5, 2, Color(red: 0.25, green: 0.36, blue: 0.28)),
        ("2025", 18, 4, Color(red: 0.52, green: 0.65, blue: 0.70)),
        ("2024", 12, 3, Color(red: 0.66, green: 0.62, blue: 0.54)),
        ("2023", 9, 1, Color(red: 0.55, green: 0.45, blue: 0.44))
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // 经典精装大书双列封面网格
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
                    spacing: 24
                ) {
                    ForEach(sampleYears, id: \.year) { item in
                        NavigationLink {
                            YearDetailView(year: item.year)
                        } label: {
                            HardcoverAnnualBookCard(
                                year: item.year,
                                color: item.color
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("年度相册")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarVisibility(.hidden, for: .tabBar)
        .hideTabBarOnRealDevice()
        .background(
            LinearGradient(
                colors: [Color(red: 0.98, green: 0.97, blue: 0.95), Color(red: 0.95, green: 0.94, blue: 0.91)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

// MARK: - 某一年份的照片记忆放映机：YearDetailView
private struct YearDetailView: View {
    let year: String

    var body: some View {
        Color(.systemBackground)
            .ignoresSafeArea()
        .navigationTitle(year)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarVisibility(.hidden, for: .tabBar)
        .hideTabBarOnRealDevice()
    }
}

// MARK: - 📖 典藏级精装特刊大书封面 (1:1 还原 Coffee Table Book 物理质感)
private struct HardcoverAnnualBookCard: View {
    let year: String
    let color: Color

    var body: some View {
        ZStack(alignment: .leading) {
            // 1. 硬皮织物/麻布特种纸精装底板
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(color)

            HardcoverLinenTexture()

            VStack(spacing: 8) {
                Text(year)
                    .font(.custom("AvenirNext-DemiBold", fixedSize: 22))
                    .foregroundStyle(Color.black.opacity(0.78))
                    .frame(height: 24)

                Image("HomeSingle01")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 76, height: 60)
                    .scaleEffect(1.45)
                    .clipped()
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 9)
            .background(Color(red: 0.95, green: 0.94, blue: 0.91))
            .overlay {
                Rectangle()
                    .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.13), radius: 3, x: 0, y: 2)
            .padding(.leading, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HardcoverBookSpine()
                .frame(width: 13)
        }
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 0.6)
        )
        .shadow(color: .black.opacity(0.18), radius: 10, x: 5, y: 6)
        .shadow(color: .black.opacity(0.08), radius: 3, x: 2, y: 2)
    }
}

private struct HardcoverLinenTexture: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 1.65
            var lightThreads = Path()
            var darkThreads = Path()
            var offset = -size.height

            while offset <= size.width {
                lightThreads.move(to: CGPoint(x: offset, y: 0))
                lightThreads.addLine(to: CGPoint(x: offset + size.height, y: size.height))

                darkThreads.move(to: CGPoint(x: offset + size.height, y: 0))
                darkThreads.addLine(to: CGPoint(x: offset, y: size.height))
                offset += spacing
            }

            context.stroke(
                darkThreads,
                with: .color(Color.black.opacity(0.13)),
                lineWidth: 0.34
            )
            context.stroke(
                lightThreads,
                with: .color(Color.white.opacity(0.18)),
                lineWidth: 0.34
            )
        }
        .allowsHitTesting(false)
    }
}

private struct HardcoverBookSpine: View {
    private let faceWidth: CGFloat = 6.5

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                HardcoverSpineFace()
                    .fill(Color.black.opacity(0.055))
                    .frame(width: faceWidth, height: proxy.size.height)

                Path { path in
                    path.move(to: CGPoint(x: 0, y: 4))
                    path.addLine(to: CGPoint(x: faceWidth, y: 0))
                    path.addLine(to: CGPoint(x: faceWidth, y: 3.5))
                    path.addLine(to: CGPoint(x: 1, y: 7))
                    path.closeSubpath()
                }
                .fill(Color.white.opacity(0.13))

                Path { path in
                    let height = proxy.size.height
                    path.move(to: CGPoint(x: 0, y: height - 4))
                    path.addLine(to: CGPoint(x: faceWidth, y: height))
                    path.addLine(to: CGPoint(x: faceWidth, y: height - 3.5))
                    path.addLine(to: CGPoint(x: 1, y: height - 7))
                    path.closeSubpath()
                }
                .fill(Color.black.opacity(0.08))

                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.16),
                        Color.white.opacity(0.12),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 3.5)
                .offset(x: faceWidth - 0.5)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct HardcoverSpineFace: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + 4))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - 4))
        path.closeSubpath()
        return path
    }
}


// MARK: - 精致编辑部杂志画报主故事详情页 (StoryDetailView - Magazine Editorial)
struct StoryDetailView: View {
    let title: String
    var coverImage: UIImage? = nil
    @ObservedObject private var dataManager = StoryDataManager.shared
    @State private var isShowingNewEntry = false

    private var allPhotos: [UIImage] {
        dataManager.entries.flatMap { $0.images }
    }

    private var formattedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy . MM . dd"
        return formatter.string(from: Date())
    }

    var body: some View {
        StoryDetailMagazineView(
            title: title,
            dateString: formattedDateString,
            coverImage: coverImage,
            photos: allPhotos,
            entries: dataManager.entries
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingNewEntry = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbarVisibility(.hidden, for: .tabBar)
        .hideTabBarOnRealDevice()
        .sheet(isPresented: $isShowingNewEntry) {
            NewDiaryEntrySheet { entry in
                dataManager.addEntry(entry)
            }
        }
    }
}

// MARK: - 📖 杂志画报主视图 (Magazine Editorial Journal View)
private struct StoryDetailMagazineView: View {
    let title: String
    let dateString: String
    let coverImage: UIImage?
    let photos: [UIImage]
    let entries: [StoryDiaryEntry]

    @State private var carouselIndex = 0
    private let timer = Timer.publish(every: 3.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // 1. 顶部封面/轮播画报 (优先展示上传照片轮播 > 封面照片 > 极简卡片)
                ZStack {
                    if !photos.isEmpty {
                        ForEach(photos.indices, id: \.self) { index in
                            if index == carouselIndex {
                                Image(uiImage: photos[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 280)
                                    .clipped()
                                    .transition(.opacity)
                            }
                        }
                    } else if let cover = coverImage {
                        Image(uiImage: cover)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 280)
                            .clipped()
                    } else {
                        // 极简特刊底框 (不带任何模糊假图片)
                        ZStack {
                            LinearGradient(
                                colors: [Color(red: 0.94, green: 0.93, blue: 0.90), Color(red: 0.88, green: 0.86, blue: 0.82)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )

                            VStack(spacing: 8) {
                                Text("栖光 · 典藏刊")
                                    .font(.system(size: 11, weight: .bold, design: .serif))
                                    .foregroundStyle(Color(red: 0.55, green: 0.50, blue: 0.45))
                                    .tracking(3)

                                Text(title)
                                    .font(.system(size: 22, weight: .bold, design: .serif))
                                    .foregroundStyle(Color(red: 0.25, green: 0.22, blue: 0.20))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 240)
                    }
                }
                .frame(height: photos.isEmpty && coverImage == nil ? 240 : 280)
                .onReceive(timer) { _ in
                    if !photos.isEmpty {
                        withAnimation(.easeInOut(duration: 1.2)) {
                            carouselIndex = (carouselIndex + 1) % photos.count
                        }
                    }
                }

                // 2. 居中标题与时间 Header
                VStack(alignment: .center, spacing: 8) {
                    Text(title)
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundStyle(.primary)

                    Text(dateString)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)
                .padding(.bottom, 20)

                // 3. 故事流 (只渲染真实数据，零假图占位)
                if !entries.isEmpty {
                    LazyVStack(spacing: 28) {
                        ForEach(entries) { entry in
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(entry.images.indices, id: \.self) { imgIdx in
                                    Image(uiImage: entry.images[imgIdx])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 300)
                                        .clipped()
                                }

                                if !entry.text.isEmpty {
                                    Text(entry.text)
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundStyle(Color(red: 0.22, green: 0.20, blue: 0.18))
                                        .lineSpacing(6)
                                        .padding(20)
                                        .background(Color(red: 0.98, green: 0.96, blue: 0.89))
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 40)
                } else {
                    // 无假图卡片，干净留白，等待用户真实上传
                    VStack(spacing: 12) {
                        Text("轻触右上角 「+」 记录第一个故事")
                            .font(.system(size: 13, weight: .medium, design: .serif))
                            .foregroundStyle(Color.secondary.opacity(0.7))
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 60)
                }
            }
            .padding(.top, 10)
        }
        .background(Color(.systemBackground))
    }
}

private struct PolaroidCardPlaceholder: View {
    let title: String
    let caption: String
    let rotateDegree: Double

    var body: some View {
        VStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.88, green: 0.90, blue: 0.92))
                .frame(height: 260)
                .overlay(
                    VStack(spacing: 6) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 32))
                        Text(title)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                )

            HStack {
                Text(caption)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(Color(red: 0.30, green: 0.25, blue: 0.22))

                Spacer()

                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(red: 0.70, green: 0.50, blue: 0.35))
            }
            .padding(.horizontal, 6)
        }
        .padding(16)
        .padding(.bottom, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
        .rotationEffect(.degrees(rotateDegree))
    }
}

private struct PolaroidCardItem: View {
    let image: UIImage
    let caption: String
    let rotateDegree: Double

    var body: some View {
        VStack(spacing: 14) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 4))

            HStack {
                Text(caption)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(Color(red: 0.30, green: 0.25, blue: 0.22))

                Spacer()

                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(red: 0.70, green: 0.50, blue: 0.35))
            }
            .padding(.horizontal, 6)
        }
        .padding(16)
        .padding(.bottom, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
        .rotationEffect(.degrees(rotateDegree))
    }
}

// MARK: - 主题 3：🖼️ 极简画廊风 (Gallery Exhibition)
private struct StoryDetailGalleryView: View {
    let title: String
    let dateString: String
    let photos: [UIImage]
    let entries: [StoryDiaryEntry]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // 画廊展厅 Header
                VStack(spacing: 6) {
                    Text("EXHIBITION · 极简画廊")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(3)

                    Text(title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.primary)

                    Text(dateString)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, 64)

                // 2 列画廊瀑布流网格
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 16) {
                    if !photos.isEmpty {
                        ForEach(photos.indices, id: \.self) { idx in
                            VStack(alignment: .leading, spacing: 6) {
                                Image(uiImage: photos[idx])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: idx % 2 == 0 ? 190 : 230)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                Text("NO. 0\(idx + 1)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    } else {
                        // 浅色画廊样板占位
                        GalleryItemPlaceholder(height: 210, title: "展品 01")
                        GalleryItemPlaceholder(height: 170, title: "展品 02")
                        GalleryItemPlaceholder(height: 180, title: "展品 03")
                        GalleryItemPlaceholder(height: 220, title: "展品 04")
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemBackground))
    }
}

private struct GalleryItemPlaceholder: View {
    let height: CGFloat
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemGray6))
                .frame(height: height)
                .overlay(
                    VStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                        Text(title)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                )

            Text("EXHIBITION PLACEHOLDER")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - 主题 4：⏳ 时光时间轴风 (Timeline River)
private struct StoryDetailTimelineView: View {
    let title: String
    let dateString: String
    let photos: [UIImage]
    let entries: [StoryDiaryEntry]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // 时间轴 Header
                VStack(spacing: 6) {
                    Text("TIMELINE · 时光长河")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(red: 0.35, green: 0.55, blue: 0.75))
                        .tracking(2.5)

                    Text(title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.primary)

                    Text(dateString)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 64)

                // 垂直时间轴节点列表
                VStack(spacing: 0) {
                    if !entries.isEmpty {
                        ForEach(entries.indices, id: \.self) { idx in
                            TimelineCardNode(entry: entries[idx], isLast: idx == entries.count - 1)
                        }
                    } else {
                        // 浅色时间轴样板试看
                        TimelinePlaceholderNode(nodeDate: "2026.08.05", nodeText: "时光时间轴样板 01 · 记录点滴瞬间", isLast: false)
                        TimelinePlaceholderNode(nodeDate: "2026.07.20", nodeText: "时光时间轴样板 02 · 阳光与海浪的声音", isLast: true)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color(red: 0.97, green: 0.97, blue: 0.98))
    }
}

private struct TimelinePlaceholderNode: View {
    let nodeDate: String
    let nodeText: String
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 左侧时间轴节点线
            VStack(spacing: 0) {
                Circle()
                    .fill(Color(red: 0.35, green: 0.55, blue: 0.75))
                    .frame(width: 12, height: 12)

                if !isLast {
                    Rectangle()
                        .fill(Color(red: 0.35, green: 0.55, blue: 0.75).opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .padding(.top, 6)

            // 右侧照片与内容卡片
            VStack(alignment: .leading, spacing: 10) {
                Text(nodeDate)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(red: 0.35, green: 0.55, blue: 0.75))

                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .frame(height: 180)
                    .overlay(
                        VStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 28))
                            Text(nodeText)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(.secondary)
                    )

                Text("在时间轴里查看每一刻的照片记录。")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.primary)
            }
            .padding(.bottom, 28)
        }
    }
}

private struct TimelineCardNode: View {
    let entry: StoryDiaryEntry
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 左侧时间轴节点线
            VStack(spacing: 0) {
                Circle()
                    .fill(Color(red: 0.35, green: 0.55, blue: 0.75))
                    .frame(width: 12, height: 12)

                if !isLast {
                    Rectangle()
                        .fill(Color(red: 0.35, green: 0.55, blue: 0.75).opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .padding(.top, 6)

            // 右侧照片与内容卡片
            VStack(alignment: .leading, spacing: 10) {
                Text(entry.date, style: .date)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(red: 0.35, green: 0.55, blue: 0.75))

                if let img = entry.images.first {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                if !entry.text.isEmpty {
                    Text(entry.text)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                }
            }
            .padding(.bottom, 28)
        }
    }
}

private struct NewDiaryEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var entryDate = Date()
    @State private var note = ""
    @State private var selectedImages: [UIImage] = []
    @FocusState private var isNoteFocused: Bool
    let onSave: (StoryDiaryEntry) -> Void

    private var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !selectedImages.isEmpty || !trimmedNote.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    DatePicker("日期", selection: $entryDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .font(.system(size: 18, weight: .semibold))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("照片")
                            .font(.system(size: 18, weight: .semibold))

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                            ForEach(selectedImages.indices, id: \.self) { index in
                                Image(uiImage: selectedImages[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 112)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .clipped()
                            }

                            Button {
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 25, weight: .regular))

                                    Text("照片稍后添加")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 112)
                                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("文案")
                            .font(.system(size: 18, weight: .semibold))

                        TextEditor(text: $note)
                            .font(.system(size: 18, weight: .regular))
                            .focused($isNoteFocused)
                            .frame(minHeight: 180)
                            .padding(12)
                            .scrollContentBackground(.hidden)
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(alignment: .topLeading) {
                                if note.isEmpty {
                                    Text("写下这一刻的故事")
                                        .font(.system(size: 18, weight: .regular))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 17)
                                        .padding(.vertical, 20)
                                        .allowsHitTesting(false)
                                }
                            }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)
                .padding(.bottom, 34)
            }
            .navigationTitle("新照片日记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundStyle(.primary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        guard canSave else { return }
                        onSave(StoryDiaryEntry(date: entryDate, text: trimmedNote, images: selectedImages))
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(canSave ? .primary : .secondary)
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - 主题 5：📸 暗房胶片风 (Editorial 35mm Darkroom - 双色明亮纸质美学)
private struct StoryDetailDarkroomView: View {
    let title: String
    let dateString: String
    let photos: [UIImage]
    let entries: [StoryDiaryEntry]

    var body: some View {
        ZStack {
            // 典雅明亮暖白/米纸底色 (极高阅读舒感，清爽看图)
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.95, blue: 0.92),
                    Color(red: 0.93, green: 0.91, blue: 0.87)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                // 1. 中央 35mm 暗房标头 Header (经典暗房朱红 + 深色衬线)
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.aperture")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(red: 0.72, green: 0.22, blue: 0.18))

                        Text("DARKROOM 35MM · KODAK PORTRA")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(red: 0.72, green: 0.22, blue: 0.18))
                            .tracking(2)
                    }

                    Text(title.isEmpty ? "暗房胶片" : title)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(Color(red: 0.18, green: 0.16, blue: 0.15))

                    Text(dateString)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(red: 0.45, green: 0.40, blue: 0.38))
                }
                .padding(.top, 14)

                // 2. 暖色复古暗房展板容器
                VStack(alignment: .leading, spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            // 3 列一排的 35mm 明亮相纸带边框底片
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)
                            ], spacing: 12) {
                                if !photos.isEmpty {
                                    ForEach(photos.indices, id: \.self) { idx in
                                        FilmCardTileItem(image: photos[idx], index: idx + 1)
                                    }
                                } else {
                                    FilmCardTilePlaceholder(title: "EXP 01", index: 1)
                                    FilmCardTilePlaceholder(title: "EXP 02", index: 2)
                                    FilmCardTilePlaceholder(title: "EXP 03", index: 3)
                                }
                            }

                            // 故事文字条目
                            if !entries.isEmpty {
                                VStack(spacing: 12) {
                                    ForEach(entries) { entry in
                                        if !entry.text.isEmpty {
                                            VStack(alignment: .leading, spacing: 6) {
                                                HStack {
                                                    Text("NOTE")
                                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                        .foregroundStyle(Color(red: 0.72, green: 0.22, blue: 0.18))
                                                    Spacer()
                                                }
                                                Text(entry.text)
                                                    .font(.system(size: 14, weight: .regular))
                                                    .foregroundStyle(Color(red: 0.22, green: 0.20, blue: 0.18))
                                                    .lineSpacing(5)
                                            }
                                            .padding(16)
                                            .background(Color.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .stroke(Color(red: 0.72, green: 0.22, blue: 0.18).opacity(0.2), lineWidth: 1)
                                            )
                                            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 60)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.98, green: 0.97, blue: 0.95))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color(red: 0.72, green: 0.22, blue: 0.18).opacity(0.15), lineWidth: 1)
                )
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
        }
        .tint(Color(red: 0.18, green: 0.16, blue: 0.15))
    }
}

private struct FilmCardTilePlaceholder: View {
    let title: String
    let index: Int

    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.90, green: 0.92, blue: 0.94))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    VStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.system(size: 18))
                        Text(title)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(Color(red: 0.5, green: 0.45, blue: 0.42))
                )

            HStack {
                Text("#0\(index)")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.72, green: 0.22, blue: 0.18))
                Spacer()
                Text("35MM")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.72, green: 0.22, blue: 0.18).opacity(0.8))
            }
            .padding(.horizontal, 2)
        }
        .padding(6)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

private struct FilmCardTileItem: View {
    let image: UIImage
    let index: Int

    var body: some View {
        VStack(spacing: 6) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .aspectRatio(1, contentMode: .fit)
                .clipped()

            HStack {
                Text("#0\(index)")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.72, green: 0.22, blue: 0.18))
                Spacer()
                Text("35MM")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.72, green: 0.22, blue: 0.18).opacity(0.8))
            }
            .padding(.horizontal, 2)
        }
        .padding(6)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}


struct ProfileView: View {
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
        }
    }
}

#Preview {
    ContentView()
}

extension View {
    func hideTabBarOnRealDevice() -> some View {
        self
            .toolbar(.hidden, for: .tabBar)
            .toolbarVisibility(.hidden, for: .tabBar)
            .onAppear {
                UITabBar.setTabBarHiddenOnDevice(true)
            }
            .onDisappear {
                UITabBar.setTabBarHiddenOnDevice(false)
            }
    }
}

fileprivate extension UITabBar {
    static func setTabBarHiddenOnDevice(_ hidden: Bool) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
        findTabBarController(in: rootVC)?.tabBar.isHidden = hidden
    }

    private static func findTabBarController(in vc: UIViewController?) -> UITabBarController? {
        if let tabBarVC = vc as? UITabBarController {
            return tabBarVC
        }
        for child in vc?.children ?? [] {
            if let found = findTabBarController(in: child) {
                return found
            }
        }
        return nil
    }
}
