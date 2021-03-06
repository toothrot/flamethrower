require File.join(File.dirname(__FILE__), "../../spec_helper")

describe Flamethrower::Campfire::Connection do
  before do
    @server = Flamethrower::MockServer.new
    @connection = @server.campfire_connection
  end

  describe "#fetch_my_user" do
    it "retrieves my user and stores it on the connection" do
      stub_request(:get, "https://mydomain.campfirenow.com/users/me.json").
        with(:headers => {'Authorization'=>['mytoken', 'x']}).
        to_return(:status => 200, :body => json_fixture("user"))
      EM.run_block { @connection.fetch_my_user }
      @server.current_user.nickname.should == "blake"
    end

    it "renames your current user to the new current user" do
      @server.current_user = Flamethrower::Irc::User.new(:nickname => "bob")
      stub_request(:get, "https://mydomain.campfirenow.com/users/me.json").
        with(:headers => {'Authorization'=>['mytoken', 'x']}).
        to_return(:status => 200, :body => json_fixture("user"))
      @server.should_receive(:send_message).with(":bob NICK blake")
      EM.run_block { @connection.fetch_my_user }
    end
  end

  describe "#rooms" do
    it "retrieves a list of rooms from JSON" do
      stub_request(:get, "https://mydomain.campfirenow.com/rooms.json").
        with(:headers => {'Authorization'=>['mytoken', 'x']}).
        to_return(:status => 200, :body => json_fixture("rooms"))
      EM.run_block { @connection.fetch_rooms }
      room = @server.irc_channels.first.to_campfire
      room.number.should == 347348
      room.name.should == "Room 1"
      room.topic.should == "some topic"
    end

    it "makes the http request with a token in basic auth" do
      stub_request(:get, "https://mydomain.campfirenow.com/rooms.json").
             with(:headers => {'Authorization'=>['mytoken', 'x']}).
             to_return(:status => 200, :body => json_fixture("rooms"))
      EM.run_block { @connection.fetch_rooms }
      assert_requested(:get, "https://mydomain.campfirenow.com/rooms.json") {|req| req.headers['Authorization'].should == ["mytoken", "x"]}
    end

    it "returns empty set if not a successful response" do
      stub_request(:get, "https://mydomain.campfirenow.com/rooms.json").
             with(:headers => {'Authorization'=>['mytoken', 'x']}).
             to_return(:status => 400)
      EM.run_block { @connection.fetch_rooms }
      @server.irc_channels.should == []
    end

    xit "sends a motd error message if unable to fetch room list" do
      @connection.should_receive(:campfire_get).and_raise(SocketError) 
      @server.should_receive(:send_message).with(@server.reply(Flamethrower::Irc::Codes::RPL_MOTD, ":ERROR: Unable to fetch room list! Check your connection?"))
      @connection.rooms.should == []
    end
  end

end
