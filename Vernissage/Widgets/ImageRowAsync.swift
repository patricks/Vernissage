//
//  https://mczachurski.dev
//  Copyright © 2023 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//
    
import SwiftUI
import MastodonKit
import NukeUI

struct ImageRowAsync: View {
    @EnvironmentObject var applicationState: ApplicationState
    @EnvironmentObject var routerPath: RouterPath

    @State public var statusViewModel: StatusModel

    @State private var imageHeight: Double
    @State private var imageWidth: Double
    @State private var heightWasPrecalculated: Bool
    @State private var showThumbImage = false
    
    init(statusViewModel: StatusModel) {
        self.statusViewModel = statusViewModel
        
        // Calculate size of frame (first from cache, then from metadata).
        if let firstAttachment = statusViewModel.mediaAttachments.first,
           let size = ImageSizeService.shared.get(for: firstAttachment.url) {
            self.imageWidth = size.width
            self.imageHeight = size.height
            
            self.heightWasPrecalculated = true
        } else if let firstAttachment = statusViewModel.mediaAttachments.first,
           let imgHeight = (firstAttachment.meta as? ImageMetadata)?.original?.height,
           let imgWidth = (firstAttachment.meta as? ImageMetadata)?.original?.width {
            
            let size = ImageSizeService.shared.calculate(for: firstAttachment.url, width: imgWidth, height: imgHeight)
            self.imageWidth = size.width
            self.imageHeight = size.height

            self.heightWasPrecalculated = true
        } else {
            self.imageWidth = UIScreen.main.bounds.width
            self.imageHeight = UIScreen.main.bounds.width * 0.75
            heightWasPrecalculated = false
        }
    }
    
    var body: some View {
        if let attachment = statusViewModel.mediaAttachments.first {
            ZStack {
                LazyImage(url: attachment.url) { state in
                    if let image = state.image {
                        if self.statusViewModel.sensitive {
                            ZStack {
                                ContentWarning(blurhash: attachment.blurhash, spoilerText: self.statusViewModel.spoilerText) {
                                    self.imageView(image: image)
                                }
                                
                                if showThumbImage {
                                    FavouriteTouch {
                                        self.showThumbImage = false
                                    }
                                }
                            }
                        } else {
                            ZStack {
                                self.imageView(image: image)
                                
                                if showThumbImage {
                                    FavouriteTouch {
                                        self.showThumbImage = false
                                    }
                                }
                            }
                        }
                    } else if state.error != nil {
                        ZStack {
                            Rectangle()
                                .fill(Color.placeholderText)
                                .scaledToFill()
                            
                            VStack(alignment: .center) {
                                Spacer()
                                Text("Cannot download image")
                                    .foregroundColor(.systemBackground)
                                Spacer()
                            }
                        }
                        .frame(width: self.imageWidth, height: self.imageHeight)
                    } else {
                        VStack(alignment: .center) {
                            BlurredImage(blurhash: attachment.blurhash)
                        }
                        .frame(width: self.imageWidth, height: self.imageHeight)
                    }
                }
                .priority(.high)
                .onSuccess { imageResponse in
                    self.recalculateSizeOfDownloadedImage(imageResponse: imageResponse)
                }
                    
                if let count = self.statusViewModel.mediaAttachments.count, count > 1 {
                    BottomRight {
                        Text("1 / \(count)")
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .font(.caption2)
                            .foregroundColor(.black)
                            .background(.ultraThinMaterial, in: Capsule())
                    }.padding()
                }
            }
            .frame(width: self.imageWidth, height: self.imageHeight)
        } else {
            EmptyView()
        }
    }
    
    private func imageView(image: NukeUI.Image) -> some View {
        image
            .onTapGesture{
                self.routerPath.navigate(to: .status(
                    id: statusViewModel.id,
                    blurhash: statusViewModel.mediaAttachments.first?.blurhash,
                    highestImageUrl: statusViewModel.mediaAttachments.getHighestImage()?.url,
                    metaImageWidth: statusViewModel.getImageWidth(),
                    metaImageHeight: statusViewModel.getImageHeight()
                ))
            }
            .onLongPressGesture(minimumDuration: 0.2) {
                Task {
                    try? await StatusService.shared.favourite(statusId: self.statusViewModel.id, for: self.applicationState.account)
                }

                self.showThumbImage = true
                HapticService.shared.touch()
            }
    }
    
    private func recalculateSizeOfDownloadedImage(imageResponse: ImageResponse) {
        guard heightWasPrecalculated == false else {
            return
        }

        if let attachment = statusViewModel.mediaAttachments.first {
            let size = ImageSizeService.shared.calculate(for: attachment.url,
                                                         width: imageResponse.image.size.width,
                                                         height: imageResponse.image.size.height)
            self.imageWidth = size.width
            self.imageHeight = size.height
        }
    }
}
