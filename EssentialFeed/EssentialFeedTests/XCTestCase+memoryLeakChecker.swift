import XCTest

extension XCTestCase {
    func checkMemoryLeak(
        _ instance: AnyObject,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        addTeardownBlock { [weak instance] in
            let errorMessage = "Instance MUST have been deallocated. Potential memory leak"
            XCTAssertNil(instance, errorMessage, file: file, line: line)
        }
    }
}
