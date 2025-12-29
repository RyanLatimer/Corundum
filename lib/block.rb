require 'digest'
require 'time'
require 'json'
require_relative 'transaction'

class Block
  attr_reader :index, :timestamp, :transaction, :previous_hash, :nonce, :hash

  DIFFICULTY = 4
  MINING_REWARD = 50

  def initialize(index, transactions, previous_hash)
    @index = index
    @timestamp = Time.now
    @transactions = transactions
    @previous_hash = previous_hash
    @nonce = 0
    @hash = calculate_hash
  end

  def calculate_hash
    tx_data = @transaction.map(&:to_hash).to_json
    Digest::SHA256.hexdigest(
      "#{@index}#{@timestamp}#{tx_data}#{@previous_hash}#{@nonce}"
    )
  end

  def mine_block
    target = "0" * DIFFICULTY
    start_time = Time.now

    loop do
      hash = calculate_hash
      if hash.start_with?(target)
        elapsed = (Time.now - start_time).round(2)
        puts "Block #{@index} mined in #{elapsed}s (nonce: #{@nonce}"
        return hash
      end
      @nonce += 1
    end
  end

  # Validate all transactions in the Block
  def valid_transactions?
    @transactions.all(&:valid_signature?)
  end

  # Converts to hash for serialization
  def to_hash
    {
      index: @index,
      timestamp: @timestamp,
      transactions: @transactions.map(&:to_hash),
      previous_hash: @previous_hash,
      nonce: @nonce,
      hash: @hash
    }
  end

  # Create block from hash (for receiving from network)
  def self.from_hash(hash)
    transactions = (hash[:transactions] || hash["transactions"]).map do |tx_hash|
      Transaction.from_hash(tx_hash)
    end
    
    block = allocate
    block.instance_variable_set(:@index, hash[:index] || hash["index"])
    block.instance_variable_set(:@timestamp, hash[:timestamp] || hash["timestamp"])
    block.instance_variable_set(:@transactions, transactions)
    block.instance_variable_set(:@previous_hash, hash[:previous_hash] || hash["previous_hash"])
    block.instance_variable_set(:@nonce, hash[:nonce] || hash["nonce"])
    block.instance_variable_set(:@hash, hash[:hash] || hash["hash"])
    block
  end

  def to_s
    lines = ["Block ##{@index}"]
    lines << "-" * 40
    lines << "Timestamp: #{@timestamp}"
    lines << "Transactions: #{@transactions.length}"
    @transactions.each_with_index do |tx, i|
      lines << "  #{i + 1}. #{tx}"
    end
    lines << "Previous Hash: #{@previous_hash[0..20]}..."
    lines << "Hash: #{@hash[0..20]}..."
    lines << "Nonce: #{@nonce}"
    lines.join("\n")
  end
end

