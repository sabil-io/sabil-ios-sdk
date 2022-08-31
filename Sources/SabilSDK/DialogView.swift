//
//  SwiftUIView.swift
//  
//
//  Created by Ahmed Saleh on 7/11/22.
//

import SwiftUI

struct DialogView: View {
    @ObservedObject var viewModel: DialogViewModel
    @State private var selected = Set<SabilDevice>()
    var onDetach: ((Set<SabilDevice>) -> Void)? = nil
    var body: some View {
        VStack {
            if viewModel.loadingDevices {
                if #available(iOS 14.0, *) {
                    ProgressView()
                } else {
                    Text("...")
                }
            } else {
                Text("limit_exceeded_title", bundle: Bundle.module)
                    .font(Font.system(size: 20))
                    .fontWeight(.medium)
                    .padding()
                    .padding(.top, 15)
                    .multilineTextAlignment(.center)
                Text("logout_to_proceed \(viewModel.attachedDevices.count - (viewModel.limitConfig?.overallLimit ?? viewModel.defaultDeviceLimit))", bundle: Bundle.module)
                    .multilineTextAlignment(.center)
                    .padding()
                List(viewModel.attachedDevices, id: \.self, selection: $selected) { device in
                    HStack {
                        Image(systemName: selected.contains(device) ? "checkmark.circle.fill" : "circle")
                            .font(Font.system(size: 24))
                            .foregroundColor(selected.contains(device) ? Color(.systemBlue) : Color.primary)
                        if device.info.device?.type == SabilDeviceType.mobile.rawValue {
                            Image(systemName: "iphone")
                                .font(.title)
                                .frame(width: 50, height: 50)
                        } else if device.info.device?.type == SabilDeviceType.tablet.rawValue {
                            Image(systemName: "ipad.landscape")
                                .font(.title)
                                .frame(width: 50, height: 50)
                        } else {
                            Image(systemName: "laptopcomputer")
                                .font(.title)
                                .frame(width: 50, height: 50)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            if device.id == viewModel.currentDeviceID {
                                Text("current_device", bundle: Bundle.module)
                                    .foregroundColor(.red)
                            } else {
                                Text(device.info.os?.name ?? "Unknown")
                            }
                            Text("attached", bundle: Bundle.module)
                                .font(.caption)
                                .padding(.vertical, 3)
                                .padding(.horizontal, 8)
                                .foregroundColor(Color("successDark", bundle: .module))
                                .background(Color("successLight", bundle: .module))
                                .cornerRadius(20)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("last_update", bundle: Bundle.module)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if #available(iOS 15.0, *) {
                                Text(device.updatedAt.formatted())
                                    .font(.footnote)
                                    .padding(.top, 6)
                            } else {
                                Text(device.updatedAt.toString())
                                    .font(Font.system(size: 12))
                                    .padding(.top, 6)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selected.contains(device) {
                            selected.remove(device)
                        } else {
                            selected.insert(device)
                        }
                    }
                    .listRowBackground(selected.contains(device) ? Color(.systemFill) : Color(.systemBackground))
                }
                .listStyle(PlainListStyle())
                .disabled(viewModel.detachLoading)

            }
            Spacer()
            Button {
                onDetach?(selected)
                selected.removeAll()
            } label: {
                if viewModel.detachLoading {
                    if #available(iOS 14.0, *) {
                        ProgressView()
                    } else {
                        // Fallback on earlier versions
                        Text("...")
                    }
                } else {
                    Text("logout_selected_devices", bundle: Bundle.module)
                }
            }
            .padding()
            .background(selected.isEmpty ? Color(.systemGray4) : Color(.systemRed))
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(selected.isEmpty || viewModel.detachLoading)
            Spacer()
                .frame(height: 16)
        }
    }
}

#if DEBUG
struct DialogView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = DialogViewModel(currentDeviceID: "1",
                                        attachedDevices: [
                                            SabilDevice(id: "0", info: SabilDeviceInfo(os: SabilOS(name: "Mac OS", version: "1.0"), device: SabilDeviceDetails(vendor: "Apple", type: nil, model: nil)), user: "xyz", createdAt: Date(), updatedAt: Date()),
                                            SabilDevice(id: "1", info: SabilDeviceInfo(os: SabilOS(name: "iOS", version: "1.0"), device: SabilDeviceDetails(vendor: "Apple", type: "mobile", model: "iPhone 13")), user: "xyz", createdAt: Date(), updatedAt: Date()),
                                            SabilDevice(id: "2", info: SabilDeviceInfo(os: SabilOS(name: "iOS", version: "1.0"), device: SabilDeviceDetails(vendor: "Apple", type: "tablet", model: "iPad 5")), user: "xyz", createdAt: Date(), updatedAt: Date()),
                                            SabilDevice(id: "3", info: SabilDeviceInfo(os: SabilOS(name: "iOS", version: "1.0"), device: SabilDeviceDetails(vendor: "Apple", type: "mobile", model: "iPhone 13")), user: "xyz", createdAt: Date(), updatedAt: Date()),
                                            SabilDevice(id: "4", info: SabilDeviceInfo(os: SabilOS(name: "Windows", version: "1.0"), device: SabilDeviceDetails(vendor: "Apple", type: "", model: "iPhone 13")), user: "xyz", createdAt: Date(), updatedAt: Date())
                                        ],
                                        limitConfig: SabilLimitConfig(mobileLimit: 1, overallLimit: 1))

        DialogView(viewModel: viewModel)
    }
}
#endif
