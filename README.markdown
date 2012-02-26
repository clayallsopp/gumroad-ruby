# Gumroad-Ruby

A fun little Ruby binding for the Gumroad API.

## Usage

    u = Gumroad::Session.new("email@email.com", "password")
    => #<Gumroad::Session @email="email@email.com", @password="password"> 

    u.links
    => []

    l = Gumroad::Link.create(name: "Gumroad-Ruby", url: "https://raw.github.com/clayallsopp/gumroad-ruby/master/gumroad.rb", price: "199", description: "A nice little Ruby binding for the Gumroad API")
    => #<Gumroad::Link @price=199, @short_url="https://gumroad.com/l/HEk", ...>

    Gumroad::Link.find("HEk") # aka Gumroad::Link.find(l.id)
    => #<Gumroad::Link @price=199, @short_url="https://gumroad.com/l/HEk", ...>

    l.price = 299
    => 299
    l.save
    => #<Gumroad::Link @price=299, @short_url="https://gumroad.com/l/HEk", ...>

    u.links
    => [#<Gumroad::Link @price=299, @short_url="https://gumroad.com/l/HEk", ...>]

    Gumroad::Link.destroy("HEk") # or l.destroy
    => true

    u.logout
    => true