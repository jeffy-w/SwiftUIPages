///
//  @filename   DemoPages.swift
//  @package    SwiftUIPageDemos
//
//  @author     jeffy
//  @date       2023/11/30
//  @abstract
//
//  Copyright © 2023 and Confidential to jeffy All rights reserved.
//

import SwiftUI

public struct DemoPages: View {
    public init() {}

    public var body: some View {
        NavigationView {
            List {
                NavigationLink {
                    AnimatedTextView("SwiftUI Page Demos", fontSize: 36)
                } label: {
                    DemoLabel(title: "Animated Text")
                }
                NavigationLink {
                    OnBoardingView()
                } label: {
                    DemoLabel(title: "OnBoarding")
                }
                NavigationLink {
                    DataCRUDView()
                } label: {
                    DemoLabel(title: "SwiftData CRUD")
                }
                NavigationLink {
                    GeometryReader {
                        let size = $0.size
                        let safeArea = $0.safeAreaInsets
                        StickyHeaderView(size: size, safeArea: safeArea)
                            .ignoresSafeArea(.all, edges: .top)
                    }
                } label: {
                    DemoLabel(title: "Sticky Header")
                }
                NavigationLink {
                    CustomTabbarView()
                } label: {
                    DemoLabel(title: "Custom Tabbar")
                }
                NavigationLink {
                    BaloonAnimationView()
                } label: {
                    DemoLabel(title: "Baloon Animation")
                }
                NavigationLink {
                    EmojiPickerView()
                } label: {
                    DemoLabel(title: "Emoji Picker")
                }
//                NavigationLink {
//                    AsyncImagesViewerExampleView()
//                } label: {
//                    DemoLabel(title: "Async Images")
//                }
                NavigationLink {
                    AppleFundationModelView()
                } label: {
                    DemoLabel(title: "Apple Foundation Model")
                }
                NavigationLink {
                    ImageThumbView()
                } label: {
                    DemoLabel(title: "Image Thumb")
                }
                NavigationLink {
                    UploadSpeedWidgetView()
                } label: {
                    DemoLabel(title: "Upload Speed Widget")
                }

            }
            .navigationTitle(Text("APP_NAME"))
        }

    }
}

struct DemoLabel: View {
    var title: String
    var content: String?
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title3)
                .fontWeight(.medium)
            Group {
                if let content = content {
                    Text(content)
                        .font(.body)
                }
            }
        }
    }
}

#Preview {
    DemoPages()
}
