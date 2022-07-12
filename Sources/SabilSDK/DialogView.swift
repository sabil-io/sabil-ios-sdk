//
//  SwiftUIView.swift
//  
//
//  Created by Ahmed Saleh on 7/11/22.
//

import SwiftUI

struct DialogView: View {
    @ObservedObject var viewModel: DialogViewModel
    var body: some View {
        VStack {
            if viewModel.loadingDevices {
                if #available(iOS 14.0, *) {
                    ProgressView()
                } else {
                    Text("...")
                }
            } else {
                List(viewModel.attachedDevices) {
                    Text($0.deviceInfo.os?.name ?? "Unknown")
                }
            }
        }
    }
}

#if DEBUG
struct DialogView_Previews: PreviewProvider {
    static var previews: some View {
        DialogView(viewModel: DialogViewModel())
    }
}
#endif
