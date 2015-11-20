class User < ActiveRecord::Base

  validates :email, uniqueness: true, presence: true

  has_many :connections
  has_many :contacts, through: :connections

  def generate_connections(linkedin_password)
    browser = Watir::Browser.new :phantomjs
    browser.goto "https://www.linkedin.com/"

    username = browser.text_field :id => "login-email"
    password = browser.text_field :id => "login-password"

    username.set self.email
    password.set linkedin_password

    button = browser.button :value, "Sign in"
    button.click if button.exists?

    browser.div(:id => "identity").when_present do |identity|

    # Save number of user connections and navigate to connections list view.
      home = Nokogiri::HTML.parse(browser.html)
      num_connections = home.at_css("span.num.connections").text.to_i

      url = "https://www.linkedin.com/contacts/?filter=recent&trk=nav_responsive_sub_nav_network#?sortOrder=recent&fromFilter=true&connections=enabled&source=LinkedIn&"
      browser.goto(url)

      browser.li(:class => "contact-item-view").when_present do

    # Infinite Scroll:  Loop scroll script until user list is fully loaded.
        list_count = 0
        while list_count < num_connections
          browser.execute_script("window.scrollTo(0,document.body.scrollHeight)")
          page = Nokogiri::HTML.parse(browser.html)
          list_count = page.search(".contact-item-view").size
        end

    # Scrape full name and profile link from each connection
        contact_ids = self.connections.where(degree: 1).pluck(:contact_id)
        contact_num = 1
        page.search(".contact-item-view").each do |contact|
          name = contact.at_css(".name a").text
          link = contact.at_css(".name a")[:href]
          profile_link = "https://www.linkedin.com#{link}"
          id = link[/(?=li_ ?(\d+))/,1].to_i


          contact = Contact.find_by(linkedin_id: id)
          if !contact
            contact = Contact.create(name: name, profile_link: profile_link, linkedin_id: id)
          end
          puts "created"
          puts "#{contact.id} - #{contact.name}"

          if !contact_ids.include?(contact.id)
            self.connections.create(contact_id: contact.id, degree: 1)
            puts "connection"
          end
        end

      end
    end
    true
  end

  def first_degree_contacts
    Contact.joins(connections: :user).where("users.id = #{self.id} AND connections.degree = 1")
  end
  def second_degree_contacts
    Contact.joins(connections: :user).where("users.id = #{self.id} AND connections.degree = 2")
  end

end
