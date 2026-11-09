import Foundation

enum GuideTestEnvironment {
    static let exposesStatus = ProcessInfo.processInfo.environment["GUIDEKIT_TEST"] == "1"
    static let autostartFlowID = ProcessInfo.processInfo.environment["GUIDEKIT_TEST_FLOW"]
}
