//  BoxRow.swift

import SwiftUI

struct BoxRow: View {
    let box: Box

    var body: some View {
        HStack {
            Text(box.title)
            Spacer()
            Text(box.createdAt, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
