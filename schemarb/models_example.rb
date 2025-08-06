# Rails Model Examples with Enum Definitions
# These would typically be in app/models/ directory

# app/models/user.rb
class User < ApplicationRecord
  has_one :profile, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :support_tickets, dependent: :destroy
  has_one :notification_preference, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :audit_logs, dependent: :nullify
  
  # Define enum with integer mapping (Rails convention)
  enum status: {
    active: 0,
    inactive: 1,
    suspended: 2,
    pending_verification: 3,
    deleted: 4
  }
  
  enum role: {
    user: 0,
    moderator: 1,
    admin: 2,
    super_admin: 3
  }
  
  # Or using string keys (Rails 7+)
  # enum status: {
  #   active: "active",
  #   inactive: "inactive",
  #   suspended: "suspended",
  #   pending_verification: "pending_verification",
  #   deleted: "deleted"
  # }, _prefix: true
  
  # Validations
  validates :email, presence: true, uniqueness: true
  validates :username, presence: true, uniqueness: true
  
  # Scopes
  scope :verified, -> { where(status: :active) }
  scope :pending, -> { where(status: :pending_verification) }
  scope :admins, -> { where(role: [:admin, :super_admin]) }
end

# app/models/order.rb
class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items
  has_one :payment, dependent: :destroy
  
  # Define enums
  enum status: {
    pending: 0,
    processing: 1,
    shipped: 2,
    delivered: 3,
    cancelled: 4,
    refunded: 5
  }
  
  enum payment_method: {
    credit_card: 0,
    debit_card: 1,
    paypal: 2,
    bank_transfer: 3,
    cash_on_delivery: 4,
    cryptocurrency: 5
  }
  
  # Using _prefix or _suffix to avoid method name conflicts
  # enum status: { pending: 0, processing: 1 }, _prefix: :order
  # This creates methods like: order_pending?, order_processing?
  
  # Validations
  validates :order_number, presence: true, uniqueness: true
  validates :total_amount, presence: true, numericality: { greater_than: 0 }
  
  # Callbacks
  before_create :generate_order_number
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :completed, -> { where(status: [:delivered, :refunded]) }
  scope :in_progress, -> { where(status: [:pending, :processing, :shipped]) }
  
  private
  
  def generate_order_number
    self.order_number ||= "ORD-#{SecureRandom.hex(8).upcase}"
  end
end

# app/models/product.rb
class Product < ApplicationRecord
  has_many :order_items
  has_many :orders, through: :order_items
  has_many :reviews, dependent: :destroy
  
  # Define enum for category
  enum category: {
    electronics: 0,
    clothing: 1,
    books: 2,
    food: 3,
    home_garden: 4,
    sports: 5,
    toys: 6,
    health_beauty: 7
  }
  
  # Validations
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :sku, presence: true, uniqueness: true
  
  # Scopes
  scope :available, -> { where(active: true).where("stock_quantity > ?", 0) }
  scope :by_category, ->(category) { where(category: category) }
  
  # Instance methods
  def in_stock?
    stock_quantity > 0
  end
end

# app/models/support_ticket.rb
class SupportTicket < ApplicationRecord
  belongs_to :user
  belongs_to :assigned_to, class_name: 'User', optional: true
  has_many :comments, as: :commentable, dependent: :destroy
  
  # Define enums
  enum priority: {
    low: 0,
    medium: 1,
    high: 2,
    urgent: 3,
    critical: 4
  }, _prefix: true
  
  enum severity: {
    trivial: 0,
    minor: 1,
    major: 2,
    critical: 3,
    blocker: 4
  }, _prefix: true
  
  enum status: {
    open: 0,
    in_progress: 1,
    waiting_on_customer: 2,
    resolved: 3,
    closed: 4
  }
  
  # Validations
  validates :title, presence: true
  validates :description, presence: true
  validates :ticket_number, presence: true, uniqueness: true
  
  # Callbacks
  before_create :generate_ticket_number
  
  # Scopes
  scope :unassigned, -> { where(assigned_to_id: nil) }
  scope :assigned_to, ->(user) { where(assigned_to: user) }
  scope :high_priority, -> { where(priority: [:high, :urgent, :critical]) }
  scope :unresolved, -> { where.not(status: [:resolved, :closed]) }
  
  private
  
  def generate_ticket_number
    self.ticket_number ||= "TICKET-#{SecureRandom.hex(6).upcase}"
  end
