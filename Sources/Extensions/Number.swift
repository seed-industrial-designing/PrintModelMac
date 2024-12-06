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

#if !os(Linux)
public extension Int32
{
	init(fourCharString: String)
	{
		guard (fourCharString.count == 4) else {
			self = 0
			return
		}
		guard var codes = fourCharString.cString(using: .ascii)?.prefix(4) else {
			self = 0
			return
		}
		switch UInt32(CFByteOrderGetCurrent()) {
		case CFByteOrderLittleEndian.rawValue:
			codes.reverse()
		default:
			break
		}
		self = codes
			.enumerated()
			.reduce(Int32(0)) { (currentResult, character) in
				(currentResult | (Int32(character.element) << (8 * character.offset)))
			}
	}
}
#endif

public extension FixedWidthInteger
{
	init(upper: UInt8, lower: UInt8) { self = ((Self(upper) << 8) | Self(lower)) }
}
public extension Int16
{
	var upperByte: UInt8 { .init(self >> 8) }
	var lowerByte: UInt8 { .init(self & 0xFF) }
}
public extension FixedWidthInteger
{
	func hasBitFlag(at index: Int) -> Bool { ((self & (1 << index)) != 0) }
}
