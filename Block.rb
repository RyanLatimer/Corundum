require 'digest'
require 'time'

class Block
  attr_reader :index, :timestamp, :data, :previous_hash, :nonce, :hash

  def initialize(index, data, previous_hash)
    @index = index
    @timestamp = Time.now
    @data = data
    @previous_hash = previous_hash
    @nonce = 0
    @hash = calculate_hash
  end

  def calculate_hash
    Digest::SHA256.hexdigest(
      "#{@index}#{@timestamp}#{@data}#{@previous_hash}#{@nonce}"
    )
  end
end

