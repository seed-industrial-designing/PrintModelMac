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

public extension Int32
{
	init(fourCharString: String)
	{
		if (fourCharString.count != 4) {
			self = 0
		}
		var result: Int32 = 0
		fourCharString.withCString { charPtr in
			for i in 0..<4 {
				var characterIndex = i
				#if TARGET_RT_BIG_ENDIAN
					characterIndex = (3 - i)
				#endif
				result |= (Int32(charPtr[characterIndex]) << (8 * i))
			}
		}
		self = result
	}
}
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
