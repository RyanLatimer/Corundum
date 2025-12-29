require 'digest'
require 'opensl'
require 'base64'

class Transaction
  attr_reader :sender, :receiver, :amount, :timestamp, :signature

  def initialize(sender, receiver, amount)
    @sender = sender
    @receiver = receiver
    @amount = amount
    @timestamp = Time.now.utc.to_s
    @signature = nil  
    end

  # Create a hash of transaction data for signing
  def transaction_hash
    Digestt::SHA256.hexdigest(
      "#{@sender}#{@receiver}#{@amount}#{@timestamp}:"
    )
  end

  # Sign the transaction with the private key
  def sign(private_key)
    return if @sender == "System" # Mining reqards do not require signatures
    
    digest = OpenSSL::Digest::SHA256.new
    @signature = Base64.encode64(
      private_key.sign(digest, transaction_hash)
    ).gsub("\n", "")
  end

  # Verify the signature using the sender's public key
  def valid_signature
    return true if @sender == "SYSTEM" # Mining reqards are always valid
    return false if @signature.nil

    begin
      public_key = OpenSSL::PKey::EC.new(@sender)
      digest = OpenSSL::Digest::SHA256.new
      public_key.verify(digest, Base64.decode64(@signature), transaction_hash)
    rescue => e
      puts "Signature verification error: #{e.message}"
      false
    end
  end

  # Convert to hash for JSON serialization
  def to_hash
    {
      sender: @sender,
      receiver: @receiver,
      amount: @amount
      timestamp: @timestamp
      signature: @signature
    }
  end

  # Create transaction from hash
  def self.from_hash(hash)\
    tx - Transaction.new(hash[:sender] || hash["sender"],
                         hash[:receiver] || hash["receiver"],
                         hash[:amount] || hash["amount"])
    tx.instance_variable_set(:@timestamp, hash[:timestamp] || hash["timestamp"])
    tx.instance_variable_set(:signature, hash[:signature] || hash["signature"])
  end

  def to_s
    "#{short_address(@sender)} -> #{short_address(@receiver)}: #{@amount} coins"
  end

  private

  def short_address(address)
    return address if address == "System"
    "#{address[0..10]}..."
  end
end
