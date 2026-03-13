import SwiftUI

/// Restore an existing account using a mnemonic phrase
struct RestoreAccountView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var mnemonicInput = ""
    @State private var errorMessage = ""
    @State private var isValid = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color(hex: "#4A90D9"))
                    .padding(.top, 32)

                Text("恢复账户")
                    .font(.system(size: 22, weight: .bold))

                Text("输入您的12个助记词来恢复账户")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                // Mnemonic input
                TextEditor(text: $mnemonicInput)
                    .font(.system(size: 15, design: .monospaced))
                    .frame(height: 120)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    .onChange(of: mnemonicInput) { newValue in
                        let trimmed = newValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                        let words = trimmed.split(separator: " ")
                        isValid = words.count == 12
                        errorMessage = ""
                    }

                // Word count indicator
                let wordCount = mnemonicInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    .split(separator: " ").count
                Text("\(wordCount) / 12 个词")
                    .font(.system(size: 13))
                    .foregroundColor(wordCount == 12 ? .green : .secondary)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                }

                // Paste button
                Button(action: {
                    if let pasted = UIPasteboard.general.string {
                        mnemonicInput = pasted
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

                Button(action: restore) {
                    Text("恢复账户")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isValid ? Color(hex: "#4A90D9") : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isValid)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground))
            .navigationTitle("恢复账户")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    private func restore() {
        let trimmed = mnemonicInput.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.split(separator: " ").joined(separator: " ")

        if appState.restoreAccount(with: normalized) {
            appState.addDemoContacts()
            dismiss()
        } else {
            errorMessage = "助记词无效，请检查拼写"
        }
    }
}
