struct PriorityQueue<T> {
  private var items: [T] = []
  private let sort: (T, T) -> Bool

  init(sort: @escaping (T, T) -> Bool) {
    self.sort = sort
  }

  var isEmpty: Bool { items.isEmpty }
  var count: Int { items.count }
  var top: T? { items.first }

  mutating func push(_ value: T) {
    items.append(value)
    var i = items.count - 1
    while i > 0 {
      let parent = (i - 1) / 2
      if !sort(items[i], items[parent]) { break }
      items.swapAt(i, parent)
      i = parent
    }
  }

  mutating func pop() -> T? {
    guard !items.isEmpty else { return nil }
    items.swapAt(0, items.count - 1)
    let removed = items.removeLast()
    var i = 0
    while true {
      let left = 2 * i + 1
      let right = 2 * i + 2
      var best = i
      if left < items.count, sort(items[left], items[best]) { best = left }
      if right < items.count, sort(items[right], items[best]) { best = right }
      if best == i { break }
      items.swapAt(i, best)
      i = best
    }
    return removed
  }
}

var minHeap = PriorityQueue<Int>(sort: <)
for x in [5, 1, 4, 2] { minHeap.push(x) }
while let x = minHeap.pop() { print(x) }