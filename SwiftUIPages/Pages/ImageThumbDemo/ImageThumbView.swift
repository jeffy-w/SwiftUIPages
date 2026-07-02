//
//  ImageThumbView.swift
//  SwiftUIPages
//
//  (\(\
//  ( -.-)
//  o_(")(")
//  -----------------------
//  Created by jeffy on 9/17/25.
//

import CoreImage
import ImageIO
import PhotosUI
import Photos
import SwiftUI
import UniformTypeIdentifiers

struct ImageThumbView: View {
    @Environment(\.displayScale) var displayScale
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var uiImage: UIImage?
    @State private var thumbImage: UIImage?
    @State private var showThumb = false
    @State private var jpegQuality: Double = 1.0
    @State private var thumbStyle: String = "jpeg"
    
    // 选图时保存原始 Data
    @State private var originalImageData: Data?
    @State private var thumbBytesString: String = ""
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundColor(.white)
                Text("切换压缩算法, 长按查看缩略图")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            if uiImage != nil {
                VStack {
                    HStack {
                        Text(
                            showThumb
                                ? "缩略图" + thumbBytesString
                                : "原图" + originalBytesString
                        )
                        .font(.caption)
                        .padding(6)
                        .background(Color.black.opacity(0.5))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .padding(8)
                        Spacer()
                        Button(action: {
                            self.uiImage = nil
                            self.thumbImage = nil
                            self.selectedItem = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.5).clipShape(Circle()))
                        }
                        .padding(12)
                    }
                }
            }
            Spacer()
            ZStack {
                if let uiImage {
                    if showThumb == false {
                        Image(uiImage: uiImage)
                            .resizable()
                            .interpolation(.high)
                            //                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .shadow(radius: 4)
                    } else if let thumbImage {
                        Image(uiImage: thumbImage)
                            .resizable()
                            //                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .shadow(radius: 4)
                    } else {
                        Text("没有获取到缩略图")
                    }
                    
                } else {
                    // 打开相册选择图片按钮
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        preferredItemEncoding: .current,
                        photoLibrary: .shared()
                    ) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .overlay(Text("请选择图片").foregroundColor(.white))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(contentMode: .fit)
            .onLongPressGesture(
                minimumDuration: 0.3,
                pressing: { isPressing in
                    showThumb = isPressing
                }, perform: {})
            Spacer()
            ImageThumbFuncPicker(
                selectedSegment: $thumbStyle,
                jpegQuality: $jpegQuality
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 56)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .onChange(of: selectedItem) { _, newItem in
            if let newItem {
                Task {
                    let data = await loadOriginalAssetData(from: newItem)
                    guard let data else { return }
                    originalImageData = data
                    if let rawImage = rawDataToUIImageWithCIRAWFilter(data)
                    {
                        uiImage = rawImage
                    } else if let image = UIImage(data: data) {
                        uiImage = image
                    } else {
                        uiImage = nil
                    }
                    updateThumbImage()
                }
            }
        }
        .onChange(of: thumbStyle) { _, newValue in
            updateThumbImage()
        }
    }
    
    func rawDataToUIImageWithCIRAWFilter(_ data: Data) -> UIImage? {
        
        // 识别类型作为 hint（有助于正确解析 RAW）
        var identifierHint: String? = nil
        var orientationFromEXIF: CGImagePropertyOrientation? = nil
        if let source = CGImageSourceCreateWithData(data as CFData, nil) {
            if let type = CGImageSourceGetType(source) {
                identifierHint = type as String
            }
            if let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                let rawValue = props[kCGImagePropertyOrientation] as? UInt32,
                let ori = CGImagePropertyOrientation(rawValue: rawValue)
            {
                orientationFromEXIF = ori
            }
        }
        // 优先用 URL 初始化，部分 RAW 在 Data 路径可能只返回低清预览
        var filter: CIRAWFilter?
        if let hint = identifierHint, let utType = UTType(hint), let ext = utType.preferredFilenameExtension {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(ext)
            do {
                try data.write(to: url, options: .atomic)
                filter = CIRAWFilter(imageURL: url)
            } catch {
                filter = nil
            }
        }
        if filter == nil {
            filter = CIRAWFilter(imageData: data, identifierHint: identifierHint)
        }
        guard let filter else { return nil }
        // 全尺寸、禁用草稿、应用方向
        filter.scaleFactor = 1.0
        filter.isDraftModeEnabled = false
        if let o = orientationFromEXIF {
            filter.orientation = o
        }
        // 使用最新解码器，避免回退到兼容模式
        if let latest = filter.supportedDecoderVersions.last {
            filter.decoderVersion = latest
        }
        
        let context = CIContext()
        guard let ci = filter.outputImage else { return nil }
        guard let cg = context.createCGImage(ci, from: ci.extent) else { return nil }
        return UIImage(cgImage: cg, scale: displayScale, orientation: .up)
    }

    // 使用 PhotoKit 拉取原始资源数据（优先 RAW），避免只拿到嵌入预览
    private func loadOriginalAssetData(from item: PhotosPickerItem) async -> Data? {
        // 通过本地标识符获取 PHAsset
        if let id = item.itemIdentifier {
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
            if let asset = assets.firstObject {
                // 查找 RAW 资源
                let resources = PHAssetResource.assetResources(for: asset)
                let rawExtensions = [
                    ".dng", ".arw", ".cr2", ".cr3", ".nef", ".raf",
                    ".orf", ".rw2", ".srw", ".pef", ".crw"
                ]
                let rawRes = resources.first { res in
                    let uti = res.uniformTypeIdentifier.lowercased()
                    if uti.contains("raw") { return true }
                    let name = res.originalFilename.lowercased()
                    return rawExtensions.contains { name.hasSuffix($0) }
                }
                if let rawRes {
                    let opts = PHAssetResourceRequestOptions()
                    opts.isNetworkAccessAllowed = true
                    if let data = try? await requestData(for: rawRes, options: opts) {
                        return data
                    }
                }
                // 回退：请求原图数据（可能是渲染后的 JPEG/HEIC）
                if let data = try? await requestImageData(asset: asset) { return data }
            }
        }
        return nil
    }

    // 拉取 PHAssetResource 的数据
    private func requestData(for resource: PHAssetResource, options: PHAssetResourceRequestOptions? = nil) async throws -> Data {
        try await withCheckedThrowingContinuation { cont in
            let buffer = NSMutableData()
            PHAssetResourceManager.default().requestData(
                for: resource,
                options: options,
                dataReceivedHandler: { chunk in buffer.append(chunk) },
                completionHandler: { error in
                    if let error { cont.resume(throwing: error) }
                    else { cont.resume(returning: buffer as Data) }
                }
            )
        }
    }

    // 获取原图数据（可能不是 RAW，但优于小预览）
    private func requestImageData(asset: PHAsset) async throws -> Data? {
        try await withCheckedThrowingContinuation { cont in
            let opts = PHImageRequestOptions()
            opts.isNetworkAccessAllowed = true
            opts.deliveryMode = .highQualityFormat
            opts.version = .original
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: opts) { data, _, _, _ in
                cont.resume(returning: data)
            }
        }
    }
    
    private func updateThumbImage() {
        guard let uiImage else { return }
        var thumbData: Data?
        switch thumbStyle {
        case "heic(17+)":
            thumbData = uiImage.heicData()
        case "jpeg":
            thumbData = uiImage.jpegData(compressionQuality: CGFloat(jpegQuality))
        case "png":
            thumbData = uiImage.pngData()
        default:
            thumbData = nil
        }
        if let thumbData {
            thumbImage = UIImage(data: thumbData, scale: displayScale)
            let bytes = thumbData.count
            if bytes > 1024 * 1024 {
                thumbBytesString = String(format: "%.2fMb", Double(bytes) / (1024 * 1024))
            } else if bytes > 1024 {
                thumbBytesString = String(format: "%.2fKb", Double(bytes) / 1024)
            } else {
                thumbBytesString = "\(bytes)B"
            }
        } else {
            thumbImage = nil
            thumbBytesString = " 0B"
        }
    }
    
    // 计算原图体积
    var originalBytesString: String {
        guard let data = originalImageData else { return "0B" }
        let bytes = data.count
        if bytes > 1024 * 1024 {
            return String(format: "%.2fMb", Double(bytes) / (1024 * 1024))
        } else if bytes > 1024 {
            return String(format: "%.2fKb", Double(bytes) / 1024)
        } else {
            return "\(bytes)B"
        }
    }
    
    struct ImageThumbFuncPicker: View {
        @Binding var selectedSegment: String
        let options = ["heic(17+)", "jpeg", "png"]
        @Binding var jpegQuality: Double
        
        var body: some View {
            VStack {
                Picker("Select an option", selection: $selectedSegment) {
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedSegment) { newValue, _ in
                    print("Selected segment: \(newValue)")
                }
                if selectedSegment == "jpeg" {
                    HStack {
                        Text("压缩比: \(String(format: "%.2f", jpegQuality))")
                            .foregroundColor(.white)
                            .font(.caption)
                        Slider(value: $jpegQuality, in: 0.01...1.0, step: 0.01)
                            .accentColor(.blue)
                            .frame(maxWidth: 200)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .padding(.vertical, 8)
                }
            }
            .animation(.default, value: selectedSegment)
        }
    }
}

#Preview {
    ImageThumbView()
}
