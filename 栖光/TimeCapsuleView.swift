//
//  TimeCapsuleView.swift
//  栖光
//
//  Created by zhixin on 2026/8/6.
//

import SwiftUI
import PhotosUI

struct TimeCapsuleView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotosPickerItem: PhotosPickerItem? = nil
    @State private var userImage: UIImage? = nil

    // 动画状态量
    @State private var isTorn: Bool = false // 是否已撕下日历
    @State private var tearOffset: CGSize = .zero
    @State private var tearAngle: Double = 0
    @State private var isEjecting: Bool = false // 拍立得吐纸中
    @State private var developProgress: CGFloat = 0.0 // 拍立得照片显影进度 (0.0 -> 1.0)
    @State private var yearsAgo: Int = 2 // 默认2年前

    var body: some View {
        ZStack {
            // 背景：复古桌布纹理 + 暖暗色系
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.13, blue: 0.16), Color(red: 0.07, green: 0.08, blue: 0.10)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶栏控制
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("📅 回忆日历")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)

                    Spacer()

                    PhotosPicker(selection: $selectedPhotosPickerItem, matching: .images) {
                        HStack(spacing: 4) {
                            Image(systemName: "photo.badge.plus")
                            Text("导入照片")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(red: 0.98, green: 0.82, blue: 0.10))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.12), in: Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // 顶部状态提示标语
                        VStack(spacing: 6) {
                            Text(isTorn ? "✨ 记忆已解封 · 显影中" : "撕开今天日历 · 打开岁月胶囊")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)

                            Text(isTorn ? "\(yearsAgo) 年前的今日记忆已定格" : "下滑或点击“撕下日历”开启拍立得仪式")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.top, 8)

                        // 核心展示区域：日历撕页 与 拍立得吐纸容器
                        ZStack(alignment: .top) {
                            // 1. 底层：拍立得吐纸相机与显影照片
                            VStack(spacing: 0) {
                                // 拍立得相机顶部出纸口
                                PolaroidCameraSlotHeader()

                                // 吐出的拍立得照片
                                if isEjecting || isTorn {
                                    PolaroidPhotoCard(
                                        userImage: userImage,
                                        yearsAgo: yearsAgo,
                                        developProgress: developProgress
                                    )
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                    .padding(.top, -10)
                                }
                            }

                            // 2. 顶层：复古撕页日历 (撕下前盖在最上面)
                            if !isTorn {
                                VintageCalendarTearPage(yearsAgo: yearsAgo)
                                    .offset(tearOffset)
                                    .rotationEffect(.degrees(tearAngle))
                                    .gesture(
                                        DragGesture()
                                            .onChanged { gesture in
                                                tearOffset = gesture.translation
                                                tearAngle = Double(gesture.translation.width / 15)
                                            }
                                            .onEnded { gesture in
                                                if gesture.translation.height > 80 || abs(gesture.translation.width) > 100 {
                                                    triggerTearAnimation()
                                                } else {
                                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                        tearOffset = .zero
                                                        tearAngle = 0
                                                    }
                                                }
                                            }
                                    )
                                    .onTapGesture {
                                        triggerTearAnimation()
                                    }
                            }
                        }
                        .frame(minHeight: 460)

                        // 3. 底部控制按键
                        HStack(spacing: 20) {
                            if !isTorn {
                                Button {
                                    triggerTearAnimation()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "scissors")
                                        Text("撕下日历解封")
                                    }
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Color(red: 0.15, green: 0.10, blue: 0.05))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(red: 0.98, green: 0.85, blue: 0.35), Color(red: 0.95, green: 0.72, blue: 0.15)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        in: Capsule()
                                    )
                                    .shadow(color: Color(red: 0.95, green: 0.72, blue: 0.15).opacity(0.4), radius: 10, x: 0, y: 5)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button {
                                    resetCalendar()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.counterclockwise")
                                        Text("重新封装胶囊")
                                    }
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.white.opacity(0.15), in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .hideTabBarOnRealDevice()
        .onChange(of: selectedPhotosPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.userImage = uiImage
                    }
                }
            }
        }
    }

    // 触发撕纸与拍立得吐纸全动画
    private func triggerTearAnimation() {
        withAnimation(.easeOut(duration: 0.4)) {
            tearOffset = CGSize(width: 120, height: 350)
            tearAngle = 25
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isTorn = true
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isEjecting = true
            }

            // 渐进化学显影动画 (0% -> 100%)
            developProgress = 0.0
            withAnimation(.easeInOut(duration: 2.2)) {
                developProgress = 1.0
            }
        }
    }

    private func resetCalendar() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isTorn = false
            isEjecting = false
            tearOffset = .zero
            tearAngle = 0
            developProgress = 0.0
            yearsAgo = [1, 2, 3, 5].randomElement() ?? 2
        }
    }
}

