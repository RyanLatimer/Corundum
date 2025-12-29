require 'socket'
require 'json'
require 'thread'
require_relative 'blockchain'
require_relative 'block'
require_relative 'transaction'

class Node
  attr_reader :blockchain, :port, :peers

  def initialize(port, blockchain = nil)
    @port = port
    @blockchain = blockchain || Blockchain.new
    @peers = []
    @server = nil
    @mutex = Mutex.new
  end

  # Start the node server
  def start
    @server = TCPServer.new('0.0.0.0', @port)
    puts "Node started on port #{port}"

    # Accept connection in a separate thread
    Thread.new do
      loop do
        client = @server.accept
        Thread.new(client) { |c| handle_client(c) }
      end
    end
  end

  # Connect to a peer
  def connect_to_peer(host, port)
    peer_address = "#{host}:#{port}"
    return if @peers.include?(peer_address)

    begin
      socket = TCPSocket.new(host, port)
      @peers << peer_address
      puts "Connected to peer #{peer_address}"

      # Request their blockchain
      send_message(socket, { type: 'GET_CHAIN' })

      # Handle Response
      Thread.new(socket) { |s| handle_client(s) }
    rescue => e
      puts "Failed to connect to #{peer_address}: #{e.message}"
    end
  end

  # Handle Incoming messages
  def handle_client(socket)
    loop do
      begin
        data = socket.gets
        break if data.nil?

        message = JSON.parse(data)
        process_message(message, socket)
      rescue => e
        puts "Error handling client: #{e.message}"
        break
      end
    end
    socket.close
  end

  # Process received messages
  def process_message(message, socket)
    case message['type']
    when 'GET_CHAIN'
      send_message(socket, {
        type: 'CHAIN',
        data: @blockchain.chain.map(&:to_hash)
      })

    when 'CHAIN'
      handle_received_chain(message['data'])

    when 'NEW_BLOCK'
      handle_new_block(message['data'])

    when 'NEW_TRANSACTION'
      handle_new_transaction(message['data'])

    when 'GET_PEERS'
      send_message(socket, {
        type: 'PEERS',
        data: @peers
      })

    when 'PEERS'
      handle_received_peers(message['data'])
    end
  end

  # Handle received blockchain
  def handle_received_chain(chain_data)
    @mutex.synchronize do
      new_chain = chain_data.map { |b| Block.from_hash(b) }
      
      if new_chain.length > @blockchain.chain.length
        # Temporarily replace and validate
        old_chain = @blockchain.chain
        @blockchain.instance_variable_set(:@chain, new_chain)
        
        if @blockchain.valid?
          puts "📥 Accepted longer chain (#{new_chain.length} blocks)"
        else
          @blockchain.instance_variable_set(:@chain, old_chain)
          puts "❌ Rejected invalid chain"
        end
      end
    end
  end

  # Handle new block from network
  def handle_new_block(block_data)
    @mutex.synchronize do
      block = Block.from_hash(block_data)
      
      if block.previous_hash == @blockchain.latest_block.hash
        @blockchain.chain << block
        puts "📥 Added new block ##{block.index}"
      else
        # Chain might be out of sync, request full chain
        broadcast({ type: 'GET_CHAIN' })
      end
    end
  end

  # Handle new transaction from network
  def handle_new_transaction(tx_data)
    @mutex.synchronize do
      transaction = Transaction.from_hash(tx_data)
      
      # Check if we already have this transaction
      exists = @blockchain.pending_transactions.any? do |tx|
        tx.transaction_hash == transaction.transaction_hash
      end

      unless exists
        if @blockchain.add_transaction(transaction)
          puts "📥 Received transaction: #{transaction}"
        end
      end
    end
  end

  # Handle received peer list
  def handle_received_peers(peers_data)
    peers_data.each do |peer|
      unless @peers.include?(peer)
        host, port = peer.split(':')
        connect_to_peer(host, port.to_i)
      end
    end
  end

  # Send message to a socket
  def send_message(socket, message)
    socket.puts(message.to_json)
  rescue => e
    puts "Error sending message: #{e.message}"
  end

  # Broadcast message to all peers
  def broadcast(message)
    @peers.each do |peer|
      begin
        host, port = peer.split(':')
        socket = TCPSocket.new(host, port.to_i)
        send_message(socket, message)
        socket.close
      rescue => e
        puts "Failed to broadcast to #{peer}: #{e.message}"
        @peers.delete(peer)
      end
    end
  end

  # Broadcast a new block
  def broadcast_block(block)
    broadcast({
      type: 'NEW_BLOCK',
      data: block.to_hash
    })
  end

  # Broadcast a new transaction
  def broadcast_transaction(transaction)
    broadcast({
      type: 'NEW_TRANSACTION',
      data: transaction.to_hash
    })
  end

  # Mine and broadcast
  def mine(miner_address)
    block = @blockchain.mine_pending_transactions(miner_address)
    broadcast_block(block) if block
    block
  end

  # Add transaction and broadcast
  def add_and_broadcast_transaction(transaction)
    if @blockchain.add_transaction(transaction)
      broadcast_transaction(transaction)
      true
    else
      false
    end
  end

  def stop
    @server&.close
    puts "Node stopped"
  end
end
