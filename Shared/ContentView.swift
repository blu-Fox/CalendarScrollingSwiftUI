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
/// - Expansion could be done by increasing width/height of the card, while also increasing x/y offset of the card by the current expansion divided by 2.

import SwiftUI

struct ContentView: View {
  @State var minWidth: CGFloat = 100
  @State var width: CGFloat?
  @State var height: CGFloat = 100
  @State var offset: CGSize = .zero
  var body: some View {
    ZStack {
      RedRectangle(width: width ?? minWidth)
      HStack {
        Resizer()
          .gesture(
            DragGesture()
              .onChanged { value in
                print(width!)
                print(value.translation.width)
                width = max(minWidth, width! + value.translation.width)
              })
        Spacer()
        Resizer()
          .gesture(
            DragGesture()
              .onChanged { value in
                width = max(minWidth, abs(width! + value.translation.width))
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
          withAnimation {
            offset = value.translation
          }
        }
        .onEnded { value in
          withAnimation {
            offset = .zero
          }
        })
  }
}

struct RedRectangle: View {
  let width: CGFloat

  var body: some View {
    RoundedRectangle(cornerRadius: 15)
      .fill(Color.red)
      .frame(width: width, height: 100)
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
