class Contact < ActiveRecord::Base
  validates :name, :linkedin_id, :profile_link, presence: true
  validates :linkedin_id, uniqueness: true
  has_many :connections
  has_many :users, through: :connections

  def self.find_create_or_update(options)
    contact = Contact.where(linkedin_id: options[:linkedin_id]).first

    if contact && (
        contact.name != options[:name] ||
        contact.title != options[:title] ||
        contact.company != options[:company]
      )

      contact.update(options)

    elsif !contact
      contact = Contact.create(options)
    end
    contact
  end
end
