//
//  ContentView.swift
//  栖光
//
//  Created by zhixin on 2026/7/6.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house")
                }

            MemoriesView()
                .tabItem {
                    Label("回忆", systemImage: "clock")
                }

            StoriesView()
                .tabItem {
                    Label("故事", systemImage: "book.closed")
                }

            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.circle")
                }
        }
    }
}

private struct HomeView: View {
    var body: some View {
        NavigationStack {
            Text("首页")
                .foregroundStyle(.secondary)
                .navigationTitle("首页")
        }
    }
}

private struct MemoriesView: View {
    var body: some View {
        NavigationStack {
            Text("回忆")
                .foregroundStyle(.secondary)
                .navigationTitle("回忆")
        }
    }
}

private struct StoriesView: View {
    @State private var isShowingNewCollection = false
    @State private var collectionTitle: String?

    var body: some View {
        NavigationStack {
            Group {
                if let collectionTitle {
                    StoryCollectionView(title: collectionTitle)
                } else {
                    VStack(spacing: 26) {
                        StoryEmptyIcon()

                        VStack(spacing: 10) {
                            Text("创建你的第一个故事")
                                .font(.system(size: 25, weight: .semibold))
                                .foregroundStyle(.primary)

                            Text("把照片串成一段时光")
                                .font(.system(size: 19, weight: .regular))
                                .foregroundStyle(.secondary)
                        }

                        Button {
                            isShowingNewCollection = true
                        } label: {
                            Text("开始创作")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 168, height: 56)
                                .background(Color(.systemGray6), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 32)
                }
            }
        }
        .sheet(isPresented: $isShowingNewCollection) {
            NewCollectionSheet { title in
                collectionTitle = title
            }
        }
    }
}

private struct NewCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var collectionName = ""
    @FocusState private var isNameFocused: Bool
    let onCreate: (String) -> Void

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
                Text("新收藏集")
                    .font(.system(size: 22, weight: .semibold))

                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .regular))
                            .foregroundStyle(.primary)
                            .frame(width: 58, height: 58)
                            .background(Color(.systemGray6), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)

            TextField("收藏集名称", text: $collectionName)
                .font(.system(size: 42, weight: .regular))
                .foregroundStyle(.primary)
                .tint(.primary)
                .multilineTextAlignment(.center)
                .focused($isNameFocused)
                .padding(.horizontal, 34)
                .frame(maxWidth: .infinity)
                .frame(height: 260)

            Button {
                guard !trimmedName.isEmpty else { return }
                onCreate(trimmedName)
                dismiss()
            } label: {
                Text("创建收藏集")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(trimmedName.isEmpty ? Color(.systemGray4) : .primary, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(trimmedName.isEmpty)
            .padding(.horizontal, 32)
            .padding(.top, 26)

            Spacer(minLength: 0)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(36)
        .onAppear {
            isNameFocused = true
        }
    }
}

private struct StoryCollectionView: View {
    let title: String

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 150), spacing: 18)],
                spacing: 24
            ) {
                NavigationLink {
                    StoryDetailView(title: title)
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        StoryCoverView()
                            .aspectRatio(1, contentMode: .fit)

                        Text(title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.top, 28)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct StoryCoverView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color(.systemGray6))
    }
}

private struct StoryDetailView: View {
    let title: String
    @State private var isShowingNewEntry = false
    @State private var entries: [StoryDiaryEntry] = []

    private var photoCount: Int {
        entries.reduce(0) { $0 + $1.images.count }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 38, weight: .regular))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text("2026年  \(photoCount)  张照片")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 24)
            .padding(.top, 24)

            if !entries.isEmpty {
                VStack(spacing: 0) {
                    Color(.separator)
                        .opacity(0.22)
                        .frame(height: 0.5)

                    Color(red: 0.985, green: 0.985, blue: 0.98)
                        .frame(height: 12)
                }
                .padding(.top, 24)

                LazyVStack(spacing: 22) {
                    ForEach(entries) { entry in
                        StoryDiaryCard(entry: entry)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingNewEntry = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.primary)
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $isShowingNewEntry) {
            NewDiaryEntrySheet { entry in
                entries.insert(entry, at: 0)
            }
        }
    }
}

private struct StoryDiaryEntry: Identifiable {
    let id = UUID()
    let date: Date
    let text: String
    let images: [UIImage]
}

private struct NewDiaryEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var entryDate = Date()
    @State private var note = ""
    @State private var selectedItems: [PhotosPickerItem] = []
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

                            PhotosPicker(selection: $selectedItems, maxSelectionCount: 9, matching: .images) {
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 25, weight: .regular))

                                    Text("添加照片")
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
        .onChange(of: selectedItems) { _, newItems in
            Task {
                var images: [UIImage] = []

                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        images.append(image)
                    }
                }

                selectedImages = images
            }
        }
    }
}

private struct StoryDiaryCard: View {
    let entry: StoryDiaryEntry

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: entry.date)
    }

    private var noteText: String {
        entry.text.isEmpty ? "这一天的照片" : entry.text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            if !entry.images.isEmpty {
                StoryDiaryPhotoLayout(images: entry.images)
                    .frame(maxWidth: .infinity)
            }

            VStack(alignment: .leading, spacing: 9) {
                Text(noteText)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.primary)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(dateText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(.systemGray3))
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
    }
}

private struct StoryDiaryPhotoLayout: View {
    let images: [UIImage]

    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.width * 0.625

            if images.count == 1, let image = images.first {
                StoryDiaryImage(image: image)
                    .frame(width: proxy.size.width, height: height)
            } else {
                HStack(spacing: 0) {
                    ForEach(Array(images.prefix(2).enumerated()), id: \.offset) { _, image in
                        StoryDiaryImage(image: image)
                            .frame(width: proxy.size.width / 2, height: height)
                    }
                }
            }
        }
        .aspectRatio(1.6, contentMode: .fit)
    }
}

private struct StoryDiaryImage: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .clipped()
    }
}

private struct StoryEmptyIcon: View {
    private let columns = [
        GridItem(.fixed(46), spacing: 4),
        GridItem(.fixed(46), spacing: 4)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            iconTile(.blue.opacity(0.75))
            iconTile(.cyan.opacity(0.65))
            iconTile(.indigo.opacity(0.55))
            iconTile(.teal.opacity(0.7))
        }
        .frame(width: 96, height: 96)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func iconTile(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.95), color.opacity(0.55)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 46, height: 46)
    }
}

private struct ProfileView: View {
    var body: some View {
        NavigationStack {
            Text("我的")
                .foregroundStyle(.secondary)
                .navigationTitle("我的")
        }
    }
}

#Preview {
    ContentView()
}
