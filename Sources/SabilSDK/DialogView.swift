//
//  SwiftUIView.swift
//  
//
//  Created by Ahmed Saleh on 7/11/22.
//

import SwiftUI

@available(iOS 13.0.0, *)
struct DialogView: View {
    var body: some View {
        Text("Hello, World!")
    }
}

#if DEBUG
@available(iOS 13.0.0, *)
struct DialogView_Previews: PreviewProvider {
    static var previews: some View {
        DialogView()
    }
}
#endif
