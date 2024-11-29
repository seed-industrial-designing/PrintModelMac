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

@objc public final class DeviceDescriptor : NSObject, NSCopying
{
	private static var _deviceDescriptors: [DeviceDescriptor]? = nil
	public class var supported: [DeviceDescriptor]
	{
		if (_deviceDescriptors == nil) {
			_deviceDescriptors = ConnectPluginManager.shared.plugins.flatMap { $0.deviceDescriptors }
		}
		return _deviceDescriptors!
	}
	
	enum SerializedInfoContainer: Decodable
	{
		case base(BaseSerializedInfo)
		case override(OverrideSerializedInfo)
		
		init(from decoder: any Decoder) throws
		{
			enum TypeCheckCodingKeys: CodingKey { case baseModelName }
			let typeCheckContainer = try decoder.container(keyedBy: TypeCheckCodingKeys.self)
			self = if typeCheckContainer.contains(.baseModelName) {
				try .override(.init(from: decoder))
			} else {
				try .base(.init(from: decoder))
			}
		}
	}
	struct OverrideSerializedInfo: Decodable
	{
		var modelName: String
		var baseModelName: String
		
		//These properties are replaced:
		var isDisabled: Bool?
		var displayName: String?
		var printerType: String?
		var canvases: [Canvas.SerializedInfo]?
		var transportTypes: [String]?
		var colorAbility: String?
		var offsetBases: [String]?
		
		//These properties are merged:
		var additionalInfos: DeviceAdditionalInfoDictionary?
		@CustomDecodedParameterSerializedInfos var parameterProperties: [DeviceSettingParameterSerializedInfo]
		var maintenanceActions: [MaintenanceAction.SerializedInfo]?
		
		func connected(base: BaseSerializedInfo) -> BaseSerializedInfo
		{
			var result = base; do {
				result.isDisabled = isDisabled
				result.modelName = modelName
				if let displayName { result.displayName = displayName }
				if let printerType { result.printerType = printerType }
				if let canvases { result.canvases = canvases }
				if let transportTypes { result.transportTypes = transportTypes }
				if let colorAbility { result.colorAbility = colorAbility }
				if let offsetBases { result.offsetBases = offsetBases }
				if let additionalInfos {
					result.additionalInfos = additionalInfos.merging(preferring: additionalInfos)
				}
				func merge<T>(override: [T], base: [T], id: KeyPath<T, String>) -> [T]
				{
					var result = base
					for overrideItem in override {
						if let i = result.firstIndex(where: { $0[keyPath: id] == overrideItem[keyPath: id] }) {
							result.replaceSubrange(i...i, with: [overrideItem])
						} else {
							result.append(overrideItem)
						}
					}
					return result
				}
				if !parameterProperties.isEmpty {
					result.parameterProperties = merge(override: parameterProperties, base: base.parameterProperties, id: \.identifier)
				}
				if let maintenanceActions {
					result.maintenanceActions = merge(override: maintenanceActions, base: (base.maintenanceActions ?? []), id: \.identifier)
				}
			}
			return result
		}
	}
	struct BaseSerializedInfo: Decodable
	{
		var isDisabled: Bool?
		var modelName: String
		var displayName: String?
		var printerType: String
		var printVerb: PrintVerb?
		var canvases: [Canvas.SerializedInfo]
		
		var transportTypes: [String]?
		var colorAbility: String?
		var headDotCount: Int?
		var dpi: CGFloat
		var hidesDpi: Bool?
		var offsetBases: [String]
		var completionAlertVideoName: String?
		
		@CustomDecodedParameterSerializedInfos var parameterProperties: [DeviceSettingParameterSerializedInfo]
		var maintenanceActions: [MaintenanceAction.SerializedInfo]?
		var showsMaintenanceButton: Bool?
		var additionalInfos: DeviceAdditionalInfoDictionary?
	}
	public static func deviceDescriptors(decoding jsonData: Data, bundle: Bundle) throws -> [DeviceDescriptor]
	{
		let jsonDecoder = JSONDecoder()
		
		struct ModelNameOnly: Decodable { var modelName: String }
		let allModelNames = try jsonDecoder.decode([ModelNameOnly].self, from: jsonData)
			.map { $0.modelName }
		
		let all = try jsonDecoder.decode([DeviceDescriptor.SerializedInfoContainer].self, from: jsonData)
		var connected: [BaseSerializedInfo] = all.compactMap { if case .base(let base) = $0 { base } else { nil } }
		var overrides: [OverrideSerializedInfo] = all.compactMap { if case .override(let override) = $0 { override } else { nil } }
		while !overrides.isEmpty {
			for (i, override) in Array(overrides).enumerated() {
				if let base = connected.first(where: { $0.modelName == override.baseModelName }) {
					connected.append(override.connected(base: base))
					overrides.remove(at: i)
					break
				}
			}
		}
		return allModelNames
			.compactMap { modelName in connected.first(where: { $0.modelName == modelName }) }
			.filter { !($0.isDisabled ?? false) }
			.map { DeviceDescriptor(from: $0, bundle: bundle) }
	}

