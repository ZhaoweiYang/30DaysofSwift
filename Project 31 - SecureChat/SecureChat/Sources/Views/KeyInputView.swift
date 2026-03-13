import SwiftUI

/// View for entering an encryption key received from a contact
struct KeyInputView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    let contactID: String
    @State private var keyInput = ""
    @State private var errorMessage = ""

    var contact: Contact? {
        appState.contacts.first(where: { $0.id == contactID })
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "key.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color(hex: "#4A90D9"))
                    .padding(.top, 32)

                Text("输入加密密钥")
                    .font(.system(size: 22, weight: .bold))

                Text("输入 \(contact?.displayName ?? "对方") 分享给您的加密密钥")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Key input
                TextEditor(text: $keyInput)
                    .font(.system(size: 13, design: .monospaced))
                    .frame(height: 80)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                }

                // Paste button
                Button(action: {
                    if let pasted = UIPasteboard.general.string {
                        keyInput = pasted.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }) {
                    HStack {
                        Image(systemName: "doc.on.clipboard")
                        Text("从剪贴板粘贴")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#4A90D9"))
                }

                Spacer()

                Button(action: importKey) {
                    Text("确认导入")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(keyInput.isEmpty ? Color.gray : Color(hex: "#4A90D9"))
                        .cornerRadius(12)
                }
                .disabled(keyInput.isEmpty)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationTitle("导入密钥")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    private func importKey() {
        let trimmed = keyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard CryptoService.importKey(trimmed) != nil else {
            errorMessage = "密钥格式无效，请检查后重试"
            return
        }
        appState.updateContactKey(contactID: contactID, keyBase64: trimmed)
        dismiss()
    }
}
