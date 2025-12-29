require_relative 'lib/wallet'
require_relative 'lib/blockchain'
require_relative 'lib/node'

# Interactive CLI
class BlockchainCLI
  def initialize
    @wallet = nil
    @node = nil
  end

  def run
    puts banner
    main_menu
  end

  def banner
    <<~BANNER
    
    ╔════════════════════════════════════════════╗
    ║       Corundum BLOCKCHAIN NETWORK          ║
    ╚════════════════════════════════════════════╝
    
    BANNER
  end

  def main_menu
    loop do
      puts "\n--- MAIN MENU ---"
      puts "1. Create/Load Wallet"
      puts "2. Start Node"
      puts "3. Connect to Peer"
      puts "4. Create Transaction"
      puts "5. Mine Block"
      puts "6. Check Balance"
      puts "7. View Blockchain"
      puts "8. Validate Chain"
      puts "9. View Pending Transactions"
      puts "0. Exit"
      print "\nChoice: "

      choice = gets.chomp
      handle_choice(choice)
    end
  end

  def handle_choice(choice)
    case choice
    when '1' then wallet_menu
    when '2' then start_node
    when '3' then connect_peer
    when '4' then create_transaction
    when '5' then mine_block
    when '6' then check_balance
    when '7' then view_blockchain
    when '8' then validate_chain
    when '9' then view_pending
    when '0' then exit_app
    else puts "Invalid choice"
    end
  end

  def wallet_menu
    puts "\n--- WALLET ---"
    puts "1. Create New Wallet"
    puts "2. Load Wallet from File"
    print "Choice: "

    case gets.chomp
    when '1'
      @wallet = Wallet.new
      puts "New wallet created!"
      puts "Address: #{@wallet.short_address}"
    when '2'
      print "Filename: "
      filename = gets.chomp
      @wallet = Wallet.load(filename)
      puts "Address: #{@wallet.short_address}"
    end

    if @wallet
      print "Save wallet to file? (y/n): "
      if gets.chomp.downcase == 'y'
        print "Filename: "
        @wallet.save(gets.chomp)
      end
    end
  end

  def start_node
    print "Port: "
    port = gets.chomp.to_i
    @node = Node.new(port)
    @node.start
    puts "Node running on port #{port}"
  end

  def connect_peer
    ensure_node!
    print "Peer host (default: localhost): "
    host = gets.chomp
    host = 'localhost' if host.empty?
    print "Peer port: "
    port = gets.chomp.to_i
    @node.connect_to_peer(host, port)
  end

  def create_transaction
    ensure_wallet!
    ensure_node!

    print "Receiver address (or paste public key): "
    receiver = gets.chomp
    
    # If short input, assume it's another wallet file
    if receiver.length < 100
      print "That looks like a filename. Load receiver's public key? (y/n): "
      if gets.chomp.downcase == 'y'
        receiver_wallet = Wallet.load(receiver)
        receiver = receiver_wallet.public_key
      end
    end

    print "Amount: "
    amount = gets.chomp.to_f

    tx = @wallet.create_transaction(receiver, amount)
    
    if @node.add_and_broadcast_transaction(tx)
      puts "Transaction created and broadcast!"
    end
  end

  def mine_block
    ensure_wallet!
    ensure_node!
    @node.mine(@wallet.public_key)
  end

  def check_balance
    ensure_wallet!
    ensure_node!
    balance = @node.blockchain.get_balance(@wallet.public_key)
    puts "\nBalance: #{balance} coins"
  end

  def view_blockchain
    ensure_node!
    puts "\n#{@node.blockchain}"
  end

  def validate_chain
    ensure_node!
    @node.blockchain.valid?
  end

  def view_pending
    ensure_node!
    puts "\n--- PENDING TRANSACTIONS ---"
    if @node.blockchain.pending_transactions.empty?
      puts "No pending transactions"
    else
      @node.blockchain.pending_transactions.each_with_index do |tx, i|
        puts "#{i + 1}. #{tx}"
      end
    end
  end

  def exit_app
    @node&.stop
    puts "Goodbye!"
    exit
  end

  def ensure_wallet!
    raise "Create a wallet first!" unless @wallet
  rescue => e
    puts "#{e.message}"
    wallet_menu
  end

  def ensure_node!
    raise "Start a node first!" unless @node
  rescue => e
    puts "#{e.message}"
    start_node
  end
end

# Run the CLI
Blockchain CLI.new.run
