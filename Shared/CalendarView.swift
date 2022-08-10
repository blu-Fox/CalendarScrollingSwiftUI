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
  @State var calendarOffset: CGFloat = 0
  @State var calendarFrame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
  // Set the visible "peeping hole" view of the calendar
  let visibleCalendarFrame: CGFloat = 700

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
              // Save the offset of Scrollview as preference key value
              .preference(key: ScrollViewOffsetPreferenceKey.self, value: offset)
            // Track changes in the offset of Scrollview
              .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
                calendarOffset = value
              }
            // Record the original calendarFrame so views outside of Scrollview (specifically, draggableEventView can use it. This cannot be done outside of Scrollview. As scrollview is scrolled, this value actually changes, so we should only record it when the view first appears.
            .onAppear {
                calendarFrame = proxy.frame(in: .named("CalendarView"))
                  .offsetBy(dx: 0, dy: 0 - calendarOffset)
              }
//            EventView(area: proxy,
//                      wasLongPressed: $eventWasLongPressed,
//                      isDraggable: $eventIsDraggable)
          } //: GeometryReader

        } //: ZStack
        // coordinateSpace should not be attached to ScrollView, because it gets smaller as we scroll down, for some reason. Placing it in child ZStack is fine.
        .coordinateSpace(name: "Calendar")
      } //: Scrollview
      // This frame constrains Scrollview relative to other elements and thus sets our view into Scrollview, sort of like a peeping hole. We can set this to whatever we want. But it should be something smaller or equal to screen height.
      .frame(height: visibleCalendarFrame)

      // Once calendar frame has been recorded, we can show a draggable view.
      if calendarFrame != CGRect(x: 0, y: 0, width: 0, height: 0) {
          DraggableEventView(parentFrame: calendarFrame,
                             visibleCalendarFrameHeight: visibleCalendarFrame,
                             wasLongPressed: $eventWasLongPressed,
                             isDraggable: $eventIsDraggable)
          // Event should be offset by the amout that we scroll the underlying scrollview. That way, it appears to be in the same position relative to the scrollview.
          .offset(y: calendarOffset)
          // This frame sets the maximum reach of DraggableEventView and should be equal to the total height of calendar view. Without this, the maximum frame would be set by the parentZStack, which has a default height of screensize - safe areas. This would mess up drag gestures, as the event view would not render in sizes larger than this size.
          .frame(height: calendarFrame.height)
      }

      // Header and footer, with space in between. This should have higher zIndex than Scrollview and DraggableEventView
      VStack {
        Rectangle().fill(.gray)
        Spacer(minLength: visibleCalendarFrame)
        Rectangle().fill(.gray)
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
