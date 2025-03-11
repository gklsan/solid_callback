# SolidCallback

[![Gem Version](https://badge.fury.io/rb/solid_callback.svg)](https://badge.fury.io/rb/solid_callback)
[![Build Status](https://github.com/gklsan/solid_callback/workflows/tests/badge.svg)](https://github.com/gklsan/solid_callback/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

SolidCallback adds powerful method interception capabilities to your Ruby classes with near-zero overhead. Clean, flexible, and unobtrusive.

## Features

- 🔄 **Method Lifecycle Hooks**: `before_call`, `after_call`, and `around_call` - intercept methods without modifying their code
- 🧩 **Zero-coupling**: Keep your business logic and cross-cutting concerns separate
- 🔍 **Selective targeting**: Apply callbacks to specific methods or all methods
- ⚡ **Performance-focused**: Minimal overhead through efficient method wrapping
- 🔒 **Thread-safe**: Safely use in concurrent applications
- 📝 **Conditional execution**: Run callbacks only when specific conditions are met

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'solid_callback'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself:

```bash
$ gem install solid_callback
```

## Usage

### Basic Example

```ruby
require 'solid_callback'

class UserService
  include SolidCallback
  
  before_call :authenticate
  after_call :log_activity
  around_call :measure_performance
  
  def find_user(id)
    puts "Finding user with ID: #{id}"
    { id: id, name: "User #{id}" }
  end
  
  def update_user(id, attributes)
    puts "Updating user #{id} with #{attributes}"
    { id: id, updated: true }
  end
  
  private
  
  def authenticate
    puts "🔐 Authenticating request"
  end
  
  def log_activity
    puts "📝 Logging activity"
  end
  
  def measure_performance
    start_time = Time.now
    result = yield  # Execute the original method
    duration = Time.now - start_time
    puts "⏱️ Method took #{duration} seconds"
    result  # Return the original result
  end
end

service = UserService.new
service.find_user(42)
```

### Advanced Usage

Apply callbacks to specific methods:

```ruby
class PaymentProcessor
  include SolidCallback
  
  before_call :validate_amount, only: [:charge, :refund]
  after_call :send_receipt, only: [:charge]
  after_call :notify_fraud_department, only: [:flag_suspicious]
  around_call :transaction, only: [:charge, :refund]
  
  # Rest of class...
end
```

Use conditional callbacks:

```ruby
class DocumentProcessor
  include SolidCallback
  
  attr_reader :document_size
  
  before_call :check_permissions
  before_call :backup_document, if: :large_document?
  around_call :with_retry, unless: :read_only?
  
  def process_document(doc)
    # Implementation...
  end
  
  private
  
  def large_document?
    @document_size > 10_000
  end
  
  def read_only?
    # Some condition
  end
end
```

You can even use procs for conditions:

```ruby
before_call :notify_admin, if: -> { Rails.env.production? }
```

### Skipping Callbacks

Skip callbacks for specific methods:

```ruby
class ApiService
  include SolidCallback
  
  before_call :rate_limit
  
  skip_callbacks_for :health_check
  
  def get_data
    # Implementation...
  end
  
  def health_check
    # This method won't trigger the rate_limit callback
    { status: "ok" }
  end
end
```

## Callback Options

Each callback method accepts the following options:

| Option | Description |
|--------|-------------|
| `only` | Array of method names to which the callback applies |
| `except` | Array of method names to which the callback does not apply |
| `if` | Symbol (method name) or Proc that must return true for the callback to run |
| `unless` | Symbol (method name) or Proc that must return false for the callback to run |

## How It Works

Callbacker uses Ruby's metaprogramming to wrap your methods with callback functionality:

1. When included, it extends your class with callback registration methods
2. When a callback is registered, it stores the configuration
3. When a method is defined, it wraps the method with callback handling code
4. When the method is called, it executes the callbacks in the proper order

## 📚 Use Cases

- Authentication & Authorization
- Logging & Monitoring
- Caching
- Performance measurement
- Error handling
- Background job retries
- Transaction management
- Input validation
- Data transformation

## 🤝 Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/gklsan/solid_callback.

## 📄 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
