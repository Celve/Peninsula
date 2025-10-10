import SwiftUI
import KeyboardShortcuts

struct SwitchSettingView: View {
    @StateObject var notchViewModel: NotchViewModel
    @StateObject var notchModel = NotchModel.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Cmd+Tab: ")
                Picker(String(), selection: $notchModel.cmdTabTrigger) {
                    ForEach(SwitchState.allCases) { state in
                        Text(state.id).tag(state)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Text("Opt+Tab: ")
                Picker(String(), selection: $notchModel.optTabTrigger) {
                    ForEach(SwitchState.allCases) { state in
                        Text(state.id).tag(state)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            HStack {
                Text("Cmd+`: ")
                Picker(String(), selection: $notchModel.cmdBtickTrigger) {
                    ForEach(SwitchState.allCases) { state in
                        Text(state.id).tag(state)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Text("Opt+`: ")
                Picker(String(), selection: $notchModel.optBtickTrigger) {
                    ForEach(SwitchState.allCases) { state in
                        Text(state.id).tag(state)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            HStack {
                Text("Switch between windows: ")
                KeyboardShortcuts.Recorder(for: .toggleSearchInterWindows)
                
                Text("Switch between apps: ")
                KeyboardShortcuts.Recorder(for: .toggleSearchApps)
            }
            
            HStack {
                Text("Switch between windows for an app: ")
                KeyboardShortcuts.Recorder(for: .toggleSearchIntraWindows)
            }
        }
        .padding()
        .animation(
            notchViewModel.status == .opened ? notchViewModel.innerOnAnimation : notchViewModel.innerOffAnimation, value: notchViewModel.status)
    }
}
