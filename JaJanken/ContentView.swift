//
//  ContentView.swift
//  JaJanken
//
//  Created by Carlos Mbendera on 2023-04-14.
//

import SwiftUI

struct ContentView: View {
    
    @State private var overlayPoints: [CGPoint] = []
    
    var CameraViewFinder : some View{
         CameraView {    overlayPoints = $0  }
             .overlay(FingersOverlay(with: overlayPoints)
                 .foregroundColor(.green)
             )
             .ignoresSafeArea()
         
     }
    
    var body: some View {
    
        
        ZStack{
            CameraViewFinder
                .rotationEffect(.degrees(-90))
                .scaledToFill()
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct FingersOverlay: Shape {
    let points: [CGPoint]
    private let pointsPath = UIBezierPath()
    
    init(with points: [CGPoint]) {
        self.points = points
    }
    
    func path(in rect: CGRect) -> Path {
        for point in points {
            pointsPath.move(to: point)
            pointsPath.addArc(withCenter: point, radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        }
        
        return Path(pointsPath.cgPath)
    }
}
