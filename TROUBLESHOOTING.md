# Troubleshooting

## ExternalBookRow 이미지 간헐적 로딩 실패

- 날짜: 2025-02-17
- 파일: `BookTracker/Sources/Utils/Views/ExternalBookRow.swift`

### 증상

- AsyncImage로 책 썸네일 로딩 시 간헐적으로 failure 상태 발생
- 이미지 캐싱이 거의 안 됨

### 원인

- SwiftUI AsyncImage는 URL이 같아도 뷰가 재생성되면 이미지를 다시 로드함
- AsyncImage 자체에 디스크 캐시가 없어서 스크롤할 때마다 네트워크 요청 발생 → 간헐적 실패

### 해결 과정

1. `.id(url)` 추가하여 URL 기반으로 뷰 identity 고정 → 간헐적 failure 일부 완화
   - 이후 `.id(book.id)`로 변경 (URL이 옵셔널이라 nil일 때 identity 꼬일 수 있어서)
2. 근본적으로 AsyncImage의 캐시 부재 문제는 해결 안 됨
3. Kingfisher 도입하여 전면 교체

### 최종 해결

- `Tuist/Package.swift`에 Kingfisher 8.0+ 추가
- `Project.swift`에 `.external(name: "Kingfisher")` 연결
- AsyncImage → KFImage 교체 (디스크/메모리 캐시 + 실패 시 리트라이 2회)
- 적용 파일:
  - `Utils/Views/ExternalBookRow.swift`
  - `Utils/Views/BookRow.swift` (ThumbnailAsyncImage 헬퍼 뷰도 제거)
  - `Features/Main/SubFeatures/Book/ExternalBookDetailView.swift`
  - `Features/Main/SubFeatures/Book/BookDetailView.swift`
- 로딩 상태 표시 통일:
  - 로딩 중: ProgressView (스피너)
  - 성공: fade(duration: 0.2) 트랜지션
  - 실패: 리트라이 2회 후 placeholder 유지
