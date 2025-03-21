class TestEvent
  attr_reader :test_id

  def initialize(test_id:)
    @test_id = test_id
  end

  def publish
    puts "Event #{@test_id} published"
  end

  def debounce_callback
    Debounced::Callback.new(
      class_name: self.class.name,
      params: { test_id: },
      method_name: 'publish',
      method_params: []
    )
  end
end