import Foundation
import CryptoKit

/// BIP39-inspired mnemonic word list (simplified subset of 2048 words)
/// Used to generate human-readable seed phrases for account creation
struct MnemonicGenerator {

    // MARK: - Word List (256 common English words for 8-bit indexing)
    static let wordList: [String] = [
        "abandon", "ability", "able", "about", "above", "absent", "absorb", "abstract",
        "absurd", "abuse", "access", "accident", "account", "accuse", "achieve", "acid",
        "acoustic", "acquire", "across", "act", "action", "actor", "actress", "actual",
        "adapt", "add", "addict", "address", "adjust", "admit", "adult", "advance",
        "advice", "aerobic", "affair", "afford", "afraid", "again", "age", "agent",
        "agree", "ahead", "aim", "air", "airport", "aisle", "alarm", "album",
        "alcohol", "alert", "alien", "all", "alley", "allow", "almost", "alone",
        "alpha", "already", "also", "alter", "always", "amateur", "amazing", "among",
        "amount", "amused", "analyst", "anchor", "ancient", "anger", "angle", "angry",
        "animal", "ankle", "announce", "annual", "another", "answer", "antenna", "antique",
        "anxiety", "any", "apart", "apology", "appear", "apple", "approve", "april",
        "arch", "arctic", "area", "arena", "argue", "arm", "armed", "armor",
        "army", "around", "arrange", "arrest", "arrive", "arrow", "art", "artefact",
        "artist", "artwork", "ask", "aspect", "assault", "asset", "assist", "assume",
        "asthma", "athlete", "atom", "attack", "attend", "attitude", "attract", "auction",
        "audit", "august", "aunt", "author", "auto", "autumn", "average", "avocado",
        "avoid", "awake", "aware", "awesome", "awful", "awkward", "axis", "baby",
        "bachelor", "bacon", "badge", "bag", "balance", "balcony", "ball", "bamboo",
        "banana", "banner", "bar", "barely", "bargain", "barrel", "base", "basic",
        "basket", "battle", "beach", "bean", "beauty", "because", "become", "beef",
        "before", "begin", "behave", "behind", "believe", "below", "belt", "bench",
        "benefit", "best", "betray", "better", "between", "beyond", "bicycle", "bid",
        "bike", "bind", "biology", "bird", "birth", "bitter", "black", "blade",
        "blame", "blanket", "blast", "bleak", "bless", "blind", "blood", "blossom",
        "blow", "blue", "blur", "blush", "board", "boat", "body", "boil",
        "bomb", "bone", "bonus", "book", "boost", "border", "boring", "borrow",
        "boss", "bottom", "bounce", "box", "boy", "bracket", "brain", "brand",
        "brass", "brave", "bread", "breeze", "brick", "bridge", "brief", "bright",
        "bring", "brisk", "broccoli", "broken", "bronze", "broom", "brother", "brown",
        "brush", "bubble", "buddy", "budget", "buffalo", "build", "bulb", "bulk",
        "bullet", "bundle", "bunny", "burden", "burger", "burst", "bus", "business",
        "busy", "butter", "buyer", "buzz", "cabbage", "cabin", "cable", "cactus"
    ]

    /// Generate a mnemonic phrase with the specified number of words (default 12)
    static func generate(wordCount: Int = 12) -> String {
        var words: [String] = []
        let entropyBytes = wordCount  // 1 byte per word for simplicity
        var randomBytes = [UInt8](repeating: 0, count: entropyBytes)
        _ = SecRandomCopyBytes(kSecRandomDefault, entropyBytes, &randomBytes)

        for i in 0..<wordCount {
            let index = Int(randomBytes[i]) % wordList.count
            words.append(wordList[index])
        }
        return words.joined(separator: " ")
    }

    /// Derive a deterministic 256-bit key from a mnemonic phrase
    static func deriveKey(from mnemonic: String) -> SymmetricKey {
        let data = Data(mnemonic.utf8)
        let hash = SHA256.hash(data: data)
        return SymmetricKey(data: hash)
    }

    /// Derive a user ID from a mnemonic phrase (first 8 bytes of SHA256 as hex)
    static func deriveUserID(from mnemonic: String) -> String {
        let data = Data(mnemonic.utf8)
        let hash = SHA256.hash(data: data)
        return hash.prefix(8).map { String(format: "%02x", $0) }.joined()
    }

    /// Derive a display name from a mnemonic (first two words capitalized)
    static func deriveDisplayName(from mnemonic: String) -> String {
        let words = mnemonic.split(separator: " ")
        guard words.count >= 2 else { return "User" }
        return words.prefix(2).map { $0.capitalized }.joined(separator: "")
    }

    /// Validate that a mnemonic phrase contains valid words
    static func validate(mnemonic: String) -> Bool {
        let words = mnemonic.split(separator: " ").map(String.init)
        guard words.count == 12 else { return false }
        return words.allSatisfy { wordList.contains($0.lowercased()) }
    }
}
