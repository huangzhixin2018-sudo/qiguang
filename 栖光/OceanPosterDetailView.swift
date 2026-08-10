//
//  OceanPosterDetailView.swift
//  栖光
//
//  Created by zhixin on 2026/8/10.
//

import SwiftUI

/// 模板空白详情页（仅保留返回按钮，页面留白待开发）
struct OceanPosterDetailView: View {
    @Environment(\.dismiss) private var dismiss
    var title: String = "单图排版模板"

    var body: some View {
        ZStack {
            // 极简纯白留白画板
            Color(red: 0.985, green: 0.985, blue: 0.975)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部 Navigation Header（仅保留返回按钮）
                HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .hideTabBarOnRealDevice()
    }
}

#Preview {
    OceanPosterDetailView()
}
