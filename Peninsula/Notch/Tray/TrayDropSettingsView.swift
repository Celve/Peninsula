//
//  TrayDropSettingsView.swift
//  Peninsula
//
//  Created by Celve on 12/30/24.
//

import SwiftUI

struct TryDropSettingsView: View {
    @StateObject var notchViewModel: NotchViewModel
    @StateObject var notchModel = NotchModel.shared
    @StateObject var trayDrop: TrayDrop = .shared

    var body: some View {
        VStack(spacing: notchViewModel.spacing) {
            HStack {
                Text("File Storage Time: ")
                Picker(String(), selection: $trayDrop.selectedFileStorageTime) {
                    ForEach(TrayDrop.FileStorageTime.allCases) { time in
                        Text(time.localized).tag(time)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 100)
                if trayDrop.selectedFileStorageTime == .custom {
                    TextField("Days", value: $trayDrop.customStorageTime, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                        .padding(.leading, 10)
                    Picker("Time Unit", selection: $trayDrop.customStorageTimeUnit) {
                        ForEach(TrayDrop.CustomstorageTimeUnit.allCases) { unit in
                            Text(unit.localized).tag(unit)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 200)
                }
            }
            .padding()
        }
        .animation(notchViewModel.normalAnimation, value: notchViewModel.contentType)
        .animation(
            notchViewModel.status == .opened ? notchViewModel.innerOnAnimation : notchViewModel.innerOffAnimation, value: notchViewModel.status)
    }
}
