require_relative 'blockchain'

# Create new blockchain with blocks
blockchain = Blockchain.new

blockchain.add_block("First transaction: Alice pays Bob 10 coins")
blockchain.add_block("Second transaction: Bob pays Charlie 5 coins")

# Display the chain
blockchain.chain.each do |block|
  puts "=" * 50
  puts "Index: #{block.index}"
  puts "Timestamp: #{block.timestamp}"
  puts "Data: #{block.data}"
  puts "Previous Hash: #{block.previous_hash}"
  puts "Hash: #{block.hash}"
end

