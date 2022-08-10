//
//  EventView.swift
//  DragGestureTest
//
//  Created by Jan Stehlík on 30.07.2022.
//

import SwiftUI

// Removal of conflict between scrollview and event view:
// (1) I tried using .updating and .onChange to update a specific variable when dragging/stretching. If the variable was on, scrollview would be off. However, this did not produce the intended result. After drag gesture ends, a subsequent attempt at a drag gesture scrolls the scrollview instead. Only holding for some time magically switches to the drag gesture
// (2) I tried moving the dragged view outside of the scrollview. This seems to be the case in iOS calendar. When we drag or expand, the original view stays in scrollview and slightly loses opacity, and a bright overlay appears over the scrollview. AND IT WORKS!!!1!!1!1!1!!1!1
// (3) However, we removed the event view from the parent coordinate space. So now, it cannot get the coordinates of Scrollview. To solve it, I tried passing the Scrollview frame around and into the event view. This indeed works.
// (4) However, gestures were still hardwired into the local space, which is what first appears on the screen. So I set gestures to the parent coordinate space. This made the numbers more sensible. A bigger problem was that event view refused to stretch beyond screen size - safe areas. It turns out the culprit was the parent ZStack of Calendar view, which contained everything and was just set to the default frame. Enlarging the frame for draggable view resolved this problem.
// (5) However, we now have new problems.
  //  (a) stretch gesture now continues beyond calendar view. I fixed it by limiting gesture to the visible part of calendar view (700).
  // (b) drag onChanged works fine, but onEnded has a weird frame: its minY is 100 larger, and its maxY 50 larger than Calendar view. This fixed itself after fixing (a).
  // (c) bottomStretch should be rewritten along the new implementation of topStretch. This was successfully rewritten.
// (6) Some small issue persists in bottomStretch.onEnded. For some reason, it refuses to auto-align to 1200. Turns out we only had 24 points, but we need 25: 0, and then a point at the end of each row.
// (7) Dragging and stretching now (FINALLY) works as it should. Time to make it a bit useful.
  // (a) First, we should clean all this up. Create a model (Event) and viewModel(s) (Protocols - come on, you wanna be a pro) to store all these values and functions.
  // (b) LongPress on calendar should show a DraggableEvent in that location, with possibility to move it around (like iOS).
  // (c) On Ended, draggable event should snap into place and turn into a "normal" event (at this point, iOS calendar brings up a sheet).
  // (d) LongPress elsewhere would repat the process.
  // (e) LongPress on "normal" event will bring up draggable event (normal event will dim slightly)
  // (f) If two "normal" events overlap, their position.x and width should change
#warning("To continue, see point 7 above.")

struct DraggableEventView: View {
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
  let parentFrame: CGRect
  // The height of the visible calendar view (700 in this example). We can adapt gestures to only work within this value, relative to the parentFrame. Hardcoded, it would be between 250 and 950 in this example, because parentFrame is 1200 high and the calendar view is set in the middle of parentFrame.
  let visibleCalendarFrameHeight: CGFloat
  // Determines if the object was longPressed and can be moved around. Tapping anywhere in the parent view turns this off and makes the view unmovable (like in iOS calendar)
  @Binding var wasLongPressed: Bool
  // Determines if the view is draggable. This second var works in tandem with wasLongPressed. 2 vars are needed because there are 2 gesture modifiers, because Gesture and Sequenced Gesture are not the same type. So we cannot use a ternary operator.
  @Binding var isDraggable: Bool
  // array of points into which events should auto-align. Offset by rowHeight/2 so it auto-aligns even if position is slightly above the row area.
  var pointsArray: [CGFloat] {
    var array: [CGFloat] = []
    for row in 0...24 { // 25 points in total (number of rows, plus 0 point)
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
      position = CGPoint(x: UIScreen.main.bounds.midX,
                         y: 200)
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
        wasLongPressed = true
      }
  }

