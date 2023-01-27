//
//  https://mczachurski.dev
//  Copyright © 2023 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

extension View {
    func withAppRouteur() -> some View {
        self.navigationDestination(for: RouteurDestinations.self) { destination in
            switch destination {
            case .tag(let hashTag):
                StatusesView(listType: .hashtag(tag: hashTag))
            case .status(let id, let blurhash, let highestImageUrl, let metaImageWidth, let metaImageHeight):
                StatusView(statusId: id,
                           imageBlurhash: blurhash,
                           highestImageUrl: highestImageUrl,
                           imageWidth: metaImageWidth,
                           imageHeight: metaImageHeight)
            case .statuses(let listType):
                StatusesView(listType: listType)
            case .userProfile(let accountId, let accountDisplayName, let accountUserName):
                UserProfileView(
                    accountId: accountId,
                    accountDisplayName: accountDisplayName,
                    accountUserName: accountUserName)
            case .accounts(let entityId, let listType):
                AccountsView(entityId: entityId, listType: listType)
            case .signIn:
                SignInView()
            }
        }
    }
  
    func withSheetDestinations(sheetDestinations: Binding<SheetDestinations?>) -> some View {
        self.sheet(item: sheetDestinations) { destination in
            switch destination {
            case .replyToStatusEditor(let status):
                ComposeView(statusViewModel: status)
            case .newStatusEditor:
                ComposeView()
            case .settings:
                SettingsView()
            }
        }
    }
}
