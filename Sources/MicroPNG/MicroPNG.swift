public final class MicroPNG {
    public enum Errors: Error {
        case invalidDataSize
    }

    /// 32 ARGB Data to uncompressed 24 bit RGB PNG
    public func encodeRGBUncompressed(data: [UInt32], width: UInt32, height: UInt32) throws -> [UInt8] {
        return try encodeUncompressed(data: data, width: width, height: height, format: .rgb)
    }

    /// 32 ARGB Data to uncompressed 32 bit RGBA PNG
    public func encodeARGBUncompressed(data: [UInt32], width: UInt32, height: UInt32) throws -> [UInt8] {
        return try encodeUncompressed(data: data, width: width, height: height, format: .rgba)
    }

    private func encodeUncompressed(data: [UInt32], width: UInt32, height: UInt32, format: PNGData.Format) throws -> [UInt8] {
        let expectedNumberOfPixels = width * height

        guard data.count == expectedNumberOfPixels else {
            throw Errors.invalidDataSize
        }

        var pngData = PNGData(width: width, height: height, format: format)

        pngData.appendIHDRChunk()
        pngData.appendRGBIDATChunk(data: data)
        pngData.appendIENDChunk()

        return pngData.bytes
    }

    /**
     Wrapper that stores the generated png data and allows appending of chunks, etc.
     */
    private struct PNGData {
        fileprivate enum Format {
            case rgb
            case rgba

            fileprivate var bytesPerPixel: UInt32 {
                switch self {
                case .rgb: return 3
                case .rgba: return 4
                }
            }
        }

        private let width: UInt32
        private let height: UInt32

        private let format: Format

        fileprivate var bytes: [UInt8] = []

        private var crc32: UInt32 = 0

        private var adler1: UInt32 = 1
        private var adler2: UInt32 = 0

        fileprivate init(width: UInt32, height: UInt32, format: Format) {
            self.width = width
            self.height = height
            self.format = format

            // header
            bytes.append(contentsOf: [
                0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a
            ])
        }

        fileprivate mutating func appendIHDRChunk() {
            startChunk(code: "IHDR", size: 13)

            appendBigEndianUInt32(width)
            appendBigEndianUInt32(height)

            let formatDescription: [UInt8]

            switch format {
            case .rgb:
                formatDescription = [
                    0x8, 0x2, 0x0, 0x0, 0x0
                ]
            case .rgba:
                formatDescription = [
                    0x8, 0x6, 0x0, 0x0, 0x0
                ]
            }

            appendBytes(formatDescription)

            endChunk()
        }

        fileprivate mutating func appendRGBIDATChunk(data: [UInt32]) {
            let bytesPerLine = 1 + format.bytesPerPixel * width
            let dataChunkSize = 2 + height * bytesPerLine + 4

            startChunk(code: "IDAT", size: dataChunkSize)

            // start of deflate block
            appendByte(0x78)
            appendByte(0x01)

            var index = 0
            for y in 0 ..< height {
                appendByte((y + 1) == height ? 1 : 0) // 1 if last line, 0 otherwise

                appendLittleEndianUInt16(UInt16(bytesPerLine))
                appendLittleEndianUInt16(~UInt16(bytesPerLine))

                appendByteAndUpdateAdler(0)

                // for performance reasons we don't do this check in the inner loop
                switch format {
                case .rgb:
                    for _ in 0 ..< width {
                        let color = data[index]

                        let r = UInt8((color >> 16) & 0xFF)
                        let g = UInt8((color >> 8) & 0xFF)
                        let b = UInt8(color & 0xFF)

                        appendByteAndUpdateAdler(r)
                        appendByteAndUpdateAdler(g)
                        appendByteAndUpdateAdler(b)

                        index += 1
                    }
                case .rgba:
                    for _ in 0 ..< width {
                        let color = data[index]

                        let a = UInt8(color >> 24)
                        let r = UInt8((color >> 16) & 0xFF)
                        let g = UInt8((color >> 8) & 0xFF)
                        let b = UInt8(color & 0xFF)

                        appendByteAndUpdateAdler(r)
                        appendByteAndUpdateAdler(g)
                        appendByteAndUpdateAdler(b)
                        appendByteAndUpdateAdler(a)

                        index += 1
                    }
                }
            }

            appendAdler()

            endChunk()
        }

        fileprivate mutating func appendIENDChunk() {
            startChunk(code: "IEND", size: 0)

            endChunk()
        }

        private mutating func startChunk(code: String, size: UInt32) {
            let asciiCharacters = code.compactMap { $0.asciiValue }

            appendBigEndianUInt32(size)

            crc32 = 0xFFFFFFFF;

            appendBytes(asciiCharacters)
        }

        private mutating func endChunk() {
            appendBigEndianUInt32(0xFFFFFFFF ^ crc32)
        }

        @inline(__always)
        private mutating func appendByte(_ data: UInt8) {
            bytes.append(data)

            updateCRC(with: data)
        }

        private mutating func appendBytes(_ data: [UInt8]) {
            for byte in data {
                appendByte(byte)
            }
        }

        private mutating func appendBigEndianUInt32(_ data: UInt32) {
            appendByte(UInt8((data >> 24) & 0xFF))
            appendByte(UInt8((data >> 16) & 0xFF))
            appendByte(UInt8((data >> 8) & 0xFF))
            appendByte(UInt8(data & 0xFF))
        }

        private mutating func appendLittleEndianUInt16(_ data: UInt16) {
            appendByte(UInt8(data & 0xFF))
            appendByte(UInt8((data >> 8) & 0xFF))
        }

        private mutating func appendAdler() {
            appendBigEndianUInt32((adler2 << 16) + adler1)
        }

        @inline(__always)
        private mutating func appendByteAndUpdateAdler(_ data: UInt8) {
            appendByte(data)

            adler1 = (adler1 + UInt32(data)) % 65521
            adler2 = (adler2 + adler1) % 65521
        }

        @inline(__always)
        private mutating func updateCRC(with data: UInt8) {
            let crcTable: [UInt32] = [
                0x00000000, 0x1db71064, 0x3b6e20c8, 0x26d930ac,
                0x76dc4190, 0x6b6b51f4, 0x4db26158, 0x5005713c,
                0xedb88320, 0xf00f9344, 0xd6d6a3e8, 0xcb61b38c,
                0x9b64c2b0, 0x86d3d2d4, 0xa00ae278, 0xbdbdf21c
            ]

            var tableIndex = UInt8(crc32 & 0xFF) ^ data

            crc32 = crcTable[Int(tableIndex) & 0xF] ^ (crc32 >> 4);

            tableIndex = UInt8(crc32 & 0xFF) ^ (data >> 4);

            crc32 = crcTable[Int(tableIndex) & 0xF] ^ (crc32 >> 4);
        }
    }
}
