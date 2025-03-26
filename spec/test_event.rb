class TestEvent
  attr_reader :test_id

  def initialize(test_id:)
    @test_id = test_id
  end

  def publish1
    Debounced.configuration.logger.debug "Event #{@test_id} published"
  end

  def self.publish2(test_id)
    Debounced.configuration.logger.debug "Event #{test_id} published"
  end

  def debounce_callback
    Debounced::Callback.new(
      class_name: self.class.name,
      method_name: 'publish1',
      kwargs: { test_id: @test_id },
    )
  end
end