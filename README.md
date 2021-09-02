# MicroPNG

This package currently offers a very minimal PNG encoder for uncompressed RGB and RGBA PNG files.

It does not rely on any frameworks and should work on all Swift supported platforms.

Some of the work is based on this implementation: https://github.com/jamesbowman/pngout/blob/master/pngout.c

## Example usage

```swift
let width = UInt32(512)
let height = UInt32(512)

var imageData: [UInt32] = .init(repeating: 0, count: Int(width * height))

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

let pngData = try! encoder.encodeRGBUncompressed(data: imageData,
                                                 width: width,
                                                 height: height)

pngData.withUnsafeBytes { pointer in
    let data = Data(bytes: pointer.baseAddress!, count: pointer.count)

    try! data.write(to: URL(fileURLWithPath: "EXPORT PATH"))
}
```
