//
//  SwiftUIView.swift
//  
//
//  Created by Ahmed Saleh on 7/11/22.
//

import SwiftUI

struct DialogView: View {
    @ObservedObject var viewModel: DialogViewModel
    @State private var selected = Set<SabilDeviceUsage>()
    var onDetach: ((Set<SabilDeviceUsage>) -> Void)? = nil
    var body: some View {
        VStack {
            if viewModel.loadingDevices {
                if #available(iOS 14.0, *) {
                    ProgressView()
                } else {
                    Text("...")
                }
            } else {
                Text("Too many devices using your account")
                    .font(Font.system(size: 20))
                    .fontWeight(.medium)
                    .padding()
                    .padding(.top, 15)
                Text("To proceed, please log out \(viewModel.attachedDevices.count - viewModel.limitConfig.overallLimit) device(s) from the list below.")
                    .padding()
                List(viewModel.attachedDevices, id: \.self, selection: $selected) { usage in
                    HStack {
                        Image(systemName: selected.contains(usage) ? "checkmark.circle.fill" : "circle")
                            .font(Font.system(size: 24))
                            .foregroundColor(selected.contains(usage) ? Color(.systemBlue) : Color.primary)
                        if usage.deviceInfo.device?.type == SabilDeviceType.mobile.rawValue {
                            Image(systemName: "iphone")
                                .font(.title)
                                .frame(width: 50, height: 50)
                        } else if usage.deviceInfo.device?.type == SabilDeviceType.tablet.rawValue {
                            Image(systemName: "ipad.landscape")
                                .font(.title)
                                .frame(width: 50, height: 50)
                        } else {
                            Image(systemName: "laptopcomputer")
                                .font(.title)
                                .frame(width: 50, height: 50)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            if usage.deviceID == viewModel.currentDeviceID {
                                Text(LocalizedStringKey("Current device"))
                                    .foregroundColor(.red)
                            } else {
                                Text(usage.deviceInfo.os?.name ?? "Unknown")
                            }
                            Text("Attached")
                                .font(.caption)
                                .padding(.vertical, 3)
                                .padding(.horizontal, 8)
                                .foregroundColor(Color("successDark", bundle: .module))
                                .background(Color("successLight", bundle: .module))
                                .cornerRadius(20)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Last update")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if #available(iOS 15.0, *) {
                                Text(usage.updatedAt.formatted())
                                    .font(.footnote)
                                    .padding(.top, 6)
                            } else {
                                Text(usage.updatedAt.toString())
                                    .font(Font.system(size: 12))
                                    .padding(.top, 6)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selected.contains(usage) {
                            selected.remove(usage)
                        } else {
                            selected.insert(usage)
                        }
                    }
                    .listRowBackground(selected.contains(usage) ? Color(.systemFill) : Color(.systemBackground))
                }
                .listStyle(PlainListStyle())
                .disabled(viewModel.detachLoading)

            }
            Spacer()
            Button {
                onDetach?(selected)
            } label: {
                if viewModel.detachLoading {
                    if #available(iOS 14.0, *) {
                        ProgressView()
                    } else {
                        // Fallback on earlier versions
                        Text("...")
                    }
                } else {
                    Text("Log out the selected devices")
                }
            }
            .padding()
            .background(selected.isEmpty ? Color(.systemGray) : Color.black)
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
                                            SabilDeviceUsage(id: "0", deviceID: "0", deviceInfo: SabilDeviceInfo(os: SabilOS(name: "Mac OS", version: "1.0"), device: SabilDevice(vendor: "Apple", type: nil, model: nil)), user: "xyz", detachedAt: nil, createdAt: Date(), updatedAt: Date()),
                                            SabilDeviceUsage(id: "1", deviceID: "1", deviceInfo: SabilDeviceInfo(os: SabilOS(name: "iOS", version: "1.0"), device: SabilDevice(vendor: "Apple", type: "Mobile", model: "iPhone 13")), user: "xyz", detachedAt: nil, createdAt: Date(), updatedAt: Date()),
                                            SabilDeviceUsage(id: "2", deviceID: "2", deviceInfo: SabilDeviceInfo(os: SabilOS(name: "iOS", version: "1.0"), device: SabilDevice(vendor: "Apple", type: "Tablet", model: "iPad 5")), user: "xyz", detachedAt: nil, createdAt: Date(), updatedAt: Date()),
                                            SabilDeviceUsage(id: "3", deviceID: "3", deviceInfo: SabilDeviceInfo(os: SabilOS(name: "iOS", version: "1.0"), device: SabilDevice(vendor: "Apple", type: "Mobile", model: "iPhone 13")), user: "xyz", detachedAt: nil, createdAt: Date(), updatedAt: Date()),
                                            SabilDeviceUsage(id: "4", deviceID: "4", deviceInfo: SabilDeviceInfo(os: SabilOS(name: "iOS", version: "1.0"), device: SabilDevice(vendor: "Apple", type: "Mobile", model: "iPhone 13")), user: "xyz", detachedAt: nil, createdAt: Date(), updatedAt: Date())
                                        ],
                                        limitConfig: SabilLimitConfig(mobileLimit: 1, overallLimit: 1))

        DialogView(viewModel: viewModel)
    }
}
#endif
