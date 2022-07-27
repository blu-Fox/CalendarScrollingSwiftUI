//
//  DragInSpecificDirection.swift
//  DragGestureTest
//
//  Created by Jan Stehlík on 27.07.2022.
//

import SwiftUI

// this view allows dragging only in a specific direction
// this can be enhanced to only drag trailing, bottom etc

struct DragInSpecificDirection: View {
  var body: some View {
    VStack {
      // vertical
      Rectangle()
        .foregroundColor(.green)
        .frame(width: 100, height: 100)
        .modifier(DraggableModifier(direction: .vertical))
      // horizontal
      Rectangle()
        .foregroundColor(.red)
        .frame(width: 100, height: 100)
        .modifier(DraggableModifier(direction: .horizontal))
      // leading
      Rectangle()
        .foregroundColor(.blue)
        .frame(width: 100, height: 100)
        .modifier(DirectionModifier(direction: .leading))
      // trailing
      Rectangle()
        .foregroundColor(.orange)
        .frame(width: 100, height: 100)
        .modifier(DirectionModifier(direction: .trailing))
      // top
      Rectangle()
        .foregroundColor(.pink)
        .frame(width: 100, height: 100)
        .modifier(DirectionModifier(direction: .top))
      // bottom
      Rectangle()
        .foregroundColor(.black)
        .frame(width: 100, height: 100)
        .modifier(DirectionModifier(direction: .bottom))
    }
  }
}

struct DragInSpecificDirection_Previews: PreviewProvider {
  static var previews: some View {
    DragInSpecificDirection()
  }
}

// constrains to vertical/horizontal drag direction
struct DraggableModifier : ViewModifier {

  enum Direction {
    case vertical
    case horizontal
  }

  let direction: Direction

  @State private var draggedOffset: CGSize = .zero

  func body(content: Content) -> some View {
    content
      .offset(
        CGSize(width: direction == .vertical ? 0 : draggedOffset.width,
               height: direction == .horizontal ? 0 : draggedOffset.height)
      )
      .gesture(
        DragGesture()
          .onChanged { value in
            self.draggedOffset = value.translation
          }
          .onEnded { value in
            self.draggedOffset = .zero
          }
      )
  }

}

// constrains to leading/trailing/top/bottom drag direction
struct DirectionModifier : ViewModifier {

  enum Direction {
    case leading
    case trailing
    case top
    case bottom
  }

  let direction: Direction

  @State private var draggedOffset: CGSize = .zero

  func body(content: Content) -> some View {
    content
      .offset(calculateOffset(direction: direction))
      .gesture(
        DragGesture()
          .onChanged { value in
            self.draggedOffset = value.translation
          }
          .onEnded { value in
            self.draggedOffset = .zero
          }
      )
  }

  func calculateOffset(direction: Direction) -> CGSize {
    var offset = CGSize()
    switch direction {
    case .leading:
      offset = CGSize(width: draggedOffset.width > 0 ? 0 : draggedOffset.width, height: 0)
    case .trailing:
      offset = CGSize(width: draggedOffset.width < 0 ? 0 : draggedOffset.width, height: 0)
    case .top:
      offset = CGSize(width: 0, height: draggedOffset.height > 0 ? 0 : draggedOffset.height)
    case .bottom:
      offset = CGSize(width: 0, height: draggedOffset.height < 0 ? 0 : draggedOffset.height)
    }
    return offset
  }

}
