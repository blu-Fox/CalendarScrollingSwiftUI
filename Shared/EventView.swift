//
//  EventView.swift
//  DragGestureTest
//
//  Created by Jan Stehlík on 30.07.2022.
//

import SwiftUI

struct EventView: View {
  
  let minHeight: CGFloat = 100
  // Current height
  @State var height: CGFloat = 100
  // Original height before the start of a gesture. Used to calculate view position when stretching it up/down. MinHeight is the absolute minimum, originalHeight changes after each gesture ends.
  @State var originalHeight: CGFloat?
  // Current position of the object
  @Binding var position: CGPoint
  // Bounds in which the object can be moved
  var area: GeometryProxy
  // used to calculate view position when stretching it up/down
  @State var originalPosition: CGPoint?
  // Updating this var triggers a function in other views that determines if this view overlays them
  @Binding var checkIfOverlaid: UUID
  // Determines if the object was longPressed and can be moved around. Tapping anywhere in the parent view turns this off and makes the view unmovable (like in iOS calendar)
  @Binding var wasLongPressed: Bool
  // Determines if the view is draggable. This second var works in tandem with wasLongPressed. 2 vars are needed because there are 2 gesture modifiers, bc Gesture and Sequenced Gesture are not the same type.
  @Binding var isDraggable: Bool

  var body: some View {
    ZStack {
      Color.red

      VStack {
        RoundedRectangle(cornerRadius: 10)
          .fill(Color.blue)
          .frame(width: UIScreen.main.bounds.width - 20, height: 8)
          .gesture(stretchTop)
        Spacer()
        RoundedRectangle(cornerRadius: 10)
          .fill(Color.blue)
          .frame(width: UIScreen.main.bounds.width - 20, height: 8)
          .gesture(stretchBottom)
      } //: VStack
    } //: ZStack
    .frame(maxWidth: UIScreen.main.bounds.width, minHeight: minHeight, maxHeight: height)
    .opacity(wasLongPressed ? 1 : 0.5)
    .onAppear {
      originalHeight = height
      position = CGPoint(x: area.frame(in: .named("Calendar")).midX,
                         y: area.frame(in: .named("Calendar")).midY)
      originalPosition = position
    } //: OnAppear
    // .position must be placed after onAppear to function properly
    .position(position)
    // 2 modifiers bc different return types (Gesture and SequencedGesture)
    .gesture(isDraggable ? nil : longPress.sequenced(before: drag))
    .gesture(isDraggable ? drag : nil)
  } //: body

  var longPress: some Gesture {
    LongPressGesture(minimumDuration: 1)
      .onEnded { value in
        // can also write wasLongPressed = value
        wasLongPressed = true
      }
  }

  var drag: some Gesture {
    DragGesture()
      .onChanged { value in
        // calculate if gesture is within the parent area reduced by size/2 of the event. That way, borders of the event will not pass beyond the parent area.
        if pointWithinBounds(position: value.location, bounds: maxPositionArea(area: area.frame(in: .named("Calendar")), eventWidth: UIScreen.main.bounds.width, eventHeight: height)) {

          // this works, but skips to the current gesture location. if the gesture location is off centre, it creates a large, unpleasant jump. Instead, position should be progressively moved by the gesture translation.
          position.y = value.location.y

//          This almost works in reducing the initial jump to position. What we need is save original gesture position, or really the original difference between the gesture position and event position when the drag gesture started.
//          let differenceY = abs(value.location.y - originalPosition!.y) // <- value.location.y should actually be the original value when gesture started
//          if value.location.y <= position.y {
//            print("Test 1")
//            print(differenceY)
//            position.y = (value.location.y + differenceY)
//          } else {
//            print("Test 2")
//            print(differenceY)
//            position.y = (value.location.y - differenceY)
//          }

        } else { // event is out of bounds
          // furthest location
          // position should be parentArea.maxY + height
          if value.location.y < area.frame(in: .local).midY {
            position.y = area.frame(in: .local).minY + height/2
          } else {
            position.y = area.frame(in: .local).maxY - height/2
          }
          // position.y = furthestPosition(area: eventArea(position: position, width: UIScreen.main.bounds.width, height: height), parentArea: area.frame(in: .named("Calendar"))).y
        }

      } //: onchanged
      .onEnded { value in
        // Record position, so that we can expand/contract correctly
        originalPosition = position
        // Retain drag if user returns finger back on the circle
        isDraggable = true
        // snap to place if needed
        checkIfOverlaid = UUID()
      }
  }

