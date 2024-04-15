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

public struct LocalizedStringTable: Equatable
{
	public static let main = Self(bundle: .main)
	
	public init(bundle: Bundle, name: String? = nil)
	{
		self.bundle = bundle
		self.name = name
	}
	
	public var bundle: Bundle
	public var name: String?
	
	//MARK: - Localized String
	
	public static func preferredLocalizedString(forKey key: String, in tables: [Self]) -> String?
	{
		tables.lazy.compactMap { $0.getLocalizedStringOrNull(forKey: key) }.first
	}
	public func getLocalizedStringOrNull(forKey key: String) -> String?
	{
		let localizedString = getLocalizedStringOrKey(forKey: key)
		guard (localizedString != key) else { return nil }
		return localizedString
	}
	public func getLocalizedStringOrKey(forKey key: String) -> String
	{
		bundle.localizedString(forKey: key, value: nil, table: name)
	}
	
	//MARK: - Formatted Localized String
	
	public func getLocalizedStringOrNull(forKey key: String, _ formatArguments: CVarArg...) -> String?
	{
		guard let localizedString = getLocalizedStringOrNull(forKey: key) else {
			return nil
		}
		if formatArguments.isEmpty {
			return localizedString
		} else {
			return String(format: localizedString, arguments: formatArguments)
		}
	}
	public func getLocalizedStringOrKey(forKey key: String, _ formatArguments: CVarArg...) -> String
	{
		let localizedString = getLocalizedStringOrKey(forKey: key)
		if formatArguments.isEmpty {
			return localizedString
		} else {
			return String(format: localizedString, arguments: formatArguments)
		}
	}
}
