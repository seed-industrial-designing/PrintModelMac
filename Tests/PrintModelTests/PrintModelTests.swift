import XCTest
#if os(macOS)
import AppKit
#endif
@testable import PrintModel

final class PrintModelTests: XCTestCase
{	
	@available(macOS 10.0, *)
	func testFourCharString()
	{
		XCTAssertEqual(NSFileTypeForHFSTypeCode(.init(Int32(fourCharString: "abcd"))), "\'abcd\'")
	}
}
