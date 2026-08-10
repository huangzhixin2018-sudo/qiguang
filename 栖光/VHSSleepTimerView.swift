import SwiftUI
import Combine

struct VHSSleepTimerView: View {
    @State private var currentTime = Date()
    @State private var isEjected = false
    @State private var showPolaroid = false
    @Environment(\.dismiss) private var dismiss
    
    // For glitch effect animation
    @State private var glitchOffset: CGFloat = 0
    @State private var chromaticAberration: CGFloat = 0
    
    // Timer to update the current time
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var archiveDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: Date())
    }
    
    // Define the time thresholds
    // Using Calendar to easily manipulate components for demonstration/logic
    // For a real app, this compares against actual local time.
    private var tapeStatus: TapeStatus {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        
        if hour >= 4 && hour < 23 {
            return .safe // Day time until 11 PM
        } else if hour == 23 {
            return .warning // 11 PM to 12 AM
        } else {
            return .danger // 12 AM to 4 AM
        }
    }
    
    enum TapeStatus {
        case safe
        case warning
        case danger
        
        var message: String {
            switch self {
            case .safe: return "[ 恢复区 / RECOVERY ]\n发量保护机制已激活，适宜立刻闭眼。"
            case .warning: return "[ 临界区 / WARNING ]\n头发与尊严的拉锯战，建议火速撤退。"
            case .danger: return "[ 修仙区 / GLITCH ]\n赛博飞升中...生命体征正逐渐转化为乱码。"
            }
        }
        
        var accentColor: Color {
            switch self {
            case .safe: return Color(red: 0.31, green: 0.41, blue: 0.32) // #4E6851 Vintage Green
            case .warning: return Color(red: 0.85, green: 0.55, blue: 0.2) // Retro Orange
            case .danger: return Color(red: 0.72, green: 0.23, blue: 0.18) // #B83A2D Brick Red
            }
        }
        
        var rotationSpeed: Double {
            switch self {
            case .safe: return 4.0
            case .warning: return 2.0
            case .danger: return 0.5 // Fast, frantic
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background (American Retro Sand/Beige)
            Color(red: 0.86, green: 0.79, blue: 0.66) // #DCC9A9
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 24) {
                Spacer()
                    .frame(height: 40)
                
                // Tape and Card Group
                VStack(spacing: -2) {
                    // VHS Tape Visual
                    VHSTapeGraphic(status: tapeStatus, isEjected: isEjected)
                        .frame(height: 180)
                        .padding(.horizontal, 12) // Make tape very wide and grand
                        // Glitch and Chromatic Aberration applied to the main visual
                        .offset(x: tapeStatus == .danger ? glitchOffset : 0)
                        .shadow(color: tapeStatus == .danger ? .red.opacity(0.8) : .clear, radius: 0, x: chromaticAberration, y: 0)
                        .shadow(color: tapeStatus == .danger ? .blue.opacity(0.8) : .clear, radius: 0, x: -chromaticAberration, y: 0)
                        .zIndex(2)
                    
                    ZStack(alignment: .top) {
                        // Memory Time Card (Film Strip Style)
                        MemoryTimeCard(currentTime: currentTime, status: tapeStatus)
                            .padding(.top, 4) // Nudge down so it slips under the slit cleanly
                            .padding(.horizontal, 24) // Wide card, slightly narrower than slit
                            .zIndex(0)
                        
                        // The Spit-out Slot Front (Top Lip + Dark Slit)
                        VStack(spacing: 0) {
                            // Top lip
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(Color(white: 0.15))
                                .frame(width: 362, height: 6)
                            // Dark slit
                            Rectangle()
                                .fill(Color.black.opacity(0.95))
                                .frame(width: 358, height: 4)
                                // Inner shadow to create depth in the slit, casting onto the card
                                .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 3)
                        }
                        .zIndex(1) // Slot is above the card
                    }
                    .zIndex(1)
                }
                
                // Zone Cards
                HStack(spacing: 12) {
                    ZoneCardView(
                        days: 12,
                        title: "恢复区",
                        timeRange: "<23h",
                        isSelected: tapeStatus == .safe,
                        selectedColor: TapeStatus.safe.accentColor
                    )
                    
                    ZoneCardView(
                        days: 5,
                        title: "临界区",
                        timeRange: "23h-00h",
                        isSelected: tapeStatus == .warning,
                        selectedColor: TapeStatus.warning.accentColor
                    )
                    
                    ZoneCardView(
                        days: 2,
                        title: "修仙区",
                        timeRange: ">00h",
                        isSelected: tapeStatus == .danger,
                        selectedColor: TapeStatus.danger.accentColor
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer(minLength: 20)
                
                // Destination Subway Map (Option 1)
                JourneyMapView(currentStage: 3, targetCity: "REYKJAVIK")
                    .drawingGroup() // Optimize rendering for complex paths and shadows
                
                Spacer(minLength: 20)
                
                // Energy Stairway (Option 2)
                EnergyStairwayView(currentLevel: 3)
                    .drawingGroup() // Flatten into a single layer to fix scroll lag
                
                Spacer(minLength: 20)
                
                // Energy Lore Card
                EnergyLoreCardView(currentLevel: 3)
                
                Spacer(minLength: 40)
                
                // Option 2 removed, we keep Energy Stairway as the primary component
                
                // Button temporarily removed per user request
                }
            }
            
            // Noise/Glitch Overlay
            if tapeStatus == .danger {
                NoiseOverlay()
                    .opacity(0.15)
                    .allowsHitTesting(false)
            }
            
            // Polaroid Spit-out Overlay
            if showPolaroid {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        dismiss() // tap background to close
                    }
                
                MemoryPolaroidCard(
                    dateString: archiveDate,
                    timeString: timeFormatter.string(from: currentTime),
                    status: tapeStatus
                ) {
                    dismiss() // tap card to close
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .hideTabBarOnRealDevice()
        .onReceive(timer) { time in
            currentTime = time
            if tapeStatus == .danger {
                triggerGlitch()
            }
        }
        // Allows forcing status for preview/testing by setting specific dates
        // Uncomment to test danger mode:
        // .onAppear {
        //     currentTime = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: Date()) ?? Date()
        // }
    }
    
    private func triggerGlitch() {
        // Random glitch effect every second when in danger
        withAnimation(.interactiveSpring(response: 0.1, dampingFraction: 0.1)) {
            glitchOffset = CGFloat.random(in: -10...10)
            chromaticAberration = CGFloat.random(in: 3...8)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                glitchOffset = 0
                chromaticAberration = 0
            }
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
}

// Visual representation of a VHS tape
private struct VHSTapeGraphic: View {
    let status: VHSSleepTimerView.TapeStatus
    let isEjected: Bool
    
    @State private var rotation: Double = 0
    
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            
            ZStack {
                // Tape Shell
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    )
                
                // Top Label Area
                RoundedRectangle(cornerRadius: 4)
                    .fill(status.accentColor.opacity(0.2))
                    .frame(height: height * 0.25)
                    .overlay(
                        Text("记忆磁带")
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .frame(maxHeight: .infinity, alignment: .top)
                
                // Clear Window
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.15))
                    .frame(height: height * 0.45)
                    .padding(.horizontal, 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            .padding(.horizontal, 40)
                    )
                
                // The Reels
                HStack(spacing: 0) {
                    // Left Reel (Supply)
                    TapeReel(
                        status: status,
                        size: reelSize(for: status, isLeft: true),
                        rotation: rotation
                    )
                    .frame(width: width / 2)
                    
                    // Right Reel (Take-up)
                    TapeReel(
                        status: status,
                        size: reelSize(for: status, isLeft: false),
                        rotation: rotation
                    )
                    .frame(width: width / 2)
                }
                .frame(height: height * 0.45)
                
                // Labels below the clear window
                HStack(spacing: 0) {
                    Text("熬夜8天")
                        .font(.system(size: 16, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color(red: 0.86, green: 0.79, blue: 0.66)) // Full opacity for clarity
                        .shadow(color: .black, radius: 1, x: 0, y: 1)
                        .frame(width: width / 2)
                    
                    Text("早睡3天")
                        .font(.system(size: 16, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color(red: 0.86, green: 0.79, blue: 0.66))
                        .shadow(color: .black, radius: 1, x: 0, y: 1)
                        .frame(width: width / 2)
                }
                .offset(y: (height * 0.45) / 2 + 24) // Moved down slightly
            }
            .offset(y: isEjected ? -300 : 0) // Eject animation
            .opacity(isEjected ? 0 : 1)
            .onAppear {
                startRotation()
            }
            .onChange(of: status) { _, _ in
                // Restart rotation with new speed when status changes
                startRotation()
            }
        }
    }
    
    private func startRotation() {
        withAnimation(.linear(duration: status.rotationSpeed).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }
    
    // Calculates reel size based on status (time of day)
    private func reelSize(for status: VHSSleepTimerView.TapeStatus, isLeft: Bool) -> CGFloat {
        let baseSize: CGFloat = 80
        switch status {
        case .safe:
            return isLeft ? baseSize * 0.8 : baseSize * 0.3
        case .warning:
            return isLeft ? baseSize * 0.4 : baseSize * 0.7
        case .danger:
            return isLeft ? baseSize * 0.1 : baseSize * 0.95 // Almost empty on left
        }
    }
}

private struct TapeReel: View {
    let status: VHSSleepTimerView.TapeStatus
    let size: CGFloat
    let rotation: Double
    
    var body: some View {
        ZStack {
            // Tape wound on the reel
            Circle()
                .fill(Color(red: 0.8, green: 0.6, blue: 0.1)) // Amber/Yellow magnetic tape
                .frame(width: max(40, size), height: max(40, size))
            
            // White hub gear
            Circle()
                .stroke(Color.white.opacity(0.8), lineWidth: 4)
                .frame(width: 32, height: 32)
            
            // Hub spokes
            ForEach(0..<6) { i in
                Rectangle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 4, height: 12)
                    .offset(y: -10)
                    .rotationEffect(.degrees(Double(i) * 60))
            }
        }
        .rotationEffect(.degrees(rotation))
    }
}