end

# app/models/notification_preference.rb
class NotificationPreference < ApplicationRecord
  belongs_to :user
  
  # Define enum for notification types (stored as array of integers)
  enum enabled_type: {
    email: 0,
    sms: 1,
    push: 2,
    in_app: 3,
    webhook: 4
  }, _prefix: true
  
  enum email_frequency: {
    instant: 0,
    daily: 1,
    weekly: 2,
    monthly: 3
  }
  
  # For array columns, we can use scopes
  scope :with_notification_type, ->(type) { 
    where("? = ANY(enabled_types)", enabled_types[type]) 
  }
  
  # Helper methods for array enum handling
  def has_notification_type?(type)
    enabled_types.include?(self.class.enabled_types[type])
  end
  
  def add_notification_type(type)
    type_value = self.class.enabled_types[type]
    self.enabled_types << type_value unless enabled_types.include?(type_value)
  end
  
  def remove_notification_type(type)
    self.enabled_types.delete(self.class.enabled_types[type])
  end
end

# app/models/payment.rb
class Payment < ApplicationRecord
  belongs_to :order
  
  # Reuse payment_method enum from Order or define separately
  enum payment_method: {
    credit_card: 0,
    debit_card: 1,
    paypal: 2,
    bank_transfer: 3,
    cash_on_delivery: 4,
    cryptocurrency: 5
  }
  
  enum status: {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3,
    refunded: 4,
    partially_refunded: 5
  }, _prefix: :payment
  
  # Validations
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_id, uniqueness: true, allow_nil: true
  
  # Scopes
  scope :successful, -> { where(status: :completed) }
  scope :failed, -> { where(status: :failed) }
end

# app/models/review.rb
class Review < ApplicationRecord
  belongs_to :product
  belongs_to :user
  
  # Rating could be an enum or just validated integer
  # If using enum:
  # enum rating: {
  #   one_star: 1,
  #   two_stars: 2,
  #   three_stars: 3,
  #   four_stars: 4,
  #   five_stars: 5
  # }, _prefix: true
  
  # Validations
  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :user_id, uniqueness: { scope: :product_id, 
    message: "can only review a product once" }
  
  # Scopes
  scope :verified, -> { where(verified_purchase: true) }
  scope :with_comments, -> { where.not(comment: [nil, ""]) }
  scope :highly_rated, -> { where(rating: [4, 5]) }
end

# app/models/audit_log.rb
class AuditLog < ApplicationRecord
  belongs_to :auditable, polymorphic: true
  belongs_to :user, optional: true
  
  # Action could be an enum
  enum action: {
    create: 0,
    update: 1,
    delete: 2,
    login: 3,
    logout: 4,
    password_change: 5
  }, _prefix: true
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  scope :for_model, ->(model_name) { where(auditable_type: model_name) }
end

# Example of using concerns for shared enum behavior
# app/models/concerns/statusable.rb
module Statusable
  extend ActiveSupport::Concern
  
  included do
    enum status: {
      draft: 0,
      pending: 1,
      approved: 2,
      rejected: 3,
      archived: 4
    }, _prefix: true
    
    scope :published, -> { where(status: :approved) }
    scope :pending_review, -> { where(status: :pending) }
  end
  
  def publish!
    update!(status: :approved)
  end
  
  def archive!
    update!(status: :archived)
  end
end

# Usage examples in Rails console:
# user = User.create(email: "test@example.com", username: "testuser")
# user.active!  # Set status to active
# user.active?  # Check if status is active
# User.active   # Scope to get all active users
# 
# order = Order.new
# order.payment_method = :credit_card  # Set using symbol
# order.payment_method = "credit_card" # Or string
# order.payment_method = 0             # Or integer value
# order.credit_card?                   # Check payment method
# 
# ticket = SupportTicket.new
# ticket.priority_high!                # Set priority (with prefix)
# ticket.priority_high?                # Check priority
# SupportTicket.priority_high          # Scope for high priority tickets