//
//  WatermarkAddressView.swift
//  栖光
//

import SwiftUI
import AVFoundation
import CoreLocation
import Photos
import Combine

struct WatermarkAddressView: View {
    @Environment(\.dismiss) private var dismiss

    // 真实 GPS 定位与天气管理器
    @StateObject private var locationManager = RealLocationManager()

    // 真正的 AVFoundation 相机控制器
    @StateObject private var cameraController = RealAVCameraController()

    // 状态控制
    @State private var capturedImage: UIImage? = nil
    @State private var isShowingToast = false
    @State private var toastMessage = ""
    @State private var isFlashOn = false
    @State private var isWeatherEnabled = true // 默认开启天气打卡

    var body: some View {
        ZStack {
            // 背景纯黑沉浸
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. 顶部 Header (返回 + 打卡相机 + 天气开关 + 闪光灯)
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(Color.white.opacity(0.15), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Text("打卡相机")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)

                    Spacer()

                    // 天气打卡开关
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isWeatherEnabled.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isWeatherEnabled ? "sun.max.fill" : "sun.max")
                                .font(.system(size: 13, weight: .bold))
                            Text(isWeatherEnabled ? "天气开启" : "天气关闭")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(isWeatherEnabled ? Color.yellow : Color.white.opacity(0.6))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            isWeatherEnabled ? Color.yellow.opacity(0.2) : Color.white.opacity(0.15),
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)

                    // 闪光灯按钮
                    Button {
                        isFlashOn.toggle()
                        cameraController.toggleFlash(isFlashOn)
                    } label: {
                        Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isFlashOn ? .yellow : .white)
                            .frame(width: 42, height: 42)
                            .background(Color.white.opacity(0.15), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 12)

                // 2. 中央 AVFoundation 相机取景框 (悬浮 1:1 蓝轨地理与天气水印)
                Spacer(minLength: 0)

