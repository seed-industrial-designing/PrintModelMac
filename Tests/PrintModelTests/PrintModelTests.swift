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
	
	func testDeviceDescriptorDeserialization() throws
	{
		let json = """
		[
			{
				"modelName": "Animal",
				"isDisabled": true,
				"printerType": "animal",
				"headDotCount": 384,
				"dpi": 600,
				"hidesDpi": true,
				"colorAbility": "fullColor",
				"transportTypes": ["usb", "wifi"],
				"canvases": [
					{
						"identifier": "default",
						"size_mm": {
							"width": 210,
							"height": 297
						}
					}
				],
				"parameterProperties": [
					{
						"identifier": "paperKind",
						"type": "pick",
						"defaultValue": "glossy",
						"items": [
							"plain",
							"glossy"
						]
					}
				],
				"offsetBases": ["top", "center"],
				"maintenanceActions": [
					{
						"identifier": "cleaning"
					}
				]
			},
			{
				"modelName": "Dog",
				"baseModelName": "Animal",
				"printerType": "animal",
				"maintenanceActions": [
					{
						"identifier": "sniff",
						"visibility": "debug"
					}
				]
			}
		]
"""
		try JSONDecoder().decode([DeviceDescriptor.SerializedInfoContainer].self, from: json.data(using: .utf8)!)
	}
}
