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
import AppKit
#else
import UIKit
#endif
import Accelerate.vImage
import UniformTypeIdentifiers

/// We had been happy with `NSImage` for a long time. So considered using `UIImage` as an equivalent on UIKit.
/// But `UIImage` is useless since it can not draw PDF files as vector images.
/// `UIGraphicsImageRenderer` seems similar but it generates rasterized `UIImage`.
/// This `Drawing` class provides similar function to `NSImage(size:flipped:drawingHandler:)`.
struct Drawing
{
	var size: CGSize
	var drawingHandler: ((CGContext) -> Void)
	
	func draw(in rect: CGRect, context: CGContext, flipContext: Bool)
	{
		context.saveGState(); defer { context.restoreGState() }
		
		if flipContext {
			context.translateBy(x: 0, y: rect.height)
			context.scaleBy(x: 1, y: -1)
		}
		context.scaleBy(x: (rect.width / size.width), y: (rect.height / size.height))
		context.translateBy(x: rect.minX, y: rect.minY)
		
		drawingHandler(context)
	}
}

private enum _OriginalSizeInfo: Equatable
{
	case px(size: Size_px)
	case mm(size: CGSize) //x.xx
}

public enum OriginalImageError: LocalizableError
{
	public static var errorTypeIdentifier = "OriginalImage"
	public static var table: LocalizedStringTable = .printModel
	
	case containsNoValidImage(name: String)
	
	//MARK: - Format Arguments
	
	public var descriptionFormatArguments: [CVarArg]
	{
		switch self {
		case .containsNoValidImage(name: let name):
			return [name]
		}
	}
	public var recoverySuggestionFormatArguments: [CVarArg]
	{
		switch self {
		case .containsNoValidImage(name: let name):
			return [name]
		}
	}
}

@objc(OriginalImage)
public final class OriginalImage: NSObject, NSCopying
{
	//MARK: - Image File Types
	
	#if os(macOS)
	public static var imageFileTypes = (NSImage.imageTypes + ["com.adobe.illustrator.ai-image"])
	#endif
	
	@available(macOS 11, iOS 14, *) public static let imageFileUTTypes: [UTType] = [
		.bmp, .heic, .jpeg, .png, .gif, .pdf, .init("com.adobe.illustrator.ai-image")
	].compactMap { $0 }
	
	//MARK: - Properties
	
	@objc public dynamic let data: Data
	@objc public dynamic let fileURL: URL
	private let drawing: Drawing
	
	@objc public let cgImage: CGImage? //only available for bitmap images.
	
	@objc public var fileName: String { fileURL.lastPathComponent }
	@objc public var filePath: String { fileURL.path }
	
	@objc(vector) public dynamic let isVector: Bool
	@objc public dynamic let widthPerHeight: CGFloat
	
	//MARK: - Init
	
	//If image is invalid, initializers return nil.
	public convenience init?(contentsOfURL fileURL: URL)
	{
		if let data = try? Data(contentsOf: fileURL) {
			self.init(data: data, fileURL: fileURL)
		} else {
			return nil
		}
	}
	public func copy(with zone: NSZone? = nil) -> Any
	{
		return self
	}
	
	public init?(cgImage cgImage_: CGImage, data data_: Data, fileURL fileURL_: URL, exifOrientation: CGImagePropertyOrientation = .up)
	{
		data = data_
		fileURL = fileURL_

		let storedCgImage: CGImage
		if #available(macOS 10.15, iOS 15, *) {
			storedCgImage = Self.rotatedCgImage(cgImage_, exifOrientation: exifOrientation) ?? cgImage_
		} else {
			storedCgImage = cgImage_
		}
		let size_px = Size_px(width: storedCgImage.width, height: storedCgImage.height)
		guard ((size_px.width > 0) && (size_px.height > 0)) else { return nil }
		
