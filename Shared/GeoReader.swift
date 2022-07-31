//
//  GeoReader.swift
//  DragGestureTest
//
//  Created by Jan Stehlík on 28.07.2022.
//

/// This view demonstrates how an element can be moved around, and snapped into place where needed.
/// There are 2 options to detect the appropriate area:
/// - 1: Check if the currect position is within the x/y bounds of the area. This is good for rectangles.
/// - 2: Check how far the position is from the centre of the area. This is perfect for regular circles.
/// Frame coordinate spaces:
/// - GLOBAL is for the entire screen. It is affected by ignoring safe areas.
/// - LOCAL is for the immediate parent view of the geo reader
/// - CUSTOM is whatever view we attach this to. Very useful.
///
/// Constraints to the gray area:
/// If gesture value exceeds given bounds, set position of the orange circle to the maximum x/y coordinates within the bounds. The other coordinate can remain the same, unless it is also out of bounds, in which case set position to maximum bounds or zero (circle will end up in the corner).
///
/// Gestures can be combined using .sequenced. That way, drag is enabled after longPress ends.

import SwiftUI

struct GeoReader: View {
  // Position of the movable circle
  @State private var circlePosition: CGPoint = .zero
  // First variable tells us we longPressed and can start dragging automatically
  @State private var circleWasLongPressed = false
  // Second variable enables drag rigth away, if we already longPressed previously
  @State private var circleIsDraggable = false
  // Refreshing this triggers a function in child views, which checks if the movable circle overlays the child view
  @State private var checkIfOverlaid = UUID()

  var body: some View {
    
    GeometryReader { proxy in
      ZStack {

        // bottom layer
        // rectangles
        VStack {
          Text("Position: x: \(circlePosition.x), y: \(circlePosition.y)")
          HStack {
            ForEach(0..<3, id: \.self) { _ in
              RectangleView(position: $circlePosition, checkIfOverlaid: $checkIfOverlaid)
            }
          }
          // circles
          HStack {
            ForEach(0..<3, id: \.self) { _ in
              CircleView(position: $circlePosition, checkIfOverlaid: $checkIfOverlaid)
            }
          }
        } //: VStack

        // top layer
        // using position makes the view want to grow like a ZStack
        MovableCircle(position: $circlePosition, area: proxy, checkIfOverlaid: $checkIfOverlaid, wasLongPressed: $circleWasLongPressed, isDraggable: $circleIsDraggable)

      }
      .background(Color.gray)
      .onTapGesture {
        // end gesture, like in iOS calendar. if draggable is true, turn off draggable and completedLongPress
        if circleIsDraggable {
          circleIsDraggable = false
          circleWasLongPressed = false
        } //: if
      } //: on tap
    } //: Georeader
    .frame(width: 350, height: 500)
    .coordinateSpace(name: "Test")
  } //: body
} //: struct

// OPTION 1: RECTANGLE
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
    .frame(width: 100, height: 60)
  }
}

// OPTION 2: CIRCLE
struct CircleView: View {
  @Binding var position: CGPoint
  @Binding var checkIfOverlaid: UUID
  @State var center: CGPoint?
  let diameter: CGFloat = 100

  var body: some View {
    GeometryReader { proxy in
      Circle()
        .foregroundColor(CGPointDistance(from: position, to: center ?? .zero) < diameter/2 ? .red : .black)
        .animation(Animation.easeIn, value: CGPointDistance(from: position, to: center ?? CGPoint(x: proxy.frame(in: .named("Test")).midX, y: proxy.frame(in: .named("Test")).midY)) < diameter/2)
        .onAppear {
          center = CGPoint(x: proxy.frame(in: .named("Test")).midX, y: proxy.frame(in: .named("Test")).midY)
        }
        .task(id: checkIfOverlaid) {
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

struct MovableCircle: View {
  @Binding var position: CGPoint
  var area: GeometryProxy
  @Binding var checkIfOverlaid: UUID
  @Binding var wasLongPressed: Bool
  @Binding var isDraggable: Bool

  var body: some View {
    movableCircle
  }

  var movableCircle: some View {
      Circle()
        .fill(.orange)
        .opacity(wasLongPressed ? 1 : 0.5)
        .frame(width: 40, height: 40)
        .position(position)
        .onAppear {
          position = CGPoint(x: area.frame(in: .local).midX,
                             y: area.frame(in: .local).midY + 200)
        }
        // first longPress, then drag. If we already longPressed and this gesture ended, we can drag straight away. Cannot be in a single ternary operator bc Gesture and SequencedGesture are different types
        .gesture(isDraggable ? nil : longPress.sequenced(before: drag))
        .gesture(isDraggable ? drag : nil)
  }


  var longPress: some Gesture {
    LongPressGesture(minimumDuration: 1)
//      .updating($isDetectingLongPress) { currentState, gestureState, transaction in
//        gestureState = currentState
//        transaction.animation = Animation.easeIn(duration: 2.0)
//      }
      .onEnded { value in
        // can also write wasLongPressed = value
        wasLongPressed = true
      }
  }

  var drag: some Gesture {
    DragGesture()
      .onChanged { value in
        // constrain to the blue area
        // if value.location goes beyond area.frame(in: .named("Test"))
        // move the circle to the closest point within area.frame(in: .named("Test"))
        if overlaid(position: value.location, frame: area.frame(in: .named("Test"))) {
          position = value.location
        } else {
          // find a point closest to this one that is within the frame
          position = furthestLocation(gesturePosition: value.location, frame: area.frame(in: .named("Test")))
        }
      }
      .onEnded { value in
        // Retain drag if user returns finger back on the circle
        isDraggable = true
        // snap to place if needed
        checkIfOverlaid = UUID()
      }
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

// func 3: find a point within a frame that is closest to a given point, to constrain the circle in the given bounds
func furthestLocation(gesturePosition: CGPoint, frame: CGRect) -> CGPoint {
  // if x is below 0, it should be 0
  // if x is above maxX, it should be maxX
  // else x should remain the same
  var x = gesturePosition.x
  if gesturePosition.x < 0 {
    x = 0
  } else if gesturePosition.x > frame.maxX {
    x = frame.maxX
  }
  // same as x
  var y = gesturePosition.y
  if gesturePosition.y < 0 {
    y = 0
  } else if gesturePosition.y > frame.maxY {
    y = frame.maxY
  }
  // return point
  return CGPoint(x: x, y: y)
}


struct GeoReader_Previews: PreviewProvider {
  static var previews: some View {
    GeoReader()
  }
}
