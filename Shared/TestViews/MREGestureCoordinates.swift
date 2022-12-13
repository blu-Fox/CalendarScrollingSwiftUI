//
//  MREGestureCoordinates.swift
//  DragGestureTest
//
//  Created by Jan Stehlík on 04.08.2022.
//

import SwiftUI

// This is a minimum reproducible example of a problem wherein gesture coordinates are tied to the parent view.
struct MREGestureCoordinates: View {
    var body: some View {
      ZStack {
        Color.gray
        ZStack {
          Rectangle()
            .fill(.red)
            .frame(width: 100, height: 100)
            .gesture(
              DragGesture()
                .onChanged { value in
                  print("Child X: \(value.location.x)")
                  print("Child Y: \(value.location.y)")
                }
            )
        }
        .frame(width: 500, height: 500)
        .background(.blue)
        .gesture(
          DragGesture()
            .onChanged { value in
              print("Parent X: \(value.location.x)")
              print("Parent Y: \(value.location.y)")
            }
        )
      }
      .ignoresSafeArea()
    }
}

struct MREGestureCoordinates_Previews: PreviewProvider {
    static var previews: some View {
        MREGestureCoordinates()
    }
}
