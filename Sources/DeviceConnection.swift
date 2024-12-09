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
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

import PipeModel

extension UInt8
{
	public static func charCode(_ character: Character) -> Self { character.asciiValue! }
	public static var stx: Self { 0x02 }
	public static var etx: Self { 0x03 }
	public static var ack: Self { 0x06 }
	public static var nak: Self { 0x15 }
	public static var esc: Self { 0x1B }
}
public enum DeviceStatusElement: Equatable
{
	static let dateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.locale = .init(identifier: "en_US_POSIX")
		dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
		return dateFormatter
	}()
	
	case dateTime(date: Date)
	case app(value: String)
	@available(iOS, unavailable) case mac(value: String)
	@available(iOS, unavailable) case macOs(value: String)
	case error(error: NSError)
	case alert(error: NSError)

	case modelName(value: String)
	case firmware(value: String)
	case serial(value: String)
	
	case headTemperature(celsius: Int)
	case foilTemperature(celsius: Int)
	case motorTemperature(celsius: Int)
	case colorInkStatus(status: String)
	case blackInkStatus(status: String)
	case remainingColorInk(factor: CGFloat)
	case remainingBlackInk(factor: CGFloat)
	
	public static let colonSeparator = LocalizedStringTable.printModel.getLocalizedStringOrNull(forKey: "DeviceStatusElement_ColonSeparator")!
	
	public var localizedLabel: String { String(describing: self).split(separator: "(").first.map { LocalizedStringTable.printModel.getLocalizedStringOrNull(forKey: ("DeviceStatusElement_Label_" + $0)) ?? .init($0) } ?? "Unknown" }
	public var localizedValue: String
	{
		switch self {
		case .dateTime(let date):
			return DeviceStatusElement.dateFormatter.string(from: date)
		case .app(let value), .mac(let value), .macOs(let value):
			return value
		case .error(let error), .alert(let error):
			let texts = [error.localizedDescription, (error as NSError).localizedRecoverySuggestion]
			return texts
				.compactMap { $0 }
				.filter { !$0.isEmpty }
				.map { "\"" + $0 + "\"" }
				.joined(separator: " ")
		
		case .modelName(let value), .firmware(let value), .serial(let value):
			return value
			
		case .headTemperature(let celsius), .foilTemperature(let celsius), .motorTemperature(let celsius):
			return "\(celsius)℃"
		case .colorInkStatus(let status), .blackInkStatus(let status):
			return status
		case .remainingColorInk(let factor), .remainingBlackInk(let factor):
			return "\(round(factor * 100.0))%"
		}
	}
	
	public enum IconAsset: String, CaseIterable, Equatable
	{
		case timeTemplate
		case applicationTemplate
		case computerTemplate
		case osTemplate
		case infoTemplate
		case alertTemplate
		case temperatureTemplate
		case inkColor
		case inkBlack
		
		#if os(macOS)
		var imageName: NSImage.Name { "Status" + rawValue.uppercased(onlyFirstCharacter: true) }
		#endif
		
		@available(iOS 15, macOS 11, *)
		public var systemImageName: String
		{
			switch self {
			case .timeTemplate:
				"clock"
			case .applicationTemplate:
				"app"
			case .computerTemplate:
				#if canImport(AppKit)
				"display"
				#elseif canImport(UIKit)
				switch UIDevice.current.model {
				case "iPad":
					"ipad"
				case "iPod touch":
					"ipodtouch"
				default:
					"iphone"
				}
				#endif
			case .osTemplate:
				#if os(Linux)
				"pc"
				#else
				"\(ProcessInfo().operatingSystemVersion.majorVersion).square"
				#endif
			case .infoTemplate:
				"info.circle"
			case .alertTemplate:
				"exclamationmark.triangle"
			case .temperatureTemplate:
				"thermometer"
			case .inkColor:
				"paintpalette"
			case .inkBlack:
				"drop"
			}
		}
	}
	
	#if os(macOS)
	static var isImagesLoaded = false
	public var icon: NSImage?
	{
		if !DeviceStatusElement.isImagesLoaded {
			for name in IconAsset.allCases {
				let image = Bundle.printModel.image(forResource: name.imageName)
				if (image == nil) {
					NSLog("IMAGE NOT LOADED for \(name.rawValue)")
				}
				image?.setName(name.imageName)
			}
			DeviceStatusElement.isImagesLoaded = true
		}
		return NSImage(named: iconAsset.imageName)
	}
	#endif
	public var iconAsset: IconAsset
	{
		switch self {
		case .dateTime(_):
			return .timeTemplate
		case .app(_):
			return .applicationTemplate
		case .mac(_):
			return .computerTemplate
		case .macOs(_):
			return .osTemplate
		case .error(_), .alert(_):
			return .alertTemplate
		case .modelName(_), .firmware(_), .serial(_):
			return .infoTemplate
			
		case .headTemperature(_), .foilTemperature(_), .motorTemperature(_):
			return .temperatureTemplate
		case .colorInkStatus(_), .remainingColorInk(_):
			return .inkColor
		case .blackInkStatus(_), .remainingBlackInk(_):
			return .inkBlack
		}
	}
}

