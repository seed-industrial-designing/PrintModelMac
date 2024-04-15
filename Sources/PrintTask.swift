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
import CoreGraphics

public enum ImageSource
{
	public struct OriginalImageDrawingOptions
	{
		public init() {}
		
		public var imageBitmapConversionThreshold: CGFloat = 0.5
		public var imageBitmapExpansionLevel = 0
		public var imageOffset_mm = CGPoint.zero
		public var imageSize_px = Size_px.zero
		public var imageOrientation = ImageRotation.none
		public var imageOffsetBase = OffsetBase.center
		public var flipsImageHorizontal = false
		
		public var imageRepeatXCount = 1
		public var imageRepeatYCount = 1
		public var imageRepeatXMargin_mm: CGFloat = 0.0
		public var imageRepeatYMargin_mm: CGFloat = 0.0
		
		public var minimumSeparatedXMargin_mm: CGFloat = 70.0
		public var maximumBlackXLength_mm: CGFloat = 150.0
		public var additionalWhitespaceLength_start_mm: CGFloat = 0.0
		public var additionalWhitespaceLength_end_mm: CGFloat = 0.0

		public var usesMinimumSeparatedXMargin = true
		public var usesMaximumBlackXLength = true
		
		//"ForDisplay" means rotated.
		public var imageSizeForDisplay_px: Size_px { imageOrientation.isWidthHeightFlipped ? imageSize_px.rotated : imageSize_px }
	}
	case originalImage(OriginalImage, options: OriginalImageDrawingOptions)
	case canvasSizedImage(handler: () -> CGImage)
	case rawImageData(handler: () -> Data)
}

public struct PrintTask
{
	public var deviceDescriptor: DeviceDescriptor
	public var canvas: Canvas
	public var transportType: TransportType
	
	public var imageSource: ImageSource

	public var deviceSettingValues: [String: Any] = [:]
	public func deviceSetting(forKey key: String) -> Any
	{
		if let value = deviceSettingValues[key] {
			return value
		}
		return deviceDescriptor.parameterProperties.first(where: { $0.identifier == key })!.default as Any
	}
	
	public init(deviceDescriptor: DeviceDescriptor, canvas: Canvas, transportType: TransportType, imageSource: ImageSource, deviceSettingValues: [String: Any])
	{
		self.deviceDescriptor = deviceDescriptor
		self.canvas = canvas
		self.transportType = transportType
		self.imageSource = imageSource
		self.deviceSettingValues = deviceSettingValues
	}
}
