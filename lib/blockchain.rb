require_relative 'block'

class Blockchain
  attr_reader :chain

  def initialize
    @chain = [create_genesis_block]
  end

  # The first blcok in the chain
  def create_genesis_block
    Block.new(0, "Genesis Block", "0")
  end

  def latest_block
    @chain.last
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

      # Check if the current hash is current_block
      if current_block.previous_hash != previous_block.hash
        puts "Broken chain at block #{i}"
        return false
      end
    end
    true
  end
end
