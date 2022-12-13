//
//  GanttChartView.swift
//  DragGestureTest
//
//  Created by Jan Stehlík on 30.07.2022.
//
// Abstract: View for the daily calendar timeline.

import SwiftUI

struct CalendarView: View {
  // eventWasLongPressed: determines if a calendar event was longPressed and can be dragged around. Tapping anywhere else turns this off and makes the view unmovable (like in iOS calendar)
  @State var eventWasLongPressed = false
  // eventIsDraggable: determines if any given event is draggable. This second var works in tandem with eventWasLongPressed. 2 vars are needed because there are 2 gesture modifiers, because Gesture and Sequenced Gesture are not the same type. So we cannot use a ternary operator.
  @State var eventIsDraggable = false
  // calendarOffset: current scrollview offset of the calendar.
  @State var calendarOffset: CGFloat = 0
  // calendarFrame: here we store the original calendarFrame (once CalendarView appears) so views outside of Scrollview (specifically, DraggableEventView) can use it.
  @State var calendarFrame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
  // visibleCalendarFrame: set the visible "peeping hole" through which we see the calendar
  let visibleCalendarFrame: CGFloat = 700
  // The following variables are used to implement auto-scrolling.
  // draggingInAutoScrollArea: determines if a drag gesture is within a legitimate area for auto-scrolls
  @State var draggingInAutoScrollArea = false
  // triggerAutoScroll: triggers an automatic scroll to the nearest row ouside of the visible area
  @State var triggerAutoScroll = UUID()
  // autoScrollOffset: used to position draggable event view correctly when auto-scrolling. Calculated as difference between current normalisedOffset and row to which we are auto-scrolling.
  @State var autoScrollOffset: CGFloat = 0
  // pointsArray: array of points into which we can auto-scroll.
  var pointsArray: [CGFloat] {
    var array: [CGFloat] = []
    // 25 points in total (0 point + number of rows)
    for row in 0...24 {
      // 50 is same as row height
      array.append(CGFloat(0 + 50*row))
    }
    return array
  }
  

  var body: some View {
    ZStack {
      ScrollView {
        ScrollViewReader { scrollProxy in
          ZStack {
            VStack(spacing: 0) {
              ForEach(0..<24, id: \.self) { row in
                RowView(rowNumber: row)
                  .id(row)
              } //: ForEach
            } //: VStack
            .onChange(of: triggerAutoScroll) { value in
              print("Firing auto-scroll")
              // Row to which we should auto-scroll
              var row: Int {
                // Normalised offset, because our inner view is larger (1200) to accomodate drag gestures. The top is pre-offset by (1200 - 700)/2 = 250. As a result, normalisedOffset begins at 0 on top of the visible scrollview. Also inverted the value (0-offset), so scrolling down produces a positive value.
                let normalisedOffset = 0 - (calendarOffset - (calendarFrame.height - visibleCalendarFrame)/2)
                // Take the array of row origins (+ end of last row), and filter it so that the row top is less than calendarOffset, but more than calendarOffset - 50. This gives us one row to scroll to.
                let rowPosition = pointsArray.filter { $0 < normalisedOffset && $0 > normalisedOffset - 50 }.first
                // set autoScrollOffset
                autoScrollOffset = abs(normalisedOffset - (rowPosition ?? 0))
                print("autoScrollOffset in Calendar is: \(autoScrollOffset)")
                // return correct row id(Int), e.g. 700.00 -> 14
                return Int((rowPosition ?? 0)/50)
              } //: row
              withAnimation(.linear) {
                scrollProxy.scrollTo(row)
              }

            } //: onChange
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
                  print("CalendarOffset: \(calendarOffset)")
                  // Normalised offset, because our inner view is larger (1200) to accomodate drag gestures. The top is pre-offset by (1200 - 700)/2 = 250. As a result, normalisedOffset begins at 0 on top of the visible scrollview. Also inverted the value (0-offset), so scrolling down produces a positive value.
                  let normalisedOffset = 0 - (calendarOffset - (calendarFrame.height - visibleCalendarFrame)/2)
                  print("NormalisedOffset: \(normalisedOffset)")
                  // if animation from 1st loop is finished and we need another)
                  // We want to check if normalisedOffset is close to one of the values in pointsArray
                  let offsetAtRow = pointsArray.contains { point in
                      if abs(point - normalisedOffset) < 0.5 {
                          return true
                      } else {
                          return false
                      }
                  }
                  if draggingInAutoScrollArea && offsetAtRow {
                    triggerAutoScroll = UUID()
                  }
                }
                // Record the original calendarFrame so views outside of Scrollview (specifically, DraggableEventView) can use it. This cannot be done outside of Scrollview. As scrollview is scrolled, this value actually changes, so we should only record it when the view first appears.
                .onAppear {
                  calendarFrame = proxy.frame(in: .named("CalendarView"))
                    .offsetBy(dx: 0, dy: 0 - calendarOffset)
                }
            } //: GeometryReader

          } //: ZStack
          // coordinateSpace should not be attached to ScrollView, because it gets smaller as we scroll down, for some reason. Placing it in child ZStack is fine.
          .coordinateSpace(name: "Calendar")
        } //: ScrollViewReader
      } //: Scrollview
      // This frame constrains Scrollview relative to other elements and thus sets our view into Scrollview, sort of like a peeping hole. We can set this to whatever we want. But it should be something smaller or equal to screen height.
      .frame(height: visibleCalendarFrame)

      // Once calendar frame has been recorded, we can show a draggable view.
      if calendarFrame != CGRect(x: 0, y: 0, width: 0, height: 0) {
        DraggableEventView(parentFrame: calendarFrame,
                           visibleCalendarFrameHeight: visibleCalendarFrame,
                           wasLongPressed: $eventWasLongPressed,
                           isDraggable: $eventIsDraggable,
                           calendarOffset: calendarOffset,
                           draggingInAutoScrollArea: $draggingInAutoScrollArea,
                           triggerAutoScroll: $triggerAutoScroll,
                           autoScrollOffset: $autoScrollOffset)
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
// NOTE: There is no non-scrollable state in iOS calendar. Underlying scrollview can be scrolled even when we're moving an event.
enum ScrollState {
  case fullyScrollable
  case partiallyScrollable
}
