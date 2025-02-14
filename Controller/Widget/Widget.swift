//
//  Widget.swift
//  Widget
//
//  Created by fengtianyu on 2025/2/9.
//

import WidgetKit
import SwiftUI


struct PowerStatusProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> PowerStatusEntry {
        PowerStatusEntry(date: Date(), powerStatus: "未知状态")
    }

    func getSnapshot(in context: Context, completion: @escaping (PowerStatusEntry) -> Void) {
        let entry = PowerStatusEntry(date: Date(), powerStatus: "未知状态")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PowerStatusEntry>) -> Void) {
        // 模拟获取开机状态，实际中需要替换为网络请求
        let currentDate = Date()
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)!
        let status = fetchPowerStatus()
        let entry = PowerStatusEntry(date: currentDate, powerStatus: status)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }

    private func fetchPowerStatus() -> String {
        // 这里可以使用 URLSession 或 Alamofire 等进行网络请求获取状态
        // 示例中简单返回一个固定值，实际需根据服务端接口实现
        return "开机"
    }
}

// 定义小组件的时间线条目
struct PowerStatusEntry: TimelineEntry {
    let date: Date
    let powerStatus: String // 开机状态信息，如 "开机"、"关机"
}


struct PowerStatusWidgetEntryView : View {
    var entry: PowerStatusProvider.Entry
    
    var body: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea()
            VStack {
                let on = entry.powerStatus == "开机"
                HStack {
                    Circle().fill(on ? Color.green : Color.gray)
                        .frame(width: 8)
                    
                    Image(systemName: on ? "laptopcomputer" : "laptopcomputer.slash")
                        .foregroundStyle(.tint)
                        .imageScale(.large)
                }.padding(.bottom, 12)
                
                if on {
                    Button(action: {
                        // 处理关机操作
                        // performShutdown()
                    }) {
                        Text("关机")
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                    }
                }
            }
        }
        .containerBackground(.background, for: .widget)
    }
}

@main
struct PowerStatusWidget: Widget {
    let kind: String = "PowerStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PowerStatusProvider()) { entry in
            PowerStatusWidgetEntryView(entry: entry)
        }
       .configurationDisplayName("开机状态小组件")
       .description("实时显示开机状态并可一键关机")
       .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])

    }
}


#Preview(as: .systemSmall) {
    PowerStatusWidget()
} timeline: {
    PowerStatusEntry(date: .now, powerStatus: "开机")
    PowerStatusEntry(date: .now, powerStatus: "关机")
}
