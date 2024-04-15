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

public extension String
{
	var utf8Bytes: [UInt8] { utf8CString.map { UInt8(bitPattern: $0) } }
	var utf8BytesRemovingTerminationCharacter: [UInt8] {
		guard !isEmpty else {
			return []
		}
		let bytes = utf8Bytes
		return [UInt8](utf8Bytes[0...(bytes.count - 2)])
	}
	
	init?(cStringAppendingNullCharacter data: Data, encoding: String.Encoding)
	{
		var bytes = [UInt8](data).map { CChar(bitPattern: $0) } + [CChar(bitPattern: .charCode("\0"))]
		guard let string = String(cString: &bytes, encoding: encoding) else { return nil }
		self = string
	}
	
	func uppercased(onlyFirstCharacter: Bool) -> String //This is not same to .capitalized() which converts non-first characters to lowercased.
	{
		if onlyFirstCharacter {
			let secondCharacterIndex = index(after: startIndex)
			return (self[startIndex...startIndex].uppercased() + self[secondCharacterIndex...])
		} else {
			return uppercased()
		}
	}
	
	var strippingLastDotZero: String
	{
		if hasSuffix(".0") {
			return .init(dropLast(2))
		} else {
			return self
		}
	}
}
