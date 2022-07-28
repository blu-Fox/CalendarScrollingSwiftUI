//
//  GeoReader.swift
//  DragGestureTest
//
//  Created by Jan Stehlík on 28.07.2022.
//

import SwiftUI

/// Snap to place
/// This view demonstrates how an element can be moved around, and snapped into place where needed.
/// There are 2 options to detect the appropriate area:
/// - 1: Check if the currect position is within the x/y bounds of the area. This is good for rectangles.
/// - 2: Check how far the position is from the centre of the area. This is perfect for regular circles.
/// Frame coordinate spaces:
/// - GLOBAL is for the entire screen. It is affected by ignoring safe areas.
/// - LOCAL is for the immediate parent view of the geo reader
/// - CUSTOM is whatever view we attach this to. Very useful.

struct GeoReader: View {
  @State private var position: CGPoint = .zero
  @State private var checkIfOverlaid = UUID()

  var body: some View {
    GeometryReader { proxy in
      ZStack {

        // bottom layer
      VStack {
        HStack {
          ForEach(0..<3, id: \.self) { _ in
            RectangleView(position: $position, checkIfOverlaid: $checkIfOverlaid)
          }
        }
        HStack {
          ForEach(0..<3, id: \.self) { _ in
            CircleView(position: $position, checkIfOverlaid: $checkIfOverlaid)
          }
        }

      } //: VStack

        // upper layer
        // using position makes the view want to grow like a ZStack
        Circle()
          .fill(.orange)
          .frame(width: 40, height: 40)
          .position(position)
          .onAppear {
            position = CGPoint(x: proxy.frame(in: .local).midX,
                               y: proxy.frame(in: .local).midY + 200)
          }
          .gesture(
            DragGesture()
              .onChanged { value in
                position = value.location
              }
              .onEnded { value in
                // save new position
                position = value.location
                // snap to place if needed
                checkIfOverlaid = UUID()
              })
      }
      .background(Color.cyan)
    } //: Georeader
    .frame(height: 500)
    .ignoresSafeArea()
    .coordinateSpace(name: "Test")
  } //: body
} //: struct

// OPTION 1
struct RectangleView: View {
  @Binding var position: CGPoint
  @Binding var checkIfOverlaid: UUID

  var body: some View {
    GeometryReader { proxy in
      RoundedRectangle(cornerRadius: 15)
        .foregroundColor(overlaid(position: position, frame: proxy.frame(in: .named("Test"))) ? .red : .black)
        .animation(Animation.easeIn, value: overlaid(position: position, frame: proxy.frame(in: .named("Test"))))
        .task(id: checkIfOverlaid) {

          // option 1: calculates if position is within CGRect. Works with rectangles.
          if overlaid(position: position, frame: proxy.frame(in: .named("Test"))) {
                      withAnimation {
                        position = CGPoint(x: proxy.frame(in: .named("Test")).midX,
                                         y: proxy.frame(in: .named("Test")).midY)
                      }
                    }
        }
    }
    .frame(width: 120, height: 60)
  }
}

// OPTION 2
struct CircleView: View {
  @Binding var position: CGPoint
  @Binding var checkIfOverlaid: UUID
  @State var center: CGPoint?
  let diameter: CGFloat = 120

  var body: some View {
    GeometryReader { proxy in
      Circle()
        .foregroundColor(CGPointDistance(from: position, to: center ?? .zero) < diameter/2 ? .red : .black)
        .animation(Animation.easeIn, value: CGPointDistance(from: position, to: center ?? .zero) < diameter/2)
        .onAppear {
          center = CGPoint(x: proxy.frame(in: .named("Test")).midX, y: proxy.frame(in: .named("Test")).midY)
        }
        .task(id: checkIfOverlaid) {
          // This use of task is not ideal, because the action also triggers on appear (see how the circles flash red)
          if let center = center {
            if CGPointDistance(from: position, to: center) < diameter/2 {
              withAnimation {
                position = center
              }
            }
          }
        }
    }
    .frame(width: diameter, height: diameter)
  }
}

// func 1: calculates if position is within CGRect. Works with rectangles.
// if position of orange circle is between the min and max frame of the circle view, the circle view will change colour
func overlaid(position: CGPoint, frame: CGRect) -> Bool {
  if position.x >= frame.minX && position.x <= frame.maxX &&
      position.y >= frame.minY && position.y <=  frame.maxY {
    return true
  }
  return false
}

// func 2: calculates distance between position and center of this view. Perfect for regular circles.
// from https://www.hackingwithswift.com/example-code/core-graphics/how-to-calculate-the-distance-between-two-cgpoints
func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
  return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
}
func CGPointDistance(from: CGPoint, to: CGPoint) -> CGFloat {
  return sqrt(CGPointDistanceSquared(from: from, to: to))
}


struct GeoReader_Previews: PreviewProvider {
  static var previews: some View {
    GeoReader()
  }
}