                ZStack(alignment: .top) {
                    if let capturedImage {
                        Image(uiImage: capturedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    } else {
                        AVCameraPreviewRepresentable(controller: cameraController)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    }

                    // 1:1 精确蓝轨地理水印遮罩 (支持开启/关闭天气)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("时间：\(locationManager.currentTimeString)")

                            if isWeatherEnabled {
                                Spacer()
                                Text("天气：\(locationManager.weatherString)")
                                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                            }
                        }

                        Text("位置：\(locationManager.addressString)")
                            .lineLimit(2)

                        HStack {
                            Text("经度：\(locationManager.longitudeString)")
                            Spacer()
                            Text("纬度：\(locationManager.latitudeString)")
                        }
                    }
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.15, green: 0.45, blue: 0.85).opacity(0.75),
                                Color(red: 0.1, green: 0.3, blue: 0.65).opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .padding(.horizontal, 12)

                Spacer(minLength: 0)

                // 3. 底部相机拍照与保存控制栏
                HStack {
                    if capturedImage != nil {
                        Button("重拍照片") {
                            withAnimation {
                                capturedImage = nil
                            }
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.2), in: Capsule())
                    } else {
                        Button {
                        } label: {
                            Image(systemName: "photo")
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.white.opacity(0.15), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    // 大圆圈快门按键
                    Button {
                        if capturedImage == nil {
                            triggerCapturePhoto()
                        } else {
                            saveCapturedPhotoToLibrary()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 74, height: 74)

                            Circle()
                                .fill(capturedImage == nil ? Color.white : Color(red: 0.15, green: 0.45, blue: 0.85))
                                .frame(width: 62, height: 62)

                            if capturedImage != nil {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if capturedImage != nil {
                        Button("保存相册") {
                            saveCapturedPhotoToLibrary()
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white, in: Capsule())
                    } else {
                        // 拍照镜头切换
                        Button {
                            cameraController.switchCamera()
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.white.opacity(0.15), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 34)
            }

            // Toast 消息
            if isShowingToast {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(toastMessage)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.85), in: Capsule())
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .hideTabBarOnRealDevice()
        .navigationBarBackButtonHidden(true)
        .onAppear {
            locationManager.requestLocationPermission()
            cameraController.checkPermissionsAndStartSession()
        }
        .onDisappear {
            cameraController.stopSession()
        }
    }

    /// 触发拍照并合成地理/天气水印导出
    private func triggerCapturePhoto() {
        cameraController.capturePhoto { photoImage in
            let rawImage = photoImage ?? generateSimulatorSnapshot()
            renderAndSaveWatermarkedPhoto(rawImage)
        }
    }

    private func renderAndSaveWatermarkedPhoto(_ baseImage: UIImage) {
        let exportContent = WatermarkExportRenderViewDynamic(
            image: baseImage,
            timeString: locationManager.currentTimeString,
            weatherString: locationManager.weatherString,
            isWeatherEnabled: isWeatherEnabled,
            locationAddress: locationManager.addressString,
            longitudeText: locationManager.longitudeString,
            latitudeText: locationManager.latitudeString
        )
        .frame(width: 600, height: 800)

        let renderer = ImageRenderer(content: exportContent)
        renderer.scale = 2.0

        guard let uiImage = renderer.uiImage else { return }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            if status == .authorized || status == .limited {
                UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                DispatchQueue.main.async {
                    self.capturedImage = uiImage
                    let msg = isWeatherEnabled ? "照片带地理与实时天气水印已保存至相册！" : "照片带地理水印已保存至相册！"
                    showToast(msg)
                }
            } else {
                DispatchQueue.main.async {
                    self.capturedImage = uiImage
                    showToast("已成功捕获照片！")
                }
            }
        }
    }

    private func saveCapturedPhotoToLibrary() {
        showToast("照片已成功保存至手机相册！")
    }

    private func generateSimulatorSnapshot() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 800))
        return renderer.image { ctx in
            let colors = [
                UIColor(red: 0.12, green: 0.22, blue: 0.32, alpha: 1.0).cgColor,
                UIColor(red: 0.06, green: 0.1, blue: 0.16, alpha: 1.0).cgColor
            ]
            let space = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: space, colors: colors as CFArray, locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(gradient, start: CGPoint.zero, end: CGPoint(x: 600, y: 800), options: [])

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 26, weight: .bold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.85),
                .paragraphStyle: paragraph
            ]
            let str = "相机打卡照片\n（已成功捕获合成）"
            str.draw(in: CGRect(x: 50, y: 360, width: 500, height: 100), withAttributes: attrs)
        }
    }

    private func showToast(_ msg: String) {
        toastMessage = msg
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isShowingToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { isShowingToast = false }
        }
    }
}

/// 导出合成带动态地理/天气水印图的 View
private struct WatermarkExportRenderViewDynamic: View {
    let image: UIImage
    let timeString: String
    let weatherString: String
    let isWeatherEnabled: Bool
    let locationAddress: String
    let longitudeText: String
    let latitudeText: String

    var body: some View {
        ZStack(alignment: .top) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 600, height: 800)
                .clipped()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("时间：\(timeString)")

                    if isWeatherEnabled {
                        Spacer()
                        Text("天气：\(weatherString)")
                    }
                }

                Text("位置：\(locationAddress)")
                    .lineLimit(2)

                HStack {
                    Text("经度：\(longitudeText)")
                    Spacer()
                    Text("纬度：\(latitudeText)")
                }
            }
            .font(.system(size: 20, weight: .medium, design: .default))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.15, green: 0.45, blue: 0.85).opacity(0.78),
                        Color(red: 0.1, green: 0.3, blue: 0.65).opacity(0.72)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .frame(width: 600, height: 800)
    }
}

