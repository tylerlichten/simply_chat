require 'spec_helper_generator'
require 'generator_spec'

describe ChatterGenerator, type: :generator do
  before(:all) do
    prepare_destination
    run_generator
  end

  it "creates a view for chatroom" do
    assert_file "app/views/messages/index.html.erb", 
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
  end

  it "creates a controller for chat messages" do
    assert_file "app/controllers/messages_controller.rb", 
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

  it "creates redis server config" do
    assert_file "app/config/redis/cable.yml", 
    "development: &development
	  :url: redis://localhost:6379
	  :host: localhost
	  :port: 6379
	  :timeout: 1
	  :inline: true
	test: *development"
  end

  it "creates actioncable server config" do
    assert_file "cable/config.ru", 
    "require ::File.expand_path('../../config/environment',  __FILE__)
	Rails.application.eager_load!

	require 'action_cable/process/logging'

	run ActionCable.server"
  end

  it "creates puma server cable" do
    assert_file "bin/cable", 
    "bundle exec puma -p 28080  cable/config.ru"
  end

  it "creates a base class channel" do
    assert_file "app/channels/application_cable/channel.rb", 
    "module ApplicationCable
	  class Channel < ActionCable::Channel::Base
	  end
	end"
  end

  it "creates a base class connection" do
    assert_file "app/channels/application_cable/connection.rb", 
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

  it "adds paths to manifest file" do
    assert_file "app/assets/javascripts/application.js", 
    "\n//= require cable
	//= require ./remote
	//= require ./messages"
  end

  it "creates a message form" do
    assert_file "app/assets/javascripts/messages.es6", 
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

  it "creates a remote form" do
    assert_file "app/applications/javascripts/remote.es6", 
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

  it "creates a message model" do
    assert_file "app/models/message.rb", 
    "class Message < ActiveRecord::Base
	  belongs_to :user

	  scope :current, -> { order(created_at: :desc).limit(5) }

	  def as_json(options = {})
	    MessageSerializer.new(self).as_json
	  end
	end"
  end

  it "creates a User association for messages" do
    assert_file "app/models/user.rb", 
    "\n  has_many :messages"
  end

  it "creates a base stylesheet" do
    assert_file "app/assets/stylesheets/base.css.sass", 
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

  it "creates a messages stylesheet" do
    assert_file "app/assets/stylesheets/messages.css.sass", 
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

  it "creates a message serializer" do
    assert_file "app/lib/message_serializer.rb", 
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
