import XCTest

extension XCTestCase {
    func makeAnyNSError() -> NSError {
        return NSError(domain: "any-error", code: -1)
    }
}
