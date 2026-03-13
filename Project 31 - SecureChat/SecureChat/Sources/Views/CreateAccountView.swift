import SwiftUI

/// Account creation screen using mnemonic phrase (like a crypto wallet)
struct CreateAccountView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var mnemonic = ""
    @State private var displayName = ""
    @State private var step: CreateStep = .generate
    @State private var mnemonicWords: [String] = []
    @State private var confirmed = false
    @State private var copiedToClipboard = false

    enum CreateStep {
        case generate
        case backup
        case setName
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Step indicator
                HStack(spacing: 8) {
                    StepDot(active: true, label: "生成")
                    StepLine(active: step != .generate)
                    StepDot(active: step == .backup || step == .setName, label: "备份")
                    StepLine(active: step == .setName)
                    StepDot(active: step == .setName, label: "命名")
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                .padding(.bottom, 32)

                switch step {
                case .generate:
                    generateStepView
                case .backup:
                    backupStepView
                case .setName:
                    setNameStepView
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("创建账户")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear {
                mnemonic = MnemonicGenerator.generate()
                mnemonicWords = mnemonic.split(separator: " ").map(String.init)
            }
        }
    }

    // MARK: - Step 1: Generate
    var generateStepView: some View {
        VStack(spacing: 20) {
            Image(systemName: "key.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "#4A90D9"))

            Text("您的助记词")
                .font(.system(size: 22, weight: .bold))

            Text("以下12个词是您的账户密钥。\n请务必安全保存，丢失后无法找回。")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Mnemonic grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 10) {
                ForEach(Array(mnemonicWords.enumerated()), id: \.offset) { index, word in
                    HStack(spacing: 4) {
                        Text("\(index + 1)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .frame(width: 18, alignment: .trailing)
                        Text(word)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 24)

            // Copy button
            Button(action: {
                UIPasteboard.general.string = mnemonic
                copiedToClipboard = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    copiedToClipboard = false
                }
            }) {
                HStack {
                    Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                    Text(copiedToClipboard ? "已复制" : "复制助记词")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#4A90D9"))
            }
            .padding(.top, 4)

            Spacer()

            Button(action: { step = .backup }) {
                Text("下一步")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(hex: "#4A90D9"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Step 2: Backup Confirmation
    var backupStepView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("确认备份")
                .font(.system(size: 22, weight: .bold))

            Text("请确认您已安全保存助记词。\n这是恢复账户的唯一方式。")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 12) {
                WarningRow(text: "助记词是您账户的唯一凭证")
                WarningRow(text: "请勿截图或在线存储助记词")
                WarningRow(text: "建议手写在纸上并妥善保管")
                WarningRow(text: "任何人获得助记词即可控制账户")
            }
            .padding(20)
            .background(Color.orange.opacity(0.08))
            .cornerRadius(12)
            .padding(.horizontal, 24)

            Toggle(isOn: $confirmed) {
                Text("我已安全保存助记词")
                    .font(.system(size: 15))
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)

            Spacer()

            HStack(spacing: 12) {
                Button(action: { step = .generate }) {
                    Text("返回")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Color(hex: "#4A90D9"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "#4A90D9").opacity(0.1))
                        .cornerRadius(12)
                }

                Button(action: { step = .setName }) {
                    Text("下一步")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(confirmed ? Color(hex: "#4A90D9") : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!confirmed)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Step 3: Set Display Name
    var setNameStepView: some View {
        VStack(spacing: 20) {
            // Avatar preview
            let derivedName = displayName.isEmpty ? MnemonicGenerator.deriveDisplayName(from: mnemonic) : displayName
            ZStack {
                Circle()
                    .fill(Color(hex: "#4A90D9"))
                    .frame(width: 80, height: 80)
                Text(String(derivedName.prefix(1)))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }

            Text("设置昵称")
                .font(.system(size: 22, weight: .bold))

            Text("给自己取一个昵称吧")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            TextField("输入昵称（留空使用默认）", text: $displayName)
                .textFieldStyle(.plain)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 32)

            // User ID preview
            let userID = MnemonicGenerator.deriveUserID(from: mnemonic)
            HStack {
                Text("您的ID:")
                    .foregroundColor(.secondary)
                Text(userID)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.primary)
            }
            .font(.system(size: 13))

            Spacer()

            Button(action: {
                let name = displayName.isEmpty ? nil : displayName
                appState.createAccount(with: mnemonic, displayName: name)
                appState.addDemoContacts()
                dismiss()
            }) {
                Text("完成创建")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(hex: "#4A90D9"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

struct WarningRow: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundColor(.orange)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.primary)
        }
    }
}

struct StepDot: View {
    let active: Bool
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(active ? Color(hex: "#4A90D9") : Color(.systemGray4))
                .frame(width: 10, height: 10)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(active ? Color(hex: "#4A90D9") : .secondary)
        }
    }
}

struct StepLine: View {
    let active: Bool
    var body: some View {
        Rectangle()
            .fill(active ? Color(hex: "#4A90D9") : Color(.systemGray4))
            .frame(height: 2)
            .offset(y: -6)
    }
}