open class DeviceConnection
{
	public typealias PrintCompletionResult = Result<Void, Error>
	public typealias DeviceOpeningHandlerResult = Result<Void, Error>
	
	public var communicator: (any DeviceCommunicator)!
	public var transportType: TransportType!
	
	public var deviceDescriptor: DeviceDescriptor
	public required init(deviceDescriptor: DeviceDescriptor, transportType: TransportType)
	{
		self.deviceDescriptor = deviceDescriptor
		self.transportType = transportType
	}
	open func print(_ task: PrintTask, progress: Progress) async throws
	{
		
	}
	open func performMaintenanceAction(_ maintenanceAction: MaintenanceAction, progress: Progress) async throws
	{
		
	}
	public func getStatus(progress: Progress) async -> (elements: [DeviceStatusElement], error: Error?)
	{
		let deviceDescriptor = self.deviceDescriptor
		var status: [DeviceStatusElement] = []
		var returnedError: Error?
		do {
			let context = try await openDevice(progress: progress)
			status = try await _getStatusElements(context: context)
		} catch let error {
			returnedError = error
			status.append(.error(error: (error as NSError)))
		}
		
		let bundle = Bundle.main
		#if os(macOS)
		status.insert(.mac(value: NSWorkspace.shared.macModel), at: 0)
		status.insert(.macOs(value: ProcessInfo().operatingSystemVersionString), at: 0)
		
		let appShortVersion = (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown")
		let appBuildNumber = (bundle.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "unknown")
		status.insert(.app(value: String(format: LocalizedStringTable.printModel.getLocalizedStringOrNull(forKey: "DeviceStatusElement_Content_app_format")!, appShortVersion, appBuildNumber)), at: 0)
		status.insert(.modelName(value: deviceDescriptor.localizedName), at: 0)
		status.insert(.dateTime(date: Date()), at: 0)
		#endif
		
		return (status, returnedError)
	}
	open func _getStatusElements(context: some DeviceCommunicationContext) async throws -> [DeviceStatusElement] { [] } //subclasses should override!
	
	public func openDevice(progress: Progress) async throws -> any DeviceCommunicationContext
	{
		try await communicator.open(progress: progress)
	}
	
	public func waitAck(context: some DeviceCommunicationContext) async throws
	{
		for _ in 0..<30 {
			let receivedBytes: [UInt8]
			do {
				receivedBytes = try await context.readBytes(length: 1)
			}
			catch let error {
				if let pipeErrorCode = error.pipeErrorCode {
					switch pipeErrorCode {
					case .timeout:
						break
					case .noDevice:
						throw error
					case .couldNotReopen:
						throw error
					default:
						break
					}
				} else {
					#if os(macOS)
					if let ioReturn = error.ioReturn {
						switch ioReturn {
						case kIOReturnNotResponding:
							throw error
						default:
							break
						}
					}
					#endif
				}
				try await Task.sleep(nanoseconds: 500_000_000)
				continue
			}
			switch receivedBytes.first! {
			case .ack:
				Swift.print("received ACK.")
				return
			case .nak:
				Swift.print("received NAK!\n\(Thread.callStackSymbols)")
				throw ConnectionError.receivedInvalidData
			default:
				try await Task.sleep(nanoseconds: 500_000_000)
				continue
			}
		}
		throw NSError(deviceErrorCode: .timeout)
	}
}

#if os(macOS)
extension NSWorkspace
{
	var macModel: String
	{
		var bufferLength = 0
		sysctlbyname("hw.model", nil, &bufferLength, nil, 0)
		
		guard (bufferLength > 0) else { return "Unknown" }
		
		var modelNameBuffer = [CChar].init(repeating: 0, count: bufferLength)
		sysctlbyname("hw.model", &modelNameBuffer, &bufferLength, nil, 0)
		return String(cString: modelNameBuffer, encoding: .utf8) ?? "Unknown"
	}
}
#endif