	init(from serializedInfo: BaseSerializedInfo, bundle: Bundle)
	{
		var localizedStringTables: [LocalizedStringTable] = [.main, .printModel]; do {
			let bundleTable = LocalizedStringTable(bundle: bundle, name: nil)
			if !localizedStringTables.contains(bundleTable) {
				localizedStringTables.insert(bundleTable, at: 0)
			}
		}
		self.localizedStringTables = localizedStringTables
		
		let modelName = serializedInfo.modelName
		self.modelName = modelName
		localizedName = (serializedInfo.displayName ?? modelName)
		printerType = serializedInfo.printerType
		printVerb = (serializedInfo.printVerb ?? .print)
		colorAbility = serializedInfo.colorAbility.flatMap { ColorAbility(rawValue: $0) } ?? .blackWhite
		colorAbility_objc = colorAbility.rawValue
		headDotCount = serializedInfo.headDotCount ?? 1
		dpi = .init(rawValue: serializedInfo.dpi)
		dpi_objc = dpi.rawValue
		hidesDpi = serializedInfo.hidesDpi ?? false
		
		canvases = serializedInfo.canvases.map { Canvas(from: $0, localizedStringTables: localizedStringTables) }
		
		allowedOffsetBases = serializedInfo.offsetBases.compactMap { OffsetBase(rawValue: $0) }
		_allowedOffsetBases_objc = allowedOffsetBases.map { $0.rawValue }
				
		transportTypes = (serializedInfo.transportTypes ?? ["usb"]).map { TransportType(rawValue: $0)! }
		transportTypes_objc = transportTypes.map { $0.rawValue }
		
		guard !allowedOffsetBases.isEmpty, !canvases.isEmpty else {
			fatalError()
		}
		
		if let maintenanceActionInfos = serializedInfo.maintenanceActions {
			maintenanceActions = maintenanceActionInfos.map { .init(from: $0, localizedStringTables: localizedStringTables) }
		} else {
			maintenanceActions = []
		}
		visibleMaintenanceActions = maintenanceActions.filter { $0.visibility == .visible }
		visibleMaintenanceActionsIncludingDebug = maintenanceActions.filter { $0.visibility != .hidden }

		parameterProperties = serializedInfo.parameterProperties.map {
			switch $0 {
			case let number as DeviceSettingParameter.NumberParameter.SerializedInfo:
				return DeviceSettingParameter.NumberParameter(from: number, localizedStringTables: localizedStringTables)
			case let bool as DeviceSettingParameter.BoolParameter.SerializedInfo:
				return DeviceSettingParameter.BoolParameter(from: bool, localizedStringTables: localizedStringTables)
			case let pick as DeviceSettingParameter.PickParameter.SerializedInfo:
				return DeviceSettingParameter.PickParameter(from: pick, localizedStringTables: localizedStringTables)
			default:
				fatalError()
			}
		}
		
		showsMaintenanceButton = serializedInfo.showsMaintenanceButton ?? true
		
		completionAlertVideoUrl = serializedInfo.completionAlertVideoName.flatMap {
			bundle.url(forResource: $0, withExtension: "mp4")
		}
		
		additionalInfos = serializedInfo.additionalInfos ?? .init()
		
		super.init()
	}
	public func copy(with zone: NSZone? = nil) -> Any { self }
	
	@objc public dynamic let modelName: String
	@objc public dynamic let localizedName: String
	@objc public dynamic let printerType: String
	public var printVerb: PrintVerb
	@objc public dynamic let canvases: [Canvas]
	@nonobjc public let transportTypes: [TransportType]
	@objc(transportTypes) public dynamic let transportTypes_objc: [String]
	@nonobjc public let colorAbility: ColorAbility
	@objc(colorAbility) public dynamic let colorAbility_objc: String
	@objc public dynamic let headDotCount: Int
	@nonobjc public let dpi: Dpi
	@objc(dpi) public dynamic let dpi_objc: CGFloat
	@objc public dynamic let hidesDpi: Bool
	@objc public dynamic let completionAlertVideoUrl: URL?
	public let maintenanceActions: [MaintenanceAction]
	public let visibleMaintenanceActions: [MaintenanceAction]
	public let visibleMaintenanceActionsIncludingDebug: [MaintenanceAction]

	@nonobjc public let allowedOffsetBases: [OffsetBase]
	@objc(allowedOffsetBases) public dynamic let _allowedOffsetBases_objc: [String]
	
