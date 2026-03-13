import SwiftUI

/// Welcome / onboarding screen with options to create or restore an account
struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showCreateAccount = false
    @State private var showRestoreAccount = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Spacer()

                // Logo
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#4A90D9"), Color(hex: "#357ABD")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 24)

                Text("SecureChat")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)

                Text("端到端加密通讯")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)

                Spacer()

                // Feature highlights
                VStack(spacing: 16) {
                    FeatureRow(icon: "key.fill", title: "助记词账户", subtitle: "无需手机号或邮箱，用助记词创建身份")
                    FeatureRow(icon: "lock.fill", title: "本地加密", subtitle: "消息在发送前在本地加密，平台无法读取")
                    FeatureRow(icon: "arrow.triangle.2.circlepath", title: "密钥交换", subtitle: "与联系人共享密钥，实现安全通信")
                }
                .padding(.horizontal, 32)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: { showCreateAccount = true }) {
                        Text("创建新账户")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(hex: "#4A90D9"))
                            .cornerRadius(12)
                    }

                    Button(action: { showRestoreAccount = true }) {
                        Text("恢复已有账户")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(hex: "#4A90D9"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(hex: "#4A90D9").opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .sheet(isPresented: $showCreateAccount) {
                CreateAccountView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showRestoreAccount) {
                RestoreAccountView()
                    .environmentObject(appState)
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(Color(hex: "#4A90D9"))
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}
