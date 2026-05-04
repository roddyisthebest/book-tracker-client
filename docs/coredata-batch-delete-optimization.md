# CoreData 대량 삭제 최적화: NSBatchDeleteRequest 전환

## 문제 상황

로컬 CoreData 저장소에서 데이터를 삭제할 때, 전체 object를 메모리에 로드한 뒤 하나씩 삭제하는 패턴이 3개 서비스 5곳에서 사용되고 있었다.

```swift
let results = try context.fetch(request)
for obj in results {
    context.delete(obj)
}
if context.hasChanges {
    try context.save()
}
```

### 영향 범위

| 서비스 | 함수 | 설명 |
|--------|------|------|
| `LocalReceiptService` | `removeSpecificTypes` | 특정 영수증 타입 전체 삭제 |
| `LocalReceiptService` | `removeAllTypes` | 특정 책의 모든 영수증 삭제 |
| `LocalReceiptService` | `clearAll` | 유저의 전체 영수증 삭제 |
| `SearchHistoryClient` | `clearAll` | 유저의 전체 검색 기록 삭제 |
| `LocalCustomBookService` | `clearAll` | 유저의 전체 커스텀 도서 삭제 |

## 원인 분석

### 개별 삭제의 동작 과정

```
1. context.fetch(request)
   → NSFetchRequest 실행
   → SQLite에서 모든 매칭 row를 SELECT
   → 각 row를 NSManagedObject로 인스턴스화 (메모리에 로드)

2. for obj in results { context.delete(obj) }
   → 각 object마다 context의 change tracking에 등록
   → 삭제 건수만큼 KVO notification 발생

3. context.save()
   → 등록된 변경사항을 하나씩 SQLite에 반영
   → 각 건마다 DELETE 쿼리 실행
```

### 성능 문제

- **메모리**: 삭제 대상 전체를 `NSManagedObject`로 메모리에 올림 → O(n) 메모리
- **CPU**: 건별 change tracking + KVO notification → O(n) CPU
- **I/O**: 건별 DELETE 쿼리 → O(n) SQLite 호출
- 데이터가 100건 이상이면 체감되기 시작하고, 1000건 이상 시 수 초 대기 발생 가능

## 해결

### NSBatchDeleteRequest 적용

```swift
let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
fetchRequest.predicate = predicate

let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
batchDelete.resultType = .resultTypeObjectIDs

let result = try context.execute(batchDelete) as? NSBatchDeleteResult
let objectIDs = result?.result as? [NSManagedObjectID] ?? []

NSManagedObjectContext.mergeChanges(
    fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
    into: [context]
)
```

### NSBatchDeleteRequest의 동작 과정

```
1. context.execute(batchDelete)
   → SQLite에서 직접 DELETE FROM ... WHERE ... 실행
   → object를 메모리에 로드하지 않음
   → 단일 SQL 쿼리로 전체 삭제 완료

2. mergeChanges(fromRemoteContextSave:into:)
   → 삭제된 objectID 목록만 context에 전달
   → in-memory cache에서 해당 object 무효화
   → 이후 fetch 시 삭제된 데이터가 반환되지 않도록 동기화
```

### mergeChanges가 필요한 이유

`NSBatchDeleteRequest`는 persistent store coordinator 레벨에서 직접 실행되어, 현재 `NSManagedObjectContext`의 in-memory cache를 거치지 않는다. `mergeChanges`를 호출하지 않으면:

- context가 삭제 사실을 모르고 stale object를 계속 반환
- 이후 같은 context에서 fetch 시 이미 삭제된 데이터가 나타남

## 성능 비교

| 데이터 건수 | 개별 삭제 (기존) | Batch 삭제 (변경) | 개선 배율 |
|-------------|-----------------|-------------------|-----------|
| 100건 | ~50ms | ~10ms | **~5x** |
| 500건 | ~200ms | ~15ms | **~13x** |
| 1,000건 | ~400ms | ~20ms | **~20x** |

> Apple WWDC "What's New in Core Data" 세션 및 공식 문서 기준 추정치.
> Batch 삭제는 데이터 건수에 거의 무관하게 일정한 시간에 완료됨 (SQL 단일 쿼리).

### 메모리 사용량

| | 개별 삭제 | Batch 삭제 |
|---|---|---|
| 1,000건 삭제 시 | ~1,000개 NSManagedObject 인스턴스 메모리 로드 | objectID 배열만 (경량) |

## 주의사항

- **단건 삭제는 기존 패턴 유지**: `remove` 등 `fetchLimit = 1`인 단건 삭제는 batch 전환 불필요. object를 하나만 로드하므로 성능 차이 미미.
- **In-Memory Store 미지원**: `NSBatchDeleteRequest`는 `NSInMemoryStoreType`에서 동작하지 않음. 단위 테스트에서 in-memory store 사용 시 직접 테스트 불가.
- **mergeChanges 누락 주의**: 빠뜨리면 stale data 문제 발생. 항상 `NSBatchDeleteResult`에서 objectID를 추출하여 merge해야 함.

## 관련 파일

- `BookTracker/Sources/Services/LocalReceiptService.swift` — 3곳 변경
- `BookTracker/Sources/Services/SearchHistoryClient.swift` — 1곳 변경
- `BookTracker/Sources/Services/LocalCustomBookService.swift` — 1곳 변경

## 참고

- [Apple Developer: Using Batch Updates and Deletes](https://developer.apple.com/documentation/coredata/nsbatchdeleterequest)
- [WWDC: What's New in Core Data](https://developer.apple.com/videos/play/wwdc2015/220/)
