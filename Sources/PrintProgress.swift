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

public enum PrintProgressDescription: String, LocalizedProgressDescription
{
	case processingImage
	case sendingImageData
	case sendingRemainingImageData
	case preparingForScreenMaking
	case preparingDataForImage
	case checkingPrinterStatus
	case settingParametersForScreenMaking
	case settingParametersForPrint
	case movingPrintHead
	case finishingPrint
	case imageDataSendingCompleted
	case startingPrint
	case printing
	case preparingForPrint
	case startingScreenMaking
	case workingScreenMaking
	case sequenceAofB
	case sendingCommand
	case readyToExchangeCartridges

	public var localizedValue: String { LocalizedStringTable.printModel.getLocalizedStringOrNull(forKey: ("PrintProgress_Description_" + rawValue.uppercased(onlyFirstCharacter: true))) ?? rawValue }
}
public enum ScanProgressDescription: String, LocalizedProgressDescription
{
	case moving
	case analyzingImage
	case startingScan
	case scanning
	case finishedScan
	case connectingToScanner
	case turningScannerOff
	case transferringImageFromScanner

	public var localizedValue: String { LocalizedStringTable.printModel.getLocalizedStringOrNull(forKey: ("ScanProgress_Description_" + rawValue.uppercased(onlyFirstCharacter: true))) ?? rawValue }
}

public enum PrintProgressAdditionalDescription: String, LocalizedAdditionalProgressDescription
{
	case clickCancelWhenCartridgeExchangeIsCompleted
	
	public var localizedValue: String { LocalizedStringTable.printModel.getLocalizedStringOrNull(forKey: ("PrintProgress_AdditionalDescription_" + rawValue.uppercased(onlyFirstCharacter: true))) ?? rawValue }
}

public protocol LocalizedProgressDescription
{
	var localizedValue: String { get }
}
public protocol LocalizedAdditionalProgressDescription
{
	var localizedValue: String { get }
}

extension Progress
{
	public func setLocalizedDescription<T: LocalizedProgressDescription>(_ type: T)
	{
		#if os(Linux)
		print(type.localizedValue)
		#else
		localizedDescription = type.localizedValue
		#endif
	}
	public func setLocalizedAdditionalDescription<T: LocalizedAdditionalProgressDescription>(_ type: T)
	{
		#if os(Linux)
		print(type.localizedValue)
		#else
		localizedAdditionalDescription = type.localizedValue
		#endif
	}
}