  var drag: some Gesture {
    DragGesture(coordinateSpace: .named("CalendarView"))
      .onChanged { value in

        // Gesture updates for the first time: get distance between gesture and position. This distance will inform this and subsequent updates, so the view does not unpleasantly jump towards the centre of the gesture.
        if gestureState == .inactive {
          gesturePositionDistanceY = abs(value.location.y - position.y)
          gesturePositionDistanceX = abs(value.location.x - position.x)
          gestureState = .updating
        } //: if

        // Execute the rest of the code: position view to the gesture, offset by the original distance between gesture and position (recorded above).
        // Set X
        // Gesture is left of position
        if value.location.x < position.x {
          position.x = (value.location.x + gesturePositionDistanceX)
        // Gesture is right of position
        } else {
          position.x = (value.location.x - gesturePositionDistanceX)
        }
        // Set Y
        // Gesture is above the position
        if value.location.y < position.y {
          position.y = (value.location.y + gesturePositionDistanceY)
        // gesture is below the position
        } else {
          position.y = (value.location.y - gesturePositionDistanceY)
        }

        // VERSION WITH HARD EDGES. ONCE EVENT REACHES THE EDGE, IT STOPS RIGHT THERE.
        // A bug remains where locationY changes if we keep dragging above/below the static centre of the event. Fix if needed.
//        let locationY: CGFloat = (value.location.y <= position.y) ? value.location.y + gesturePositionDistanceY : value.location.y - gesturePositionDistanceY
//        let location: CGPoint = CGPoint(x: value.location.x, y: locationY)
//        // calculate if gesture is within the parent area reduced by size/2 of the event. That way, borders of the event will not pass beyond the parent area.
//        if pointWithinBounds(position: location, bounds: maxPositionArea(area: area.frame(in: .named("DraggableEvent")), eventWidth: UIScreen.main.bounds.width, eventHeight: height)) {
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
        // Auto-align. X is static (middle of screen), Y must be calculated.
        // (1) Get array of numbers where:
          // (a) number >= parentFrame.minY + height/2 (so that new position does not reach above calendar. Calendar minY is 0 before scrolling, but could be something else after scroll)
          // (b) number <= parentFrame.maxY - height/2 (so that new position does not reach below calendar)
          //  In an actual calendar app, this should be done differently. We should instead measure the extra height and add/detract the time as needed, so the event could e.g. start on a previous day.
          // c) number - height/2 is divisible by rowHeight (so event always begins at rowHeight)
        // (2) from this array, get number closest to position
        var newPosition: CGFloat {
          var array: [CGFloat] = []
          for row in 0..<48 { // same as number of rows * 2
            array.append(CGFloat(0 + 25 * row)) // 50 is same as row height/2
          }
          let closestPoint = array
            .filter {
              $0 >=  parentFrame.minY + height/2 &&
              $0 <= parentFrame.maxY - height/2 &&
              ($0 - height/2).truncatingRemainder(dividingBy: 50) == 0
            }
            .sorted { abs(position.y - $0) < abs(position.y - $1) }
            .first
          return closestPoint ?? originalPosition!.y
        }
        // (3) set position to this number
        withAnimation {
          position.x = parentFrame.midX
          position.y = newPosition
        }
        // Save new position, so that we can expand/contract correctly
        originalPosition = position
        // Retain drag if user returns their finger on draggableEventView
        isDraggable = true
        // Reset gesture state, so distance between finger and position is calculated anew if user returns their finger on draggableEventView
        gestureState = .inactive
      }
  }

  var stretchTop: some Gesture {
    DragGesture(coordinateSpace: .named("CalendarView"))
      .onChanged { value in
        // (1) Check if our gesture is within the visible area of calendar view. In this example, the view of the calendar is 700 high and in the middle of a 1200 ZStack. So the visible part is between 250 and 950.
        if value.location.y >= (parentFrame.height/2 - visibleCalendarFrameHeight/2) &&
            value.location.y <= (parentFrame.height/2 + visibleCalendarFrameHeight/2) {
          // (2) Position is whatever is smaller (i.e. higher): originalPosition.y + originalHeight/2 - minHeight/2 (limit), or originalPosition.y + value.translation.height/2 (current calculation)
          position.y = min(
            originalPosition!.y + originalHeight!/2 - minHeight/2,
            originalPosition!.y + value.translation.height/2)
          // (3) Height is whatever is larger: minHeight or original height + value.translation.height. The correct implementation depends on whether user is stretching up or contracting down.
          if value.translation.height < 0 {
            height = max(
              minHeight,
              originalHeight! + abs(value.translation.height))
          } else {
            height = max(
              minHeight,
              originalHeight! - value.translation.height)
          }
         } //: if
      } //: onChanged
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
    DragGesture(coordinateSpace: .named("CalendarView"))
      .onChanged { value in

        // (1) Check if our gesture is within the visible area of calendar view. Calendar view is 700 high and in the middle of a 1200 ZStack. So the visible part is between 250 and 950.
        if value.location.y >= 250 && value.location.y <= 950 {
          // (2) Position is whatever is larger (i.e. lower): originalPosition.y - originalHeight/2 + minHeight/2 (limit), or originalPosition.y + value.translation.height/2 (current calculation)
          position.y = max(
            originalPosition!.y - originalHeight!/2 + minHeight/2,
            originalPosition!.y + value.translation.height/2)
          // (3) Height is whatever is larger: minHeight or original height + value.translation.height. The correct implementation depends on whether user is contracting up or stretching down.
          if value.translation.height < 0 {
            height = max(
              minHeight,
              originalHeight! + value.translation.height)
          } else {
            height = max(
              minHeight,
              originalHeight! + value.translation.height)
          }
        } //: if
      }
      .onEnded { value in
        // Auto-align
        // (1) calculate CGRect of event.
        let eventRect = eventArea(position: position, width: UIScreen.main.bounds.width, height: height)
        // (2) filter out points to find a point closest to current maxY -> this is where event maxY should be set to
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

struct DraggableEventView_Previews: PreviewProvider {
  static var previews: some View {
    CalendarView()
  }
}
