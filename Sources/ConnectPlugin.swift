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
#if os(macOS)
import AppKit
#endif

public protocol ConnectPlugin
{
	var deviceDescriptorsJson: String { get }
	
	func newConnection(for deviceDescriptor: DeviceDescriptor, transportType: TransportType) -> DeviceConnection?
	
	#if os(macOS)
	func makeDialog(of maintenanceAction: MaintenanceAction, for deviceDescriptor: DeviceDescriptor, transportType: TransportType) -> NSViewController?
	#endif
	
	static var bundle: Bundle { get }
	var localizedStringTable: LocalizedStringTable { get }
}
public extension ConnectPlugin
{
	var deviceDescriptors: [DeviceDescriptor]
	{
		try! DeviceDescriptor.deviceDescriptors(decoding: deviceDescriptorsJson.data(using: .utf8)!, bundle: Self.bundle)
	}
	
	var localizedStringTable: LocalizedStringTable { .init(bundle: Self.bundle) }
	
	#if os(macOS)
	func makeDialog(of maintenanceAction: MaintenanceAction, for deviceDescriptor: DeviceDescriptor, transportType: TransportType) -> NSViewController? { nil }
	#endif
}
