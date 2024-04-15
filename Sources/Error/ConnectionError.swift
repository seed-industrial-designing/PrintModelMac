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

public enum ConnectionError: LocalizableError
{
	public static var errorTypeIdentifier = "connection"
	public static var table: LocalizedStringTable = .printModel
	
	//MARK: - Document related
	case incorrectDeviceModel
	case noDeviceModelInDocument
	case noImageInDocument
	case documentImageIsTooSmall
	case documentImageIsNotInCanvas
	
	//MARK: - Printer related
	case couldNotGetPrinterStatus
	case receivedInvalidData
	case printerIsBusy
	case headIsTooHighTemperature(preferredTemperature: Int, currentTemperature: Int)
	
	//MARK: - User related
	case userCancelled
	case scriptingPrintIsNotAllowedByUser
	
	//MARK: - Format Arguments
	
	public var descriptionFormatArguments: [CVarArg]
	{
		switch self {
		case .headIsTooHighTemperature(_, let currentTemperature):
			return [currentTemperature]
		default:
			return []
		}
	}
	public var recoverySuggestionFormatArguments: [CVarArg]
	{
		switch self {
		case .headIsTooHighTemperature(let preferredTemperature, _):
			return [preferredTemperature]
		default:
			return []
		}
	}
}
