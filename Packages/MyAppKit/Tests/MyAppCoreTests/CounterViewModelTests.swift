import MyAppCore
import Testing

@MainActor
@Suite("CounterViewModel")
struct CounterViewModelTests {
    @Test("default init starts at 0 with movement enabled both ways")
    func defaultInit() {
        let model = CounterViewModel()
        #expect(model.value == 0)
        #expect(model.canIncrement)
        #expect(model.canDecrement)
    }

    @Test("init with a custom counter passes its value through")
    func customCounterInit() throws {
        let model = try CounterViewModel(counter: Counter(value: 7))
        #expect(model.value == 7)
    }

    @Test("increment and decrement move the exposed value")
    func incrementDecrement() {
        let model = CounterViewModel()
        model.increment()
        #expect(model.value == 1)
        model.decrement()
        model.decrement()
        #expect(model.value == -1)
    }

    @Test("canIncrement flips off only at the upper bound")
    func canIncrementFlipsAtMax() throws {
        let model = try CounterViewModel(counter: Counter(value: 9, range: 0 ... 10))
        #expect(model.canIncrement)
        model.increment()
        #expect(model.value == 10)
        #expect(!model.canIncrement)
        #expect(model.canDecrement)
    }

    @Test("canDecrement flips off only at the lower bound")
    func canDecrementFlipsAtMin() throws {
        let model = try CounterViewModel(counter: Counter(value: 1, range: 0 ... 10))
        #expect(model.canDecrement)
        model.decrement()
        #expect(model.value == 0)
        #expect(!model.canDecrement)
        #expect(model.canIncrement)
    }

    @Test("a full walk to max stays clamped and reports the bound")
    func fullWalkToMax() throws {
        let model = try CounterViewModel(counter: Counter(value: 0, range: 0 ... 5))
        for _ in 1 ... 8 {
            model.increment()
        }
        #expect(model.value == 5)
        #expect(!model.canIncrement)
    }

    @Test("reset returns to 0 for the default range")
    func resetDefaultRange() {
        let model = CounterViewModel()
        model.increment()
        model.increment()
        model.reset()
        #expect(model.value == 0)
    }

    @Test("reset falls back to the lower bound when 0 is out of range")
    func resetWithoutZeroInRange() throws {
        let model = try CounterViewModel(counter: Counter(value: 5, range: 1 ... 10))
        model.reset()
        #expect(model.value == 1)
    }
}
