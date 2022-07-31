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
            .gesture(
              DragGesture()
                .onChanged { value in
                  calculateStretchTop(gestureHeight: value.translation.height)
                }
                .onEnded { value in
                  originalPosition = position
                  originalHeight = height
                })
          Spacer()
          RoundedRectangle(cornerRadius: 10)
            .fill(Color.blue)
            .frame(width: UIScreen.main.bounds.width - 20, height: 8)
            .gesture(
              DragGesture()
                .onChanged { value in
                  calculateStretchBottom(gestureHeight: value.translation.height)
                }
                .onEnded { value in
                  originalPosition = position
                  originalHeight = height
                })
        } //: VStack
      } //: ZStack
      .frame(maxWidth: UIScreen.main.bounds.width, minHeight: minHeight, maxHeight: height)
      .opacity(wasLongPressed ? 1 : 0.5)
      .onAppear {
        originalHeight = height
        #warning("change this later to be the position.y of the longPress gesture on the parent view. position.x can be middle of the screen.")
        position = CGPoint(x: area.frame(in: .local).midX,
                           y: area.frame(in: .local).midY)
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
        // constrain to the parent area. if value.location goes beyond area.frame(in: .named("Test")), move the circle to the closest point within area.frame(in: .named("Test")).
        #warning("this skips to the current gesture location. if the gesture location is off centre, it creates a large, unpleasant jump. Instead, position should be progressively moved by the gesture translation.")
//        if overlaid(position: value.location, frame: area.frame(in: .named("CalendarPreview"))) {
//          position = value.location
//        } else {
//          // find a point closest to this one that is within the frame
//          position = furthestLocation(gesturePosition: value.location, frame: area.frame(in: .named("CalendarPreview")))
//        }
        // new if that uses position
        #warning("fix: position stutters, while value.location works but breaks if finger is off center. actually this function should only run when value.location is within frame OR value.location.y distance from the frame is less than distance between value.location.y and position.y.")
        if overlaid(position: position, frame: area.frame(in: .named("CalendarPreview"))) {
          // this will not work, because it adds the entire path of the gesture at every update. So the view will quickly whizz of the screen!
          // position.y += value.translation.height

          // 1 Get difference between value.location.y (finger position) and position.y (current position of the view)
          // 2 then, position.y = value.location.y - difference
          // 3 that way, view will be changed smoothly
          let difference = abs(value.location.y - position.y)
          print("value.translation.height: \(value.translation.height)")
          if value.translation.height < 0 {
            position.y = value.location.y
          } else {
            position.y = value.location.y
          }

        } else {
          // find a point closest to this one that is within the frame
          position.y = furthestLocation(gesturePosition: value.location, frame: area.frame(in: .named("CalendarPreview"))).y
        } //: if
      }
      .onEnded { value in
        // Record position, so that we can expand/contract correctly
        originalPosition = position
        // Retain drag if user returns finger back on the circle
        isDraggable = true
        // snap to place if needed
        checkIfOverlaid = UUID()
      }
  }

  func calculateStretchTop(gestureHeight: CGFloat) {
    if gestureHeight < 0 { // user is stretching the view upwards
        // set height. add dragged value to current width.
      height = max(minHeight, height + abs(gestureHeight))
        // set position. x remains the same, y loses half of the gesture position
      position.y -= abs(gestureHeight * 0.5)
    } else { // user is contracting the view downwards
        // set height. Detract the positive value from the currently higher height.
        height = max(minHeight, height - gestureHeight)
      // set position to whichever is smaller (i.e. higher):
      // originalPosition.y + originalHeight*0.5 - minHeight * 0.5 (this is the maximum position we can achieve
      // OR
      // current position.y + what we can add: abs(gestureValue.translation.height * 0.5
        position.y = min((originalPosition!.y + originalHeight! * 0.5 - minHeight * 0.5), position.y + abs(gestureHeight * 0.5))
      // I tried using the following simpler method, but the results were inconsistent if the drag gesture was too fast.
      // if minHeight < (height! - gestureValue.translation.height) {
      //   position.y += abs(gestureValue.translation.height * 0.5)
      // }
    }
  }

    func calculateStretchBottom(gestureHeight: CGFloat) {
      if gestureHeight > 0 {
        height = max(minHeight, height + gestureHeight)
        position.y += abs(gestureHeight * 0.5)
      } else {
          height = max(minHeight, height - abs(gestureHeight))
          position.y = max((originalPosition!.y - originalHeight! * 0.5 + minHeight * 0.5), position.y - abs(gestureHeight * 0.5))
      }
    }
}

struct EventPreview: View {
  @State var position: CGPoint = .zero // will be replaced once event appears
  @State var eventOverlaid = UUID()
  @State var eventWasLongPressed = false
  @State var eventIsDraggable = false
   var body: some View {
    GeometryReader { proxy in
      ZStack {
        Color.gray
        EventView(position: $position, area: proxy, checkIfOverlaid: $eventOverlaid, wasLongPressed: $eventWasLongPressed, isDraggable: $eventIsDraggable)
      }
      .onTapGesture {
        // end gesture, like in iOS calendar. if draggable is true, turn off draggable and completedLongPress
        if eventIsDraggable {
          eventIsDraggable = false
          eventWasLongPressed = false
        }
      }
    }
    .frame(width: UIScreen.main.bounds.width, height: 300)
    .coordinateSpace(name: "CalendarPreview")
  }
}


struct EventView_Previews: PreviewProvider {
    static var previews: some View {
      EventPreview()
    }
}
