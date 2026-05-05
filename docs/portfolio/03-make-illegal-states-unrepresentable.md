### **3. Make Illegal States Unrepresentable — Bool 플래그 → LoadingState enum**

9개 Feature의 State에서 `isLoading: Bool` + `isError: Bool` 조합으로
로딩 상태를 관리하고 있었다.
가장 심각한 케이스는 `ExternalBookDetailFeature`로, Bool 3개가 사용되고 있었다.

<!-- 📸 이미지: Bool 플래그 조합으로 표현 가능한 상태 다이어그램 (유효 상태 vs 불가능 상태) -->

**Before: Bool 플래그 — 잘못된 상태 조합이 타입 시스템으로 방지되지 않음**

```swift
// ❌ BEFORE: ExternalBookDetailFeature (3개 Bool, 가장 심각한 케이스)
var isRegisteredReceiptTypesLoading: Bool = false
var isRegisteredReceiptTypesLoadError: Bool = false
var isRegisteredReceiptTypesLoadSuccess: Bool = false

// ❌ BEFORE: 나머지 8개 Feature (2개 Bool)
var isLoading: Bool = false
var isError: Bool = false
```

| Bool 개수 | 가능한 조합 | 유효한 상태 | **잘못된 상태** |
|-----------|------------|------------|----------------|
| 2개 | 4가지 | 3가지 (idle/loading/error) | **1가지** (`isLoading=true, isError=true`) |
| 3개 | 8가지 | 4가지 (idle/loading/success/error) | **4가지** |

Reducer에서도 전환마다 모든 Bool을 정확히 reset해야 하는 부담이 있었다.

```swift
// ❌ BEFORE: 다중 대입이 산재
case .loadBooks:
    state.isLoading = true
    state.isError = false      // reset 빠뜨리면 버그
    ...
case .loadBooksResponse(.success(let books)):
    state.isLoading = false
    state.books = books
case .loadBooksResponse(.failure):
    state.isLoading = false
    state.isError = true
```

### 문제 원인

상호 배타적(mutually exclusive)인 상태를 독립적인 Bool로 표현한 것이 근본 원인.
Swift의 enum을 사용하면 타입 시스템이 잘못된 조합을 **컴파일 타임에 차단**할 수 있다.

**After: LoadingState enum — 상태 1개로 통합**

```swift
// ✅ AFTER: 공유 enum 정의
enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error
}
```

```swift
// ✅ AFTER: ExternalBookDetailFeature — 3개 Bool → 1개 enum
var receiptTypesLoadState: LoadingState = .idle

// ✅ AFTER: 나머지 8개 Feature — 2개 Bool → 1개 enum
var loadingState: LoadingState = .idle
```

Reducer에서 상태 전환이 단일 대입으로 변경되었다.

```swift
// ✅ AFTER: 단일 대입, reset 빠뜨릴 일 없음
case .loadBooks:
    state.loadingState = .loading
    ...
case .loadBooksResponse(.success(let books)):
    state.loadingState = .loaded
    state.books = books
case .loadBooksResponse(.failure):
    state.loadingState = .error
```

View에서도 조건 분기가 명확해졌다.

```swift
// ✅ AFTER: View
if store.loadingState == .loading { ProgressView() }
if store.loadingState == .error { ErrorView() }
.disabled(store.loadingState == .loading || store.loadingState == .error)
```

**결과**

| 항목 | Before | After |
|------|--------|-------|
| 적용 범위 | 9개 Feature | 9개 Feature |
| 변경 파일 | — | 27개 (Feature 9 + View 9 + Test 9) |
| 코드 변화 | — | 106 insertions, 149 deletions (순 -43줄) |
| Bool 변수 | 19개 | → 9개 enum 프로퍼티로 통합 |
| 잘못된 상태 조합 | ExternalBookDetailFeature 기준 4가지 | **0가지** |
| 테스트 | 9개 Feature 기존 단위 테스트 전체 통과 | — |

> Bool 플래그 2~3개를 enum 1개로 바꾸면, 런타임 버그가 될 수 있었던 잘못된 상태 조합이
> **아예 표현 불가능**해진다. 이것이 "Make Illegal States Unrepresentable" 원칙의 실용적 적용이다.