// Basic noise overlay for glitch effect
private struct NoiseOverlay: View {
    // Generate a static noise pattern once or use a timeline view for animated noise
    // For simplicity and performance, we'll draw many tiny semitransparent dots
    var body: some View {
        Canvas { context, size in
            for _ in 0..<500 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let rect = CGRect(x: x, y: y, width: 2, height: 2)
                context.fill(Path(rect), with: .color(.white))
            }
        }
    }
}

// The Polaroid Card View
private struct MemoryPolaroidCard: View {
    let dateString: String
    let timeString: String
    let status: VHSSleepTimerView.TapeStatus
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Photo Area
            ZStack {
                // Background gradient based on status
                LinearGradient(
                    colors: [
                        status == .danger ? .red.opacity(0.8) : Color(red: 0.15, green: 0.25, blue: 0.35),
                        status == .danger ? .black : Color(red: 0.4, green: 0.5, blue: 0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                if status == .danger {
                    NoiseOverlay().opacity(0.4)
                }
                
                Image(systemName: status == .safe ? "moon.stars.fill" : (status == .warning ? "exclamationmark.triangle.fill" : "xmark.octagon.fill"))
                    .font(.system(size: 64))
                    .foregroundColor(.white.opacity(status == .danger ? 0.9 : 0.7))
                    // Subtle float effect
                    .offset(y: status == .danger ? CGFloat.random(in: -5...5) : 0)
            }
            .frame(height: 320)
            .clipped()
            
            // Text Area
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .bottom) {
                    Text(dateString)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.black.opacity(0.8))
                    Spacer()
                    Text(timeString)
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .foregroundColor(.black)
                }
                
                let zoneName = status == .safe ? "[ 恢复区 ]" : (status == .warning ? "[ 临界区 ]" : "[ 修仙区 ]")
                Text(zoneName)
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(status == .danger ? .red : .primary)
                
                Text(status.message.replacingOccurrences(of: "\n", with: " "))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black.opacity(0.6))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer(minLength: 0)
                
