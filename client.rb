#!/usr/bin/env ruby -w

##############################################################################
#    Distributed Code Sample
#    Copyright (C) 2015  Sinan ISLEKDEMIR
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
##############################################################################

##############################################################################
# This script is an example for runnig your codes on several computers.
#
# Client Script
##############################################################################

require "socket"
require "json"

# Worker client class
class Client
  # initialize client
  def initialize(host, port)
    # create connection
    puts "Connecting to #{host} on port #{port}"
    @server = TCPSocket.open(host, port)
    @unique_id = nil
    @response = nil
    # listening for incoming commands
    listen
    @response.join
  end

  def eval_code(code, client_row)
    eval(code)
  end

  def listen
    @response = Thread.new do
      loop do
        msg = @server.gets.chomp
        command = JSON.parse(msg)
        if command['msg'] == "connected"
          puts "Connection established with unique_id #{command['unique_id']}"
        end
        if command['msg'] == "server_full"
          puts "Server already has enough clients"
          break
        end
        if command['msg'] == "welcome"
          puts "Joined to server pool, got the code"
          result = eval_code(command['code'], command['client'])
          puts "Sending results to server: "
          @server.puts(result.to_json)
        end
        if command['msg'] == "thank_you"
          puts "Mission accomplished, server said 'thank you' :)"
          break
        end
      end
    end
    @response.join
  end
end

puts "Usage; ruby client.rb <host_address>"
host = ARGV.count == 0 ? "localhost" : ARGV[0]

Client.new(host, 3000)
