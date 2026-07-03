import Observation

/// Observable presentation state for a ``Counter``.
///
/// Lives in Core (imports Observation only, never SwiftUI) so its logic stays
/// unit-testable with plain `swift test` and counts toward the coverage floor.
@MainActor
@Observable
public final class CounterViewModel {
    public private(set) var counter: Counter

    /// Creates a view model over the default counter (0 in -100...100).
    public init() {
        do {
            counter = try Counter()
        } catch {
            // Unreachable: 0 always lies within the default range.
            preconditionFailure("Counter's default configuration is always valid: \(error)")
        }
    }

    /// Creates a view model over an existing counter.
    public init(counter: Counter) {
        self.counter = counter
    }

    /// The current counter value.
    public var value: Int { counter.value }
    /// Whether increment would change the value (false at the upper bound).
    public var canIncrement: Bool { !counter.isAtMax }
    /// Whether decrement would change the value (false at the lower bound).
    public var canDecrement: Bool { !counter.isAtMin }

    public func increment() {
        counter.increment()
    }

    public func decrement() {
        counter.decrement()
    }

    public func reset() {
        counter.reset()
    }
}
