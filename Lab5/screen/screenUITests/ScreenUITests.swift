import XCTest

final class ScreenUITests: XCTestCase {
    private let morse: [String: Character] = [
        ".-": "A", "-...": "B", "-.-.": "C", "-..": "D", ".": "E", "..-.": "F", "--.": "G",
        "....": "H", "..": "I", ".---": "J", "-.-": "K", ".-..": "L", "--": "M", "-.": "N",
        "---": "O", ".--.": "P", "--.-": "Q", ".-.": "R", "...": "S", "-": "T", "..-": "U",
        "...-": "V", ".--": "W", "-..-": "X", "-.--": "Y", "--..": "Z",
    ]

    func testTabsShowTheirPages() {
        let app = launch()
        XCTAssertTrue(app.tabBars.buttons["Battery"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Battery"].isSelected)
        for title in ["Apps", "Server", "Security"] {
            app.tabBars.buttons[title].tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 3), title)
        }
        app.tabBars.buttons["Battery"].tap()
        XCTAssertTrue(app.tabBars.buttons["Battery"].isSelected)
    }

    func testCoefficientSliderReachesTwenty() {
        let app = launch()
        app.tabBars.buttons["Apps"].tap()
        let slider = app.sliders["badRate"]
        XCTAssertTrue(slider.waitForExistence(timeout: 3))
        slider.adjust(toNormalizedSliderPosition: 1)
        XCTAssertEqual(app.staticTexts["badCoefficient"].label, "Coefficient, 20 %/min")
        XCTAssertEqual(app.staticTexts["goodCoefficient"].label, "Coefficient, 1 %/min")
    }

    func testBlockingToggleTurnsOn() {
        let app = launch()
        app.tabBars.buttons["Apps"].tap()
        let toggle = app.switches["Block bad apps at 0%"]
        if !toggle.waitForExistence(timeout: 3) { app.swipeUp() }
        XCTAssertEqual(toggle.value as? String, "0")
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        XCTAssertEqual(toggle.value as? String, "1")
    }

    func testInvalidLinkShowsError() {
        let app = launch()
        app.tabBars.buttons["Server"].tap()
        enter("http://example.com", into: app.textFields["goodLink"])
        XCTAssertTrue(app.staticTexts["Enter a valid https:// link."].waitForExistence(timeout: 3))
    }

    func testValidLinkHasNoError() {
        let app = launch()
        app.tabBars.buttons["Server"].tap()
        enter("https://example.com/usage", into: app.textFields["goodLink"])
        XCTAssertFalse(app.staticTexts["Enter a valid https:// link."].waitForExistence(timeout: 2))
    }

    func testLogLimitCanBeChanged() {
        let app = launch()
        app.tabBars.buttons["Server"].tap()
        choose("10", in: "Keep last", app: app)
        XCTAssertTrue(app.staticTexts["Requests (0/10)"].waitForExistence(timeout: 3))
    }

    func testMathTaskLocksAndUnlocks() {
        let app = launch()
        app.tabBars.buttons["Security"].tap()
        choose("Math task", in: "Protection", app: app)
        XCTAssertTrue(app.staticTexts["Example"].waitForExistence(timeout: 3))

        lockAndOpenChallenge(app: app, page: "Security")
        let prompt = app.staticTexts["challengePrompt"]
        XCTAssertTrue(prompt.waitForExistence(timeout: 3))
        let field = app.textFields["challengeAnswer"]

        enter("0", into: field, submit: false)
        app.navigationBars["Math task"].buttons["Unlock"].tap()
        XCTAssertTrue(app.staticTexts["Wrong answer, try again."].waitForExistence(timeout: 3))

        enter(String(solve(prompt.label)), into: field, submit: false)
        app.navigationBars["Math task"].buttons["Unlock"].tap()
        XCTAssertTrue(picker("Protection", in: app).waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["Locked"].exists)
    }

