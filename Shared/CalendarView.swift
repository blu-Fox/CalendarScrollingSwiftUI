//
//  GanttChartView.swift
//  DragGestureTest
//
//  Created by Jan Stehlík on 30.07.2022.
//

import SwiftUI

/// TODO:
/// Even struct (like expandable rectangle struct)
/// - On long press gesture within the area with rows, create a new event in that position that is immediately draggable

struct CalendarView: View {
  @State var eventOverlaid = UUID()
  @State var eventWasLongPressed = false
  @State var eventIsDraggable = false
  @State var eventOffset: CGFloat = 0
  @State var calendarFrame: CGRect?
  @State var coordinateSpace: CoordinateSpace = .local

  var body: some View {

    ZStack {

      ScrollView {

        ZStack {

          VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { row in
              RowView(rowNumber: row)
            } //: ForEach
          } //: VStack
          .onTapGesture {
            // Reset gestures when user taps outside of the draggable event, like in iOS calendar.
            eventIsDraggable = false
            eventWasLongPressed = false
          } //: on tap

          GeometryReader { proxy in
            // Get the offset of scrollview from the top of the frame.
            let offset = proxy.frame(in: .named("CalendarView")).minY
            Color.clear
              // Save the offset as preference key value
              .preference(key: ScrollViewOffsetPreferenceKey.self, value: offset)
              // Record the original calendarView frame so views outside of Scrollview (specifically, draggableEventView can use it. This cannot be done outside of Scrollview. As scrollview is scrolled, this value actually changes, so we should only record it when the view first appears.
              .onAppear {
                calendarFrame = proxy.frame(in: .named("CalendarView"))
                coordinateSpace = .named("CalendarView")
              }

//            EventView(area: proxy,
//                      checkIfOverlaid: $eventOverlaid,
//                      wasLongPressed: $eventWasLongPressed,
//                      isDraggable: $eventIsDraggable)
          } //: GeometryReader
          .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
            eventOffset = value
          }
        } //: ZStack
        // coordinateSpace should not be attached to ScrollView, because it gets smaller as we scroll down, for some reason. Placing it in child ZStack is fine.
        .coordinateSpace(name: "Calendar")
      } //: Scrollview

      // Once calendar frame has been recorded, we can show a draggable view
      if let calendarFrame = calendarFrame {
        if coordinateSpace == .named("CalendarView") {
          DraggableEventView(parentFrame: calendarFrame,
                             checkIfOverlaid: $eventOverlaid,
                             wasLongPressed: $eventWasLongPressed,
                             isDraggable: $eventIsDraggable,
                             coordinateSpace: coordinateSpace)
          .offset(y: eventOffset)
        }
      }

    } //: ZStack with scrollview and overlay view
    .coordinateSpace(name: "CalendarView")
  } //: body
} //: struct

struct GanttChartView_Previews: PreviewProvider {
  static var previews: some View {
    CalendarView()
  }
}

// Scrollview behaviours.
// (1) Fully scrollable when event is not being edited.
// (2) Partially scrollable when event is being edited but not dragged/stretched. Scrollview only works in non-event areas.
// There is no non-scrollable state in iOS calendar. Underlying scrollview can be scrolled even when we're moving an event.
enum ScrollState {
  case fullyScrollable
  case partiallyScrollable
}
