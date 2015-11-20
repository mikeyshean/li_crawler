class Contact < ActiveRecord::Base
  validates :name, :linkedin_id, :profile_link, presence: true
  validates :linkedin_id, uniqueness: true
  has_many :connections
  has_many :users, through: :connections
end
