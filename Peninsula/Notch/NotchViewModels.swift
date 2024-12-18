//
//  NotchViewModels.swift
//  Peninsula
//
//  Created by Celve on 12/10/24.
//

import Foundation

class NotchViewModels: ObservableObject {
    static let shared = NotchViewModels()
    @Published var inner: [NotchViewModel] = []
}
