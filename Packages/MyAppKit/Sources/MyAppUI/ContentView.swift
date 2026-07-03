import MyAppCore
import SwiftUI

/// The app's single screen: a bounded counter with increment/decrement/reset.
///
/// Deliberately thin — every behavior it renders is owned and unit-tested by
/// `CounterViewModel` in MyAppCore.
public struct ContentView: View {
    @State private var model = CounterViewModel()

    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            Text("\(model.value)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .accessibilityIdentifier("counterValue")
            HStack {
                Button("−") { model.decrement() }
                    .disabled(!model.canDecrement)
                    .accessibilityIdentifier("decrementButton")
                Button("Reset") { model.reset() }
                    .accessibilityIdentifier("resetButton")
                Button("+") { model.increment() }
                    .disabled(!model.canIncrement)
                    .accessibilityIdentifier("incrementButton")
            }
        }
        .padding(32)
        .frame(minWidth: 320, minHeight: 240)
    }
}
