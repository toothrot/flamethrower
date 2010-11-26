module Flamethrower
  module Server
    include Flamethrower::Irc::Commands

    attr_accessor :campfire_connection, :current_user, :dispatcher, :log, :channels

    def initialize(options = {})
      @log = options[:log] || Logger.new(STDOUT)
      @channels = []
      @current_user ||= Flamethrower::Irc::User.new
      @dispatcher ||= Flamethrower::Dispatcher.new(self)
    end

    def after_connect
      send_motd
    end

    def send_message(msg)
      send_data "#{msg}\r\n"
      log.debug ">> #{msg}"
      msg
    end

    def receive_data(msg)
      messages = msg.split("\r\n")
      messages.each do |message|
        dispatcher.handle_message(Flamethrower::Message.new(message))
        log.debug "<< #{message}"
      end
    end

    def send_messages(*messages)
      yield(messages) if block_given?
      messages.each {|msg| send_message(msg)}
    end

  end
end
