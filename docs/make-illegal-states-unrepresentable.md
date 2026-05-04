# Make Illegal States Unrepresentable: Bool 플래그 → LoadingState enum

## 문제 인식

9개 Feature의 State에서 `isLoading: Bool` + `isError: Bool` 조합으로 로딩 상태를 관리하고 있었다.

```swift
// Before — ExternalBookDetailFeature (3개 Bool, 가장 심각한 케이스)
var isRegisteredReceiptTypesLoading: Bool = false
var isRegisteredReceiptTypesLoadError: Bool = false
var isRegisteredReceiptTypesLoadSuccess: Bool = false

// Before — 나머지 8개 Feature (2개 Bool)
var isLoading: Bool = false
var isError: Bool = false
```

### 왜 문제인가?

| Bool 개수 | 가능한 조합 | 유효한 상태 | 잘못된 상태 |
|-----------|------------|------------|------------|
| 2개 | 4가지 | 3가지 (idle/loading/error) | 1가지 (`isLoading=true, isError=true`) |
| 3개 | 8가지 | 4가지 (idle/loading/success/error) | 4가지 |

- 런타임에 `isLoading = true`와 `isError = true`가 동시에 `true`가 되는 **불가능한 상태**가 타입 시스템으로 방지되지 않음
- 새로운 상태 전환을 추가할 때 모든 Bool을 정확히 reset해야 하는 부담
- Reducer에서 `state.isLoading = false; state.isError = true` 같은 다중 대입이 산재

## 원인 분석

상호 배타적(mutually exclusive)인 상태를 독립적인 Bool로 표현한 것이 근본 원인.
Swift의 enum을 사용하면 타입 시스템이 잘못된 조합을 **컴파일 타임에 차단**할 수 있다.

## 해결

### 공유 enum 정의

```swift
// LoadingState.swift
enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error
}
```

### State 변경

```swift
// After — ExternalBookDetailFeature
var receiptTypesLoadState: LoadingState = .idle  // 3개 Bool → 1개 enum

// After — 나머지 8개 Feature
var loadingState: LoadingState = .idle  // 2개 Bool → 1개 enum
```

### Reducer 변경

```swift
// Before
case .loadBooks:
    state.isLoading = true
    state.isError = false
    ...
case .loadBooksResponse(.success(let books)):
    state.isLoading = false
    state.books = books
case .loadBooksResponse(.failure):
    state.isLoading = false
    state.isError = true

// After
case .loadBooks:
    state.loadingState = .loading
    ...
case .loadBooksResponse(.success(let books)):
    state.loadingState = .loaded
    state.books = books
case .loadBooksResponse(.failure):
    state.loadingState = .error
```

### View 변경

```swift
// Before
if store.isLoading { ProgressView() }
if store.isError { ErrorView() }
.disabled(store.isLoading || store.isError)

// After
if store.loadingState == .loading { ProgressView() }
if store.loadingState == .error { ErrorView() }
.disabled(store.loadingState == .loading || store.loadingState == .error)
```

## 적용 범위

| Feature | Before | After |
|---------|--------|-------|
| ExternalBookDetailFeature | 3 Bool (8가지 조합) | 1 enum (4가지 상태) |
| ReadingCalendarFeature | 2 Bool | 1 enum |
| ReadingReportFeature | 2 Bool | 1 enum |
| DoneBooksCalendarFeature | 2 Bool | 1 enum |
| MyBookListFeature | 2 Bool | 1 enum |
| CollectionDetailFeature | 2 Bool | 1 enum |
| ReceiptListFeature | 2 Bool | 1 enum |
| CollectionSelectBooksFeature | 2 Bool | 1 enum |
| ReceiptDetailFeature | 2 Bool | 1 enum |

## 수치

- **변경 파일**: 27개 (Feature 9 + View 9 + Test 9)
- **코드 변화**: 106 insertions, 149 deletions (**net -43 lines**)
- **제거된 Bool 변수**: 19개 → 9개 enum 프로퍼티로 통합
- **잘못된 상태 조합**: ExternalBookDetailFeature 기준 4가지 → 0가지

## 검증

- 9개 Feature의 기존 단위 테스트 전체 통과
- 빌드 성공 확인
- "Make Illegal States Unrepresentable" 원칙 — 타입 시스템이 잘못된 상태를 컴파일 타임에 차단

## 핵심 포인트

> Bool 플래그 2~3개를 enum 1개로 바꾸면, 런타임 버그가 될 수 있었던 잘못된 상태 조합이 **아예 표현 불가능**해진다. 이것이 Swift enum의 가장 실용적인 활용이다.
