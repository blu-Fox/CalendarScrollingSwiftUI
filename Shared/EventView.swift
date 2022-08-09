//
//  EventView.swift
//  DragGestureTest
//
//  Created by Jan Stehlík on 30.07.2022.
//

import SwiftUI

struct EventView: View {
  // Current position of the event. Will be updated once event appears
  @State var position: CGPoint = .zero
  // Current height
  @State var height: CGFloat = 200
  // Minimum height
  let minHeight: CGFloat = 100
  // Original height before the start of a gesture. Used to calculate view position when stretching it up/down. MinHeight is the absolute minimum, originalHeight changes after each gesture ends.
  @State var originalHeight: CGFloat?
  // used to calculate view position when stretching it up/down
  @State var originalPosition: CGPoint?
  // Bounds in which the object can be moved
  var area: GeometryProxy
  // Determines if the object was longPressed and can be moved around. Tapping anywhere in the parent view turns this off and makes the view unmovable (like in iOS calendar)
  @Binding var wasLongPressed: Bool
  // Determines if the view is draggable. This second var works in tandem with wasLongPressed. 2 vars are needed because there are 2 gesture modifiers, because Gesture and Sequenced Gesture are not the same type. So we cannot use a ternary operator.
  @Binding var isDraggable: Bool
  // array of points into which events should auto-align. Offset by rowHeight/2 so it auto-aligns even if position is slightly above the row area.
  var pointsArray: [CGFloat] {
    var array: [CGFloat] = []
    for row in 0..<24 { // same as number of rows
      array.append(CGFloat(0 + 50*row)) // 50 is same as row height
    }
    return array
  }
  // gesture state, to execute different code at different situations
  @State var gestureState: DragGestureState = .inactive
  // Distance between event position and gesture location. Useful for dragging the event without it unpleasantly jumping to the current gesture location.
  @State var gesturePositionDistanceY: CGFloat = 0
  @State var gesturePositionDistanceX: CGFloat = 0

  var body: some View {
    ZStack {
      Color.red.opacity(0.9)
      VStack {
        RoundedRectangle(cornerRadius: 10)
          .fill(Color.white.opacity(0.5))
          .frame(width: UIScreen.main.bounds.width - 20, height: 15)
          .gesture(stretchTop)
        Spacer()
        RoundedRectangle(cornerRadius: 10)
          .fill(Color.white.opacity(0.5))
          .frame(width: UIScreen.main.bounds.width - 20, height: 15)
          .gesture(stretchBottom)
      } //: VStack
      .opacity(wasLongPressed ? 1 : 0)
    } //: ZStack
    .frame(maxWidth: UIScreen.main.bounds.width, minHeight: minHeight, maxHeight: height)
    .cornerRadius(10)
    .opacity(wasLongPressed ? 1 : 0.5)
    .onAppear {
      originalHeight = height
      position = CGPoint(x: area.frame(in: .named("Calendar")).midX,
                         y: area.frame(in: .named("Calendar")).midY)
      originalPosition = position
    } //: OnAppear
    // .position must be placed after onAppear to function properly
    .position(position)
    // adding .onTapGesture { } here is a hack so scrolling of calendar is not blocked by event view. From: https://stackoverflow.com/questions/57700396/adding-a-drag-gesture-in-swiftui-to-a-view-inside-a-scrollview-blocks-the-scroll
    .onTapGesture { }
    // 2 modifiers bc different return types (Gesture and SequencedGesture)
    .gesture(isDraggable ? nil : longPress.sequenced(before: drag))
    .gesture(isDraggable ? drag : nil)
  } //: body

  var longPress: some Gesture {
    LongPressGesture(minimumDuration: 1)
      .onEnded { value in
        wasLongPressed = true
      }
  }

