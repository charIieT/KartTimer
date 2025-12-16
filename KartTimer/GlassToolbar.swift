//
//  GlassToolbar.swift
//  KartTimer
//
//  Created by Charlie Taylor on 13/12/2025.
//

import SwiftUI

struct GlassToolbar<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .background(Color(white: 1, opacity: 0.08))
            .background(
                Color(white: 1, opacity: 0.03)
                    .blur(radius: 10)
            )
    }
}
