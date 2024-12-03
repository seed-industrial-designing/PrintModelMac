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
				],
				"additionalInfos": {
					"food": {
						"kind": "meat"
					}
				}
			}
		]
"""
		let containers = try JSONDecoder().decode([DeviceDescriptor.SerializedInfoContainer].self, from: json.data(using: .utf8)!)
		
		let base = switch containers.first {
		case .base(let info):
			info
		default:
			fatalError("not base")
		}
		let override = switch containers.last {
		case .override(let info):
			info
		default:
			fatalError("not override")
		}
		
		let dog = override.connected(base: base)
		struct Food: DeviceAdditionalInfo
		{
			static let key = "food"
			var kind: String = ""
		}
		XCTAssertEqual(try dog.additionalInfos!.value(of: Food.self).kind, "meat")
	}
}
