require "rails/generators"
require "thor"

class ChatterGenerator < Rails::Generators::Base
  desc "This generator creates required files for a chatroom"

  def create_chat_view
  	create_file "app/views/chats/index.html.erb", 
  	"<div id='chats'>
	  <ul id='chats-list'>
	    <% @current_chats.each do |chat| %>
	      <li class='chats-list-item'>
	        <div class='chats-list-item-name'>
	          <%= chat.user.uid %>:
	          <div class='chats-list-item-timestamp'>
	            (<%= l chat.created_at, format: :short %>)
	          </div>        
	        </div>
	        <div class='chats-list-item-body'>
	          <%= chat.body %>
	        </div>
	      </li>
	    <% end %>
	  </ul>
	</div>

	<div id='chat-form-wrapper'>
	  <%= form_for :chat, html: { id: 'chat-form' } do |f| %>
	    <%= f.text_area :body, id: 'chat-form-body' %>
	    <%= f.submit id: 'chat-form-submit' %>
	  <% end %>
	  <div class='clear'></div>
	</div>"
  end 

  def create_chat_controller
  	create_file "app/controllers/chats_controller.rb", 
  	"class ChatsController < ApplicationController
	  def index
	    @current_chats = Chat.current.includes(:user).reverse
	  end

	  private

	  def chat_params
	    params.require(:chat).permit(:body)
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
	//= require ./chats",
	after: "//= require turbolinks"
  end 

  def create_chat_form
  	create_file "app/assets/javascripts/chats.es6",
  	"$(function() {
	  $('#chat-form').submit(function(event) {
	    event.preventDefault();
	    let $chatBody = $(this).find(\"textarea[name='chat[body]']\")
	    Remote.chatting.sendchat($chatBody.val());
	    $chatBody.val(null);
	  });

	  $(Remote.chatting).on('received', function(event, data) {
	    let { body: body, created_at: createdAt } = data.chat;
	    let { uid } = data.user;
	    let html = `<li class='chats-list-item'>
	                  <div class='chats-list-item-name'>
	                    ${ uid }
	                  </div>
	                  <div class='chats-list-item-body'>
	                    ${ body }
	                    <span class='chats-list-item-timestamp'>
	                      ${ createdAt }
	                    </span>
	                  </div>
	                </li>`;

	    $('#chats-list').append($(html));
	  });
	});"
  end 

  def create_remote_form
  	create_file "app/applications/javascripts/remote.es6",
  	"var Remote = {};

	Remote.cable = Cable.createConsumer(`ws://${window.location.hostname}:28080`);

	Remote.chatting = Remote.cable.subscriptions.create('chatsChannel', {
	  received: function(data) {
	    $(this).trigger('received', data);
	  },
	  sendchat: function(chatBody) {
	    this.perform('send_chat', { body: chatBody });
	  }
	});"
  end

  def create_chat_channel
  	create_file "app/channels/chats_channel.rb",
  	"class ChatsChannel < ApplicationCable::Channel
	  def subscribed
	    stream_from \"chats\"
	  end

	  def send_chat(data)
	    chat = current_user.chats.create(body: data['body'])
	    ActionCable.server.broadcast 'chats', { chat: chat,
	                                               user: current_user }
	  end
	end"
  end 

  def insert_chat_model
  	insert_into_file "app/models/chat.rb",
  	"\n
  	belongs_to :user

	  scope :current, -> { order(created_at: :desc).limit(5) }

	  def as_json(options = {})
	    chatSerializer.new(self).as_json
	  end
	end",
	after: "class Chat < ActiveRecord::Base"
  end

  def insert_chat_association
    insert_into_file "app/models/user.rb",
      "\n  has_many :chats",
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

  def create_chats_stylesheet
  	create_file "app/assets/stylesheets/chats.css.sass",
  	"#chats-list
	  list-style: none
	  display: table
	  line-height: 1.2
	  font-size: 1.2em
	  padding-left: 0
	  max-width: 1000px
	  margin: 0 auto

	.chats-list-item
	  display: table-row
	  border-bottom: 1px solid #ccc

	.chats-list-item-name
	  display: table-cell
	  font-weight: bold
	  color: #0a0a0a
	  width: 10%
	  font-family: 'Istok Web', sans-serif

	.chats-list-item-body
	  display: table-cell
	  padding: 10px
	  width: 90%

	.chats-list-item-timestamp
	  text-align: left
	  color: #ccc
	  margin-top: 5px
	  font-size: 0.8em

	#chat-form-wrapper
	  width: 100%
	  margin: 0 auto
	  position: fixed
	  bottom: 0
	  padding: 5px 0 10px 0
	  border-top: 1px solid #ccc
	  background-color: #f6f6f6

	#chat-form
	  width: 100%
	  max-width: 1000px
	  margin: 10px auto

	#chat-form-body
	  width: 85%
	  height: 50px
	  float: left
	  border: 1px solid #2f2f2f
	  border-radius: 3px

	#chat-form-submit
	  width: 10%
	  margin-left: 5%
	  height: 50px
	  float: left
	  border: 0px
	  border-radius: 3px
	  background-color: #2cc36b
	  color: white"
  end

  def create_chat_serializer
  	create_file "app/lib/chat_serializer.rb",
  	"class chatSerializer
	  include ActionView::Helpers::SanitizeHelper
	  attr_reader :chat

	  def initialize(chat)
	    @chat = chat
	  end

	  def as_json
	    {
	      body: sanitize(chat.body),
	      created_at: I18n.l(chat.created_at, format: :short)
	    }
	  end
	end"
  end
end 
