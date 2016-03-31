require "rails/generators"
require "thor"

class ChatterGenerator < Rails::Generators::Base
  desc "This generator creates required files for a chatroom"

  def create_chat_view
  	create_file "app/views/messages/index.html.erb", 
  	"<div id='messages'>
	  <ul id='messages-list'>
	    <% @current_messages.each do |message| %>
	      <li class='messages-list-item'>
	        <div class='messages-list-item-name'>
	          <%= message.user.uid %>:
	          <div class='messages-list-item-timestamp'>
	            (<%= l message.created_at, format: :short %>)
	          </div>        
	        </div>
	        <div class='messages-list-item-body'>
	          <%= message.body %>
	        </div>
	      </li>
	    <% end %>
	  </ul>
	</div>

	<div id='message-form-wrapper'>
	  <%= form_for :message, html: { id: 'message-form' } do |f| %>
	    <%= f.text_area :body, id: 'message-form-body' %>
	    <%= f.submit id: 'message-form-submit' %>
	  <% end %>
	  <div class='clear'></div>
	</div>"

	create_file "app/views/layouts/application.html.erb"
  end 

  def create_chat_controller
  	create_file "app/controllers/messages_controller.rb", 
  	"class MessagesController < ApplicationController
	  before_action :require_current_user

	  def index
	    @current_messages = Message.current.includes(:user).reverse
	  end

	  private

	  def message_params
	    params.require(:message).permit(:body)
	  end
	end"
  end

  def create_actioncable_server_redis
  	create_file "app/config/redis/cable.yml", 
  	"development: &development
	  :url: redis://localhost:6379
	  :host: localhost
	  :port: 6379
	  :timeout: 1
	  :inline: true
	test: *development"
  end

  def create_actioncable_server_config
  	create_file "cable/config.ru", 
  	"require ::File.expand_path('../../config/environment',  __FILE__)
	Rails.application.eager_load!

	require 'action_cable/process/logging'

	run ActionCable.server"
  end 

  def create_actioncable_server_puma
  	create_file "bin/cable", 
  	"bundle exec puma -p 28080  cable/config.ru"
  end

  def create_base_class_channel
  	create_file "app/channels/application_cable/channel.rb",
  	"module ApplicationCable
	  class Channel < ActionCable::Channel::Base
	  end
	end"
  end

  def create_base_class_connection
  	create_file "app/channels/application_cable/connection.rb",
  	"module ApplicationCable
	  class Connection < ActionCable::Connection::Base
	    identified_by :current_user

	    def connect
	      self.current_user = find_verified_user
	    end

	    protected

	    def find_verified_user

	      if verified_user = User.find_by(id: cookies.signed[:user_id])
	        verified_user
	      else
	        reject_unauthorized_connection
	      end

	    end
	  end
	end"
  end

  def insert_js_lib
  	insert_into_file "app/assets/javascripts/application.js",
  	"\n//= require cable
	//= require ./remote
	//= require ./messages",
	after: "//= require turbolinks"
  end 

  def create_message_form
  	create_file "app/assets/javascripts/messages.es6",
  	"$(function() {
	  $('#message-form').submit(function(event) {
	    event.preventDefault();
	    let $messageBody = $(this).find(\"textarea[name='message[body]']\")
	    Remote.messaging.sendMessage($messageBody.val());
	    $messageBody.val(null);
	  });

	  $(Remote.messaging).on('received', function(event, data) {
	    let { body: body, created_at: createdAt } = data.message;
	    let { uid } = data.user;
	    let html = `<li class='messages-list-item'>
	                  <div class='messages-list-item-name'>
	                    ${ uid }
	                  </div>
	                  <div class='messages-list-item-body'>
	                    ${ body }
	                    <span class='messages-list-item-timestamp'>
	                      ${ createdAt }
	                    </span>
	                  </div>
	                </li>`;

	    $('#messages-list').append($(html));
	  });
	});"
  end 

  def create_remote_form
  	create_file "app/applications/javascripts/remote.es6",
  	"var Remote = {};

	Remote.cable = Cable.createConsumer(`ws://${window.location.hostname}:28080`);

	Remote.messaging = Remote.cable.subscriptions.create('MessagesChannel', {
	  received: function(data) {
	    $(this).trigger('received', data);
	  },
	  sendMessage: function(messageBody) {
	    this.perform('send_message', { body: messageBody });
	  }
	});"
  end

  def create_message_channel
  	create_file "app/controllers/messages_controller.rb",
  	"class MessagesChannel < ApplicationCable::Channel
	  def subscribed
	    stream_from \"messages\"
	  end

	  def send_message(data)
	    message = current_user.messages.create(body: data['body'])
	    ActionCable.server.broadcast 'messages', { message: message,
	                                               user: current_user }
	  end
	end"
  end 

  def create_message_model
  	create_file "app/models/message.rb",
  	"class Message < ActiveRecord::Base
	  belongs_to :user

	  scope :current, -> { order(created_at: :desc).limit(5) }

	  def as_json(options = {})
	    MessageSerializer.new(self).as_json
	  end
	end"
  end

  def insert_message_association
    insert_into_file "app/models/user.rb",
      "\n  has_many :messages",
      after: "class User < ActiveRecord::Base"
  end 

  def create_base_stylesheet
  	create_file "app/assets/stylesheets/base.css.sass",
  	"@import url(https://fonts.googleapis.com/css?family=Istok+Web:400,700|Lora:400,700)

	html
	  box-sizing: border-box

	*, *:before, *:after
	  box-sizing: inherit

	body
	  background-color: #fafafa
	  color: #2f2f2f
	  font-family: 'Lora', serif

	nav
	  text-align: right
	  margin-top: 10px

	a, a:active, a:visited
	  color: #2f3da2
	  text-decoration: none
	  font-family: 'Istok Web', sans-serif"
  end

  def create_messages_stylesheet
  	create_file "app/assets/stylesheets/messages.css.sass",
  	"#messages-list
	  list-style: none
	  display: table
	  line-height: 1.2
	  font-size: 1.2em
	  padding-left: 0
	  max-width: 1000px
	  margin: 0 auto

	.messages-list-item
	  display: table-row
	  border-bottom: 1px solid #ccc

	.messages-list-item-name
	  display: table-cell
	  font-weight: bold
	  color: #0a0a0a
	  width: 10%
	  font-family: 'Istok Web', sans-serif

	.messages-list-item-body
	  display: table-cell
	  padding: 10px
	  width: 90%

	.messages-list-item-timestamp
	  text-align: left
	  color: #ccc
	  margin-top: 5px
	  font-size: 0.8em

	#message-form-wrapper
	  width: 100%
	  margin: 0 auto
	  position: fixed
	  bottom: 0
	  padding: 5px 0 10px 0
	  border-top: 1px solid #ccc
	  background-color: #f6f6f6

	#message-form
	  width: 100%
	  max-width: 1000px
	  margin: 10px auto

	#message-form-body
	  width: 85%
	  height: 50px
	  float: left
	  border: 1px solid #2f2f2f
	  border-radius: 3px

	#message-form-submit
	  width: 10%
	  margin-left: 5%
	  height: 50px
	  float: left
	  border: 0px
	  border-radius: 3px
	  background-color: #2cc36b
	  color: white"
  end

  def create_message_serializer
  	create_file "app/lib/message_serializer.rb",
  	"class MessageSerializer
	  include ActionView::Helpers::SanitizeHelper
	  attr_reader :message

	  def initialize(message)
	    @message = message
	  end

	  def as_json
	    {
	      body: sanitize(message.body),
	      created_at: I18n.l(message.created_at, format: :short)
	    }
	  end
	end"
  end
end 