    func testMorseCodeUnlocks() {
        let app = launch()
        app.tabBars.buttons["Security"].tap()
        choose("Morse code", in: "Protection", app: app)
        app.buttons["Easy"].tap()

        lockAndOpenChallenge(app: app, page: "Security")
        let prompt = app.staticTexts["challengePrompt"]
        XCTAssertTrue(prompt.waitForExistence(timeout: 3))
        let word = String(prompt.label.split(separator: " ").compactMap { morse[String($0)] })
        XCTAssertEqual(word.count, 3)

        enter(word.lowercased(), into: app.textFields["challengeAnswer"], submit: false)
        app.navigationBars["Morse code"].buttons["Unlock"].tap()
        XCTAssertTrue(picker("Protection", in: app).waitForExistence(timeout: 3))
    }

    func testPasswordLocksAndUnlocks() {
        let app = launch()
        app.tabBars.buttons["Security"].tap()
        choose("Password", in: "Protection", app: app)
        enter("1234", into: app.secureTextFields["New password"], submit: false)
        app.buttons["Save password"].tap()
        XCTAssertTrue(app.staticTexts["Password is set."].waitForExistence(timeout: 3))

        lockAndOpenChallenge(app: app, page: "Security")
        let field = app.secureTextFields["challengeAnswer"]
        enter("9999", into: field, submit: false)
        app.navigationBars["Password"].buttons["Unlock"].tap()
        XCTAssertTrue(app.staticTexts["Wrong answer, try again."].waitForExistence(timeout: 3))

        enter("1234", into: field, submit: false)
        app.navigationBars["Password"].buttons["Unlock"].tap()
        XCTAssertTrue(picker("Protection", in: app).waitForExistence(timeout: 3))
    }

    func testLockedPagesHideSettings() {
        let app = launch()
        app.tabBars.buttons["Security"].tap()
        choose("Math task", in: "Protection", app: app)
        app.navigationBars["Security"].buttons["Lock"].tap()

        for page in ["Apps", "Server", "Security"] {
            app.tabBars.buttons[page].tap()
            XCTAssertTrue(app.staticTexts["Locked"].waitForExistence(timeout: 3), page)
        }
        app.tabBars.buttons["Apps"].tap()
        XCTAssertFalse(app.sliders["badRate"].exists)
        app.tabBars.buttons["Server"].tap()
        XCTAssertFalse(app.textFields["goodLink"].exists)
    }

    func testCancelKeepsPageLocked() {
        let app = launch()
        app.tabBars.buttons["Security"].tap()
        choose("Math task", in: "Protection", app: app)
        lockAndOpenChallenge(app: app, page: "Security")
        app.navigationBars["Math task"].buttons["Cancel"].tap()
        XCTAssertTrue(app.staticTexts["Locked"].waitForExistence(timeout: 3))
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
        return app
    }

    private func picker(_ title: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", title + ",")).firstMatch
    }

    private func choose(_ option: String, in title: String, app: XCUIApplication) {
        let button = picker(title, in: app)
        XCTAssertTrue(button.waitForExistence(timeout: 3), title)
        button.tap()
        let item = app.buttons[option].firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 3), option)
        item.tap()
    }

    private func enter(_ text: String, into field: XCUIElement, submit: Bool = true) {
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap()
        field.typeText(submit ? text + "\n" : text)
    }

    private func lockAndOpenChallenge(app: XCUIApplication, page: String) {
        app.navigationBars[page].buttons["Lock"].tap()
        XCTAssertTrue(app.staticTexts["Locked"].waitForExistence(timeout: 3))
        app.buttons["Unlock"].tap()
    }

    private func solve(_ prompt: String) -> Int {
        let numbers = prompt.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        guard prompt.contains("×") else { return numbers[0] + numbers[1] }
        let product = numbers[0] * numbers[1]
        return prompt.contains("+") ? product + numbers[2] : product - numbers[2]
    }
}
