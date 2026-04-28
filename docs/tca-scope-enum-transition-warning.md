# TCA Scope enum 전환 시 "child action when state is different case" 경고 해결

## 문제 상황

검색 화면에서 추천 키워드를 탭하거나 검색어를 입력하면 콘솔에 아래 경고가 반복 출력되었다.

```
A "Scope" at "BookTracker/SearchFeature.swift:141" received a child action
when child state was set to a different case.

  Action:
    SearchFeature.Destination.Action.suggestions(.loadSearchKeywordResponse(.success))
  State:
    SearchFeature.Destination.State.results
```

## 배경 지식

### SearchFeature의 Destination 구조

`SearchFeature`는 하나의 화면 안에서 두 가지 자식 상태를 enum으로 전환한다.

```
SearchFeature
├── Destination (enum)
│   ├── .suggestions(SearchSuggestionsFeature.State)  ← 추천/최근 검색어
│   └── .results(SearchResultFeature.State)           ← 검색 결과 목록
```

전환 방향:
- **suggestions → results**: 사용자가 검색어를 입력하거나 추천어를 탭할 때
- **results → suggestions**: 검색어를 지우거나 X 버튼을 누를 때

### Destination Reducer (수동 Scope 방식)

이 프로젝트의 `SearchFeature.Destination`은 `@Reducer enum`(modern 패턴)이 아닌, 수동으로 `Scope`를 사용하는 legacy 패턴이다.

```swift
struct Destination: Reducer {
    enum State { case suggestions(...), case results(...) }
    enum Action { case suggestions(...), case results(...) }

    var body: some ReducerOf<Self> {
        Scope(state: /State.suggestions, action: /Action.suggestions) {
            SearchSuggestionsFeature()
        }
        Scope(state: /State.results, action: /Action.results) {
            SearchResultFeature()
        }
    }
}
```

**핵심 차이**: `@Reducer enum`은 내부적으로 `ifCaseLet`을 사용하며, enum case가 바뀌면 이전 case의 in-flight effect를 **자동 취소**한다. 반면 수동 `Scope`는 **자동 취소하지 않는다**.

## 원인 분석

### 발생 시나리오

```
1. 검색 화면 진입 → destination = .suggestions
2. SearchSuggestionsFeature.onAppear 실행
   → loadSearchKeyword (API 호출) effect 시작
   → loadRecents (로컬 조회) effect 시작
3. API 응답이 오기 전에 사용자가 검색어 입력 또는 추천어 탭
4. 부모(SearchFeature)가 state.destination = .results(...) 로 직접 전환
5. loadSearchKeywordResponse(.success)가 뒤늦게 도착
6. Scope가 .suggestions 액션을 라우팅하려 하지만, 현재 state는 .results
   → 경고 발생
```

### 핵심 원인

`state.destination`을 직접 대입하면 enum case만 바뀌고, 이전 case에서 시작된 비동기 effect는 그대로 살아있다. 수동 `Scope`는 case 전환 시 effect를 취소해주지 않으므로, 이전 effect의 응답이 도착했을 때 case 불일치가 발생한다.

## 1차 시도 (부분 해결)

results → suggestions 방향에만 "Cancellation-First Transition" 패턴을 적용했다.

```swift
// results → suggestions: 검색어 비움
return .concatenate(
    .send(.destination(.results(.cancelSearch))),  // 1) 자식 effect 취소
    .send(._setSuggestions)                        // 2) case 전환
)
```

`SearchResultFeature`에는 이미 `cancelSearch` 액션과 `CancelID`가 있었기 때문에 바로 적용 가능했다.

**결과**: results → suggestions 전환은 해결되었지만, 반대 방향(suggestions → results)에서 동일 경고가 계속 발생했다.

### 놓친 부분

- `SearchSuggestionsFeature`의 effect에 `.cancellable(id:)`가 없었다
- 취소할 수 있는 액션(`cancelLoading`)도 없었다
- suggestions → results 전환 코드에서 취소 없이 `state.destination`을 직접 대입하고 있었다

문제가 되는 코드 (2곳):

```swift
// 1) 검색어 입력 시 (binding)
state.destination = .results(SearchResultFeature.State(keyword: trimmed))  // ← 바로 전환

// 2) 추천어 탭 시 (delegate)
state.destination = .results(SearchResultFeature.State(keyword: keyword))  // ← 바로 전환
```

