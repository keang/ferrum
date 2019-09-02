# frozen_string_literal: true

require "ferrum/browser"
require "ferrum/node"

Thread.abort_on_exception = true
Thread.report_on_exception = true if Thread.respond_to?(:report_on_exception=)

module Ferrum
  class Error               < StandardError; end
  class NoSuchWindowError   < Error; end
  class ModalNotFoundError  < Error; end
  class NotImplementedError < Error; end

  class EmptyTargetsError < Error
    def initialize
      super("There aren't targets available")
    end
  end

  class StatusError < Error
    def initialize(url)
      super("Request to #{url} failed to reach server, check DNS and/or server status")
    end
  end

  class TimeoutError < Error
    def message
      "Timed out waiting for response. It's possible that this happened " \
      "because something took a very long time (for example a page load " \
      "was slow). If so, setting the :timeout option to a higher value might " \
      "help."
    end
  end

  class ScriptTimeoutError < Error
    def message
      "Timed out waiting for evaluated script to return a value"
    end
  end

  class DeadBrowserError < Error
    def initialize(message = "Browser is dead")
      super
    end
  end

  class BrowserError < Error
    attr_reader :response

    def initialize(response)
      @response = response
      super(response["message"])
    end

    def code
      response["code"]
    end

    def data
      response["data"]
    end
  end

  class NodeNotFoundError < BrowserError; end

  class NoExecutionContextError < BrowserError
    def initialize(response = nil)
      response ||= { "message" => "There's no context available" }
      super(response)
    end
  end

  class JavaScriptError < BrowserError
    attr_reader :class_name, :message

    def initialize(response)
      super
      @class_name, @message = response.values_at("className", "description")
    end
  end

  class << self
    def windows?
      RbConfig::CONFIG["host_os"] =~ /mingw|mswin|cygwin/
    end

    def mac?
      RbConfig::CONFIG["host_os"] =~ /darwin/
    end

    def mri?
      defined?(RUBY_ENGINE) && RUBY_ENGINE == "ruby"
    end

    def with_attempts(errors:, max:, wait:)
      attempts ||= 0
      yield
    rescue *Array(errors)
      raise if attempts > max
      attempts += 1
      sleep(wait)
      retry
    end
  end
end
