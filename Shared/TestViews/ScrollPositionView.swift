//
//  ScrollPositionView.swift
//  DragGestureTest
//
//  Created by Jan Stehlík on 06.08.2022.
//

// View that demonstrates how to read offset of child view using preference keys.
import SwiftUI

struct ScrollPositionView: View {
  var body: some View {
    ScrollView {
      ZStack {
        LazyVStack {
          ForEach(0...100, id: \.self) { index in
            Text("Row \(index)")
          }
        }
        GeometryReader { proxy in
          let offset = proxy.frame(in: .named("scroll")).minY
          Color.clear.preference(key: ScrollViewOffsetPreferenceKey.self, value: offset)
        }
      }
    }
    .coordinateSpace(name: "scroll")
    .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
      print(value)
    }
  }
}

struct ScrollPositionView_Previews: PreviewProvider {
  static var previews: some View {
    ScrollPositionView()
  }
}

struct ScrollViewOffsetPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat = 0

  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}
