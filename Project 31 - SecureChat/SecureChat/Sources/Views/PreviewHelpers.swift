import SwiftUI

// MARK: - SwiftUI Previews

#Preview("欢迎页") {
    WelcomeView()
        .environmentObject(AppState())
}

#Preview("创建账户") {
    CreateAccountView()
        .environmentObject(AppState())
}

#Preview("会话列表") {
    let state = AppState.previewState()
    ConversationListView()
        .environmentObject(state)
}

#Preview("聊天页面") {
    let state = AppState.previewState()
    NavigationView {
        ChatView(contactID: "demo001")
            .environmentObject(state)
    }
}

#Preview("个人资料") {
    ProfileView()
        .environmentObject(AppState.previewState())
}

// MARK: - Preview Helper

extension AppState {
    static func previewState() -> AppState {
        let state = AppState()
        let mnemonic = "abandon ability able about above absent absorb abstract absurd abuse access accident"
        state.createAccount(with: mnemonic, displayName: "测试用户")
        state.addDemoContacts()

        // Add some demo messages
        _ = state.sendMessage(to: "demo001", plaintext: "你好 Alice！")
        _ = state.sendMessage(to: "demo001", plaintext: "这条消息是端到端加密的 🔒")
        _ = state.sendMessage(to: "demo002", plaintext: "Hi Bob!")

        return state
    }
}