	public let additionalInfos: DeviceAdditionalInfoDictionary
	@objc public dynamic let parameterProperties: [DeviceSettingParameter]
	@objc public dynamic let showsMaintenanceButton: Bool
	
	public var localizedStringTables: [LocalizedStringTable]
}

public struct MaintenanceAction
{
	public enum Visibility: String, Decodable
	{
		case visible, hidden, debug
	}
	struct SerializedInfo: Decodable
	{
		let identifier: String
		let visibility: Visibility?
	}
	init(from serializedInfo: SerializedInfo, localizedStringTables: [LocalizedStringTable])
	{
		func getLocalization(for key: String) -> String
		{
			return LocalizedStringTable.preferredLocalizedString(
				forKey: ("MaintenanceAction_" + serializedInfo.identifier + key),
				in: localizedStringTables
			) ?? serializedInfo.identifier
		}
		identifier = serializedInfo.identifier
		visibility = serializedInfo.visibility ?? .visible
		buttonTitle = getLocalization(for: "_buttonTitle")
		progressTitle = getLocalization(for: "_progressTitle")
	}
	init(identifier: String, visibility: Visibility = .visible, buttonTitle: String, progressTitle: String)
	{
		self.identifier = identifier
		self.visibility = visibility
		self.buttonTitle = buttonTitle
		self.progressTitle = progressTitle
	}
	
	public let identifier: String
	public let visibility: Visibility
	public let buttonTitle: String
	public let progressTitle: String
}
extension DeviceDescriptor
{
	public var showsCompletionAlert: Bool { printCompletionMessage != nil }
}
extension DeviceDescriptor
{
	@objc public var printProgressTitle: String
	{
		let localizedKey: String
		switch printVerb {
		case .screenMaking:
			localizedKey = "ScreenMaking"
		default:
			localizedKey = "Print"
		}
		return LocalizedStringTable.printModel.getLocalizedStringOrNull(forKey: ("PrintProgress_title_" + localizedKey)) ?? localizedKey
	}
	@objc public var printButtonTitle: String
	{
		let localizedKey: String
		switch printVerb {
		case .screenMaking:
			if showsCompletionAlert {
				localizedKey = "PrepareScreenMaking"
			} else {
				localizedKey = "StartScreenMaking"
			}
		default:
			localizedKey = "Print"
		}
		return LocalizedStringTable.printModel.getLocalizedStringOrNull(forKey: ("Inspector_Print_PrintButtonTitle_" + localizedKey)) ?? localizedKey
	}
	@objc public var printInspectorOptionsExpanderTitle: String
	{
		let localizedKey: String
		switch printVerb {
		case .screenMaking:
			localizedKey = "ScreenMaking"
		default:
			localizedKey = "Print"
		}
		return LocalizedStringTable.printModel.getLocalizedStringOrNull(forKey: ("Inspector_Print_OptionsExpanderTitle_" + localizedKey)) ?? localizedKey
	}
	@objc public var printMenuItemTitle: String
	{
		let localizedKey: String
		switch printVerb {
		case .screenMaking:
			if showsCompletionAlert {
				localizedKey = "PrepareScreenMaking"
			} else {
				localizedKey = "StartScreenMaking"
			}
		default:
			localizedKey = "Print"
		}
		return LocalizedStringTable.printModel.getLocalizedStringOrNull(forKey: ("Menu_" + localizedKey)) ?? localizedKey
	}
	@objc public var printInspectorPaneTitle: String
	{
		let localizedKey: String
		switch printVerb {
		case .screenMaking:
			localizedKey = "ScreenMaking"
		default:
			localizedKey = "Print"
		}
		return LocalizedStringTable.printModel.getLocalizedStringOrNull(forKey: ("Inspector_Print_Title_" + localizedKey)) ?? localizedKey
	}
	@objc public var overflowAlertMessage: String
	{
		let localizedKey: String
		switch printVerb {
		case .screenMaking:
			localizedKey = "ScreenMaking"
		default:
			localizedKey = "Print"
		}
		return LocalizedStringTable.printModel.getLocalizedStringOrNull(forKey: ("Inspector_ImageLayout_overflowAlertDescription_" + localizedKey)) ?? localizedKey
	}
	@objc public var printCompletionMessage: String?
	{
		LocalizedStringTable.preferredLocalizedString(forKey: ("PrintCompletionAlert_Message_" + modelName), in: localizedStringTables)
	}
	@objc public var printCompletionInformativeText: String?
	{
		LocalizedStringTable.preferredLocalizedString(forKey: ("PrintCompletionAlert_InformativeText_" + modelName), in: localizedStringTables)
	}
}
