//
//  AnnualLatestPhotoStore.swift
//  栖光
//

import SwiftUI
import Combine
import Photos

private struct LatestYearAsset: Sendable {
    let year: String
    let localIdentifier: String
}

@MainActor
final class AnnualLatestPhotoStore: ObservableObject {
    @Published private(set) var imagesByYear: [String: UIImage] = [:]
    @Published private(set) var availableYears: [String] = []

    private let imageManager = PHCachingImageManager()
    private var didStartLoading = false

    func loadAvailableYears() async {
        guard !didStartLoading else { return }
        didStartLoading = true

        let status = await photoAuthorizationStatus()
        guard status == .authorized || status == .limited else { return }

        await Task.yield()
        let latestAssets = await Self.discoverLatestAssetsByYear()

        for item in latestAssets {
            requestThumbnail(for: item)
        }
    }

    private func requestThumbnail(for item: LatestYearAsset) {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [item.localIdentifier], options: nil)
        guard let asset = result.firstObject else { return }

        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.resizeMode = .exact
        requestOptions.isNetworkAccessAllowed = true

        imageManager.requestImage(
            for: asset,
            targetSize: CGSize(width: 480, height: 480),
            contentMode: .aspectFill,
            options: requestOptions
        ) { [weak self] image, info in
            guard let image,
                  (info?[PHImageCancelledKey] as? Bool) != true,
                  info?[PHImageErrorKey] == nil else {
                return
            }

            Task { @MainActor in
                guard let self else { return }
                self.imagesByYear[item.year] = image

                if !self.availableYears.contains(item.year) {
                    self.availableYears.append(item.year)
                    self.availableYears.sort { (Int($0) ?? 0) > (Int($1) ?? 0) }
                }
            }
        }
    }

    nonisolated private static func discoverLatestAssetsByYear() async -> [LatestYearAsset] {
        await Task.detached(priority: .userInitiated) {
            let boundsOptions = PHFetchOptions()
            boundsOptions.predicate = NSPredicate(format: "creationDate != nil")
            boundsOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

            let allAssets = PHAsset.fetchAssets(with: .image, options: boundsOptions)
            guard let newestDate = allAssets.firstObject?.creationDate,
                  let oldestDate = allAssets.lastObject?.creationDate else {
                return []
            }

            let calendar = Calendar.current
            let newestYear = calendar.component(.year, from: newestDate)
            let oldestYear = calendar.component(.year, from: oldestDate)
            guard newestYear >= oldestYear else { return [] }

            var results: [LatestYearAsset] = []

            for year in stride(from: newestYear, through: oldestYear, by: -1) {
                guard let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
                      let endDate = calendar.date(byAdding: .year, value: 1, to: startDate) else {
                    continue
                }

                let options = PHFetchOptions()
                options.predicate = NSPredicate(
                    format: "creationDate >= %@ AND creationDate < %@",
                    startDate as NSDate,
                    endDate as NSDate
                )
                options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                options.fetchLimit = 1

                if let asset = PHAsset.fetchAssets(with: .image, options: options).firstObject {
                    results.append(
                        LatestYearAsset(
                            year: String(year),
                            localIdentifier: asset.localIdentifier
                        )
                    )
                }
            }

            return results
        }.value
    }

    private func photoAuthorizationStatus() async -> PHAuthorizationStatus {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard currentStatus == .notDetermined else { return currentStatus }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status)
            }
        }
    }
}
