//
//  ContentView.swift
//  Shared
//
//  Created by Jan Stehlík on 26.07.2022.
//


/// Resizing the card
/// - The card can be resized using the handle.
/// - However, this resizes the card in both directions.
/// - How to achieve expansion only in the specified direction?
///
/// Drag start limit
/// - I tried to limit drag start by condition if abs(value.translation.height) > 50
/// - This works on start, but then prevents the card from being manually returned to its starting position.
/// - Perhaps this can be improved somehow, to make the condition only apply before offset reaches abs(50). After that, the condition will cease to apply.
///
/// Expand in one direction
/// - Expansion is done by increasing width/height of the card, while also increasing x/y offset of the card by the current expansion divided by 2.
/// The tricky part is returning back to the original offset. This requires keeping a record of the original width and offset, and then reducing actual width and offset (by half speed of the width) until we reduce the view to its minWidth. At that point, we should stop moving offset, otherwise the view will begin sliding too far. To get this boundary when going left, we should take the original offset, detract half of the original view width, and add half of the view's minimum width. This is switched around when going right: take the original offset, add half of the original view width, and detract half of the view's minimum width.

import SwiftUI

struct ContentView: View {
  @State var minWidth: CGFloat = 100
  @State var width: CGFloat?
  @State var height: CGFloat = 100
  @State var offset: CGSize = .zero
  @State var originalOffset: CGSize = .zero
  @State var originalWidth: CGFloat = 100


  var body: some View {
    ZStack {
      RedRectangle(width: width ?? minWidth)
      HStack {
        Resizer()
          .gesture(
            DragGesture()
              .onChanged { value in
                calculateStretchLeading(dragPosition: value.translation)
              }
              .onEnded { value in
                originalOffset = offset
                originalWidth = width!
              })
        Spacer()
        Resizer()
          .gesture(
            DragGesture()
              .onChanged { value in
                calculateStretchTrailing(dragPosition: value.translation)
              }
              .onEnded { value in
                originalOffset = offset
                originalWidth = width!
              })
      }
      .frame(maxWidth: width ?? minWidth)
    }
    .offset(offset)
    .onAppear {
      width = minWidth
    }
    .gesture(
      DragGesture()
        .onChanged { value in
          getObjectOffset(dragPosition: value.translation)
        }
        .onEnded { value in
          // add snap to grid here
          // center to screen (offset width = 0)
          // get height position of nearest row
          // offset height = row height
          originalOffset = offset
        })
  }

  func calculateStretchLeading(dragPosition: CGSize) {
    if dragPosition.width < 0 {
      // set width. add dragged value to current width.
      width = max(minWidth, width! + abs(dragPosition.width))
      // set offset. detract half of dragged width from current offset value.
      offset.width = offset.width - abs(dragPosition.width * 0.5)
    } else {
      // set width. Detract the positive value from the currently higher width.
      width = max(minWidth, width! - dragPosition.width)
      // set offset. if it hits 0 (default), it should stay in place
      offset.width = min((originalOffset.width + originalWidth * 0.5 - minWidth * 0.5), offset.width + abs(dragPosition.width * 0.5))
    }
  }

  func calculateStretchTrailing(dragPosition: CGSize) {
    if dragPosition.width > 0 {
      // set width. add dragged value to current width.
      width = max(minWidth, width! + dragPosition.width)
      // set offset. detract half of dragged width from current offset value.
      offset.width = offset.width + (dragPosition.width * 0.5)
    } else {
      // set width. Detract the positive value from the currently higher width.
      width = max(minWidth, width! - abs(dragPosition.width))
      // set offset. detract value from currently higher offset. If it hits 0 (default), it should stay in place
      offset.width = max((originalOffset.width - originalWidth * 0.5 + minWidth * 0.5), offset.width - abs(dragPosition.width * 0.5))
    }
  }

  func getObjectOffset(dragPosition: CGSize) {
    if dragPosition.width > 0 {
      offset.width = originalOffset.width + dragPosition.width
    } else {
      offset.width = originalOffset.width - abs(dragPosition.width)
    }
    if dragPosition.height > 0 {
      offset.height = originalOffset.height + dragPosition.height
    } else {
      offset.height = originalOffset.height - abs(dragPosition.height)
    }
  }

}

struct RedRectangle: View {
  let width: CGFloat

  var body: some View {
    RoundedRectangle(cornerRadius: 15)
      .fill(Color.red)
      .frame(maxWidth: width, maxHeight: 100)
  }
}

struct Resizer: View {
  var body: some View {
    Rectangle()
      .fill(Color.blue)
      .frame(width: 8, height: 75)
      .cornerRadius(10)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
