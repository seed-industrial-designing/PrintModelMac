//
// PrintModelMac
// Copyright © 2025 Seed Industrial Designing Co., Ltd. All rights reserved.
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

public enum BlackConversion
{
	public struct ThresholdOption: Codable
	{
		enum ClampedValueRanges
		{
			static var threshold = 0.0...1.0
			static var expansionLevel = 0...5
		}
		
		public init() { }
		public var threshold = 0.5
		public var expansionLevel = 0
	}
	public struct HalftoneOption: Codable
	{
		enum ClampedValueRanges
		{
			static var brightnessFactor = -0.6...0.6
			static var blackClampFactor = 0.0...0.4
			static var whiteClampFactor = 0.0...0.4
		}
		
		public init() { }
		public var linesPerInch = 20.0
		public var angle_deg = 30.0
		public var brightnessFactor = 0.0
		public var blackClampFactor = 0.0
		public var whiteClampFactor = 0.0
	}
	
	case threshold(ThresholdOption)
	case halftone(HalftoneOption)
}
public enum BlackConversionType: String, CaseIterable
{
	case threshold
	case halftone
}
