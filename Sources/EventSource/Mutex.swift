import Foundation

package struct Mutex<Value>: @unchecked Sendable {
    private let _box: Box
    private let _lock = NSLock()

    package init(_ initialValue: consuming Value) {
        _box = Box(initialValue)
    }

    private final class Box {
        var value: Value
        init(_ initialValue: consuming Value) {
            value = initialValue
        }
    }

    borrowing func withLock<Result>(_ body: (inout Value) throws -> Result) rethrows -> Result {
        _lock.lock()
        defer { _lock.unlock() }
        return try body(&_box.value)
    }

    borrowing func withLockIfAvailable<Result>(_ body: (inout Value) throws -> Result) rethrows -> Result? {
        guard _lock.try() else { return nil }
        defer { _lock.unlock() }
        return try body(&_box.value)
    }
}

package extension Mutex where Value == Void {
    borrowing func _unsafeLock() {
        _lock.lock()
    }

    borrowing func _unsafeTryLock() -> Bool {
        _lock.try()
    }

    borrowing func _unsafeUnlock() {
        _lock.unlock()
    }
}
