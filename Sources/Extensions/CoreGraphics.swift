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

import CoreGraphics

public extension CGContext
{
	static func grayOpaqueContext(data: UnsafeMutableRawPointer? = nil, size: Size_px) -> Self
	{
		.init(
			data: data,
			width: size.width,
			height: size.height,
			bitsPerComponent: 8,
			bytesPerRow: size.width,
			space: CGColorSpaceCreateDeviceGray(),
			bitmapInfo: CGBitmapInfo(alphaInfo: .none).rawValue
		)!
	}
	
	func performSavingGState<T>(_ handler: ()->T) -> T
	{
		saveGState()
		defer { restoreGState() }
		
		return handler()
	}
}

public extension CGImage
{
	var grayConvertedPixels: [UInt8]
	{
		var data = [UInt8](repeating: 0x0, count: (width * height))
		let grayContext = CGContext.grayOpaqueContext(data: &data, size: .init(width: width, height: height))
		grayContext.performSavingGState {
			let imageBounds = CGRect(x: 0, y: 0, width: width, height: height)
			grayContext.setFillColor(gray: 1, alpha: 1)
			grayContext.fill(imageBounds)
			grayContext.draw(self, in: imageBounds)
		}
		return data
	}
}

public extension CGSize
{
	var rotated: Self { .init(width: height, height: width) }
	
	func rotatedContainerSize(radians: CGFloat) -> CGSize
	{
		var radians = radians; do {
			radians = radians.remainder(dividingBy: (.pi * 2.0))
			if (radians < 0) {
				radians += (.pi * 2.0)
			}
		}
		if (radians < (.pi * 0.5)) {
			let cosine = cos(radians)
			let sine = sin(radians)
			return .init(
				width: (width * cosine) + (height * sine),
				height: (width * sine) + (height * cosine)
			)
		} else if (radians < .pi) {
			let cosine = cos(radians - (.pi * 0.5))
			let sine = sin(radians - (.pi * 0.5))
			return .init(
				width: (width * sine) + (height * cosine),
				height: (width * cosine) + (height * sine)
			)
		} else if (radians < (.pi * 1.5)) {
			let cosine = cos(radians - .pi)
			let sine = sin(radians - .pi)
			return .init(
				width: (width * cosine) + (height * sine),
				height: (width * sine) + (height * cosine)
			)
		} else {
			let cosine = cos(radians - (.pi * 1.5))
			let sine = sin(radians - (.pi * 1.5))
			return .init(
				width: (width * sine) + (height * cosine),
				height: (width * cosine) + (height * sine)
			)
		}
	}
}

public extension CGBitmapInfo
{
	init(alphaInfo: CGImageAlphaInfo, byteOrder: CGImageByteOrderInfo = .orderDefault)
	{
		self.init(rawValue: (alphaInfo.rawValue | byteOrder.rawValue))
	}
	@available(macOS 10.14, iOS 15, *)
	init(alphaInfo: CGImageAlphaInfo, byteOrder: CGImageByteOrderInfo = .orderDefault, pixelFormat: CGImagePixelFormatInfo)
	{
		self.init(rawValue: (alphaInfo.rawValue | byteOrder.rawValue | pixelFormat.rawValue))
	}
	var alphaInfo: CGImageAlphaInfo
	{
		get { .init(rawValue: (rawValue & Self.alphaInfoMask.rawValue))! }
		mutating set { self = .init(rawValue: ((rawValue & ~Self.alphaInfoMask.rawValue) | newValue.rawValue)) }
	}
	var byteOrderInfo: CGImageByteOrderInfo
	{
		get { .init(rawValue: (rawValue & Self.byteOrderMask.rawValue))! }
		mutating set { self = .init(rawValue: ((rawValue & ~Self.byteOrderMask.rawValue) | newValue.rawValue)) }
	}
	@available(macOS 10.14, iOS 15, *)
	var pixelFormatInfo: CGImagePixelFormatInfo
	{
		get { .init(rawValue: (rawValue & CGImagePixelFormatInfo.mask.rawValue))! }
		mutating set { self = .init(rawValue: ((rawValue & ~CGImagePixelFormatInfo.mask.rawValue) | newValue.rawValue)) }
	}
}

extension CGBitmapInfo: CustomDebugStringConvertible
{
	public var debugDescription: String
	{
		if #available(macOS 10.14, iOS 15, *) {
			return "CGBitmapInfo(alphaInfo: \(alphaInfo.rawValue), byteOrderInfo: \(byteOrderInfo.rawValue), pixelFormatInfo: \(pixelFormatInfo.rawValue))"
		} else {
			return "CGBitmapInfo(alphaInfo: \(alphaInfo.rawValue), byteOrderInfo: \(byteOrderInfo.rawValue))"
		}
	}
}