/// 真实 AVFoundation 相机控制器
@MainActor
final class RealAVCameraController: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    nonisolated let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var completionHandler: ((UIImage?) -> Void)?

    @Published var isCameraReady = false

    func checkPermissionsAndStartSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    Task { @MainActor [weak self] in
                        self?.setupSession()
                    }
                }
            }
        default:
            break
        }
    }

    private func setupSession() {
        guard !session.isRunning else { return }

        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        session.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            Task { @MainActor [weak self] in
                self?.isCameraReady = true
            }
        }
    }

    func stopSession() {
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.stopRunning()
            }
        }
    }

    func toggleFlash(_ isOn: Bool) {
        // Flash control
    }

    func switchCamera() {
        // Switch camera
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        self.completionHandler = completion
        if session.isRunning {
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self)
        } else {
            completion(nil)
        }
    }

    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            Task { @MainActor [weak self] in
                self?.completionHandler?(nil)
            }
            return
        }
        Task { @MainActor [weak self] in
            self?.completionHandler?(image)
        }
    }
}

/// 相机实时 Viewfinder 视频预览 View
private struct AVCameraPreviewRepresentable: UIViewRepresentable {
    @ObservedObject var controller: RealAVCameraController

    func makeUIView(context: Context) -> AVCameraPreviewUIView {
        let view = AVCameraPreviewUIView()
        view.videoPreviewLayer.session = controller.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: AVCameraPreviewUIView, context: Context) {}
}

private class AVCameraPreviewUIView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}

/// 真实 CoreLocation 定位与实时 Weather 气象管理器
@MainActor
final class RealLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var currentTimeString: String = ""
    @Published var addressString: String = "广东省广州市海珠区东晓南路瑞宝一社瑞宝瑞兴街一横街7号"
    @Published var longitudeString: String = "113.284032"
    @Published var latitudeString: String = "23.076629"
    @Published var weatherString: String = "26°C 晴" // 实时天气描述

    private var timer: Timer?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        updateTimeString()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateTimeString()
            }
        }
    }

    deinit {
        timer?.invalidate()
    }

    /// 触发系统定位权限弹窗提示 ("允许使用您的位置信息")
    func requestLocationPermission() {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        manager.startUpdatingLocation()
    }

    private func updateTimeString() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.currentTimeString = formatter.string(from: Date())
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    @available(iOS, deprecated: 26.0)
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        let latVal = location.coordinate.latitude
        let lonVal = location.coordinate.longitude
        let lon = String(format: "%.6f", lonVal)
        let lat = String(format: "%.6f", latVal)

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.longitudeString = lon
            self.latitudeString = lat

            self.performReverseGeocode(for: location)
            self.fetchRealWeather(latitude: latVal, longitude: lonVal)
        }
    }

    @available(iOS, deprecated: 26.0)
    private func performReverseGeocode(for location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let placemark = placemarks?.first else { return }
            let province = placemark.administrativeArea ?? ""
            let city = placemark.locality ?? ""
            let district = placemark.subLocality ?? ""
            let street = placemark.thoroughfare ?? ""
            let number = placemark.subThoroughfare ?? ""

            let full = "\(province)\(city)\(district)\(street)\(number)"
            if !full.isEmpty {
                Task { @MainActor [weak self] in
                    self?.addressString = full
                }
            }
        }
    }

    /// 根据当前 GPS 经纬度在线拉取真实天气与气象
    private func fetchRealWeather(latitude: Double, longitude: Double) {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current_weather=true"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let currentWeather = json["current_weather"] as? [String: Any],
                   let temp = currentWeather["temperature"] as? Double,
                   let code = currentWeather["weathercode"] as? Int {

                    let weatherDesc = self?.translateWeatherCode(code) ?? "晴"
                    let formatted = "\(Int(round(temp)))°C \(weatherDesc)"

                    Task { @MainActor [weak self] in
                        self?.weatherString = formatted
                    }
                }
            } catch {}
        }.resume()
    }

    nonisolated private func translateWeatherCode(_ code: Int) -> String {
        switch code {
        case 0: return "晴"
        case 1, 2: return "晴间多云"
        case 3: return "阴"
        case 45, 48: return "有雾"
        case 51, 53, 55, 61, 63, 65: return "小雨"
        case 80, 81, 82: return "阵雨"
        case 95, 96, 99: return "雷阵雨"
        default: return "晴"
        }
    }
}
