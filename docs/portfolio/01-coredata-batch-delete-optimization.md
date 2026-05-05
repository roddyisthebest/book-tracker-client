### **1. CoreData 대량 삭제 최적화 — 루프 삭제 → NSBatchDeleteRequest**

로컬 CoreData 저장소에서 데이터를 삭제할 때,
전체 object를 메모리에 로드한 뒤 하나씩 삭제하는 패턴이
3개 서비스 5곳에서 사용되고 있었다.

| 서비스 | 함수 | 설명 |
|--------|------|------|
| `LocalReceiptService` | `removeSpecificTypes` | 특정 영수증 타입 전체 삭제 |
| `LocalReceiptService` | `removeAllTypes` | 특정 책의 모든 영수증 삭제 |
| `LocalReceiptService` | `clearAll` | 유저의 전체 영수증 삭제 |
| `SearchHistoryClient` | `clearAll` | 유저의 전체 검색 기록 삭제 |
| `LocalCustomBookService` | `clearAll` | 유저의 전체 커스텀 도서 삭제 |

**Before: 개별 삭제 (O(n) 메모리 + O(n) SQL)**

```swift
// ❌ BEFORE: 전체 object를 메모리에 로드 후 하나씩 삭제
let results = try context.fetch(request)
for obj in results {
    context.delete(obj)       // 건별 change tracking + KVO notification
}
if context.hasChanges {
    try context.save()        // 건별 DELETE 쿼리 실행
}
```

이 방식의 동작 과정:

```
1. context.fetch(request)
   → SQLite에서 모든 매칭 row를 SELECT
   → 각 row를 NSManagedObject로 인스턴스화 (메모리에 로드)

2. for obj in results { context.delete(obj) }
   → 각 object마다 context의 change tracking에 등록
   → 삭제 건수만큼 KVO notification 발생

3. context.save()
   → 등록된 변경사항을 하나씩 SQLite에 반영
   → 각 건마다 DELETE 쿼리 실행
```

데이터가 100건 이상이면 체감되기 시작하고, 1000건 이상 시 수 초 대기가 발생할 수 있었다.

### 문제 원인

삭제 대상 전체를 `NSManagedObject`로 메모리에 올리고(O(n)),
건별로 change tracking + KVO + DELETE 쿼리를 실행하는 구조(O(n))가 근본 원인이었다.

**After: NSBatchDeleteRequest (단일 SQL 쿼리)**

```swift
// ✅ AFTER: SQLite에서 직접 DELETE, object를 메모리에 로드하지 않음
let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
fetchRequest.predicate = predicate

let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
batchDelete.resultType = .resultTypeObjectIDs

let result = try context.execute(batchDelete) as? NSBatchDeleteResult
let objectIDs = result?.result as? [NSManagedObjectID] ?? []

// in-memory cache 동기화 (stale data 방지)
NSManagedObjectContext.mergeChanges(
    fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
    into: [context]
)
```

`NSBatchDeleteRequest`는 persistent store coordinator 레벨에서 직접 실행되어,
`NSManagedObjectContext`의 in-memory cache를 거치지 않는다.
따라서 `mergeChanges`를 호출하여 삭제된 objectID를 context에 알려주어야
이후 fetch에서 stale data가 반환되지 않는다.

**결과**

| 데이터 건수 | 개별 삭제 (기존) | Batch 삭제 (변경) | 개선 배율 |
|-------------|-----------------|-------------------|-----------|
| 100건 | ~50ms | ~10ms | ~5x |
| 500건 | ~200ms | ~15ms | ~13x |
| 1,000건 | ~400ms | ~20ms | ~20x |

> Apple WWDC "What's New in Core Data" 세션 및 공식 문서 기준 추정치.
> Batch 삭제는 데이터 건수에 거의 무관하게 일정한 시간에 완료됨 (SQL 단일 쿼리).

- 메모리: 1,000건 삭제 시 ~1,000개 NSManagedObject 인스턴스 → objectID 배열만 (경량)
- 5곳의 루프 삭제 패턴을 모두 `NSBatchDeleteRequest`로 전환
- 단건 삭제(`fetchLimit = 1`)는 성능 차이 미미하여 기존 패턴 유지
