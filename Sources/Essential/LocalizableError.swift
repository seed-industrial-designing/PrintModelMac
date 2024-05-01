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

public protocol LocalizableError: LocalizedError
{
	/*required*/ static var errorTypeIdentifier: String { get }
	var codeIdentifier: String { get }
	
	var descriptionFormatArguments: [CVarArg] { get }
	var recoverySuggestionFormatArguments: [CVarArg] { get }
	
	static var table: LocalizedStringTable { get }
}
extension LocalizableError
{
	public var codeIdentifier: String { (Mirror(reflecting: self).children.first?.label ?? String(describing: self)) }
	
	public var descriptionFormatArguments: [CVarArg] { [] }
	public var recoverySuggestionFormatArguments: [CVarArg] { [] }
	
	public var recoverySuggestion: String? { _getMessages(errorTypeIdentifier: Self.errorTypeIdentifier).recoverySuggestion }
	public var errorDescription: String? { _getMessages(errorTypeIdentifier: Self.errorTypeIdentifier).description }
		
	func _getMessages(errorTypeIdentifier: String) -> (description: String, recoverySuggestion: String?)
	{
		let messages = _getRawMessages(errorTypeIdentifier: errorTypeIdentifier)
		var description = messages.description
		if !descriptionFormatArguments.isEmpty {
			description = String(format: description, arguments: descriptionFormatArguments)
		}
		var recoverySuggestion = messages.recoverySuggestion
		if let recoverySuggestion_ = recoverySuggestion, !recoverySuggestionFormatArguments.isEmpty {
			recoverySuggestion = String(format: recoverySuggestion_, arguments: recoverySuggestionFormatArguments)
		}
		return (description: description, recoverySuggestion: recoverySuggestion)
	}
	func _getRawMessages(errorTypeIdentifier: String) -> (description: String, recoverySuggestion: String?)
	{
		let localizedKeyForDomain = ("Error_" + errorTypeIdentifier)
		let localizedKeyBaseForCode = (localizedKeyForDomain + "_" + codeIdentifier)
		
		let table = Self.table
		let description = table.getLocalizedStringOrKey(forKey: localizedKeyBaseForCode)
		if let recoverySuggestion = table.getLocalizedStringOrNull(forKey: (localizedKeyBaseForCode + "_recoverySuggestion")) {
			return (description: description, recoverySuggestion: recoverySuggestion)
		} else {
			if let domainTitle = table.getLocalizedStringOrNull(forKey: localizedKeyForDomain) {
				return (description: domainTitle, recoverySuggestion: description)
			} else {
				return (description: description, recoverySuggestion: nil)
			}
		}
	}
}
extension LocalizableError where Self: RawRepresentable, Self.RawValue == CustomStringConvertible
{
	public var codeIdentifier: String { rawValue.description }
}
