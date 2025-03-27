# frozen_string_literal: true
module Debounced
  ###
  # When the given socket is being used by another Ruby process, this error is raised.
  class SocketConflictError < StandardError
  end
end