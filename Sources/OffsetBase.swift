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

public enum OffsetBaseVerticalPosition
{
	case top
	case middle
	case bottom
}
public enum OffsetBaseHorizontalPosition
{
	case left
	case middle
	case right
}

public struct OffsetBase: RawRepresentable, Hashable, Codable
{
	private static let fourCharCodes: [Self: Int32] = [ //for legacy purpose
		.topLeft: .init(fourCharString: "obTL"),
		.top: .init(fourCharString: "obTo"),
		.topRight: .init(fourCharString: "obTR"),
		
		.left: .init(fourCharString: "obLe"),
		.center: .init(fourCharString: "obCe"),
		.right: .init(fourCharString: "obRi"),
		
		.bottomLeft: .init(fourCharString: "obBL"),
		.bottom: .init(fourCharString: "obBo"),
		.bottomRight: .init(fourCharString: "obBR"),
	]
	public init?(rawValue: String)
	{
		switch rawValue {
		case "topLeft":
			self = .topLeft
		case "top":
			self = .top
		case "topRight":
			self = .topRight
		case "left":
			self = .left
		case "center":
			self = .center
		case "right":
			self = .right
		case "bottomLeft":
			self = .bottomLeft
		case "bottom":
			self = .bottom
		case "bottomRight":
			self = .bottomRight
		default:
			return nil
		}
	}
	public init?(fourCharCode: Int32)
	{
		guard let newSelf = Self.fourCharCodes.first(where: { $0.value == fourCharCode })?.key else {
			return nil
		}
		self = newSelf
	}
	public init(positionVertical verticalPosition: OffsetBaseVerticalPosition, horizontal horizontalPosition: OffsetBaseHorizontalPosition)
	{
		self.verticalPosition = verticalPosition
		self.horizontalPosition = horizontalPosition
	}
	public static var topLeft = Self(positionVertical: .top, horizontal: .left)
	public static var top = Self(positionVertical: .top, horizontal: .middle)
	public static var topRight = Self(positionVertical: .top, horizontal: .right)
	
	public static var left = Self(positionVertical: .middle, horizontal: .left)
	public static var center = Self(positionVertical: .middle, horizontal: .middle)
	public static var right = Self(positionVertical: .middle, horizontal: .right)
	
	public static var bottomLeft = Self(positionVertical: .bottom, horizontal: .left)
	public static var bottom = Self(positionVertical: .bottom, horizontal: .middle)
	public static var bottomRight = Self(positionVertical: .bottom, horizontal: .right)
	
	//MARK: - Positions
	
	public var verticalPosition: OffsetBaseVerticalPosition
	public var horizontalPosition: OffsetBaseHorizontalPosition
	
	//MARK: - Localization
	
	public var rawValue: String
	{
		switch (verticalPosition, horizontalPosition) {
		case (.top, .left):
			return "topLeft"
		case (.top, .middle):
			return "top"
		case (.top, .right):
			return "topRight"
		case (.middle, .left):
			return "left"
		case (.middle, .middle):
			return "center"
		case (.middle, .right):
			return "right"
		case (.bottom, .left):
			return "bottomLeft"
		case (.bottom, .middle):
			return "bottom"
		case (.bottom, .right):
			return "bottomRight"
		}
	}
	public var fourCharCode: Int32? { Self.fourCharCodes[self] }
	
	@available(iOS 13, *)
	@available(macOS 11, *)
	public var systemSymbolName: String
	{
		switch self {
		case .topLeft:
			return "arrow.up.left"
		case .top:
			return "arrow.up"
		case .topRight:
			return "arrow.up.right"
		case .left:
			return "arrow.left"
		case .center:
			return "plus"
		case .right:
			return "arrow.right"
		case .bottomLeft:
			return "arrow.down.left"
		case .bottom:
			return "arrow.down"
		case .bottomRight:
			return "arrow.down.right"
		default:
			fatalError()
		}
	}
	
	public var menuTitle: String
	{
		var shouldContainArrowInTitle = true
		#if os(macOS)
		if #available(macOS 11, *) {
			shouldContainArrowInTitle = false
		}
		#else
		shouldContainArrowInTitle = false
		#endif
		let prefix = (shouldContainArrowInTitle ? "OffsetBase_menuTitle_" : "OffsetBase_menuTitleWithoutArrow_")
		return LocalizedStringTable.printModel.getLocalizedStringOrKey(forKey: (prefix + rawValue))
	}
}
extension OffsetBase: CustomDebugStringConvertible
{
	public var debugDescription: String { rawValue }
}
