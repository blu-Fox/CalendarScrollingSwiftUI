//
//  RowView.swift
//  DragGestureTest
//
//  Created by Jan Stehlík on 30.07.2022.
//

import SwiftUI

struct RowView: View {

  let rowNumber: Int

  var body: some View {
    ZStack {
      Color.gray.opacity(0.4)
      Text("Row \(rowNumber)")
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    .frame(height: 50)
    .border(Color.orange)
  }
}

struct RowView_Previews: PreviewProvider {
    static var previews: some View {
        RowView(rowNumber: 3)
    }
}
