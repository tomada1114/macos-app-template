import MyAppCore
import Testing

@Suite("Counter")
struct CounterTests {
    // MARK: - init

    @Test("init defaults to 0 in -100...100")
    func initDefaults() throws {
        let counter = try Counter()
        #expect(counter.value == 0)
        #expect(counter.range == -100 ... 100)
    }

    @Test("init accepts values at both boundaries", arguments: [-100, 100])
    func initAtBoundary(value: Int) throws {
        let counter = try Counter(value: value)
        #expect(counter.value == value)
    }

    @Test("init throws valueOutOfRange with the offending payload", arguments: [-101, 101, 999])
    func initOutOfRange(value: Int) {
        #expect(throws: Counter.CounterError.valueOutOfRange(value: value, range: -100 ... 100)) {
            try Counter(value: value)
        }
    }

    @Test("init accepts a custom range")
    func initCustomRange() throws {
        let counter = try Counter(value: 5, range: 1 ... 10)
        #expect(counter.value == 5)
        #expect(counter.range == 1 ... 10)
    }

    // MARK: - increment / decrement

    @Test("increment adds one below the upper bound")
    func incrementNormal() throws {
        var counter = try Counter()
        counter.increment()
        #expect(counter.value == 1)
    }

    @Test("decrement subtracts one above the lower bound")
    func decrementNormal() throws {
        var counter = try Counter()
        counter.decrement()
        #expect(counter.value == -1)
    }

    @Test("operations clamp at the bounds", arguments: [(-100, false), (100, true)])
    func clampsAtBound(bound: Int, incrementing: Bool) throws {
        var counter = try Counter(value: bound)
        if incrementing {
            counter.increment()
        } else {
            counter.decrement()
        }
        #expect(counter.value == bound)
    }

    @Test("repeated increments stay clamped at max")
    func repeatedIncrementAtMax() throws {
        var counter = try Counter(value: 100)
        for _ in 1 ... 5 {
            counter.increment()
        }
        #expect(counter.value == 100)
        #expect(counter.isAtMax)
    }

    @Test("repeated decrements stay clamped at min")
    func repeatedDecrementAtMin() throws {
        var counter = try Counter(value: -100)
        for _ in 1 ... 5 {
            counter.decrement()
        }
        #expect(counter.value == -100)
        #expect(counter.isAtMin)
    }

    // MARK: - isAtMax / isAtMin

    @Test("isAtMax and isAtMin flip only at their bound")
    func boundFlags() throws {
        let mid = try Counter()
        #expect(!mid.isAtMax)
        #expect(!mid.isAtMin)

        let max = try Counter(value: 100)
        #expect(max.isAtMax)
        #expect(!max.isAtMin)

        let min = try Counter(value: -100)
        #expect(min.isAtMin)
        #expect(!min.isAtMax)
    }

    // MARK: - reset

    @Test("reset returns to 0 when the range contains 0")
    func resetWithZeroInRange() throws {
        var counter = try Counter(value: 42)
        counter.reset()
        #expect(counter.value == 0)
    }

    @Test("reset falls back to the lower bound when 0 is out of range")
    func resetWithoutZeroInRange() throws {
        var counter = try Counter(value: 5, range: 1 ... 10)
        counter.reset()
        #expect(counter.value == 1)
    }

    // MARK: - Equatable

    @Test("counters with equal state are equal")
    func equatableSemantics() throws {
        let a = try Counter(value: 3)
        let b = try Counter(value: 3)
        let c = try Counter(value: 4)
        #expect(a == b)
        #expect(a != c)

        let narrow = try Counter(value: 3, range: 0 ... 5)
        #expect(a != narrow)
    }
}
