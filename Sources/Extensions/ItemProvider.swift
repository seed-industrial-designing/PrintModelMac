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

#if !os(Linux)

import Foundation

public extension NSItemProvider
{
	@available(macOS 11, iOS 15, *)
	func loadDataRepresentation(forTypeIdentifier typeIdentifier: String, progress: inout Progress?) async throws -> Data
	{
		try await withUnsafeThrowingContinuation { continuation in
			progress = loadDataRepresentation(forTypeIdentifier: typeIdentifier) { (data, error) in
				if let data {
					continuation.resume(returning: data)
				} else {
					continuation.resume(throwing: error!)
				}
			}
		}
	}
}

#endif
