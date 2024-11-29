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

public protocol DeviceAdditionalInfo: Decodable
{
	init()
	static var key: String { get }
}
public struct DeviceAdditionalInfoDictionary: Decodable
{
	struct CustomCodingKey: CodingKey
	{
		var stringValue: String
		init(stringValue: String)
		{
			self.stringValue = stringValue
		}
		var intValue: Int? { nil }
		init?(intValue: Int) { nil }
	}
	let keyedContainers: [KeyedDecodingContainer<CustomCodingKey>] //[override, ..., base]
	init()
	{
		self = (try! JSONDecoder().decode(Self.self, from: "{}".data(using: .utf8)!))
	}
	init(keyedContainers: [KeyedDecodingContainer<CustomCodingKey>])
	{
		self.keyedContainers = keyedContainers
	}
	public init(from decoder: Decoder) throws
	{
		keyedContainers = [try decoder.container(keyedBy: CustomCodingKey.self)]
	}
	public func value<T: DeviceAdditionalInfo>(of type: T.Type) throws -> T
	{
		for container in keyedContainers {
			if let result = try container.decodeIfPresent(T.self, forKey: .init(stringValue: T.key)) {
				return result
			}
		}
		fatalError("Could not decode additional info of type \(T.self).")
	}
	public func valueOrDefault<T: DeviceAdditionalInfo>(of type: T.Type) -> T
	{
		(try? value(of: type)) ?? .init()
	}
	
	public func merging(preferring override: Self) -> Self
	{
		.init(keyedContainers: (override.keyedContainers + keyedContainers))
	}
}
