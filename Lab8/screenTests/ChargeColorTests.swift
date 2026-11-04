import SwiftUI
import Testing
@testable import screen

struct ChargeColorTests {
    @Test(arguments: [(100.0, Color.green), (50, .green), (45, .yellow), (20, .yellow), (15, .orange), (5, .orange), (0, .red)])
    func colorFollowsStartingCharge(percent: Double, expected: Color) {
        #expect(AppsPage.chargeColor(percent) == expected)
    }
}
