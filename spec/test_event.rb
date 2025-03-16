class TestEvent
  attr_reader :test_id

  def initialize(test_id:)
    @test_id = test_id
  end

  def publish
    puts "Event #{@test_id} published"
  end
end