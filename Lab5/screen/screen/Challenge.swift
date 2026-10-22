import CryptoKit
import Foundation

struct Challenge: Identifiable {
    let id = UUID()
    let kind: Protection
    let prompt: String
    private let accept: (String) -> Bool

    func accepts(_ answer: String) -> Bool {
        accept(answer.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    static func make(for config: BatteryConfig) -> Challenge? {
        guard config.isProtected else { return nil }
        switch config.protection {
        case .none: return nil
        case .password: return password(hash: config.passwordHash)
        case .math: return randomMath(config.difficulty)
        case .morse: return randomMorse(config.difficulty)
        }
    }

    static func example(_ protection: Protection, _ difficulty: Difficulty) -> String? {
        switch protection {
        case .none, .password:
            return nil
        case .math:
            switch difficulty {
            case .easy: return math(.easy, 42, 37).prompt
            case .medium: return math(.medium, 23, 7, 58).prompt
            case .hard: return math(.hard, 37, 24, 315).prompt
            }
        case .morse:
            let word = switch difficulty {
            case .easy: "CAT"
            case .medium: "SMILE"
            case .hard: "KEYBOARD"
            }
            return Morse.encode(word) + "  →  " + word
        }
    }

    static func password(hash: String) -> Challenge {
        Challenge(kind: .password, prompt: "") { PasswordHash.make($0) == hash }
    }

    static func math(_ difficulty: Difficulty, _ a: Int, _ b: Int, _ c: Int = 0) -> Challenge {
        let (prompt, answer) = switch difficulty {
        case .easy: ("\(a) + \(b) = ?", a + b)
        case .medium: ("\(a) × \(b) + \(c) = ?", a * b + c)
        case .hard: ("\(a) × \(b) − \(c) = ?", a * b - c)
        }
        return Challenge(kind: .math, prompt: prompt) { Int($0) == answer }
    }

    static func randomMath(_ difficulty: Difficulty) -> Challenge {
        switch difficulty {
        case .easy:
            return math(.easy, .random(in: 10...99), .random(in: 10...99))
        case .medium:
            return math(.medium, .random(in: 12...29), .random(in: 3...9), .random(in: 10...99))
        case .hard:
            let a = Int.random(in: 12...49), b = Int.random(in: 12...49)
            return math(.hard, a, b, .random(in: 100..<a * b))
        }
    }

    static func morse(_ word: String) -> Challenge {
        Challenge(kind: .morse, prompt: Morse.encode(word)) {
            $0.uppercased().filter { !$0.isWhitespace } == word.uppercased()
        }
    }

    static func randomMorse(_ difficulty: Difficulty) -> Challenge {
        morse(String((0..<Morse.length(difficulty)).map { _ in Morse.table.keys.randomElement()! }))
    }
}

enum PasswordHash {
    static func make(_ password: String) -> String {
        SHA256.hash(data: Data(password.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

enum Morse {
    static let table: [Character: String] = [
        "A": ".-", "B": "-...", "C": "-.-.", "D": "-..", "E": ".", "F": "..-.", "G": "--.",
        "H": "....", "I": "..", "J": ".---", "K": "-.-", "L": ".-..", "M": "--", "N": "-.",
        "O": "---", "P": ".--.", "Q": "--.-", "R": ".-.", "S": "...", "T": "-", "U": "..-",
        "V": "...-", "W": ".--", "X": "-..-", "Y": "-.--", "Z": "--..",
    ]

    static func length(_ difficulty: Difficulty) -> Int {
        switch difficulty {
        case .easy: 3
        case .medium: 5
        case .hard: 8
        }
    }

    static func encode(_ text: String) -> String {
        text.uppercased().compactMap { table[$0] }.joined(separator: " ")
    }
}
