class User < ActiveRecord::Base

  validates :email, uniqueness: true, presence: true

  has_many :connections
  has_many :contacts, through: :connections

  def scrape_first_connections(linkedin_password)
    browser = Watir::Browser.new :phantomjs
    browser.goto "https://www.linkedin.com/"

    username = browser.text_field :id => "login-email"
    password = browser.text_field :id => "login-password"

    username.set self.email
    password.set linkedin_password

    button = browser.button :value, "Sign in"
    button.click if button.exists?

    browser.div(:id => "identity").when_present do

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

        contact_num = 1
        page.search(".contact-item-view").each do |contact|
          default = "N/A"
          name = contact.at_css(".name a").try(:text) || default
          title = contact.at_css(".title").try(:text) || default
          company = contact.at_css(".company").try(:text) || default
          link = contact.at_css(".name a")[:href]
          profile_link = "https://www.linkedin.com#{link}"
          id = link[/(?=li_ ?(\d+))/,1].to_i


          contact = Contact.find_create_or_update({
            name: name,
            profile_link: profile_link,
            linkedin_id: id,
            title: title,
            company: company
          })

          contacts = self.first_degree_contacts
          if !contacts.include?(contact)
            self.connections.create(contact_id: contact.id, degree: 1)
          end
        end

      end
    end
    true
  end

  def scrape_second_connections(linkedin_password)
    start = Time.now

    browser = Watir::Browser.new :phantomjs
    browser.goto "https://www.linkedin.com/"

    username = browser.text_field :id => "login-email"
    password = browser.text_field :id => "login-password"

    username.set self.email
    password.set linkedin_password

    button = browser.button :value, "Sign in"
    button.click if button.exists?

    browser.div(:id => "identity").when_present do

# Visit each first degree contact's profile
      contacts = self.first_degree_contacts
      contacts.each do |contact|
        url = contact.profile_link
        browser.goto(url)

        contacts_2 = self.second_degree_contacts

        browser.a(:class => "connections-link").when_present do
          link = browser.link :class => "connections-link"
          link.click if link.exists?

          browser.div(:id =>"connections").when_present do

# Trigger carousel and parse each 2nd degree contact
            while browser.button(:class => "next").visible? do
              page = Nokogiri::HTML.parse(browser.html)

              page.search(".cardstack-container li").each do |user|
                next if user.at_css(".degree-icon").text != "2nd"

                default = "N/A"
                name = user.at_css(".connections-name").try(:text) || default
                id = user[:id][/(?=connection- ?(\d+))/,1].to_i
                profile_link = "https://www.linkedin.com/contacts/view?id=li_#{id}&trk=contacts-contacts-list-contact_name-0"


                contact = Contact.find_create_or_update({
                  name: name,
                  profile_link: profile_link,
                  linkedin_id: id,
                  title: default,
                  company: default
                })


                if !contacts_2.include?(contact)
                  self.connections.create(contact_id: contact.id, degree: 2)
                end
              end

              loading = true
              while loading
                loading = browser.button(:class => "next", :disabled => "disabled").exists?
              end

              btn = browser.button :class => "next"
              btn.click if btn.exists? && btn.visible?

              loading = true
              while loading
                loading = browser.div(:id => "connections", :class => "loading").exists?
              end

            end
          end
        end
      end
    end
    puts Time.now - start
    true
  end

  def first_degree_contacts
    Contact.joins(connections: :user).where("users.id = #{self.id} AND connections.degree = 1")
  end

  def second_degree_contacts
    Contact.joins(connections: :user).where("users.id = #{self.id} AND connections.degree = 2")
  end

end
