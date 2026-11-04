import Testing
@testable import screen

struct ChallengeTests {
    @Test func mathAcceptsOnlyCorrectAnswer() {
        let challenge = Challenge.math(.medium, 12, 7, 30)
        #expect(challenge.prompt == "12 × 7 + 30 = ?")
        #expect(challenge.accepts("114"))
        #expect(challenge.accepts(" 114 "))
        #expect(!challenge.accepts("113"))
        #expect(!challenge.accepts("abc"))
    }

    @Test func easyMathAdds() {
        let challenge = Challenge.math(.easy, 42, 37)
        #expect(challenge.prompt == "42 + 37 = ?")
        #expect(challenge.accepts("79"))
    }

    @Test func hardMathMultipliesAndSubtracts() {
        let challenge = Challenge.math(.hard, 37, 24, 315)
        #expect(challenge.prompt == "37 × 24 − 315 = ?")
        #expect(challenge.accepts("573"))
    }

    @Test func passwordComparesHash() {
        let challenge = Challenge.password(hash: PasswordHash.make("secret"))
        #expect(challenge.prompt.isEmpty)
        #expect(challenge.accepts("secret"))
        #expect(!challenge.accepts("Secret"))
        #expect(!challenge.accepts(""))
    }

    @Test func morseShowsCodeAndAcceptsWord() {
        let challenge = Challenge.morse("SOS")
        #expect(challenge.prompt == "... --- ...")
        #expect(challenge.accepts("sos"))
        #expect(challenge.accepts("S O S"))
        #expect(!challenge.accepts("SOT"))
    }

    @Test func noChallengeWithoutProtection() {
        #expect(Challenge.make(for: BatteryConfig()) == nil)
    }

    @Test func noChallengeForPasswordWithoutHash() {
        var config = BatteryConfig()
        config.protection = .password
        #expect(Challenge.make(for: config) == nil)
    }

    @Test(arguments: [Protection.math, .morse])
    func makesChallengeOfChosenKind(_ protection: Protection) throws {
        var config = BatteryConfig()
        config.protection = protection
        let challenge = try #require(Challenge.make(for: config))
        #expect(challenge.kind == protection)
        #expect(!challenge.prompt.isEmpty)
    }

    @Test(arguments: Difficulty.allCases)
    func randomMathIsSolvable(_ difficulty: Difficulty) throws {
        for _ in 0..<20 {
            let challenge = Challenge.randomMath(difficulty)
            let numbers = challenge.prompt.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
            let answer = switch difficulty {
            case .easy: numbers[0] + numbers[1]
            case .medium: numbers[0] * numbers[1] + numbers[2]
            case .hard: numbers[0] * numbers[1] - numbers[2]
            }
            #expect(answer > 0)
            #expect(challenge.accepts(String(answer)))
        }
    }

    @Test(arguments: Difficulty.allCases)
    func randomMorseLengthFollowsDifficulty(_ difficulty: Difficulty) {
        let challenge = Challenge.randomMorse(difficulty)
        #expect(challenge.prompt.split(separator: " ").count == Morse.length(difficulty))
    }

    @Test func difficultyMakesMorseLonger() {
        #expect(Morse.length(.easy) < Morse.length(.medium))
        #expect(Morse.length(.medium) < Morse.length(.hard))
    }

    @Test func usesConfiguredDifficulty() throws {
        var config = BatteryConfig()
        config.protection = .morse
        config.difficulty = .hard
        let challenge = try #require(Challenge.make(for: config))
        #expect(challenge.prompt.split(separator: " ").count == 8)
    }

    @Test func examplesMatchDifficulty() {
        #expect(Challenge.example(.math, .easy) == "42 + 37 = ?")
        #expect(Challenge.example(.math, .medium) == "23 × 7 + 58 = ?")
        #expect(Challenge.example(.math, .hard) == "37 × 24 − 315 = ?")
        #expect(Challenge.example(.morse, .easy) == "-.-. .- -  →  CAT")
    }

    @Test(arguments: Difficulty.allCases)
    func noExampleWithoutTask(_ difficulty: Difficulty) {
        #expect(Challenge.example(.none, difficulty) == nil)
        #expect(Challenge.example(.password, difficulty) == nil)
    }
}

struct MorseTests {
    @Test func encodesLettersSeparatedBySpaces() {
        #expect(Morse.encode("abc") == ".- -... -.-.")
    }

    @Test func skipsUnknownCharacters() {
        #expect(Morse.encode("a1b") == ".- -...")
    }

    @Test func coversWholeAlphabet() {
        #expect(Morse.table.count == 26)
        #expect(Set(Morse.table.values).count == 26)
    }
}

struct PasswordHashTests {
    @Test func isStableSHA256Hex() {
        #expect(PasswordHash.make("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    @Test func differsForDifferentPasswords() {
        #expect(PasswordHash.make("1234") != PasswordHash.make("1235"))
    }
}
