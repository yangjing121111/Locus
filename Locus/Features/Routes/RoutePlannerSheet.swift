import CoreLocation
import SwiftUI

struct RoutePlannerSheet: View {
    @Binding var start: CLLocationCoordinate2D?
    @Binding var end: CLLocationCoordinate2D?
    @Binding var isRouting: Bool
    var onBuild: () -> Void
    var onPlay: () -> Void
    var onImportGPX: () -> Void
    var onExportGPX: () -> Void
    var onUseDrawn: () -> Void

    @EnvironmentObject private var session: SpoofSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("道路路线") {
                    Button("用当前大头针/模拟位置作为起点") {
                        start = session.simulated ?? session.pin
                    }
                    Button("用当前大头针作为终点") {
                        end = session.pin
                    }
                    LabeledContent("起点") {
                        Text(coordText(start)).font(.caption.monospaced())
                    }
                    LabeledContent("终点") {
                        Text(coordText(end)).font(.caption.monospaced())
                    }
                    Button {
                        onBuild()
                    } label: {
                        if isRouting {
                            ProgressView()
                        } else {
                            Label("按道路生成步行/驾车路线", systemImage: "road.lanes")
                        }
                    }
                    .disabled(isRouting)
                }

                Section("播放 / 绘制 / GPX") {
                    Button {
                        onUseDrawn()
                    } label: {
                        Label("使用地图上绘制的路径", systemImage: "pencil.tip")
                    }
                    Button(action: onPlay) {
                        Label("按路线移动", systemImage: "play.fill")
                    }
                    Button(action: onImportGPX) {
                        Label("导入 GPX", systemImage: "square.and.arrow.down")
                    }
                    Button(action: onExportGPX) {
                        Label("导出 GPX", systemImage: "square.and.arrow.up")
                    }
                }

                Section {
                    Text("路线按所选出行方式沿苹果地图的道路/步道生成。速度会有轻微随机变化，让移动看起来更自然。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("路线")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func coordText(_ c: CLLocationCoordinate2D?) -> String {
        guard let c else { return "—" }
        return String(format: "%.5f, %.5f", c.latitude, c.longitude)
    }
}
