### **4. SwiftUI ImageRenderer + AsyncImage 캡처 이슈 해결**

캘린더 뷰를 `ImageRenderer`로 캡처하여 사진첩에 저장하는 기능을 구현하던 중
두 가지 문제가 발생했다.

**문제 1: AsyncImage 렌더링 실패**

```
Unable to render flattened version of
PlatformViewRepresentableAdaptor<CircularUIKitProgressView>
```

**문제 2: Alpha 채널 경고**

```
writeImageAtIndex:1094: ERROR: 'BookTracker' is trying to save an opaque image
with 'AlphaPremulLast'. This would unnecessarily increase the file size and
will double (!!!) the required memory when decoding the image --> ignoring alpha.
```

<!-- 📸 이미지: 캡처된 이미지가 깨져서 저장된 결과물 (AsyncImage placeholder가 렌더링 실패한 상태) -->

### 문제 원인

`ImageRenderer`는 SwiftUI 뷰 계층을 **오프스크린에서 새로 생성**하여 렌더링한다.
이때 `AsyncImage`는 이미지를 처음부터 다시 로드하기 시작하며,
로딩 중 placeholder인 `ProgressView`는 내부적으로 `UIActivityIndicatorView`(UIKit)를 사용한다.
`ImageRenderer`는 UIKit 기반 뷰(`UIViewRepresentable`)를 렌더링할 수 없기 때문에
에러가 발생하고 깨진 이미지가 저장되었다.

**Before: AsyncImage — ImageRenderer에서 렌더링 불가**

```swift
// ❌ BEFORE: AsyncImage 사용
AsyncImage(url: url) { phase in
    switch phase {
    case .empty:
        ProgressView().tint(.white)  // UIKit 기반 → ImageRenderer에서 렌더링 불가
    case .success(let image):
        image.resizable().scaledToFill()
    case .failure:
        Image(systemName: "book.fill")
    @unknown default:
        EmptyView()
    }
}
```

**After: Kingfisher 캐시 동기 로드 + Opaque 변환**

화면에 표시하는 뷰는 `KFImage`(Kingfisher)로 교체했다.

```swift
// ✅ AFTER: 화면 표시용 — KFImage (Kingfisher 캐시 자동 관리)
KFImage(url)
    .placeholder {
        ProgressView().tint(.white)
    }
    .resizable()
    .scaledToFill()
```

캡처 전용 뷰에서는 Kingfisher 메모리 캐시에서 **동기적으로** 이미지를 가져온다.
사용자가 화면에서 보고 있는 이미지는 이미 캐시에 존재하므로, 추가 네트워크 호출 없이 즉시 사용 가능하다.

```swift
// ✅ AFTER: 캡처 전용 뷰 — Kingfisher 캐시 동기 로드
private struct CaptureThumbnailCell: View {
    let item: BookCalendarSummary

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "#2C2C35", default: .secondary))
            if let urlString = item.imageUrl,
               let cached = ImageCache.default.retrieveImageInMemoryCache(forKey: urlString) {
                Image(uiImage: cached)       // 순수 SwiftUI → ImageRenderer 정상 렌더링
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

Alpha 채널 경고는 저장 직전에 opaque 이미지로 변환하여 해결했다.

```swift
// ✅ AFTER: Alpha 채널 제거
final class ImageSaver: NSObject {
    func save(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        let opaqueImage = makeOpaque(image)
        UIImageWriteToSavedPhotosAlbum(opaqueImage, self, #selector(didFinishSaving), nil)
    }

    private func makeOpaque(_ image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true       // alpha 채널 없이 RGB만 생성
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(at: .zero)
        }
    }
}
```

<!-- 📸 이미지: 수정 후 정상적으로 캡처된 캘린더 이미지 (Before/After 비교) -->

**결과**

| 문제 | 원인 | 해결 |
|------|------|------|
| AsyncImage 렌더링 실패 | ImageRenderer가 UIKit 기반 ProgressView 렌더링 불가 | 캡처 뷰에서 Kingfisher 캐시 동기 로드 (`Image(uiImage:)`) |
| Alpha 경고 + 메모리 2배 | ImageRenderer가 기본 RGBA 이미지 생성 | 저장 전 `UIGraphicsImageRenderer`로 opaque 변환 |

- `AsyncImage`, `ProgressView` 모두 캡처 뷰에서 미사용 → UIKit 렌더링 문제 회피
- Kingfisher의 자체 메모리/디스크 캐시를 활용하여 추가 네트워크 비용 없음
- Alpha 채널 제거로 저장 파일 크기 감소 + 디코딩 시 메모리 절반
