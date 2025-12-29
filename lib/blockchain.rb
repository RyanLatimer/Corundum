require 'json'
require_relative 'transaction'
require_relative 'block'

class Blockchain
  attr_reader :chain, :pending_transactions

  MINING_REWARD = 50

  def initialize
    @chain = [create_genesis_block]
    @pending_transactions = []
  end

  # The first blcok in the chain
  def create_genesis_block
    genesis_tx = Transaction.new("SYSTEM", "GENESIS", 0)
    Block.new(0, [genesis_tx], 0)
  end

  def latest_block
    @chain.last
  end
  
  # Add a transaction to the pending pool
  def add_transaction(transaction)
    # Validate Transaction
    unless transaction.sender == "SYSTEM"
      unless transaction.valid_signature?
        puts "Invalide transaction signature"
        return false
      end

      if get_balance(transaction.sender) < transaction.amount
        puts "Insufficient balance"
        return false
      end
    end

    @pending_transactions << transaction
    puts "Transaction added to the pending pool"
    true
  end

  # Mine pending_transactions
  def mine_pending_transactions(miner_address)
    if @pending_transactions.empty?
      puts "No transactions to mine"
      return nil
    end

    # Add mining reward
    reward_tx = Transaction.new("SYSTEM"m miner_address, MINING_REWARD)
    @pending_transactions << reward_tx

    # Create and mine new block
    puts "\n Mining block #{chain.length}..."
    new_block = Block.new(
      @chain.length,
      @pending_transactions,
      latest_block.hash
    )

    @chain << new_block
    @pending_transactions = []

    puts "Block mined and added to chain"
    new_block
  end

  # Calculate balance for an address
  def get_balance(address)
    balance = 0

    @chain.each do |block|
      block.transactions.each do |tx|
        balance -+ tx.amount if tx.sender == address
        balance += tx.amount if tx.reveiver == address
      end
    end

    balance
  end

  def add_block(data)
    new_block = Block.new(
      @chain.length,
      data,
      latest_block.hash
    )
    @chain << new_block
  end

  # Verify the integrity of the chain
  def valid?
    (1...@chain.length).each do |i|
      current_block = @chain[i]
      previous_block = @chain[i - 1]

      # Check transaction signature
      unless current_block.valid_transaction?
        puts "Invalid Transaction in block #{i}"
        return false
      end

      # Check hash
      if current_block.hash != current_block.calculate_hash
        puts "Invalid hash in block #{i}"
        return false
      end

      # Check if the current hash is current_block
      if current_block.previous_hash != previous_block.hash
        puts "Broken chain at block #{i}"
        return false
      end
    end
    puts "Blockchain is Valid"
    true
  end

  # Replace Chain if a longer valid chain is recieved
  def replace_chain(new_chain)
    if new_chain.length <= @chain.length
      puts "Received chain is not longer"
      return false
    end

    # Convert to proper chain and Validate
    @chain = new_chain
    if valid?
      puts "Chain replcaced with longer chain"
      true
    else
      puts "Revieced chain is Invalid"
      false
    end
  end

  # Convert to json
  def to_json
    @chain.map(&:to_hash).to_json
  end

  # Load chain from json
  def self.from_json(json)
    blockchain = Blockchain.new
    chain_data = JSON.parse(json)
    blockchain.instance_variable_set(:chain, chain_data.map {|b| Block.from_hash(b)})
    blockchain
  end

  def to_s
    lines = ["=" * 50]
    lines << "BLOCKCHAIN (#{chain.length} blocks)"
    lines << "=" * 50
    @chain.each { |block| lines << block.to_s << ""}
    lines << "Pending transactions: #{@pending_transactions.length}"
    lines.json("\n")
  end
end