  var stretchTop: some Gesture {
    DragGesture()
      .onChanged { value in
        if value.translation.height < 0 { // user is stretching the view upwards
          // Here, we cannot use pointWithinBounds, because the drag gesture location is tied to its parent view (the rectangle of the event, NOT the rectangle of the calendar as a whole). 0 for this location is the top of the event. This is useless.
          // Instead, we should calculate the projected CGRect of the event (current CGRect + value height), then check if it still overlays the Calendar CGRect. If so, proceed.
           if rectWithinBounds(area: eventArea(position: position, width: UIScreen.main.bounds.width, height: height + abs(value.translation.height)), bounds: area.frame(in: .named("Calendar"))) {
            // set height. add dragged value to current width.
            height = max(minHeight, height + abs(value.translation.height))
            // set position. x remains the same, y loses half of the gesture position
            position.y -= abs(value.translation.height * 0.5)
           }
        } else { // user is contracting the view downwards
          // set height. Detract the positive value from the currently higher height.
          height = max(minHeight, height - value.translation.height)
          // set position to whichever is smaller (i.e. higher):
          // originalPosition.y + originalHeight*0.5 - minHeight * 0.5 (this is the maximum position we can achieve
          // OR
          // current position.y + what we can add: abs(gestureValue.translation.height * 0.5
          position.y = min((originalPosition!.y + originalHeight! * 0.5 - minHeight * 0.5), position.y + abs(value.translation.height * 0.5))
          // I tried using the following simpler method, but the results were inconsistent if the drag gesture was too fast.
          // if minHeight < (height! - gestureValue.translation.height) {
          //   position.y += abs(gestureValue.translation.height * 0.5)
          // }
        }
      }
      .onEnded { value in
        originalPosition = position
        originalHeight = height
      }
  }

  var stretchBottom: some Gesture {
    DragGesture()
      .onChanged { value in
        if value.translation.height > 0 { // user stretching down
          // same as stretchTop
          if rectWithinBounds(area: eventArea(position: position, width: UIScreen.main.bounds.width, height: height + abs(value.translation.height)), bounds: area.frame(in: .named("Calendar"))) {
            height = max(minHeight, height + value.translation.height)
            position.y += abs(value.translation.height * 0.5)
          }

        } else { // user contracting up
          height = max(minHeight, height - abs(value.translation.height))
          position.y = max((originalPosition!.y - originalHeight! * 0.5 + minHeight * 0.5), position.y - abs(value.translation.height * 0.5))
        }
      }
      .onEnded { value in
        originalPosition = position
        originalHeight = height
      }
  }


  // checks if a given CGPoint is within a CGRect
  func pointWithinBounds(position: CGPoint, bounds: CGRect) -> Bool {
    if position.x >= bounds.minX && position.x <= bounds.maxX &&
        position.y >= bounds.minY && position.y <=  bounds.maxY {
      return true
    }
    return false
  }
  

  // calculates the maximum parent area in which the event's position can move. It does so by detracting size/2 of the event area. That way, borders of the event area will not go past the parent area.
  // WARNING: this is implemented for Y axis only! Width remains the same in this use case.
  func maxPositionArea(area: CGRect, eventWidth: CGFloat, eventHeight: CGFloat) -> CGRect {
    // let originX: CGFloat = area.origin.x + eventWidth/2
    let originY: CGFloat = area.origin.y + eventHeight/2
    let newHeight: CGFloat = area.height - eventHeight
    return CGRect(x: area.origin.x, y: originY, width: eventWidth, height: newHeight)
  }

  // calculates the CGRect area of the event, based on its position, width and height
  func eventArea(position: CGPoint, width: CGFloat, height: CGFloat) -> CGRect {
    let originX: CGFloat = position.x - width/2
    let originY: CGFloat = position.y - height/2
    return CGRect(x: originX, y: originY, width: width, height: height)
  }

  // checks if a given CGRect is within a CGRect
  // IMPORTANT: some of this should possibly not be >=, because once the event borders are equal to parent area borders, we want the positioning to stop.
  func rectWithinBounds(area: CGRect, bounds: CGRect) -> Bool {
    if area.minX >= bounds.minX &&
        area.maxX <= bounds.maxX &&
        area.minY >= bounds.minY &&
        area.maxY <=  bounds.maxY {
      return true
    }
    return false
  }
  
}

struct EventView_Previews: PreviewProvider {
  static var previews: some View {
    CalendarView()
  }
}



//
//  // triggered when CGRect is out of bounds of parent CGRect
//  func furthestPosition(area: CGRect, parentArea: CGRect) -> CGPoint {
//    var x = CGFloat()
//    if area.minX < parentArea.minX {
//      x = parentArea.minX + area.width/2
//    } else if area.maxX > parentArea.maxX {
//      x = parentArea.maxX - area.width/2
//    }
//
//    var y = CGFloat()
//    if area.minY < parentArea.minY {
//      y = parentArea.minY + area.height/2
//    } else if area.maxY > parentArea.maxY {
//      y = parentArea.maxY - area.height/2
//    }
//    // return point
//    return CGPoint(x: x, y: y)
//  }
