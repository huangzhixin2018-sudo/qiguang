import SwiftUI
import UIKit

struct StoryDetailBookView: View {
    let title: String
    let dateString: String
    let photos: [UIImage]
    let entries: [StoryDiaryEntry]
    
    @State private var currentPageIndex: Int = 0
    
    var body: some View {
        ZStack {
            // Book background texture
            Color(red: 0.94, green: 0.93, blue: 0.91) // Muted off-white paper color
                .ignoresSafeArea()
            
            let pages = buildPages()
            
            if pages.isEmpty {
                VStack {
                    Text("暂无故事")
                        .font(.system(size: 20, weight: .medium, design: .serif))
                        .foregroundColor(.gray)
                    Text("翻开相册，写下第一页")
                        .font(.system(size: 14, design: .serif))
                        .foregroundColor(Color.gray.opacity(0.7))
                        .padding(.top, 4)
                }
            } else {
                PageCurlController(
                    pages: pages,
                    currentIndex: $currentPageIndex,
                    viewForPage: { page in
                        BookPageView(page: page, title: title, dateString: dateString)
                    }
                )
                .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func buildPages() -> [BookPageModel] {
        var pages: [BookPageModel] = []
        // Cover
        pages.append(BookPageModel(index: 0, entry: nil))
        
        // Entries
        for (i, entry) in entries.enumerated() {
            pages.append(BookPageModel(index: i + 1, entry: entry))
        }
        return pages
    }
}

struct BookPageModel: Identifiable, Equatable {
    let id = UUID()
    let index: Int
    let entry: StoryDiaryEntry?
    
    static func == (lhs: BookPageModel, rhs: BookPageModel) -> Bool {
        lhs.id == rhs.id
    }
}

struct BookPageView: View {
    let page: BookPageModel
    let title: String
    let dateString: String
    
    var body: some View {
        ZStack {
            // Paper background for each page
            Color(red: 0.98, green: 0.97, blue: 0.95)
            
            // Subtle paper texture / gradient on the spine side (left side)
            HStack(spacing: 0) {
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.08), Color.black.opacity(0.02), Color.clear]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 30)
                Spacer()
            }
            
            if let entry = page.entry {
                // Entry Page
                VStack(spacing: 24) {
                    if let firstImage = entry.images.first {
                        Image(uiImage: firstImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 380)
                            .clipped()
                            .padding(12)
                            .background(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
                            .padding(.horizontal, 20)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(entry.date, style: .date)
                            .font(.system(size: 13, weight: .bold, design: .serif))
                            .foregroundColor(Color(red: 0.60, green: 0.45, blue: 0.30))
                        
                        Text(entry.text)
                            .font(.system(size: 15, design: .serif))
                            .foregroundColor(Color(white: 0.2))
                            .lineSpacing(8)
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                    
                    Text("- \(page.index) -")
                        .font(.system(size: 12, design: .serif))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 24)
                }
                .padding(.top, 40)
            } else {
                // Cover Page
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Ornamental graphic
                    Image(systemName: "book.closed")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(Color(red: 0.60, green: 0.45, blue: 0.30))
                    
                    Text(title)
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(Color(white: 0.15))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    Rectangle()
                        .frame(width: 60, height: 1.5)
                        .foregroundColor(Color(red: 0.60, green: 0.45, blue: 0.30).opacity(0.5))
                    
                    Text(dateString)
                        .font(.system(size: 14, design: .serif))
                        .foregroundColor(Color(white: 0.4))
                        .padding(.top, 8)
                    
                    Spacer()
                    
                    Text("COLLECTION")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(6)
                        .foregroundColor(Color(white: 0.6))
                        .padding(.bottom, 48)
                }
            }
        }
    }
}

// MARK: - PageCurlController

struct PageCurlController<Page: Identifiable & Equatable, Content: View>: UIViewControllerRepresentable {
    let pages: [Page]
    @Binding var currentIndex: Int
    let viewForPage: (Page) -> Content
    
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: [UIPageViewController.OptionsKey.spineLocation: UIPageViewController.SpineLocation.min.rawValue]
        )
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator
        pageViewController.view.backgroundColor = .clear
        
        return pageViewController
    }
    
    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        context.coordinator.parent = self
        
        guard !pages.isEmpty else { return }
        
        let isForward = currentIndex >= context.coordinator.lastIndex
        context.coordinator.lastIndex = currentIndex
        
        // Only set view controllers if the current visible one doesn't match the new index
        let currentVisibles = uiViewController.viewControllers as? [UIHostingController<Content>]
        if let currentVC = currentVisibles?.first,
           let currentTag = currentVC.view.tag as Int?,
           currentTag == currentIndex {
            return
        }
        
        let hostingVC = UIHostingController(rootView: viewForPage(pages[currentIndex]))
        hostingVC.view.backgroundColor = .clear
        hostingVC.view.tag = currentIndex
        
        uiViewController.setViewControllers(
            [hostingVC],
            direction: isForward ? .forward : .reverse,
            animated: true,
            completion: nil
        )
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PageCurlController
        var lastIndex: Int = 0
        
        init(_ parent: PageCurlController) {
            self.parent = parent
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let index = viewController.view.tag as Int? else { return nil }
            if index == 0 { return nil }
            
            let newIndex = index - 1
            let hostingVC = UIHostingController(rootView: parent.viewForPage(parent.pages[newIndex]))
            hostingVC.view.backgroundColor = .clear
            hostingVC.view.tag = newIndex
            return hostingVC
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let index = viewController.view.tag as Int? else { return nil }
            if index == parent.pages.count - 1 { return nil }
            
            let newIndex = index + 1
            let hostingVC = UIHostingController(rootView: parent.viewForPage(parent.pages[newIndex]))
            hostingVC.view.backgroundColor = .clear
            hostingVC.view.tag = newIndex
            return hostingVC
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            if completed,
               let visibleVC = pageViewController.viewControllers?.first,
               let index = visibleVC.view.tag as Int? {
                parent.currentIndex = index
                lastIndex = index
            }
        }
    }
}