// MARK: - 复古撕页日历组件
private struct VintageCalendarTearPage: View {
    let yearsAgo: Int

    private var todayMonthDay: (month: String, day: String, weekday: String) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM月"
        let month = formatter.string(from: Date())
        formatter.dateFormat = "dd"
        let day = formatter.string(from: Date())
        formatter.dateFormat = "EEEE"
        let weekday = formatter.string(from: Date())
        return (month, day, weekday)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶线锯齿撕裂孔 (Perforated Line Header)
            HStack(spacing: 6) {
                ForEach(0..<16, id: \.self) { _ in
                    Circle()
                        .fill(Color(red: 0.15, green: 0.12, blue: 0.10))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.85, green: 0.25, blue: 0.20))

            // 日历主体
            VStack(spacing: 16) {
                HStack {
                    Text("\(yearsAgo) 年前的今天")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(red: 0.70, green: 0.20, blue: 0.15))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.98, green: 0.92, blue: 0.82), in: Capsule())

                    Spacer()

                    Text("农历七月初三")
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundStyle(Color.black.opacity(0.6))
                }

                VStack(spacing: 4) {
                    Text(todayMonthDay.month)
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundStyle(Color(red: 0.85, green: 0.25, blue: 0.20))

                    Text(todayMonthDay.day)
                        .font(.system(size: 96, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 0.15, green: 0.12, blue: 0.10))

                    Text(todayMonthDay.weekday)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.7))
                }

                Divider()
                    .background(Color.black.opacity(0.15))

                // 诗词 / 签语
                HStack(spacing: 6) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(red: 0.85, green: 0.25, blue: 0.20))

                    Text("风吹过的夏天，记忆在光影里发芽。")
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .foregroundStyle(Color.black.opacity(0.75))
                }
                .padding(.top, 4)
            }
            .padding(24)
            .background(Color(red: 0.97, green: 0.95, blue: 0.90))
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
        }
        .frame(width: 300)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 10)
    }
}

// MARK: - 拍立得相机出纸口 Header
private struct PolaroidCameraSlotHeader: View {
    var body: some View {
        VStack(spacing: 0) {
            // 金属相纸吐口
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.3, green: 0.3, blue: 0.35), Color(red: 0.15, green: 0.15, blue: 0.18)], startPoint: .top, endPoint: .bottom))
                .frame(width: 310, height: 16)
                .overlay(
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 280, height: 4)
                )

            Rectangle()
                .fill(Color.black.opacity(0.5))
                .frame(width: 290, height: 4)
        }
    }
}

// MARK: - 吐出的拍立得相纸组件 (含化学显影渐变)
private struct PolaroidPhotoCard: View {
    let userImage: UIImage?
    let yearsAgo: Int
    let developProgress: CGFloat // 0.0 -> 1.0 显影进度

    var body: some View {
        VStack(spacing: 0) {
            // 拍立得照片成像区
            ZStack {
                Color(red: 0.12, green: 0.12, blue: 0.14)

                if let userImage = userImage {
                    Image(uiImage: userImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 260, height: 260)
                        .clipped()
                        .opacity(developProgress) // 显影透明度渐变
                        .saturation(0.5 + (0.5 * developProgress)) // 色彩饱和度渐变
                } else {
                    // 预设拍立得风回忆照
                    ZStack {
                        LinearGradient(
                            colors: [Color(red: 0.40, green: 0.55, blue: 0.65), Color(red: 0.85, green: 0.65, blue: 0.50)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        VStack(spacing: 10) {
                            Image(systemName: "sun.haze.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.white.opacity(0.9))
                            Text("\(yearsAgo) 年前的今日旅途")
                                .font(.system(size: 16, weight: .bold, design: .serif))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 260, height: 260)
                    .opacity(developProgress)
                    .saturation(0.5 + (0.5 * developProgress))
                }

                // 未显影时的乳白色药膜层 (Polaroid Emulsion Layer)
                Color(red: 0.92, green: 0.90, blue: 0.85)
                    .opacity(1.0 - developProgress)
            }
            .frame(width: 260, height: 260)
            .border(Color.black.opacity(0.15), width: 1)
            .padding(.top, 16)
            .padding(.horizontal, 16)

            // 拍立得底部白色留白区与手写体标语
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("ON THIS DAY · \(yearsAgo) YEARS AGO")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.black.opacity(0.75))

                    Spacer()

                    Text("INSTAX 400")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.black.opacity(0.4))
                }

                Text("时光轻拭，记忆在白纸上开花。")
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundStyle(Color.black.opacity(0.7))
            }
            .padding(.top, 14)
            .padding(.bottom, 18)
            .padding(.horizontal, 20)
        }
        .frame(width: 292)
        .background(Color(red: 0.97, green: 0.96, blue: 0.93))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 8)
    }
}
