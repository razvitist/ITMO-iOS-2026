struct Point: Equatable, Hashable {
  var x: Double
  var y: Double

  mutating func move(byX: Double, byY: Double) {
    x += byX
    y += byY
  }

  var distanceToOrigin: Double {
    (x * x + y * y).squareRoot()
  }
}

struct Rectangle: Equatable, Hashable {
  var origin: Point
  var width: Double
  var height: Double

  init(origin: Point, width: Double, height: Double) {
    self.origin = origin
    self.width = width <= 0 ? 1.0 : width
    self.height = height <= 0 ? 1.0 : height
  }

  var area: Double {
    width * height
  }

  var perimeter: Double {
    2 * (width + height)
  }

  var center: Point {
    Point(x: origin.x + width / 2, y: origin.y + height / 2)
  }

  mutating func scale(by factor: Double) {
    width *= factor
    height *= factor
  }

  func contains(_ point: Point) -> Bool {
    point.x >= origin.x && point.x <= origin.x + width &&
      point.y >= origin.y && point.y <= origin.y + height
  }
}