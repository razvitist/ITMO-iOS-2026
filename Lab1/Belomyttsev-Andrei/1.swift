struct Order {
  let id: Int
  let customer: String
  let amount: Double // сумма заказа
  let isPaid: Bool
  let promoCode: String? // может отсутствовать
}

let orders: [Order] = [
  Order(id: 1, customer: "Анна", amount: 1200, isPaid: true, promoCode: "SALE10"),
  Order(id: 2, customer: "Иван", amount: 800, isPaid: false, promoCode: nil),
  Order(id: 3, customer: "Анна", amount: 5400, isPaid: true, promoCode: nil),
  Order(id: 4, customer: "Олег", amount: 300, isPaid: true, promoCode: "NEW"),
  Order(id: 5, customer: "Иван", amount: 2100, isPaid: false, promoCode: "SALE10")
]

// Получить массив сумм всех оплаченных заказов.
print(orders.filter { $0.isPaid }.map { $0.amount })

// Найти общую сумму всех неоплаченных заказов (reduce).
print(orders.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount })

// Получить список уникальных имён клиентов, отсортированный по алфавиту.
print(Set(orders.map { $0.customer }).sorted())

// Получить массив промокодов, исключив nil (compactMap). 
print(orders.compactMap { $0.promoCode })

// Сгруппировать заказы по имени клиента в словарь [String: [Order]] (через Dictionary(grouping:by:)). 
print(Dictionary(grouping: orders, by: { $0.customer }))

// Найти клиента с максимальной суммарной оплаченной суммой.
print(Dictionary(grouping: orders.filter { $0.isPaid }, by: { $0.customer }).mapValues { $0.reduce(0) { $0 + $1.amount } }.max(by: { $0.value < $1.value }) ?? ("", 0))