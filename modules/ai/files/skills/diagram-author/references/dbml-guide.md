# DBML (Database Markup Language) Guide

Quick reference for generating DBML schemas for dbdiagram.io and DrawSQL.

---

## 1. Table Definitions
```dbml
Table users {
  id integer [primary key, increment]
  email varchar(255) [unique, not null]
  full_name varchar(100)
  role varchar(20) [default: 'user', note: 'admin | user | guest']
  created_at timestamp [not null, default: `now()` ]
  updated_at timestamp [not null, default: `now()` ]
}

Table orders {
  id uuid [primary key]
  user_id integer [not null]
  total_amount decimal(12,2) [not null]
  status varchar(30) [not null, default: 'pending']
  created_at timestamp [not null]
}
```

## 2. Relationships & Cardinality
```dbml
// One-to-many: One user has many orders (<)
Ref: users.id < orders.user_id

// One-to-one (-)
Ref: users.id - user_profiles.user_id

// Many-to-many: Use join table
Ref: orders.id < order_items.order_id
Ref: products.id < order_items.product_id
```

## 3. Enums & Table Groups
```dbml
Enum order_status {
  pending
  processing
  completed
  cancelled
}

TableGroup commerce {
  orders
  order_items
  products
}
```