## 최종 해결

### 원칙

enum Destination의 case를 전환할 때, **항상** 현재 case의 in-flight effect를 먼저 취소한 후 전환한다. 양방향 모두 동일 패턴을 적용한다.

### 1단계: 자식 Feature에 cancellation 추가

`SearchSuggestionsFeature`에 `CancelID`와 `cancelLoading` 액션을 추가했다.

```swift
// SearchSuggestionsFeature.swift

private enum CancelID { case loadKeywords, loadRecents }

// 새 액션
case cancelLoading

// 핸들러
case .cancelLoading:
    state.isSearchKeywordsLoading = false
    state.isSearchesLoading = false
    return .merge(
        .cancel(id: CancelID.loadKeywords),
        .cancel(id: CancelID.loadRecents)
    )

// 기존 effect에 .cancellable 추가
case .loadSearchKeyword:
    return .run { ... }
        .cancellable(id: CancelID.loadKeywords, cancelInFlight: true)

case .loadRecents:
    return .run { ... }
        .cancellable(id: CancelID.loadRecents, cancelInFlight: true)
```

### 2단계: 부모 Feature에 내부 전환 액션 추가

`state.destination`을 직접 대입하지 않고, 내부 액션을 통해 전환한다.

```swift
// SearchFeature.swift

// 내부 전환 액션
case _setSuggestions           // results → suggestions 전환용 (기존)
case _setResults(String)       // suggestions → results 전환용 (신규)

// _setResults 핸들러
case let ._setResults(keyword):
    state.destination = .results(SearchResultFeature.State(keyword: keyword))
    return .send(.destination(.results(.setKeyword(keyword))))
```

### 3단계: 모든 전환 지점에 concatenate 패턴 적용

```swift
// suggestions → results (검색어 입력)
return .concatenate(
    .send(.destination(.suggestions(.cancelLoading))),
    .send(._setResults(trimmed))
)

// suggestions → results (추천어 탭)
return .concatenate(
    .send(.destination(.suggestions(.cancelLoading))),
    .send(._setResults(keyword))
)

// results → suggestions (검색어 비움 / X 버튼)
return .concatenate(
    .send(.destination(.results(.cancelSearch))),
    .send(._setSuggestions)
)
```

### .concatenate의 동작 원리

`.concatenate`는 effect를 **순서대로** 실행하며, 첫 번째가 완료된 후 두 번째를 시작한다.

1. `.send(.cancelLoading)` → 액션이 store에 전달 → 자식 reducer가 `.cancel(id:)` 반환 → **즉시** effect 취소
2. 취소 완료 후 `.send(._setResults)` → `state.destination` 전환 → 새 자식 effect 시작

취소가 먼저 완료되므로, 이전 case의 응답이 뒤늦게 도착하는 일이 없다.

## 정리

| 전환 방향 | 취소 대상 | 취소 액션 | 전환 액션 |
|-----------|-----------|-----------|-----------|
| suggestions → results | loadKeywords, loadRecents | `.suggestions(.cancelLoading)` | `._setResults(keyword)` |
| results → suggestions | search, loadMore | `.results(.cancelSearch)` | `._setSuggestions` |

## 체크리스트

enum Destination의 case 전환 로직을 작성할 때:

- [ ] **양방향** 전환 모두 확인했는가? (A→B, B→A)
- [ ] 전환되는 쪽 자식의 모든 비동기 effect에 `.cancellable(id:)` 붙었는가?
- [ ] 자식에 cancel 액션이 있는가?
- [ ] 부모에서 `state.destination = ...` 직접 대입 대신 `.concatenate(cancel → _set전환)` 사용하는가?
- [ ] `_set전환` 내부 액션이 정의되어 있는가?

## 관련 파일

- `BookTracker/Sources/Features/Main/SubFeatures/Search/SearchFeature.swift`
- `BookTracker/Sources/Features/Main/SubFeatures/Search/SubFeatures/SearchSuggestionsFeature.swift`
- `BookTracker/Sources/Features/Main/SubFeatures/Search/SubFeatures/SearchResultFeature.swift`

## 환경

- TCA (swift-composable-architecture)
- 수동 `Scope` + enum State/Action 패턴 (legacy)
- `@Reducer enum` 사용 시에는 `ifCaseLet`이 자동 취소하므로 이 패턴 불필요