                // Instructions
                Text("点击任意区域收起")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.black.opacity(0.3))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(24)
            .frame(height: 160)
            .background(Color(white: 0.96)) // Polaroid paper color
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 20)
        .padding(.horizontal, 36)
        .onTapGesture {
            action()
        }
    }
}

// 3-column Card View
private struct ZoneCardView: View {
    let days: Int
    let title: String
    let timeRange: String
    let isSelected: Bool
    let selectedColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(days)天")
                .font(.system(size: 14, weight: .bold))
            .foregroundColor(isSelected ? Color(white: 0.15) : selectedColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(white: 0.15) : selectedColor, lineWidth: 2)
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSelected ? Color(white: 0.15) : .white)
                Text(timeRange)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(isSelected ? Color(white: 0.15).opacity(0.6) : .white.opacity(0.6))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isSelected ? Color.white : Color(white: 0.1))
        )
        // subtle shadow if selected
        .shadow(color: isSelected ? .white.opacity(0.3) : .clear, radius: 10, x: 0, y: 4)
    }
}

// Memory Time Card (White Polaroid Style)
private struct MemoryTimeCard: View {
    let currentTime: Date
    let status: VHSSleepTimerView.TapeStatus
    
    var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: currentTime)
    }
    
    var badgeText: String {
        switch status {
        case .safe: return "早睡"
        case .warning: return "临界"
        case .danger: return "修仙"
        }
    }
    
    var badgeTextColor: Color {
        return status.accentColor
    }
    
    var emoji: String {
        switch status {
        case .safe: return "😌"
        case .warning: return "🥱"
        case .danger: return "🤯"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // The Inner Content Area (White)
            VStack(spacing: 32) {
                // Header
                HStack {
                    Text(dateString)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                    
                    Spacer()
                    
                    Text(badgeText)
                        .font(.system(size: 15, weight: .bold)) // Larger badge font
                        .foregroundColor(badgeTextColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(status.accentColor.opacity(0.15), in: Capsule())
                }
                
                // Big Time
                HStack(spacing: 8) {
                    Text(timeFormatter.string(from: currentTime))
                        .font(.system(size: 72, weight: .semibold, design: .monospaced))
                        .kerning(1.5) // Adds elegance and design sense
                        .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                }
                
                // Timeline progress (Custom)
                GeometryReader { geo in
                    let width = geo.size.width
                    VStack(spacing: 12) {
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(white: 0.9))
                                .frame(height: 8)
                            
                            // Fake progress calculation
                            let hour = Calendar.current.component(.hour, from: currentTime)
                            let currentMin = Calendar.current.component(.minute, from: currentTime)
                            let totalMins = (hour < 12 ? hour + 24 : hour) * 60 + currentMin
                            let startMins = 22 * 60 + 30 // 22:30
                            let endMins = 23 * 60 + 45   // 23:45
                            let progress = max(0.0, Swift.min(1.0, CGFloat(totalMins - startMins) / CGFloat(endMins - startMins)))
                            
                            Capsule()
                                .fill(status.accentColor)
                                .frame(width: max(0, width * progress), height: 8)
                            
                            // Indicator line
                            Rectangle()
                                .fill(Color(red: 0.72, green: 0.23, blue: 0.18)) // Retro Red indicator
                                .frame(width: 2, height: 16)
                                .offset(x: max(0, width * progress))
                        }
                        
                        HStack {
                            Text("22:30")
                            Spacer()
                            Text("23:00")
                            Spacer()
                            Text("23:45")
                        }
                        .font(.system(size: 14, weight: .bold)) // Slightly larger timeline text
                        .foregroundColor(Color(red: 0.31, green: 0.41, blue: 0.32)) // Retro Green
                    }
                }
                .frame(height: 36)
            }
            .padding(.vertical, 28)
            .padding(.horizontal, 20)
            .background(Color(red: 0.96, green: 0.95, blue: 0.92)) // Inner warm cream card
            .cornerRadius(4) // slight inner rounding
            // The black borders: left, right, top padding
            .padding(.top, 16)
            .padding(.horizontal, 16)
            
            // The thick bottom border
            Text("风吹过的夏天，记忆在光影里发芽")
                .font(.system(size: 15, weight: .bold)) // Larger poetic text
                .foregroundColor(Color(red: 0.86, green: 0.79, blue: 0.66)) // Sand color text
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(Color(red: 0.31, green: 0.41, blue: 0.32)) // #4E6851 Vintage Green frame
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Enhanced Journey Map View
struct JourneyMapView: View {
    let currentStage: Int // 1 to 5
    let targetCity: String
    
    // Stages and their required days
    let stages: [(name: String, days: Int)] = [
        ("荒野", 1),
        ("迷雾", 3),
        ("霓虹", 7),
        ("极光", 14),
        ("抵达", 21)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .bottom) {
                Text("DESTINATION / 目的地")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(white: 0.5))
                Spacer()
                Text(targetCity)
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundColor(Color(red: 0.86, green: 0.79, blue: 0.66))
                    .kerning(2)
            }
            
            // Subway Line
            VStack(spacing: 0) {
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color(white: 0.25))
                        .frame(height: 3)
                    
                    // Active track
                    GeometryReader { geo in
                        let progress = CGFloat(max(0, currentStage - 1)) / CGFloat(stages.count - 1)
                        Rectangle()
                            .fill(Color(red: 0.86, green: 0.79, blue: 0.66))
                            .frame(width: geo.size.width * progress, height: 3)
                            .shadow(color: Color(red: 0.86, green: 0.79, blue: 0.66).opacity(0.8), radius: 4, x: 0, y: 0)
                    }
                }
                .padding(.horizontal, 12) // align with centers of circles
                .offset(y: 8) // push down into the circles
                .zIndex(0)
                
                HStack {
                    ForEach(0..<stages.count, id: \.self) { index in
                        let stage = stages[index]
                        let isReached = index < currentStage
                        
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(white: 0.12)) // background to match container
                                    .frame(width: 16, height: 16)
                                
                                Circle()
                                    .stroke(isReached ? Color(red: 0.86, green: 0.79, blue: 0.66) : Color(white: 0.3), lineWidth: 3)
                                    .frame(width: 16, height: 16)
                                
                                if isReached {
                                    Circle()
                                        .fill(Color(red: 0.86, green: 0.79, blue: 0.66))
                                        .frame(width: 6, height: 6)
                                }
                            }
                            
                            VStack(spacing: 4) {
                                Text(stage.name)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(isReached ? .white : Color(white: 0.4))
                                
                                // Days target
                                Text("\(stage.days)D")
                                    .font(.system(size: 14, weight: .black, design: .monospaced))
                                    .foregroundColor(isReached ? Color(red: 0.86, green: 0.79, blue: 0.66) : Color(white: 0.4))
                            }
                        }
                        if index < stages.count - 1 {
                            Spacer()
                        }
                    }
                }
                .zIndex(1)
            }
        }
        .padding(20)
        .background(Color(white: 0.12))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Energy Stairway View (2D Wireframe Concept)
