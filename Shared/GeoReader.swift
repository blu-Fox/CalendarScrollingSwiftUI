//
//  GeoReader.swift
//  DragGestureTest
//
//  Created by Jan Stehlík on 28.07.2022.
//

import SwiftUI

struct GeoReader: View {
  @State private var position: CGPoint = .zero
  let blueCirclePosition = CGPoint(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/3)

  var body: some View {
    GeometryReader { proxy in
      ZStack {

        Circle()
          .fill(.blue)
          .frame(width: 80, height: 80)
          .position(blueCirclePosition)

        HStack {
          ForEach(0..<5, id: \.self) { _ in
            CircleView(position: $position)
          }
        }

        Circle()
          .fill(.orange)
          .frame(width: 40, height: 40)
          .position(position)
          .onAppear {
            position = CGPoint(x: proxy.frame(in: .global).midX,
                               y: proxy.frame(in: .global).midY + 200)
          }
          .gesture(
            DragGesture()
              .onChanged { value in
                position = value.location
              }
              .onEnded { value in
                // snap here
                // if less than 40 points from centre of custom coordinate space
                if CGPointDistance(from: value.location, to: blueCirclePosition) < 40 {
                  withAnimation {
                    position = blueCirclePosition
                  }
                  // snap
                } else {
                  position = value.location
                }
              })

      }
    }
    .ignoresSafeArea()
  }

  // Calculate distance between points
  func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
      return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
  }
  func CGPointDistance(from: CGPoint, to: CGPoint) -> CGFloat {
      return sqrt(CGPointDistanceSquared(from: from, to: to))
  }

}

struct CircleView: View {
  @Binding var position: CGPoint
  var body: some View {
    GeometryReader { proxy in
      Circle()
        .foregroundColor(color(frame: proxy.frame(in: .global)))
        .animation(Animation.easeIn, value: color(frame: proxy.frame(in: .global)))
    }
    .frame(width: 50, height: 50)
  }

  func color(frame: CGRect) -> Color {
    if position.x >= frame.minX && position.x <= frame.maxX &&
        position.y >= frame.minY && position.y <=  frame.maxY {
      return .red
    }
    return .black
  }
}

struct GeoReader_Previews: PreviewProvider {
  static var previews: some View {
    GeoReader()
  }
}
