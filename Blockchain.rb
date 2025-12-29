require_relative 'Block'

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
end
