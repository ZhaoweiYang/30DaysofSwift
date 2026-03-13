import SwiftUI

/// User profile view showing account info and mnemonic backup
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var showMnemonic = false
    @State private var showLogoutAlert = false
    @State private var copiedMnemonic = false
    @State private var copiedID = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Profile header
                VStack(spacing: 12) {
                    if let user = appState.currentUser {
                        AvatarView(name: user.displayName, color: user.avatarColor, size: 80)

                        Text(user.displayName)
                            .font(.system(size: 22, weight: .bold))

                        HStack(spacing: 4) {
                            Text("ID: \(user.id)")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.secondary)
                            Button(action: {
                                UIPasteboard.general.string = user.id
                                copiedID = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedID = false }
                            }) {
                                Image(systemName: copiedID ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "#4A90D9"))
                            }
                        }
                    }
                }
                .padding(.vertical, 32)

                // Settings list
                List {
                    Section(header: Text("安全")) {
                        Button(action: { showMnemonic.toggle() }) {
                            HStack {
                                Image(systemName: "key.fill")
                                    .foregroundColor(.orange)
                                    .frame(width: 28)
                                Text("查看助记词")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 13))
                            }
                        }
                        .foregroundColor(.primary)

                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.green)
                                .frame(width: 28)
                            Text("加密算法")
                            Spacer()
                            Text("AES-256-GCM")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                        }
                    }

                    Section(header: Text("数据")) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(Color(hex: "#4A90D9"))
                                .frame(width: 28)
                            Text("联系人")
                            Spacer()
                            Text("\(appState.contacts.count)")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .foregroundColor(Color(hex: "#4A90D9"))
                                .frame(width: 28)
                            Text("会话")
                            Spacer()
                            Text("\(appState.conversations.count)")
                                .foregroundColor(.secondary)
                        }
                    }

                    Section {
                        Button(action: { showLogoutAlert = true }) {
                            HStack {
                                Spacer()
                                Text("退出登录")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("个人信息")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .sheet(isPresented: $showMnemonic) {
                mnemonicSheet
            }
            .alert("确认退出", isPresented: $showLogoutAlert) {
                Button("取消", role: .cancel) { }
                Button("退出", role: .destructive) {
                    appState.logout()
                    dismiss()
                }
            } message: {
                Text("退出后需要助记词才能恢复账户。请确认已备份助记词。")
            }
        }
    }

    var mnemonicSheet: some View {
        VStack(spacing: 20) {
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 36))
                .foregroundColor(.orange)
                .padding(.top, 32)

            Text("您的助记词")
                .font(.system(size: 20, weight: .bold))

            Text("请勿在公共场合展示")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            if let mnemonic = StorageService.shared.loadMnemonic() {
                let words = mnemonic.split(separator: " ").map(String.init)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 10) {
                    ForEach(Array(words.enumerated()), id: \.offset) { index, word in
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

                Button(action: {
                    UIPasteboard.general.string = mnemonic
                    copiedMnemonic = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedMnemonic = false }
                }) {
                    HStack {
                        Image(systemName: copiedMnemonic ? "checkmark" : "doc.on.doc")
                        Text(copiedMnemonic ? "已复制" : "复制助记词")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#4A90D9"))
                }
            }

            Spacer()
        }
    }
}
