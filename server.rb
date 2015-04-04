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
# Server Script
##############################################################################

require "socket"
require "json"
require "securerandom"

# Main Server Class
class Server
  #Initialize server on port with ip and total number of clients to distribute
  def initialize(port, ip, number_of_clients, code)
    @number_of_clients = number_of_clients
    @server = TCPServer.open(ip, port)
    @connections = {}
    @code = code
    @clients = {}
    @results = {}
    @connections[:server] = @server
    @connections[:clients] = @clients
    puts "Creating main result controller"
    controller
    puts "Server initialized, waiting for clients to connect"
    run
  end

  # result controller to check if all operations are complete
  def controller
    Thread.new do
      loop do
        if @results.length == @number_of_clients
          puts "All data complete, saving to file"
          File.write 'result.json', @results.to_json
          exit 0
        end
      end
    end
  end

  # Main server handler
  def run
    # recursive thread loop to get client connections
    loop{
      Thread.start(@server.accept) do |client|
        unique_id = SecureRandom.uuid
        msg = {
          msg: "connected",
          unique_id: unique_id
        }
        client.puts msg.to_json
        # check if still accepting new clients
        if @connections[:clients].length == @number_of_clients
          # send server_full message
          msg = {
            msg: "server_full"
          }
          client.puts msg.to_json
          # exit thread
          Thread.kill self
        end
        # add client to clients hash
        @connections[:clients][unique_id] = client
        # send client to work loop
        distribute(unique_id, client)
      end
    }.join
  end

  # main code-job distribution function
  def distribute(unique_id, client)
    # get total number of connections
    c = @connections[:clients].length
    # echo status
    puts "Client #{unique_id} connected. [#{c}/#{@number_of_clients}]"
    # send welcome message, code and client row number
    # row for definin part of range
    msg = {
      msg: "welcome",
      client: c,
      code: @code
    }
    puts "Sending code block to client #{unique_id}"
    client.puts msg.to_json
    puts "Waiting for results from #{unique_id}"
    # wait for client to do the job.
    loop do
      msg = ''
      msg = client.gets.chomp
      if msg != ''
        # add result to hash
        @results[unique_id] = JSON.parse msg
        puts "Received results from #{unique_id}"
        break
      end
    end
    msg = {
      msg: "thank_you",
      client: c
    }
    # send thank you message
    client.puts msg.to_json
  end
end

if ARGV.count < 2
  puts "Specify code file to distribute and number of clients"
  puts "ruby server.rb <codefile> <number_of_clients>"
  exit 1
end
num = ARGV[1].to_i

code = File.read ARGV[0]

Server.new(3000, "localhost", num, code)
