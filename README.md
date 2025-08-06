# Database Schema Samples with Enum Types

This repository contains sample database schemas demonstrating the use of Enum types across different database engines and ORM tools.

## 📁 Directory Structure

```
sample-schema/
├── postgres/       # PostgreSQL native enum types
├── mysql/          # MySQL ENUM column types  
├── prisma/         # Prisma ORM schema definitions
├── tbls/           # tbls documentation tool schemas
└── schemarb/       # Rails Active Record schemas
```

## 🎯 Purpose

Each directory contains example schemas that demonstrate:
- Various enum type definitions
- Different use cases for enums (status, categories, priorities, etc.)
- Best practices for each platform
- Relationships between tables using enums
- Array/SET types where supported

## 📋 Enum Types Included

All examples include the following enum types:
- **User Status**: active, inactive, suspended, pending_verification, deleted
- **Order Status**: pending, processing, shipped, delivered, cancelled, refunded
- **Payment Methods**: credit_card, debit_card, paypal, bank_transfer, etc.
- **Priority Levels**: low, medium, high, urgent, critical
- **Ticket Severity**: trivial, minor, major, critical, blocker
- **Product Categories**: electronics, clothing, books, food, etc.
- **Notification Types**: email, sms, push, in_app, webhook

## 🚀 Quick Start

### PostgreSQL
```bash
cd postgres/
psql -U your_user -d your_database -f schema.sql
```

### MySQL
```bash
cd mysql/
mysql -u your_user -p your_database < schema.sql
```

### Prisma
```bash
cd prisma/
npm install prisma @prisma/client
npx prisma db push
```

### tbls
```bash
cd tbls/
# First apply the PostgreSQL schema
psql -U your_user -d your_database -f schema.sql
# Then generate documentation
tbls doc
```

### Rails (schemarb)
```bash
cd schemarb/
# Copy schema.rb to your Rails db/ directory
# Copy models_example.rb content to your app/models/
rails db:schema:load
```

## 📝 Features by Platform

### PostgreSQL
- Native ENUM types
- Array of enums support
- Type comments for documentation
- Functions and triggers using enums

### MySQL  
- ENUM column types
- SET type for multiple values
- Stored procedures with enum parameters
- Triggers for enum validation

### Prisma
- Enum definitions in schema
- Array enum fields
- Relations with enum constraints
- Multi-database support ready

### tbls
- Comprehensive table/column comments
- Configuration for documentation
- Lint rules for schema quality
- ER diagram generation support

### Rails
- Integer-based enums (Rails convention)
- PostgreSQL native enum support
- Model-level enum definitions
- Scopes and helpers for enums

## 🧪 Testing

Each directory includes test data inserts to verify the schema works correctly. Run the schema files to create tables and insert sample data.

## 📚 Documentation

- [PostgreSQL Enum Types](https://www.postgresql.org/docs/current/datatype-enum.html)
- [MySQL ENUM Type](https://dev.mysql.com/doc/refman/8.0/en/enum.html)
- [Prisma Enums](https://www.prisma.io/docs/concepts/components/prisma-schema/data-model#enums)
- [Rails Enums](https://api.rubyonrails.org/classes/ActiveRecord/Enum.html)
- [tbls Documentation](https://github.com/k1LoW/tbls)

## 🤝 Contributing

Feel free to add more examples or improve existing schemas. Each schema should:
1. Include comprehensive enum usage
2. Follow platform best practices
3. Include sample data
4. Be well-commented

## 📄 License

MIT