struct EnergyStairwayView: View {
    let currentLevel: Int // 0 to 4 (0 is worst/lowest, 4 is best/highest)
    
    // Ordered from bottom-left (worst) to top-right (best)
    let levels: [(name: String, range: String, days: String)] = [
        ("虚无", "02后", "0D"),
        ("过载", "01-02", "1D"),
        ("消耗", "00-01", "3D"),
        ("平稳", "23-00", "7D"),
        ("源力", "22-23", "21D")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            VStack(alignment: .leading, spacing: 8) {
                Text("ENERGY STAIRWAY / 能量阶梯")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(white: 0.5))
                
                let energyValues = [24, 58, 96, 132, 185]
                let energyValue = energyValues[currentLevel]
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(energyValue)")
                        .font(.system(size: 42, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color(red: 0.86, green: 0.79, blue: 0.66))
                    Text("EP")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(white: 0.4))
                }
            }
            
            let w: CGFloat = 65
            let h: CGFloat = 40
            
            ZStack {
                ForEach(0..<levels.count, id: \.self) { i in
                    let isLit = (i == currentLevel)
                    let strokeColor = Color(white: 0.15)
                    let litBgColor = Color(white: 0.15)
                    let litTextColor = Color(red: 0.86, green: 0.79, blue: 0.66) // Sand color
                    
                    VStack(spacing: 6) {
                        // Days label floating above the box
                        Text(levels[i].days)
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(isLit ? litTextColor : Color(white: 0.3))
                        
                        // The Box
                        VStack(spacing: 2) {
                            Text(levels[i].name)
                                .font(.system(size: 13, weight: isLit ? .bold : .regular))
                            Text(levels[i].range)
                                .font(.system(size: 10, weight: isLit ? .bold : .regular, design: .monospaced))
                        }
                        .foregroundColor(isLit ? litTextColor : strokeColor)
                        .frame(width: w, height: h)
                        .background(isLit ? litBgColor : Color.clear)
                        .overlay(
                            Rectangle()
                                .stroke(strokeColor, lineWidth: 1.5)
                        )
                    }
                    // Offset up and right to form a staircase
                    .offset(x: CGFloat(i) * w, y: CGFloat(-i) * h)
                }
            }
            // Group centers at (2w, -2h), so we offset backwards to visually center it in the frame
            .offset(x: -w * 2, y: h * 2)
            .frame(height: h * 5 + 30)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 80) // Push stairs down to prevent overlapping the text above
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 20)
    }
}

