### **2. TCA Destination enum 전환 시 Effect 누수 해결 → @Reducer enum 마이그레이션**

검색 화면에서 추천 키워드를 탭하거나 검색어를 입력하면
콘솔에 아래 경고가 반복 출력되었다.

```
A "Scope" at "BookTracker/SearchFeature.swift:141" received a child action
when child state was set to a different case.

  Action:
    SearchFeature.Destination.Action.suggestions(.loadSearchKeywordResponse(.success))
  State:
    SearchFeature.Destination.State.results
```

<!-- 📸 이미지: 콘솔에 경고가 출력되는 Xcode 디버그 화면 스크린샷 -->

`SearchFeature`는 하나의 화면 안에서 두 가지 자식 상태를 enum으로 전환하는 구조였다.

```
SearchFeature
├── Destination (enum)
│   ├── .suggestions(SearchSuggestionsFeature.State)  ← 추천/최근 검색어
│   └── .results(SearchResultFeature.State)           ← 검색 결과 목록
```

**Before: 수동 Scope — enum case 전환 시 Effect가 취소되지 않음**

```swift
// ❌ BEFORE: 수동 Scope 패턴
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

수동 `Scope`는 enum case가 바뀌어도 이전 case에서 시작된 비동기 Effect를 **자동 취소하지 않는다.**

```
발생 시나리오:

1. 검색 화면 진입 → destination = .suggestions
2. SearchSuggestionsFeature.onAppear → API 호출 Effect 시작
3. 응답 오기 전에 사용자가 검색어 입력
4. 부모가 state.destination = .results(...) 로 직접 전환
5. 이전 .suggestions의 API 응답이 뒤늦게 도착
6. Scope가 .suggestions 액션을 라우팅하려 하지만, 현재 state는 .results
   → ⚠️ 경고 발생
```

전환 코드도 단순 대입이라 취소 로직이 없었다.

```swift
// ❌ 직접 대입 — 이전 Effect가 살아있는 채로 case만 바뀜
state.destination = .results(SearchResultFeature.State(keyword: trimmed))
```

### 1차 해결: Cancellation-First Transition 패턴 (workaround)

자식 Feature에 `cancelLoading` 액션과 `.cancellable(id:)`를 추가하고,
부모에서 `.concatenate`로 "취소 → 전환" 순서를 보장했다.

```swift
// 1차 해결: 매 전환마다 boilerplate 필요
return .concatenate(
    .send(.destination(.suggestions(.cancelLoading))),  // 1) 자식 Effect 취소
    .send(._setResults(trimmed))                        // 2) case 전환
)
```

양방향(suggestions ↔ results) 4곳 모두에 이 패턴을 적용하여 경고는 해소되었지만,
내부 전용 액션 2개(`_setSuggestions`, `_setResults`)와 boilerplate가 늘어났다.

**After: @Reducer enum + @Presents — 자동 취소로 workaround 제거**

TCA의 `@Reducer enum` + `@Presents` + `.ifLet` 패턴으로 마이그레이션했다.
이 패턴은 내부적으로 `ifCaseLet`을 사용하며,
**enum case가 바뀌면 이전 case의 in-flight Effect를 자동 취소**한다.

```swift
// ✅ AFTER: @Reducer enum + @Presents
@Reducer(state: .equatable, action: .equatable)
enum Destination {
    case suggestions(SearchSuggestionsFeature)
    case results(SearchResultFeature)
}

// State
@Presents var destination: Destination.State? = .suggestions(SearchSuggestionsFeature.State())

// Action
case destination(PresentationAction<Destination.Action>)

// Body
.ifLet(\.$destination, action: \.destination)

// 전환: 직접 대입하면 자동 취소됨 — boilerplate 없음
state.destination = .results(SearchResultFeature.State(keyword: trimmed))
return .send(.destination(.presented(.results(.setKeyword(trimmed)))))
```

View에서는 inline enum destination을 개별 scope로 분리하여 사용한다.

```swift
@ViewBuilder
private var destinationContent: some View {
    if let suggestionsStore = store.scope(
        state: \.destination?.suggestions,
        action: \.destination.suggestions
    ) {
        SearchSuggestionsView(store: suggestionsStore)
    } else if let resultsStore = store.scope(
        state: \.destination?.results,
        action: \.destination.results
    ) {
        SearchResultView(store: resultsStore)
    }
}
```

**결과**

| 항목 | Before | After |
|------|--------|-------|
| Destination 선언 | `struct Destination: Reducer` (수동 Scope body) | `@Reducer enum Destination` |
| Effect 취소 | `.concatenate(cancel, transition)` × 4곳 | 자동 (case 전환 시) |
| 내부 전환 액션 | `_setSuggestions`, `_setResults` 2개 | 불필요 → 삭제 |
| 코드 변화 | — | 137줄 삭제, 73줄 추가 (순 -64줄) |
| TCA 콘솔 경고 | 검색 시마다 반복 출력 | 완전 해소 |

`@Reducer enum`의 자동 취소 메커니즘 덕분에
수동 취소 workaround를 완전히 제거하고, case 전환 코드가 단순 대입으로 돌아갔다.
