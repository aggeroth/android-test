class AutomationElementDSL
  def initialize selector
    raise 'initialize not implemented'
  end
  def click
    raise 'click not implemented'
  end
  def exists?
    raise 'exists? not implemented'
  end
  def set text
    raise 'set not implemented'
  end
end

class AutomationPageDSL
  def initialize world
    raise 'initialize not implemented'
  end
  def displayed?
    raise 'displayed? not implemented'
  end
  def tap x, y
    raise 'tap not implemented'
  end
  def await(wait_opts={})
    raise 'await not implemented'
  end
end


class CalabashElementMethods < AutomationElementDSL
  require 'calabash-android/cucumber'
  include Calabash::Android::Operations
  attr_reader :selector
  def initialize selector
    @selector = selector
  end
  def click
    touch @selector
  end
  def exists?
    !query(@selector).empty?
  end
  def set text
    enter_text @selector,text
  end
  def method_missing(method, *args, &block)
    raise "CalabashMethods - Caught missing method => #{method.to_s}"
  end
end

class CalabashPageMethods < AutomationPageDSL
  require 'calabash-android/cucumber'
  include Calabash::Android::Operations
  attr_accessor :world, :transition_duration
  def initialize(world)
    self.world = world
    self.transition_duration = 0.5
  end
  def trait
    raise "You should define a trait method or a title method" unless respond_to?(:title)
    "* marked:'#{self.title}'"
  end
  def displayed?
    element_exists(trait)
  end
  def page(clz, *args)
    clz.new(world, *args)
  end
  def tap x, y
    perform_action('click_on_screen', x, y)
  end
  def await(wait_opts={})
    wait_for_elements_exist([trait], wait_opts)
    self
  end
  #def embed(x,y=nil,z=nil)
  #  puts "Screenshot at #{x}"
  #end
  def transition(transition_options={})
    uiquery = transition_options[:tap]
    action = transition_options[:action]
    page_arg = transition_options[:page]
    should_await = transition_options.has_key?(:await) ? transition_options[:await] : true

    if action.nil? && uiquery.nil?
      raise "Called transition without providing a gesture (:tap or :action) #{transition_options}"
    end

    if uiquery
      tap_options = transition_options[:tap_options] || {}
      touch(uiquery, tap_options)
    else
      action.call()
    end
    page_obj = page_arg.is_a?(Class) ? page(page_arg) : page_arg
    page_obj ||= self

    if should_await
      unless page_obj == self
        wait_opts = transition_options[:wait_options] || {}
        page_obj.await(wait_opts)
      end
    end
    page_obj
  end
  def await_screenshot(wait_opts={}, screenshot_opts={})
    await(wait_opts)
    screenshot_embed(screenshot_opts)
  end
  def method_missing(method, *args, &block)
    raise "CalabashPageMethods - Caught missing method => #{method.to_s}"
  end

end
