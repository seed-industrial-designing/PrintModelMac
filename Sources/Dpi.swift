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

public struct Dpi: RawRepresentable
{
	public typealias RawValue = CGFloat
	public var rawValue: CGFloat
	
	public init(rawValue: RawValue)
	{
		self.rawValue = rawValue
	}
	
	public func mm(fromImagePx imagePx: Int) -> CGFloat
	{
		return (round((CGFloat(imagePx) / rawValue) * 25.4 * 10.0) / 10.0)
	}
	public func mm(fromImagePx size_px: Size_px) -> CGSize
	{
		return .init(width: mm(fromImagePx: size_px.width), height: mm(fromImagePx: size_px.height))
	}
	public func mm(fromImagePx rect_px: CGRect) -> CGRect
	{
		return .init(x: mm(fromImagePx: Int(rect_px.origin.x)), y: mm(fromImagePx: Int(rect_px.origin.y)), width: mm(fromImagePx: Int(rect_px.size.width)), height: mm(fromImagePx: Int(rect_px.size.height)))
	}
	public func imagePx(fromMm mm: CGFloat) -> Int
	{
		return .init(round(rawValue * (mm / 25.4)))
	}
	public func imagePx(fromMm point_mm: CGPoint) -> (x: Int, y: Int)
	{
		return (x: imagePx(fromMm: point_mm.x), y: imagePx(fromMm: point_mm.y))
	}
	public func imagePx(fromMm mm: CGSize) -> Size_px
	{
		return .init(width: imagePx(fromMm: mm.width), height: imagePx(fromMm: mm.height))
	}
	public func imagePx(fromMm rect_mm: CGRect) -> (origin: (x: Int, y: Int), size: Size_px)
	{
		return (origin: imagePx(fromMm: rect_mm.origin), size: imagePx(fromMm: rect_mm.size))
	}
}
extension Dpi: CustomStringConvertible
{
	public var description: String { .init(format: "%g dpi", rawValue) }
}
extension Dpi: Equatable
{
	public static func == (lhs: Dpi, rhs: Dpi) -> Bool { lhs.rawValue == rhs.rawValue }
}
extension Dpi: Comparable
{
	public static func < (lhs: Dpi, rhs: Dpi) -> Bool { lhs.rawValue < rhs.rawValue }
}
