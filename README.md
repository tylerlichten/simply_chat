# SimplyChat

simply_chat builds a chatroom for users of the website using Redis and Puma servers.

# Installation

Add this line to your application's Gemfile:

```ruby
gem 'simply_chat'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install simply_chat

# Usage

###Step 1

Create Chat model.

	$ rails g model Chat user_id:integer body:text    
	$ rake db:migrate

###Step 2

Add index to db using rails console.

	ActiveRecord::Migration.add_index :chats, [:user_id]

###Step 3

Add link to chatroom (place link in navbar).

	<li><%= link_to 'Chatroom', chats_path %></li>

Add path in routes.rb.

	resources :chats
	get 'chats' => 'chats#index'

# Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tylerlichten/simply_chat.

# License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

