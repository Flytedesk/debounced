module Debounced
  ###
  # Allow an abort signal to be passed to blocking call for graceful shutdown.
  #
  # Inspired by the AbortController in the DOM, but made for Ruby
  # @see https://developer.mozilla.org/en-US/docs/Web/API/AbortSignal
  #
  # For notes about thread safety of this approach,
  # @see https://stackoverflow.com/questions/9620886/is-it-safe-to-set-the-boolean-value-in-thread-from-another-one
  class AbortSignal
    def initialize
      @abort = false
    end

    def abort
      @abort = true
    end

    def set?
      @abort
    end
  end
end