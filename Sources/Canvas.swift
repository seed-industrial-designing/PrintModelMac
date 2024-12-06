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
#if os(macOS)
import AppKit.NSImage
#endif

public enum CanvasForm
{
	case plane(size_mm: CGSize)
	case variableCylinder(width_mm: CGFloat, diameterRange_mm: ClosedRange<CGFloat>)
}

#if canImport(ObjectiveC)
@objcMembers
#endif
public class Canvas: NSObject
{
	struct SerializedInfo: Decodable
	{
		let identifier: String
		let size_mm: SizeSerializedInfo
		let figureImageName: String?
		
		struct SizeSerializedInfo: Decodable
		{
			let width: CGFloat
			let height: CGFloat
		}
	}
	init(from serializedInfo: SerializedInfo, localizedStringTables: [LocalizedStringTable])
	{
		identifier = serializedInfo.identifier
		let localizationKey = ("Canvas_" + identifier + "_name")
		name = LocalizedStringTable.preferredLocalizedString(forKey: localizationKey, in: localizedStringTables) ?? serializedInfo.identifier
		size_mm = .init(width: serializedInfo.size_mm.width, height: serializedInfo.size_mm.height)
		
		#if os(macOS)
		if let figureImageName = serializedInfo.figureImageName, !figureImageName.isEmpty {
			if let image = NSImage(named: figureImageName) {
				figureImage = image
			} else if let image = Bundle.printModel.image(forResource: .init(figureImageName)) {
				figureImage = image
			} else {
				figureImage = nil
			}
		} else {
			figureImage = nil
		}
		#endif
		
		super.init()
	}
	public func copy(with zone: NSZone? = nil) -> Any
	{
		return self
	}
	
	//MARK: - Equatable & Hashable
	
	public override func isEqual(_ other: Any?) -> Bool
	{
		if let other = other as? Canvas {
			return ((identifier == other.identifier) && (size_mm == other.size_mm))
		} else {
			return false
		}
	}
	public override var hash: Int
	{
		var hasher = Hasher()
		hasher.combine(identifier)
		hasher.combine(size_mm.width)
		hasher.combine(size_mm.height)
		return hasher.finalize()
	}
	
	//MARK: - Properties
		
	public dynamic var identifier: String
	public dynamic var name: String
	public dynamic var size_mm: CGSize
	#if os(macOS)
	public dynamic var figureImage: NSImage?
	#endif
}

extension Canvas
{
	public var widthPerHeight: CGFloat { size_mm.width / size_mm.height }
	
	public var sizeDescription: String { "\(size_mm.width.description.strippingLastDotZero) × \(size_mm.height.description.strippingLastDotZero) mm" }
}

extension Canvas: Identifiable
{
	public var id: String { "\(identifier)_\(size_mm)" }
}
