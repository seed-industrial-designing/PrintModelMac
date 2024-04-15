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

public enum ImageRotation: Int, Codable
{
	case none, r90, r180, r270
	
	//MARK: - Rotating
	
	public var rotatedClockwise: Self
	{
		switch self {
		case .none: return .r90
		case .r90: return .r180
		case .r180: return .r270
		case .r270: return .none
		}
	}
	public var rotatedCounterclockwise: Self
	{
		switch self {
		case .none: return .r270
		case .r90: return .none
		case .r180: return .r90
		case .r270: return .r180
		}
	}
	public mutating func rotateClockwise() { self = rotatedClockwise }
	public mutating func rotateCounterclockwise() { self = rotatedCounterclockwise }
	
	public var isWidthHeightFlipped: Bool { [.r90, .r270].contains(self) }
	
	//MARK: - Reversing
	
	public var reversed: Self
	{
		switch self {
		case .none: return .none
		case .r90: return .r270
		case .r180: return .r180
		case .r270: return .r90
		}
	}
	
	//MARK: - Angles
	
	public var degrees: CGFloat
	{
		switch self {
		case .none: return 0
		case .r90: return 90
		case .r180: return 180
		case .r270: return 270
		}
	}
	public var radians: CGFloat
	{
		switch self {
		case .none: return 0
		case .r90: return (.pi * 0.5)
		case .r180: return .pi
		case .r270: return (.pi * 1.5)
		}
	}
}
