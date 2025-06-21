//
//  DataVerificationView.swift
//  StorageSync
//
//  Created by Jiping Yang on 6/20/25.
//

import SwiftUI

struct DataVerificationView: View {
    @State private var boxCount = 0
    @State private var totalItems = 0
    
    var body: some View {
        VStack {
            Text("Boxes: \(boxCount)")
            Text("Total Items: \(totalItems)")
            
            Button("Check Database") {
                checkData()
            }
        }
        .onAppear {
            checkData()
        }
    }
    
    private func checkData() {
        CloudKitManager.shared.fetchBoxes { result in
            if case .success(let boxes) = result {
                boxCount = boxes.count
                
                var itemCount = 0
                let group = DispatchGroup()
                
                for box in boxes {
                    group.enter()
                    CloudKitManager.shared.fetchItems(for: box.id) { itemResult in
                        if case .success(let items) = itemResult {
                            itemCount += items.count
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    totalItems = itemCount
                }
            }
        }
    }
}
