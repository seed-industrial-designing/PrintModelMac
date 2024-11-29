//
// PrintModelMac
// Copyright © 2015-2024 Seed Industrial Designing Co., Ltd. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
// and associated documentation files (the “Software”), to deal in the Software without
// restriction, including without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom
// the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import Foundation

public class DeviceSettingParameter: NSObject
{
	init(from serializedInfo: DeviceSettingParameterSerializedInfo, localizedStringTables: [LocalizedStringTable])
	{
		identifier = serializedInfo.identifier
		paneIdentifier = serializedInfo.pane ?? "Print"
		localizedLeftColumnText = LocalizedStringTable.preferredLocalizedString(forKey: ("DeviceSettingParameter_" + identifier + "_LeftColumnText"), in: localizedStringTables) ?? identifier
		super.init()
	}
	
	//MARK: - Properties
	
	@objc public var identifier: String
	@objc public var paneIdentifier: String
	@objc public var `default`: Any!
	
	@objc public var localizedLeftColumnText: String
	
	//MARK: - Subclasses
	
	public final class NumberParameter: DeviceSettingParameter
	{
		struct SerializedInfo: DeviceSettingParameterSerializedInfo
		{
			let identifier: String
			let pane: String?
			
			let minValue: Double?
			let maxValue: Double?
			let defaultValue: Double?
			let tickFrequency: Double?
		}
		
		init(from serializedInfo: SerializedInfo, localizedStringTables: [LocalizedStringTable])
		{
			super.init(from: serializedInfo, localizedStringTables: localizedStringTables)
			
			min = serializedInfo.minValue ?? 0.0
			max = serializedInfo.maxValue ?? 1.0
			`default` = serializedInfo.defaultValue ?? min
			let tickFrequency = (serializedInfo.tickFrequency ?? 1.0)
			numberOfSteps = .init(round((max - min) / tickFrequency) + 1.0)
		}
		
		//MARK: - Parameters
		
		@nonobjc public var min = 0.0
		@objc(min) public var min_objc: NSNumber { (min as NSNumber) }
		
		@nonobjc public var max = 1.0
		@objc(max) public var max_objc: NSNumber { (max as NSNumber) }
		
		@nonobjc public var defaultNumber: Double { (`default` as! Double) }
		
		@objc public dynamic var numberOfSteps = 0
		
		public func constrainValue(_ value: Double) -> Double
		{
			var value = value
			if (value < min) {
				value = min
			} else if (value > max) {
				value = max
			}
			return value
		}
	}
	public final class BoolParameter: DeviceSettingParameter
	{
		struct SerializedInfo: DeviceSettingParameterSerializedInfo
		{
			let identifier: String
			let pane: String?
			
			let defaultValue: Bool?
			let negates: Bool?
		}
		
		init(from serializedInfo: SerializedInfo, localizedStringTables: [LocalizedStringTable])
		{
			localizedCheckboxTitleText = LocalizedStringTable.preferredLocalizedString(forKey: ("DeviceSettingParameter_" + serializedInfo.identifier + "_CheckboxTitleText"), in: localizedStringTables) ?? serializedInfo.identifier

			super.init(from: serializedInfo, localizedStringTables: localizedStringTables)
			
			`default` = serializedInfo.defaultValue
			negates = serializedInfo.negates ?? false
		}
		
		//MARK: - Properties
		
		@objc public var defaultBool: Bool { (`default` as! Bool) }
		
		@objc public var negates = false
		
		@objc public var localizedCheckboxTitleText: String
	}
	public final class PickParameter: DeviceSettingParameter
	{
		struct SerializedInfo: DeviceSettingParameterSerializedInfo
		{
			let identifier: String
			let pane: String?
			
			let defaultValue: String?
			let items: [String]
		}
		
		public class Item: NSObject
		{
			//MARK: - Properties
			
			@objc public dynamic let identifier: String
			@objc public dynamic let parameterIdentifier: String
			@objc public dynamic let localizedName: String
			
			//MARK: - Init
			
			public init(identifier: String, parameterIdentifier: String, localizedStringTables: [LocalizedStringTable])
			{
				self.identifier = identifier
				self.parameterIdentifier = parameterIdentifier
				self.localizedName = LocalizedStringTable.preferredLocalizedString(forKey: ("DeviceSettingParameter_\(parameterIdentifier)_Items_\(identifier)"), in: localizedStringTables) ?? identifier
				super.init()
			}
		}
		
		//MARK: - Init
		
		init(from serializedInfo: SerializedInfo, localizedStringTables: [LocalizedStringTable])
		{
			super.init(from: serializedInfo, localizedStringTables: localizedStringTables)
			
			items = serializedInfo.items
				.map { Item(identifier: $0, parameterIdentifier: self.identifier, localizedStringTables: localizedStringTables) }
			
			`default` = serializedInfo.defaultValue ?? items.first!.identifier
		}
		
		//MARK: - Properties
		
		@objc public dynamic var items: [Item] = []
		
		@objc public var defaultItemIdentifier: String { (`default` as! String) }
	}
}

//MARK: -

protocol DeviceSettingParameterSerializedInfo: Decodable
{
	var identifier: String { get }
	var pane: String? { get }
}

@propertyWrapper struct CustomDecodedParameterSerializedInfos: Decodable
{
	enum Error: LocalizedError
	{
		case invalidType(type: String)
	}
	
	public var wrappedValue: [DeviceSettingParameterSerializedInfo] = []
	
	enum ParameterCodingKey: CodingKey
	{
		case type
	}
	public init() { }
	public init(from decoder: any Decoder) throws
	{
		var result: [DeviceSettingParameterSerializedInfo] = []
		var arrayContainerForType = try decoder.unkeyedContainer()
		var arrayContainerForDecoding = arrayContainerForType
		while !arrayContainerForType.isAtEnd {
			let container = try arrayContainerForType.nestedContainer(keyedBy: ParameterCodingKey.self)
			switch try? container.decode(String.self, forKey: .type) {
			case "bool":
				try result.append(arrayContainerForDecoding.decode(DeviceSettingParameter.BoolParameter.SerializedInfo.self))
			case "number":
				try result.append(arrayContainerForDecoding.decode(DeviceSettingParameter.NumberParameter.SerializedInfo.self))
			case "pick":
				try result.append(arrayContainerForDecoding.decode(DeviceSettingParameter.PickParameter.SerializedInfo.self))
			case let type:
				throw Error.invalidType(type: type ?? "unknown")
			}
		}
		wrappedValue = result
	}
}
extension KeyedDecodingContainer
{
	func decode(_: CustomDecodedParameterSerializedInfos.Type, forKey key: Key) throws -> CustomDecodedParameterSerializedInfos
	{
		do {
			return try .init(from: superDecoder(forKey: key))
		} catch {
			return .init()
		}
	}
}
