internal struct CRC32 {
    private static let crcTable: [UInt32] = [
        0x00000000, 0x1db71064, 0x3b6e20c8, 0x26d930ac,
        0x76dc4190, 0x6b6b51f4, 0x4db26158, 0x5005713c,
        0xedb88320, 0xf00f9344, 0xd6d6a3e8, 0xcb61b38c,
        0x9b64c2b0, 0x86d3d2d4, 0xa00ae278, 0xbdbdf21c
    ]

    internal private(set) var value: UInt32 = 0

    internal mutating func reset(to value: UInt32) {
        self.value = value
    }

    @inline(__always)
    internal mutating func update(with data: UInt8) {
        var tableIndex = UInt8(value & 0xFF) ^ data

        value = Self.crcTable[Int(tableIndex) & 0xF] ^ (value >> 4);

        tableIndex = UInt8(value & 0xFF) ^ (data >> 4);

        value = Self.crcTable[Int(tableIndex) & 0xF] ^ (value >> 4);
    }
}
