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
/// - Event can be stretched and moved across rows, but the edges must align with the rows when drag gesture ends

struct CalendarView: View {
  @State var numberOfRows = 3
  @State var eventPosition: CGPoint = .zero // will be updated once event appears
  @State var eventOverlaid = UUID()
  @State var eventWasLongPressed = false
  @State var eventIsDraggable = false
  var body: some View {
    GeometryReader { proxy in
      ZStack {
//      VStack {
//        Button("Add row") {
//          numberOfRows += 1
//        } //: Button
//        VStack(spacing: 0) {
//          ForEach(0..<numberOfRows, id: \.self) { row in
//            RowView(rowNumber: row+1)
//          } //: ForEach
//        } //: VStack
//      } //: Scrollview
        EventView(position: $eventPosition, area: proxy, checkIfOverlaid: $eventOverlaid, wasLongPressed: $eventWasLongPressed, isDraggable: $eventIsDraggable)
      } //: ZStack
    } //: GeometryReader
    .background(.green.opacity(0.2))
    .frame(width: UIScreen.main.bounds.width, height: 400)
    // .coordinateSpace(name: "Calendar")
  }
}

struct GanttChartView_Previews: PreviewProvider {
  static var previews: some View {
    CalendarView()
  }
}
