import SwiftUI

/// Add a new contact by entering their user ID
struct AddContactView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var contactID = ""
    @State private var displayName = ""
    @State private var keyBase64 = ""
    @State private var generateKey = true

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 48))
                    .foregroundColor(Color(hex: "#4A90D9"))
                    .padding(.top, 24)

                Text("添加联系人")
                    .font(.system(size: 22, weight: .bold))

                VStack(spacing: 16) {
                    // Contact ID
                    VStack(alignment: .leading, spacing: 6) {
                        Text("用户ID")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        TextField("输入对方的用户ID", text: $contactID)
                            .font(.system(size: 15, design: .monospaced))
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }

                    // Display Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("备注名")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        TextField("给对方取个名字", text: $displayName)
                            .font(.system(size: 15))
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }

                    // Key options
                    VStack(alignment: .leading, spacing: 8) {
                        Text("加密密钥")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)

                        Toggle("自动生成新密钥", isOn: $generateKey)
                            .font(.system(size: 15))

                        if !generateKey {
                            TextField("输入共享密钥（Base64）", text: $keyBase64)
                                .font(.system(size: 13, design: .monospaced))
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                Button(action: addContact) {
                    Text("添加")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(canAdd ? Color(hex: "#4A90D9") : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!canAdd)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationTitle("添加联系人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    var canAdd: Bool {
        !contactID.trimmingCharacters(in: .whitespaces).isEmpty &&
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func addContact() {
        let id = contactID.trimmingCharacters(in: .whitespaces)
        let name = displayName.trimmingCharacters(in: .whitespaces)

        var key: String?
        if generateKey {
            let newKey = CryptoService.generateConversationKey()
            key = CryptoService.exportKey(newKey)
        } else if !keyBase64.isEmpty {
            key = keyBase64.trimmingCharacters(in: .whitespaces)
        }

        appState.addContact(id: id, displayName: name, keyBase64: key)
        dismiss()
    }
}
