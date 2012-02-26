# Gumroad-Ruby

A fun little Ruby binding for the Gumroad API.

## Usage

    u = Gumroad::Session.new("email@email.com", "password")
    => #<Gumroad::Session @email="email@email.com", @password="password"> 
    u.links
    => []