# SwiftUI ImageRenderer + AsyncImage 캡처 이슈 해결

## 문제 상황

캘린더 뷰를 `ImageRenderer`로 캡처하여 사진첩에 저장하는 기능을 구현하던 중 두 가지 문제가 발생했다.

### 1. AsyncImage 렌더링 실패

```
Unable to render flattened version of
PlatformViewRepresentableAdaptor<CircularUIKitProgressView>
```

`ImageRenderer`는 SwiftUI 뷰 계층을 오프스크린에서 새로 생성하여 렌더링한다.
이때 `AsyncImage`는 이미지를 새로 로드하기 시작하며, 로딩 중 placeholder로 표시되는 `ProgressView`는 내부적으로 `UIActivityIndicatorView`(UIKit)를 사용한다.

`ImageRenderer`는 UIKit 기반 뷰(`UIViewRepresentable`)를 렌더링할 수 없기 때문에 에러가 발생하고, 깨진 이미지가 저장된다.

**핵심 원인**: `ImageRenderer`는 새로운 뷰 계층을 만들기 때문에, 화면에 이미 로드된 이미지와는 무관하게 `AsyncImage`가 처음부터 다시 로딩을 시작한다.

### 2. Alpha 채널 경고

```
writeImageAtIndex:1094: ERROR: 'BookTracker' is trying to save an opaque image
with 'AlphaPremulLast'. This would unnecessarily increase the file size and
will double (!!!) the required memory when decoding the image --> ignoring alpha.
```

`ImageRenderer`가 기본적으로 alpha 채널이 포함된 RGBA 이미지를 생성한다. 사진첩에 저장할 때 불필요한 alpha로 인해 파일 크기 증가 및 디코딩 시 메모리 2배 사용 경고가 발생한다.

## 해결 방법

### AsyncImage -> Kingfisher(KFImage) 전환

기존에 `AsyncImage`를 사용하던 `DoneBookThumbnailsGrid`를 `KFImage`(Kingfisher)로 교체했다.

**변경 전 (AsyncImage)**
```swift
AsyncImage(url: url) { phase in
    switch phase {
    case .empty:
        ProgressView().tint(.white)  // UIKit 기반 -> ImageRenderer에서 렌더링 불가
    case .success(let image):
        image.resizable().scaledToFill()
    case .failure:
        Image(systemName: "book.fill")
    @unknown default:
        EmptyView()
    }
}
```

**변경 후 (KFImage)**
```swift
KFImage(url)
    .placeholder {
        ProgressView().tint(.white)
    }
    .resizable()
    .scaledToFill()
```

Kingfisher는 자체 메모리/디스크 캐시를 관리하므로, 캡처 시 캐시에서 동기적으로 이미지를 가져올 수 있다.

### 캡처 전용 뷰에서 Kingfisher 캐시 동기 로드

`ImageRenderer`용 캡처 뷰에서는 `ImageCache.default.retrieveImageInMemoryCache(forKey:)`를 사용하여 Kingfisher 메모리 캐시에서 이미지를 동기적으로 가져온다.

```swift
private struct CaptureThumbnailCell: View {
    let item: BookCalendarSummary

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "#2C2C35", default: .secondary))
            if let urlString = item.imageUrl,
               let cached = ImageCache.default.retrieveImageInMemoryCache(forKey: urlString) {
                Image(uiImage: cached)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "book.fill")
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}
```

이렇게 하면:
- 사용자가 화면에서 보고 있는 이미지는 이미 Kingfisher 캐시에 존재
- `Image(uiImage:)`는 순수 SwiftUI이므로 `ImageRenderer`에서 정상 렌더링
- `AsyncImage`, `ProgressView` 모두 미사용 -> UIKit 렌더링 문제 회피

### Alpha 채널 제거 (Opaque 변환)

저장 직전에 alpha 채널을 제거한 opaque 이미지로 변환한다.

```swift
final class ImageSaver: NSObject {
    func save(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        let opaqueImage = makeOpaque(image)
        // ...
        UIImageWriteToSavedPhotosAlbum(opaqueImage, self, #selector(didFinishSaving), nil)
    }

    private func makeOpaque(_ image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(at: .zero)
        }
    }
}
```

`UIGraphicsImageRendererFormat.opaque = true`로 설정하면 alpha 채널 없이 RGB만으로 이미지를 생성한다.

## 정리

| 문제 | 원인 | 해결 |
|------|------|------|
| AsyncImage 렌더링 실패 | ImageRenderer가 UIKit 기반 ProgressView를 렌더링 불가 | 캡처 뷰에서 Kingfisher 캐시 동기 로드 사용 |
| Alpha 경고 + 메모리 2배 | ImageRenderer가 기본 RGBA 이미지 생성 | 저장 전 UIGraphicsImageRenderer로 opaque 변환 |

## 관련 파일

- `BookTracker/Sources/Utils/Funcs/ImageSaver.swift`
- `BookTracker/Sources/Utils/Views/DoneBookThumbnailsGrid.swift`
- `BookTracker/Sources/Features/Main/SubFeatures/Stat/SubFeatures/DoneBooksCalendarView.swift`

## 환경

- iOS 16+ (ImageRenderer 최소 요구)
- Kingfisher (이미지 캐싱 라이브러리)
- SwiftUI + Composable Architecture (TCA)
