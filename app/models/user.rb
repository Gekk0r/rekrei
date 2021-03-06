# Devise User Class
class User < ActiveRecord::Base
  # Use friendly_id on Users
  extend FriendlyId
  friendly_id :friendify, use: :slugged
  attr_accessor :login

  def login=(login)
    @login = login
  end

  def login
    @login || self.username || self.email
  end

  # necessary to override friendly_id reserved words
  def friendify
    if username.downcase == 'admin'
      "user-#{username}"
    else
      "#{username}"
    end
  end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  # Pagination
  paginates_per 100

  # Validations
  # :username
  validates :username, uniqueness: { case_sensitive: false }
  validates :username, length: { in: 4..15 }
  validates :username, format: {
    with: /\A[a-zA-Z0-9]*\z/,
    on: :create,
    message: 'can only contain letters and digits'
  }

  # :email
  validates :email, format: {
    with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
  }
  def self.paged(page_number)
    order(admin: :desc, username: :asc).page page_number
  end

  def self.search_and_order(search, page_number)
    if search
      where('username LIKE ?', "%#{search.downcase}%").order(
        admin: :desc, username: :asc
      ).page page_number
    else
      order(admin: :desc, username: :asc).page page_number
    end
  end

  def self.last_signups(count)
    order(created_at: :desc).limit(count)
      .select('id', 'username', 'slug', 'created_at')
  end

  def self.last_signins(count)
    order(last_sign_in_at:
    :desc).limit(count)
      .select('id', 'username', 'slug', 'last_sign_in_at')
  end

  def self.users_count
    where('admin = ? AND locked = ?', false, false).count
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    conditions[:email].downcase! if conditions[:email]
    if login = conditions.delete(:login)
      where(conditions.to_hash).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions.to_hash).first
    end
  end
end
