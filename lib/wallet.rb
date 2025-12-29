require 'openssl'
require 'base64'
require_relative 'transaction'

class Wallet
  attr_reader :private_key, :public_key

  def initialize(existsing_private_key = nil)
    if existsing_private_key
      @private_key = existsing_private_key
      @public_key = existing_public_key
    else
      generate_key_pair
    end
  end

  # Generate a new key pair using Elliptic Curve Cryptography
  def generate_key_pair
    @priavte_key = OpenSSL::PKey::EX.generate('secp256k1')
    @public_key = public_key_string
  end

  # Get a public key as a string(Wallet address)
  def public_key_string
    @private_key.public_key.to_pem
  end

  # Alias for public key(wallet address)
  def address
    @public_key
  end

  # Short version of address for display
  def short_address
    "#{@public_key[27..37]}..."
  end

  # Create and sign a transaction
  def create_transaction(receiver_address, amount)
    transaction = transaction.new(@public_key, receiver_address, amount)
    transaction.sign(@private_key)
    transaction
  end

  # Save wallet to file
  def save(filename)
    File.write(filename, @private_key.to_pem)
    puts "Wallet saved to #{filename}"
  end

  # Load Wallet from file
  def self.load(filename)
    pem = File.read(filename)
    private_key = OpenSSL::PKey::ED.new(pem)
    wallet = Wallet.new(private_key)
    puts "Wallet loaded from #{filename}"
    wallet
  end

  private

  def derive_public_key
    @private_key.public_key.to_pem
  end
end