// MARK: - Energy Lore Card View
struct EnergyLoreCardView: View {
    let currentLevel: Int
    
    var body: some View {
        let lore: [(title: String, desc: String)] = [
            ("虚无 (02后) / THE VOID", "时间的黑洞，光芒无法到达的深渊废墟。在这个深度熬夜区，机体的自我修复机制已完全停摆，只剩下疲惫的回音。"),
            ("过载 (01-02) / OVERLOAD", "高危红线区。时间重力剧增，身体被迫开启超频模式。在这个区间保持清醒，意味着你在疯狂透支未来的光源储备。"),
            ("消耗 (00-01) / DEPLETING", "能量池出现不可逆的裂缝。就像老旧磁带在空转中被物理磨损，你正以双倍的速度消耗着精神的备用电池。"),
            ("平稳 (23-00) / STABLE", "能量收支的完美守恒点。机体平稳进入低功耗休眠，虽然没有源力区的丰沛，但能保证明天系统运转的一丝不苟。"),
            ("源力 (22-23) / ORIGIN", "光子最活跃的绝对静谧时刻。在这里入睡，你的意识将直接捕获时间源力，重塑核心生命值。这是最奢侈的自我奖赏。")
        ]
        
        let currentLore = lore[currentLevel]
        
        VStack(alignment: .leading, spacing: 12) {
            Text(currentLore.title)
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .foregroundColor(Color(red: 0.86, green: 0.79, blue: 0.66))
            
            Text(currentLore.desc)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color(white: 0.6))
                .lineSpacing(6)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.12))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}
