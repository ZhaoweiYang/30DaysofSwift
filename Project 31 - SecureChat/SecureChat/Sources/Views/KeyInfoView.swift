import SwiftUI
import CryptoKit

/// Shows encryption key info for a conversation and allows key exchange
struct KeyInfoView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    let contactID: String
    @State private var copiedKey = false

    var contact: Contact? {
        appState.contacts.first(where: { $0.id == contactID })
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Lock icon
                ZStack {
                    Circle()
                        .fill(contact?.conversationKeyBase64 != nil ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: contact?.conversationKeyBase64 != nil ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 36))
                        .foregroundColor(contact?.conversationKeyBase64 != nil ? .green : .orange)
                }
                .padding(.top, 24)

                Text("加密信息")
                    .font(.system(size: 22, weight: .bold))

                if let keyBase64 = contact?.conversationKeyBase64,
                   let key = CryptoService.importKey(keyBase64) {
                    // Key exists
                    VStack(spacing: 16) {
                        InfoCard(title: "加密状态", value: "已建立", color: .green)
                        InfoCard(title: "加密算法", value: "AES-256-GCM", color: .primary)
                        InfoCard(title: "密钥指纹", value: CryptoService.keyFingerprint(key), color: .primary)
                    }
                    .padding(.horizontal, 24)

                    // Share key section
                    VStack(spacing: 12) {
                        Text("分享密钥给对方")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)

                        Text("将此密钥安全地发送给 \(contact?.displayName ?? "对方")，\n对方输入后即可解密您发送的消息。")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button(action: {
                            UIPasteboard.general.string = keyBase64
                            copiedKey = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copiedKey = false
                            }
                        }) {
                            HStack {
                                Image(systemName: copiedKey ? "checkmark" : "doc.on.doc")
                                Text(copiedKey ? "已复制" : "复制密钥")
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color(hex: "#4A90D9"))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 8)
                } else {
                    // No key
                    VStack(spacing: 12) {
                        Text("尚未建立加密连接")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)

                        Text("您需要获取对方的加密密钥，\n或者生成一个新密钥并分享给对方。")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button(action: generateNewKey) {
                            HStack {
                                Image(systemName: "key.fill")
                                Text("生成新密钥")
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color(hex: "#4A90D9"))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal, 24)
                    }
                }

                Spacer()

                // Explanation
                VStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("加密流程说明")
                        .font(.system(size: 13, weight: .medium))
                    Text("发送方用密钥在本地加密消息 → 平台转发加密数据 → 接收方用相同密钥在本地解密")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
            .navigationTitle("加密详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func generateNewKey() {
        let key = CryptoService.generateConversationKey()
        let keyBase64 = CryptoService.exportKey(key)
        appState.updateContactKey(contactID: contactID, keyBase64: keyBase64)
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
