//
//  DragGestureTestApp.swift
//  Shared
//
//  Created by Jan Stehlík on 26.07.2022.
//
#warning("README")

// MARK: Abstract:
// This sample app attempts to replicate the daily timeline of iOS Calendar in SwiftUI.
// We are currently stuck on the issue of auto-scrolling when we are moving or stretching an event beyond the currently visible bounds of the timeline. The timeline should automatically scroll up/down. However, the current implementation (which uses scrollTo: method) is very choppy and unreliable. The logic of this implementation is described below.

// MARK: To see the problem:
// 1) Drag your finger to scroll the calendar timeline down by a few rows (currently, we only implemented the logic for auto-scrolling up, so we need the timeline to be scrolled down by a few rows)
// 2) Long press on the event to make it draggable
// 3) Try to drag the event up, to the very first rows (which are now hidden, as per step (1)
// 4) The timeline will begin to auto-scroll, but this will be very choppy and unreliable.

// MARK: Current logic that uses scrollTo: method
// CalendarView holds variables triggerAutoScroll(UUID), draggingInAutoScrollArea(Bool) and autoScrollOffset(CGFloat)
// DraggableEvent changes draggingInAutoScrollArea when we enter the "legitimate" area (top/bottom area of the calendar, where we need the timeline to automatically start scrolling up/down), and fires triggerAutoScroll. When the user stops dragging, or the drag position leaves the legitimate area, draggingInAutoScrollArea is switched off, and auto-scroll ends.
// CalendarView detects onChange of triggerAutoScroll and initiates the first auto-scroll. It also calculates autoScrollOffset as a difference between current offset and the row to which we're auto-scrolling (using scrollTo: method).
// DraggableEvent aligns its position to whatever calculation and detracts autoScrollOffset. It then resets it to 0.
// As normalisedOffset aligns with the appropriate row, triggerAutoScroll is updated again. This happens if offset is aligned with any row && draggingInAutoScrollArea == true.
// CalendarView detects onChange of triggerAutoScroll and initiates another auto-scroll.

// MARK: Summary of CalendarView
// State triggerAutoScroll(UUID)
// State draggingInAutoScrollArea(Bool)
// State autoScrollOffset(CGFloat) = 0
// onChange of triggerAutoScroll
  // autoScrollOffset = abs(normalisedOffset - rowToScrollTo
  // execute scroll
// offset preference change
  // if draggingInAutoScrollArea == true && offset is at the row { (animation from 1st loop is finished and we need another)
    // triggerAutoScroll = UUID()

// MARK: Summary of DraggableEventView
// Binding draggingInAutoScrollArea(Bool)
// Binding triggerAutoScroll(UUID)
// Binding autoScrollOffset(CGFloat)
// onChanged (with every gesture update)
  // if in legitimate area && draggingInAutoScrollArea == false { (user moved into legitimate area for the first time)
    // draggingInAutoScrollArea = true
    // triggerAutoScroll = UUID()
  // else (user moved outside of legitimate area)
    // draggingInAutoScrollArea = false
  // position = whatever position - autoScrollOffset
  // autoScrollOffset = 0
// onEnded (gesture ended)
  // draggingInAutoScrollArea = false

import SwiftUI

@main
struct DragGestureTestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
