//
//  DragInSpecificDirection.swift
//  DragGestureTest
//
//  Created by Jan Stehlík on 27.07.2022.
//

import SwiftUI

// this modifier allows dragging only in a specific direction
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
      .offset(calculateOffset(direction: direction, currentOffset: draggedOffset))
      .gesture(
        DragGesture()
          .onChanged { value in
            withAnimation {
              draggedOffset = value.translation
            }
          }
          .onEnded { value in
            withAnimation {
              draggedOffset = .zero
            }
          }
      )
  }

  func calculateOffset(direction: Direction, currentOffset: CGSize) -> CGSize {
    var offset = CGSize()
    // set the offset. e.g. for leading: height should be 0. if the current offset is above 0, it means we are dragging in the trailing direction, so it should be 0. Otherwise, it should follow the drag.
    switch direction {
    case .leading:
      offset = CGSize(width: currentOffset.width > 0 ? 0 : currentOffset.width, height: 0)
    case .trailing:
      offset = CGSize(width: currentOffset.width < 0 ? 0 : currentOffset.width, height: 0)
    case .top:
      offset = CGSize(width: 0, height: currentOffset.height > 0 ? 0 : currentOffset.height)
    case .bottom:
      offset = CGSize(width: 0, height: currentOffset.height < 0 ? 0 : currentOffset.height)
    }
    return offset
  }
}

// this modifier constrains to vertical/horizontal drag direction
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
               height: direction == .horizontal ? 0 : draggedOffset.height))
      .gesture(
        DragGesture()
          .onChanged { value in
            withAnimation {
              draggedOffset = value.translation
            }
          }
          .onEnded { value in
            withAnimation {
              draggedOffset = .zero
            }
          })
  }
}

struct DragInSpecificDirection_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      // vertical
      Rectangle()
        .foregroundColor(.green)
        .overlay(Text("vertical").foregroundColor(.white))
        .frame(width: 100, height: 100)
        .modifier(DraggableModifier(direction: .vertical))
      // horizontal
      Rectangle()
        .foregroundColor(.red)
        .overlay(Text("horizontal").foregroundColor(.white))
        .frame(width: 100, height: 100)
        .modifier(DraggableModifier(direction: .horizontal))
      // leading
      Rectangle()
        .foregroundColor(.blue)
        .overlay(Text("leading").foregroundColor(.white))
        .frame(width: 100, height: 100)
        .modifier(DirectionModifier(direction: .leading))
      // trailing
      Rectangle()
        .foregroundColor(.orange)
        .overlay(Text("trailing").foregroundColor(.white))
        .frame(width: 100, height: 100)
        .modifier(DirectionModifier(direction: .trailing))
      // top
      Rectangle()
        .foregroundColor(.pink)
        .overlay(Text("top").foregroundColor(.white))
        .frame(width: 100, height: 100)
        .modifier(DirectionModifier(direction: .top))
      // bottom
      Rectangle()
        .foregroundColor(.black)
        .overlay(Text("bottom").foregroundColor(.white))
        .frame(width: 100, height: 100)
        .modifier(DirectionModifier(direction: .bottom))
    }
  }
}