  var drag: some Gesture {
    DragGesture()
      .onChanged { value in
        if gestureState == .inactive { // gesture updates for the first time. get distance between gesture and position, then execute code.
          gesturePositionDistanceY = abs(value.location.y - position.y)
          gesturePositionDistanceX = abs(value.location.x - position.x)
          gestureState = .updating
        } //: if

        // Set X
        if value.location.x < position.x { // gesture is above the position
          position.x = (value.location.x + gesturePositionDistanceX)
        } else { // gesture is below the position
          position.x = (value.location.x - gesturePositionDistanceX)
        }

        // Set Y
        if value.location.y < position.y { // gesture is above the position
          position.y = (value.location.y + gesturePositionDistanceY)
        } else { // gesture is below the position
          position.y = (value.location.y - gesturePositionDistanceY)
        }


        // VERSION WITH HARD EDGES. ONCE EVENT REACHES THE EDGE, IT STOPS RIGHT THERE.
        // A bug remains where locationY changes if we keep dragging above/below the static centre of the event. Fix if needed.
//        let locationY: CGFloat = (value.location.y <= position.y) ? value.location.y + gesturePositionDistanceY : value.location.y - gesturePositionDistanceY
//        let location: CGPoint = CGPoint(x: value.location.x, y: locationY)
//        // calculate if gesture is within the parent area reduced by size/2 of the event. That way, borders of the event will not pass beyond the parent area.
//        if pointWithinBounds(position: location, bounds: maxPositionArea(area: area.frame(in: .named("Calendar")), eventWidth: UIScreen.main.bounds.width, eventHeight: height)) {
//            if value.location.y <= position.y { // gesture is above the position
//              position.y = (value.location.y + gesturePositionDistanceY)
//            } else { // gesture is below the position
//              position.y = (value.location.y - gesturePositionDistanceY)
//            }
//        } else { // event is out of bounds
//          // furthest location
//          if value.location.y < area.frame(in: .local).midY { // we are at the top border.
//            position.y = area.frame(in: .local).minY + height/2
//          } else { // we are at the bottom border
//            position.y = area.frame(in: .local).maxY - height/2
//          }
//        } //: if

      } //: onchanged
      .onEnded { value in
        // Auto-align. X is static, Y must be calculated.
        // (1) Get array of numbers where:
          // a) number >= height/2 && number <= area.frame(in: .named("Calendar")).maxY - height/2 (so that new position is within calendar area)
            //  In an actual calendar app, this should be done differently. We should instead measure the extra height and add/detract the time as needed, so the event could e.g. start on a previous day.
          // b) number - height is divisible by roHeight (so event always begins at rowHeight)
          // c) number is divisible by rowHeight/2
        // (2) from this array, get number closest to position
        // (3) set position to this number

        var newPosition: CGFloat {
          var array: [CGFloat] = []
          for row in 0..<48 { // same as number of rows * 2
            array.append(CGFloat(0 + 25 * row)) // 50 is same as row height/2
          }
          let closestPoint = array
            .filter {
              $0 >= height/2 &&
              $0 <= area.frame(in: .named("Calendar")).maxY - height/2 &&
              ($0 - height/2).truncatingRemainder(dividingBy: 50) == 0
            }
            .sorted { abs(position.y - $0) < abs(position.y - $1) }
            .first
          return closestPoint ?? originalPosition!.y
        }

        withAnimation {
          position.x = area.frame(in: .named("Calendar")).midX
          position.y = newPosition
        }

        // Save new position, so that we can expand/contract correctly
        originalPosition = position
        // Retain drag if user returns finger back on the circle
        isDraggable = true
        // reset gesture state
        gestureState = .inactive
      }
  }

  var stretchTop: some Gesture {
    DragGesture()
      .onChanged { value in
        if value.translation.height < 0 { // user is stretching the view upwards
          // Here, we cannot use pointWithinBounds, because the drag gesture location is tied to its parent view (the rectangle of the event, NOT the rectangle of the calendar as a whole). 0 for this location is the top of the event. This is useless.
          // Instead, we should calculate the projected CGRect of the event (current CGRect + value height), then check if it still overlays the Calendar CGRect. If so, proceed.
           if rectWithinBounds(area: eventArea(position: position, width: UIScreen.main.bounds.width, height: height), bounds: area.frame(in: .named("Calendar"))) {
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
        // Auto-align
        // (1) calculate CGRect of event view
        let eventRect = eventArea(position: position, width: UIScreen.main.bounds.width, height: height)
        // (2) filter out points to find a point closest to current minY -> this is where event minY should be set to
        let suitableMinY = pointsArray.sorted { abs(eventRect.minY - $0) < abs(eventRect.minY - $1) }.first!
        // (3) get number closest to height that is divisible by rowHeight -> this should be the new height
        let suitableHeight = roundToRowHeight(number: height, to: 50)
        // (4) set height to newHeight and position to newLocation + newHeight/2
        withAnimation {
          height = suitableHeight
          position.y = suitableMinY + height/2
        }
        // (5) Save position and height for further action.
        originalPosition = position
        originalHeight = height
      }
  }

  var stretchBottom: some Gesture {
    DragGesture()
      .onChanged { value in
        if value.translation.height > 0 { // user stretching down
          // similar to stretchTop
          if rectWithinBounds(area: eventArea(position: position, width: UIScreen.main.bounds.width, height: height), bounds: area.frame(in: .named("Calendar"))) {
            height = max(minHeight, height + value.translation.height)
            position.y += abs(value.translation.height * 0.5)
          }

        } else { // user contracting up
          height = max(minHeight, height - abs(value.translation.height))
          position.y = max((originalPosition!.y - originalHeight! * 0.5 + minHeight * 0.5), position.y - abs(value.translation.height * 0.5))
        }
      }
      .onEnded { value in
        // Auto-align
        // (1) calculate CGRect of event. This we already do for stretching.
        let eventRect = eventArea(position: position, width: UIScreen.main.bounds.width, height: height)
        // (2) filter out points to find a point closest to current maxY -> this is where event minY should be set to
        let suitableMinY = pointsArray.sorted { abs(eventRect.maxY - $0) < abs(eventRect.maxY - $1) }.first!
        // (3) get number closest to height that is divisible by rowHeight -> this should be the new height
        let suitableHeight = roundToRowHeight(number: height, to: 50)
        // (4) set height to newHeight and position to newLocation - newHeight/2
        withAnimation {
          height = suitableHeight
          position.y = suitableMinY - height/2
        }
        // (5) Save position and height for further action.
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

  // function to round event height to a number that matches one or more rows
  func roundToRowHeight(number: CGFloat, to numberTwo: CGFloat) -> CGFloat {
      return numberTwo * CGFloat(round(number / numberTwo))
  }
  
}

struct EventView_Previews: PreviewProvider {
  static var previews: some View {
    CalendarView()
  }
}

// gesture state to track the status of the drag gesture. This enables code execution when gesture changes for the first time.
enum DragGestureState {
  case inactive
  case updating
}
