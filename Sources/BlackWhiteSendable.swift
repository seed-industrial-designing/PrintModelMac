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
import PipeModel

public protocol BlackWhiteSendable { }

public enum BlackWhiteColumnsSendingOption
{
	case reverseRows
	case reverseRowBits
	case reverseColumns
}

extension BlackWhiteSendable where Self: DeviceConnection
{
	public func convert8bitGrayBitmapToBW(bitmapBuffer: UnsafeMutablePointer<UInt8>, size bitmapSize: Size_px, bitmapConversionThreshold_255: UInt8, bitmapExpansionLevel: Int = 0)
	{
		if (bitmapExpansionLevel == 0) {
			for i in 0..<(bitmapSize.width * bitmapSize.height) {
				bitmapBuffer[i] = ((bitmapConversionThreshold_255 < bitmapBuffer[i]) ? 255 : 0)
			}
		} else {
			let expansionLevelIsPositive = (bitmapExpansionLevel > 0)
			let originalBuffer = [UInt8](UnsafeBufferPointer(start: bitmapBuffer, count: (bitmapSize.width * bitmapSize.height)))
			bitmapBuffer.initialize(repeating: (expansionLevelIsPositive ? 255 : 0), count: (bitmapSize.width * bitmapSize.height))

			for y in 0..<bitmapSize.height {
				for x in 0..<bitmapSize.width {
					let pixelIndex = ((y * bitmapSize.width) + x)
					let pixelIsBlack = (originalBuffer[pixelIndex] < bitmapConversionThreshold_255)
					if (expansionLevelIsPositive ? pixelIsBlack : !pixelIsBlack) {
						let setPixel = { (deltaX: Int, deltaY: Int, color: UInt8) in
							let outY = (y + deltaY)
							if (0 <= outY), (outY < bitmapSize.height) {
								let outX = (x + deltaX);
								if (0 <= outX), (outX < bitmapSize.width) {
									bitmapBuffer[(outY * bitmapSize.width) + outX] = color;
								}
							}
						}
						let drawingColor: UInt8 = (expansionLevelIsPositive ? 0 : 255)
						let bitmapExpansionLevel_abs = abs(bitmapExpansionLevel)
						switch bitmapExpansionLevel_abs {
						case 1:
							setPixel(0, 0, drawingColor)
							if ((x % 2) == 0) && ((y % 2) == 0) {
								setPixel(0, -1, drawingColor)
								setPixel(1, 0, drawingColor)
							}
						case 2:
							setPixel(0, 0, drawingColor)
							if ((x % 2) == 0) || ((y % 2) == 0) {
								setPixel(0, -1, drawingColor)
								setPixel(1, 0, drawingColor)
							}
						case 3:
							setPixel(0, 0, drawingColor)
							setPixel(0, -1, drawingColor)
							setPixel(1, 0, drawingColor)
						case 4:
							setPixel(0, -1, drawingColor)
							setPixel(-1, 0, drawingColor)
							setPixel(0, 0, drawingColor)
							setPixel(1, 0, drawingColor)
							setPixel(0, 1, drawingColor)
						case 5:
							let bolderAmount = (bitmapExpansionLevel_abs - 4)
							for deltaX in -bolderAmount...bolderAmount {
								for deltaY in -bolderAmount...bolderAmount {
									setPixel(deltaX, deltaY, drawingColor)
								}
							}
						default:
							break
						}
					}
				}
			}
		}
	}
	
	
	public func sendColumns(of bitmap: CGImage, progress: Progress, option: Set<BlackWhiteColumnsSendingOption>, maxBufferCount: Int = 3200, context: some DeviceCommunicationContext) async throws
	{
		let headDotCount = deviceDescriptor.headDotCount
		
		let sourceBitmapPixels = bitmap.grayConvertedPixels
		
		let columnCount = bitmap.width
		let rowCount = min(headDotCount, bitmap.height)
		
		let dataLengthPerColumn = (headDotCount / 8)
		
		//ヘッドの中央に配置
		let additionalPaddingY_px = ((headDotCount - rowCount) / 2)
		
		var buffer: [UInt8] = []
		buffer.reserveCapacity(maxBufferCount)
		
		for column in 0..<columnCount {
			// 1 カラム分の転送データバッファ（1 bit == 1 dot）
			var txData = [UInt8](repeating: 0x0, count: dataLengthPerColumn); do {
				for row in 0..<rowCount {
					var outputRow = (row + additionalPaddingY_px)
					outputRow = (option.contains(.reverseRows) ? (headDotCount - 1 - outputRow) : outputRow)
					// n 番目のバイト中の m 番目のビット
					let n = (outputRow / 8), m = (option.contains(.reverseRowBits) ? (7 - (outputRow % 8)) : (outputRow % 8));
					
					let pixelLocationInSource: (x: Int, y: Int) = (
						x: (option.contains(.reverseColumns) ? (columnCount - 1 - column) : column),
						y: row
					)
					if (sourceBitmapPixels[(bitmap.width * pixelLocationInSource.y) + pixelLocationInSource.x] < 128) {
						txData[n] |= UInt8(1 << m)
					}
				}
			}
			buffer.append(contentsOf: txData)
			
			let isLastColumn = (column == (columnCount - 1))
			while isLastColumn || (buffer.count >= maxBufferCount) {
				//sleep(forTimeInterval: 0.005)
				do {
					if (buffer.count <= maxBufferCount) {
						try await context.send(buffer)
						buffer.removeAll()
					} else {
						try await context.send(Array(buffer.prefix(maxBufferCount)))
						buffer.removeFirst(maxBufferCount)
					}
				} catch let error {
					NSLog("error sending column \(column + 1)/\(columnCount)")
					throw error
				}
				if isLastColumn && buffer.isEmpty {
					break
				}
			}
			if (column == (columnCount - 1)) || ((column % 20) == 0) {
				let column = column
				DispatchQueue.main.async {
					progress.completedUnitCount = .init(column + 1)
				}
			}
		}
	}
}
