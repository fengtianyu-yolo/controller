//
//  ContentView.swift
//  Controller
//
//  Created by 冯天宇 on 2025/2/9.
//

import SwiftUI
import Combine
import Network
import Alamofire

struct ContentView: View {
    
    @StateObject var viewModel = ControllerViewModel()
    
    var body: some View {
        if viewModel.isLoading {
//            ProgressView()
//                .padding()
            VStack {
                Image(systemName: "laptopcomputer")
                    .foregroundStyle(.tint)
                    .imageScale(.large)
                    .padding(.bottom, 12)

                Text("暂未发现设备")
            }
        } else {
            List {
                ForEach(viewModel.devices.indices, id: \.self) { index in
                    let device = viewModel.devices[index]
                    
                    let onBinding = Binding<Bool>(
                        get: {
                            self.viewModel.devices[index].isOn
                        },
                        set: { newValue in
                            self.viewModel.devices[index].isOn = newValue
                            print("click toggle")
                            viewModel.powerOff(ip: device.ip)
                        }
                    )
                    let isOn = self.viewModel.devices[index].isOn
                    HStack {
                        Circle().fill(isOn ? Color.green : Color.gray)
                            .frame(width: 8)
                        
                        Image(systemName: isOn ? "laptopcomputer" : "laptopcomputer.slash")
                            .foregroundStyle(.tint)
                            .imageScale(.large)
                        
                        VStack(alignment: .leading) {
                            Text(device.name)
                                .font(.system(size: 14.0))
                                .foregroundStyle(Color.black.opacity(0.8))
                            Text(device.ip)
                                .font(.system(size: 12.0))
                                .foregroundStyle(Color.black.opacity(0.6))
                        }
                        Spacer()
                        Toggle(isOn: onBinding) {
                        }
                    }
                    .padding(.bottom, 12)
                    .frame(height: 44.0)
                }
            }
        }
        
    }
}

#Preview {
    ContentView()
}

class ControllerViewModel: NSObject, ObservableObject, NetworkScannerDelegate {
    
    @Published var isOn = false
    @Published var devices: [DeviceModel] = []
    @Published var isLoading = true
    
    private var scanner = NetworkScanner()
    
    init(isOn: Bool = false) {
        super.init()
        self.isOn = isOn
        scanner.delegate = self
        scanner.startScanning()
    }
    
    func didResolveAddress(ip: String, name: String) {
        let model = DeviceModel(name: name, ip: ip, isOn: true)
        self.devices.append(model)
        self.isLoading = false
    }

    func powerOff(ip: String) {
        let port = "5001"
        let url = "http://\(ip):\(port)/shutdown"
        AF.request(url).response { response in
            print(response)
        }
    }
}

class DeviceModel: NSObject, ObservableObject, Identifiable {
    var id: String
    @Published var name:String
    @Published var ip: String
    @Published var isOn: Bool

    init(name: String, ip: String, isOn: Bool) {
        self.id = ip
        self.name = name
        self.ip = ip
        self.isOn = isOn
    }
}

protocol NetworkScannerDelegate: NSObject {
    func didResolveAddress(ip: String, name: String)
}

class NetworkScanner: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    
    weak var delegate: NetworkScannerDelegate?
    
    private var serviceBrowser = NetServiceBrowser()
    private var service: NetService?
    private var ipList: Set<String> = []
    private var name: String = ""
    
    func startScanning() {
        serviceBrowser.delegate = self
        print("开始扫描")
        serviceBrowser.searchForServices(ofType: "_http._tcp.", inDomain: "local.")

    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("Found service: \(service.name) \(String(describing: service.addresses))")
        self.name = service.name
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
        self.ipList = ipSet
        if let ip = ipSet.first {
            self.delegate?.didResolveAddress(ip: ip, name: self.name)
        }
    }
    
    func netServiceDidStop(_ sender: NetService) {
        print("netServiceDidStop")
    }
    
    private func extractIP(from addresses: [Data]) -> [String] {
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

}
