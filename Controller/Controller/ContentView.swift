//
//  ContentView.swift
//  Controller
//
//  Created by 冯天宇 on 2025/2/9.
//

import SwiftUI
import Combine
import Network

struct ContentView: View {
    
    @StateObject var viewModel = ControllerViewModel()
    var body: some View {
        VStack {
            HStack {
                Circle().fill(viewModel.isOn ? Color.green : Color.gray)
                    .frame(width: 8)
                
                Image(systemName: viewModel.isOn ? "laptopcomputer" : "laptopcomputer.slash")
                    .foregroundStyle(.tint)
                    .imageScale(.large)
                
                VStack(alignment: .leading) {
                    Text("小困子的iMac")
                        .font(.system(size: 14.0))
                        .foregroundStyle(Color.black.opacity(0.8))
                    Text("192.168.12.1")
                        .font(.system(size: 12.0))
                        .foregroundStyle(Color.black.opacity(0.6))
                }
                Spacer()
                Toggle(isOn: $viewModel.isOn) {
                    
                }
            }
            .padding(.bottom, 12)
            .frame(height: 44.0)
            

        }
        .padding()
    }
}

#Preview {
    ContentView()
}

class ControllerViewModel: ObservableObject {
    @Published var isOn = false
    var scanner = NetworkScanner()
    init(isOn: Bool = false) {
        self.isOn = isOn
//        scan()
        scanner.startScanning()
    }
    
}

class NetworkScanner: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    private var serviceBrowser = NetServiceBrowser()
    var service: NetService?
    
    var ipList: [String] = []
    
    func startScanning() {
        serviceBrowser.delegate = self
        serviceBrowser.searchForServices(ofType: "_http._tcp.", inDomain: "local.")

    }
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        
        print("Found service: \(service.name) \(String(describing: service.addresses))")
            
        self.service = service
        service.delegate = self
        service.resolve(withTimeout: 5)
        
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("Search failed: \(errorDict)")
    }
    // 搜索结束的代理方法
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        print("Search stopped")
    }

    func netService(_ sender: NetService, didResolveAddress addresses: [Data]) {
        print("解析到 IP 地址: \(addresses)")
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("解析失败")
    }
    
    func netServiceWillResolve(_ sender: NetService) {
        print("即将开始解析")
    }
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        print("netServiceDidResolveAddress \(sender.port)")
        guard let datas = sender.addresses else {
            return
        }
        let ips = extractIP(from: datas)
        let ipSet = Set(ips)
    }
    
    func netServiceDidStop(_ sender: NetService) {
        print("netServiceDidStop")
    }
    
    func extractIP(from addresses: [Data]) -> [String] {
        var results: [String] = []

        for addressData in addresses {
            addressData.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) in
                let sockaddrPtr = pointer.baseAddress!.assumingMemoryBound(to: sockaddr.self)

                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(sockaddrPtr, socklen_t(addressData.count), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                    let ipAddress = String(cString: hostname)
                    results.append(ipAddress)
                }
            }
        }

        return results
    }
    
    func dataToIPv6(_ data: Data) -> String? {
        guard data.count == 16 else {
            return nil
        }
        var parts: [String] = []
        for i in stride(from: 0, to: data.count, by: 2) {
            let value = (UInt16(data[i]) << 8) | UInt16(data[i + 1])
            parts.append(String(format: "%x", value))
        }
        return parts.joined(separator: ":")
    }
    
    func dataToIPv4(_ data: Data) -> String? {
//        guard data.count == 4 else {
//            return nil
//        }
        let octets = data.map { String($0) }
        return octets.joined(separator: ".")
    }

}
