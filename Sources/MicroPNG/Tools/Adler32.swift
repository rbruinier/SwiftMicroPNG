internal struct Adler32 {
    internal private(set) var value1: UInt32 = 1
    internal private(set) var value2: UInt32 = 0

    internal var result: UInt32 {
        return (value2 << 16) | value1
    }

    @inline(__always)
    internal mutating func update(with data: UInt8) {
        value1 = (value1 + UInt32(data)) % 65521
        value2 = (value2 + value1) % 65521
    }
}