		cgImage = storedCgImage
		drawing = .init(size: .init(width: size_px.width, height: size_px.height)) { context in
			context.draw(storedCgImage, in: .init(x: 0, y: 0, width: size_px.width, height: size_px.height))
		}
		imageOriginalSizeInfo = .px(size: size_px)
		widthPerHeight = (.init(size_px.width) / .init(size_px.height))
		isVector = false
		super.init()
		return
	}
	public init?(pdfPage: CGPDFPage, data: Data, fileURL: URL)
	{
		self.data = data
		self.fileURL = fileURL
		
		let pdfBox = CGPDFBox.trimBox
		let pageBoxRect_pt = pdfPage.getBoxRect(pdfBox)
		let transform = pdfPage.getDrawingTransform(pdfBox, rect: CGRect(origin: .zero, size: pageBoxRect_pt.size), rotate: 0, preserveAspectRatio: true)
		
		drawing = .init(size: pageBoxRect_pt.size) { context in
			context.saveGState(); defer { context.restoreGState() }
			
			context.concatenate(transform)
			context.drawPDFPage(pdfPage)
		}
		
		var size_mm = pageBoxRect_pt.size; do {
			//Convert to inch
			size_mm.width /= 72.0
			size_mm.height /= 72.0
			
			//Convert to mm
			size_mm.width *= 25.4
			size_mm.height *= 25.4
			
			size_mm.width = (round(size_mm.width * 10.0) / 10.0)
			size_mm.height = (round(size_mm.height * 10.0) / 10.0)
		}
		imageOriginalSizeInfo = .mm(size: size_mm)
		
		if ((size_mm.width > 0.0) && (size_mm.height > 0.0)) {
			widthPerHeight = (size_mm.width / size_mm.height)
			isVector = true
			cgImage = nil
			super.init()
			return
		} else {
			return nil
		}
	}
	public convenience init?(data: Data, fileURL: URL) //Used for SOS document loading.
	{
		guard
			!data.isEmpty,
			let dataProvider = CGDataProvider(data: data as CFData)
			else { return nil }
		
		if let cgImageSource = CGImageSourceCreateWithDataProvider(dataProvider, nil) {
			let imageIndex: Int
			if #available(macOS 10.14, iOS 15, *) {
				imageIndex = CGImageSourceGetPrimaryImageIndex(cgImageSource)
			} else {
				imageIndex = 0
			}
			var exifOrientation: CGImagePropertyOrientation?; do {
				if let properties = CGImageSourceCopyPropertiesAtIndex(cgImageSource, imageIndex, nil) as? [CFString: Any] {
					exifOrientation = ((properties[kCGImagePropertyOrientation] as? NSNumber)?.uint32Value).flatMap { CGImagePropertyOrientation(rawValue: $0) }
				}
			}
			if let cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, imageIndex, [:] as CFDictionary) {
				self.init(cgImage: cgImage, data: data, fileURL: fileURL, exifOrientation: (exifOrientation ?? .up))
				return
			}
		}
		if let pdfDocument = CGPDFDocument(dataProvider) {
			if let pdfPage = pdfDocument.page(at: 1) {
				self.init(pdfPage: pdfPage, data: data, fileURL: fileURL)
				return
			}
		}
		return nil
	}
	@MainActor
	@available(macOS 11, iOS 15, *)
	public static func make(with itemProvider: NSItemProvider) async throws -> Self
	{
		let preferredUtTypes = Self.imageFileUTTypes
		var name = (itemProvider.suggestedName ?? "Dropped")
		if name.isEmpty {
			name = UUID().uuidString
		} else {
			name = name.replacingOccurrences(of: "/", with: "-")
		}
		
		let utTypes = preferredUtTypes.filter { itemProvider.hasItemConformingToTypeIdentifier($0.identifier) }
		for utType in utTypes {
			var progress: Progress?
			let data = try await itemProvider.loadDataRepresentation(forTypeIdentifier: utType.identifier, progress: &progress)
			
			let url: URL
			if let preferredFilenameExtension = utType.preferredFilenameExtension {
				if name.hasSuffix("." + preferredFilenameExtension) {
					url = .init(fileURLWithPath: name)
				} else {
					url = .init(fileURLWithPath: [name, preferredFilenameExtension].compactMap { $0 }.joined(separator: "."))
				}
			} else {
				url = .init(fileURLWithPath: name)
			}
			print("URLRLRL: \(url)")
			
			guard
				let originalImage = Self(data: data, fileURL: url)
				else { break }
			
			return originalImage
		}
		throw OriginalImageError.containsNoValidImage(name: name)
	}
	
	//MARK: - Description
	
	override public var description: String
	{
		"OriginalImage<\(Unmanaged.passUnretained(self).toOpaque())>(\(fileURL.lastPathComponent))"
	}
	
	//MARK: - Size
	
	public func size_mm(dpi: Dpi) -> CGSize
	{
		switch imageOriginalSizeInfo {
		case .px(size: let size_px):
			return dpi.mm(fromImagePx: size_px)
		case .mm(size: let size_mm):
			return size_mm
		}
	}
	public func size_px(dpi: Dpi) -> Size_px
	{
		switch imageOriginalSizeInfo {
		case .px(size: let size_px):
			return size_px
		case .mm(size: let size_mm):
			return dpi.imagePx(fromMm: size_mm)
		}
	}
	public func isSameSize(to other: OriginalImage?) -> Bool
	{
		(other?.imageOriginalSizeInfo == imageOriginalSizeInfo)
	}
	
	//MARK: - Drawing
	
	public func draw(in destinationRect: CGRect, context: CGContext, flipContext: Bool = false)
	{
		drawing.draw(in: destinationRect, context: context, flipContext: flipContext)
	}
	public func draw(in rect: CGRect, orientation: ImageRotation, flipHorizontal: Bool, context: CGContext, flipContext: Bool = false)
	{
		context.saveGState(); defer { context.restoreGState() }
		
		var imageRectForRotation = rect
		if flipHorizontal {
			context.translateBy(x: (rect.origin.x + rect.size.width), y: rect.origin.y)
			if orientation.isWidthHeightFlipped {
				context.scaleBy(x: 1.0, y: -1.0)
			} else {
				context.scaleBy(x: -1.0, y: 1.0)
			}
			switch orientation {
			case .none:
				break
			case .r90:
				let width = imageRectForRotation.size.width
				imageRectForRotation.size.width = imageRectForRotation.size.height
				imageRectForRotation.size.height = width
				context.translateBy(x: 0.0, y: -imageRectForRotation.size.width)
			case .r180:
				context.translateBy(x: imageRectForRotation.size.width, y: imageRectForRotation.size.height)
			case .r270:
				let width = imageRectForRotation.size.width
				imageRectForRotation.size.width = imageRectForRotation.size.height
				imageRectForRotation.size.height = width
				context.translateBy(x: -imageRectForRotation.size.height, y: 0.0)
			}
			context.rotate(by: orientation.radians)
		} else {
			context.translateBy(x: imageRectForRotation.origin.x, y: imageRectForRotation.origin.y)
			switch orientation {
			case .none:
				break
			case .r90:
				let width = imageRectForRotation.size.width
				imageRectForRotation.size.width = imageRectForRotation.size.height
				imageRectForRotation.size.height = width
				context.translateBy(x: imageRectForRotation.size.height, y: 0.0)
			case .r180:
				context.translateBy(x: imageRectForRotation.size.width, y: imageRectForRotation.size.height)
			case .r270:
				let width = imageRectForRotation.size.width
				imageRectForRotation.size.width = imageRectForRotation.size.height
				imageRectForRotation.size.height = width
				context.translateBy(x: 0.0, y: imageRectForRotation.size.width)
			}
			context.rotate(by: orientation.radians)
		}
		draw(
			in: CGRect(origin: .zero, size: imageRectForRotation.size),
			context: context,
			flipContext: flipContext
		)
	}
	
	//MARK: - Size Info Text
	
	public func sizeInfoText(dpi: Dpi?) -> String
	{
		switch imageOriginalSizeInfo {
		case .px(size: let size_px):
			if let dpi {
				let size_mm = dpi.mm(fromImagePx: size_px)
				return LocalizedStringTable.printModel.getLocalizedStringOrNull(forKey: "OriginalImage_imageSizeDescriptionFormat_pxmm", size_px.width, size_px.height, size_mm.width, size_mm.height)!
			} else {
				return String(format: "%li × %li px", arguments: [size_px.width, size_px.height])
			}
		case .mm(size: let size_mm):
			return String(format: "%.1f × %.1f mm", arguments: [size_mm.width, size_mm.height])
		}
	}
	
	private var imageOriginalSizeInfo: _OriginalSizeInfo
	
	//MARK: - Rotating CGImage
	
	private struct OrientationApplyingInfo
	{
		enum FlipType { case vertical, horizontal }
		var flipType: FlipType?
		var vImageRotation = kRotate0DegreesClockwise
		
		init?(for exifOrientation: CGImagePropertyOrientation)
		{
			switch exifOrientation {
			case .up:
				return nil
			case .upMirrored:
				flipType = .horizontal
			case .down:
				vImageRotation = kRotate180DegreesClockwise
			case .downMirrored:
				flipType = .vertical
			case .leftMirrored:
				flipType = .vertical
				vImageRotation = kRotate270DegreesClockwise
			case .right:
				vImageRotation = kRotate90DegreesClockwise
			case .rightMirrored:
				flipType = .vertical
				vImageRotation = kRotate90DegreesClockwise
			case .left:
				vImageRotation = kRotate270DegreesClockwise
			}
		}
	}
	@available(macOS 10.15, iOS 15, *)
	private static func rotatedCgImage(_ cgImage: CGImage, exifOrientation: CGImagePropertyOrientation) -> CGImage?
	{
		guard let applyingInfo = OrientationApplyingInfo(for: exifOrientation) else { return nil }
		do {
			struct Operation
			{
				var destinationFormat: vImage_CGImageFormat
				var flipHandler: ((_ src: inout vImage_Buffer, _ dst: inout vImage_Buffer) -> Void)? = nil
				var rotateHandler: ((_ src: inout vImage_Buffer, _ dst: inout vImage_Buffer) -> Void)? = nil
			}
			var operation: Operation
			switch cgImage.colorSpace?.model {
			case .monochrome:
				operation = .init(destinationFormat: vImage_CGImageFormat(
					bitsPerComponent: 8,
					bitsPerPixel: 8,
					colorSpace: CGColorSpaceCreateDeviceGray(),
					bitmapInfo: .init(alphaInfo: .none)
				)!)
				switch applyingInfo.flipType {
				case .vertical:
					operation.flipHandler = { (sourceVImage, destinationVImage) in
						vImageVerticalReflect_Planar8(&sourceVImage, &destinationVImage, .zero)
					}
				case .horizontal:
					operation.flipHandler = { (sourceVImage, destinationVImage) in
						vImageHorizontalReflect_Planar8(&sourceVImage, &destinationVImage, .zero)
					}
				case .none:
					break
				}
				if (applyingInfo.vImageRotation != kRotate0DegreesClockwise) {
					operation.rotateHandler = { (sourceVImage, destinationVImage) in
						vImageRotate90_Planar8(&sourceVImage, &destinationVImage, UInt8(applyingInfo.vImageRotation), 255, .zero)
					}
				}

			default:
				let hasAlpha = ([.premultipliedFirst, .premultipliedLast, .first, .last] as [CGImageAlphaInfo])
					.contains(cgImage.alphaInfo)
				
				operation = .init(destinationFormat: vImage_CGImageFormat(
					bitsPerComponent: 8,
					bitsPerPixel: (8 * 4),
					colorSpace: CGColorSpaceCreateDeviceRGB(),
					bitmapInfo: .init(alphaInfo: (hasAlpha ? .last : .noneSkipLast), byteOrder: .orderDefault)
				)!)
				switch applyingInfo.flipType {
				case .vertical:
					operation.flipHandler = { (sourceVImage, destinationVImage) in
						vImageVerticalReflect_ARGB8888(&sourceVImage, &destinationVImage, .zero)
					}
				case .horizontal:
					operation.flipHandler = { (sourceVImage, destinationVImage) in
						vImageVerticalReflect_ARGB8888(&sourceVImage, &destinationVImage, .zero)
					}
				case .none:
					break
				}
				if (applyingInfo.vImageRotation != kRotate0DegreesClockwise) {
					operation.rotateHandler = { (sourceVImage, destinationVImage) in
						var white: [UInt8] = [255, 255, 255, 255]
						vImageRotate90_ARGB8888(&sourceVImage, &destinationVImage, UInt8(applyingInfo.vImageRotation), &white, .zero)
					}
				}
			}
			var destinationFormat = operation.destinationFormat
			
			guard let originalFormat = vImage_CGImageFormat(cgImage: cgImage) else { return nil }
			
			var colorConvertedVImage = try vImage_Buffer(
				width: cgImage.width,
				height: cgImage.height,
				bitsPerPixel: destinationFormat.bitsPerPixel
			)
			try vImageConverter.make(
				sourceFormat: originalFormat,
				destinationFormat: destinationFormat
			).convert(
				source: try vImage_Buffer(cgImage: cgImage, format: originalFormat),
				destination: &colorConvertedVImage
			)
			var flippedImage: vImage_Buffer
			if let flipHandler = operation.flipHandler {
				flippedImage = try vImage_Buffer(
					width: cgImage.width,
					height: cgImage.height,
					bitsPerPixel: destinationFormat.bitsPerPixel
				)
				flipHandler(&colorConvertedVImage, &flippedImage)
			} else {
				flippedImage = colorConvertedVImage
			}
			var rotatedSize = Size_px(width: cgImage.width, height: cgImage.height); do {
				if [kRotate90DegreesClockwise, kRotate270DegreesClockwise].contains(applyingInfo.vImageRotation) {
					rotatedSize = rotatedSize.rotated
				}
			}
			var error = vImage_Error.zero
			var rotatedImage: vImage_Buffer
			if let rotateHandler = operation.rotateHandler {
				rotatedImage = try vImage_Buffer(
					width: rotatedSize.width,
					height: rotatedSize.height,
					bitsPerPixel: destinationFormat.bitsPerPixel
				)
				rotateHandler(&flippedImage, &rotatedImage)
			} else {
				rotatedImage = flippedImage
			}
			return vImageCreateCGImageFromBuffer(&rotatedImage, &destinationFormat, nil, nil, .zero, &error)?.takeRetainedValue()
		} catch let rotationError { print("OriginalImage: couldn't rotate image. \(rotationError)") }
		return nil
	}
}

