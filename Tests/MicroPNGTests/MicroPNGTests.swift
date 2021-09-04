import XCTest
import Foundation
@testable import MicroPNG

final class MicroPNGTests: XCTestCase {
    func testRGBUncompressedEncoder() throws {
        let width = UInt32(256)
        let height = UInt32(256)

        var imageData: [UInt32] = .init(repeating: 0xFFFFFFFF, count: Int(width * height))

        var index = 0
        for y: UInt32 in 0 ..< height {
            for x: UInt32 in 0 ..< width {
                let r: UInt32 = y & 0xFF
                let g: UInt32 = x & 0xFF
                let b: UInt32 = (0xFF - x & 0xFF)

                imageData[index] = (r << 16) + (g << 8) + (b << 0)

                index += 1
            }
        }

        let encoder = MicroPNG()

        let pngData = try! encoder.encodeRGBUncompressed(data: imageData, width: width, height: height)

        let testData = try Data(contentsOf: Bundle.module.url(forResource: "Data/rgb", withExtension: "png")!)

        XCTAssertEqual(pngData, [UInt8](testData))
    }

    func testRGBAUncompressedEncoder() throws {
        let width = UInt32(256)
        let height = UInt32(256)

        var imageData: [UInt32] = .init(repeating: 0xFFFFFFFF, count: Int(width * height))

        var index = 0
        for y: UInt32 in 0 ..< height {
            for x: UInt32 in 0 ..< width {
                let a: UInt32 = (x ^ y) & 0xFF
                let r: UInt32 = y & 0xFF
                let g: UInt32 = x & 0xFF
                let b: UInt32 = (0xFF - x & 0xFF)

                imageData[index] = (a << 24) + (r << 16) + (g << 8) + (b << 0)

                index += 1
            }
        }

        let encoder = MicroPNG()

        let pngData = try! encoder.encodeARGBUncompressed(data: imageData, width: width, height: height)

        let testData = try Data(contentsOf: Bundle.module.url(forResource: "Data/rgba", withExtension: "png")!)

        XCTAssertEqual(pngData, [UInt8](testData))
    }
}
