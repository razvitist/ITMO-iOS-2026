BatteryViewModel.swift: authorize() is async and uses await to request Screen Time access without freezing the UI. ContentView.swift starts it with .task. The UI runs on MainActor.
