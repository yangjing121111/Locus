import Foundation // 引入 Foundation：提供 sin/cos/sqrt/pow 等数学函数
import CoreLocation // 引入 CoreLocation：提供经纬度类型 CLLocationCoordinate2D

/// 中国坐标修正工具：把地图上点选的坐标（GCJ-02，火星坐标）转换为系统定位需要的 WGS-84 坐标
enum ChinaCoordinate { // 用无 case 的枚举当命名空间，不能被实例化
    private static let a = 6378245.0 // 克拉索夫斯基椭球体长半轴（GCJ-02 算法固定参数）
    private static let ee = 0.00669342162296594323 // 椭球偏心率平方（GCJ-02 算法固定参数）

    /// 判断坐标是否在中国大陆范围内（范围外不做偏移，海外直接用原坐标）
    static func isInChina(_ lat: Double, _ lon: Double) -> Bool { // 参数：纬度、经度；返回：是否在中国范围
        return lon > 73.66 && lon < 135.05 && lat > 3.86 && lat < 53.55 // 用经纬度矩形粗略框出中国范围
    }

    /// 内部函数：计算纬度方向的偏移变换量
    private static func transformLat(_ x: Double, _ y: Double) -> Double { // x=经度-105，y=纬度-35
        var ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x)) // 多项式基础项
        ret += (20.0 * sin(6.0 * x * .pi) + 20.0 * sin(2.0 * x * .pi)) * 2.0 / 3.0 // 叠加按经度变化的正弦项
        ret += (20.0 * sin(y * .pi) + 40.0 * sin(y / 3.0 * .pi)) * 2.0 / 3.0 // 叠加按纬度变化的正弦项
        ret += (160.0 * sin(y / 12.0 * .pi) + 320.0 * sin(y * .pi / 30.0)) * 2.0 / 3.0 // 叠加低频正弦项
        return ret // 返回纬度方向的变换量
    }

    /// 内部函数：计算经度方向的偏移变换量
    private static func transformLon(_ x: Double, _ y: Double) -> Double { // x=经度-105，y=纬度-35
        var ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x)) // 多项式基础项
        ret += (20.0 * sin(6.0 * x * .pi) + 20.0 * sin(2.0 * x * .pi)) * 2.0 / 3.0 // 叠加按经度变化的正弦项
        ret += (20.0 * sin(x * .pi) + 40.0 * sin(x / 3.0 * .pi)) * 2.0 / 3.0 // 叠加按经度变化的低频项
        ret += (150.0 * sin(x / 12.0 * .pi) + 300.0 * sin(x / 30.0 * .pi)) * 2.0 / 3.0 // 叠加更低频的正弦项
        return ret // 返回经度方向的变换量
    }

    /// 计算 WGS-84 → GCJ-02 的偏移量（单位：度），返回 (纬度偏移, 经度偏移)
    private static func delta(_ lat: Double, _ lon: Double) -> (Double, Double) { // 参数：WGS-84 的纬度、经度
        var dLat = transformLat(lon - 105.0, lat - 35.0) // 先算纬度方向的原始偏移量
        var dLon = transformLon(lon - 105.0, lat - 35.0) // 再算经度方向的原始偏移量
        let radLat = lat / 180.0 * .pi // 把纬度从角度转换为弧度
        var magic = sin(radLat) // 取纬度的正弦值
        magic = 1 - ee * magic * magic // 计算椭球修正因子
        let sqrtMagic = sqrt(magic) // 修正因子开平方
        dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * .pi) // 把纬度偏移换算成"度"
        dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * .pi) // 把经度偏移换算成"度"
        return (dLat, dLon) // 返回两个方向的偏移量
    }

    /// 地图坐标（GCJ-02）→ 系统真实坐标（WGS-84）；在中国范围外原样返回
    static func gcj02ToWGS84(latitude: Double, longitude: Double) -> (latitude: Double, longitude: Double) { // 输入地图坐标
        guard isInChina(latitude, longitude) else { return (latitude, longitude) } // 不在中国范围，不转换
        var wgsLat = latitude // 用地图坐标作为 WGS-84 的初始猜测值
        var wgsLon = longitude // 经度同样先用地图坐标作为初始猜测
        for _ in 0..<5 { // 迭代 5 次逼近真实值（每次精度提升一个数量级，足够到亚米级）
            let (dLat, dLon) = delta(wgsLat, wgsLon) // 计算当前猜测值对应的 GCJ-02 偏移量
            wgsLat = latitude - dLat // 用"地图纬度 - 偏移"修正纬度猜测值
            wgsLon = longitude - dLon // 用"地图经度 - 偏移"修正经度猜测值
        } // 迭代结束
        return (wgsLat, wgsLon) // 返回转换后的 WGS-84 坐标
    }
}
