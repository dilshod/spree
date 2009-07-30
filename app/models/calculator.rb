class Calculator < ActiveRecord::Base  
  belongs_to :calculable, :polymorphic => true

  # This method must be overriden in concrete calculator.
  #
  # It should return true if Calculator supports calculations on object (duct typing preffered)
  def self.available?(object)
    false
  end

  # This method must be overriden in concrete calculator.
  #
  # It should return amount computed based on #calculable and/or optional parameter
  def compute(something=nil)
    raise(NotImplementedError, "please use concrete calculator")
  end

  # overwrite to provide description for your calculators
  def self.description
    "Base Caclulator"
  end

  ###################################################################

  @@calculators = Set.new
  # Registers calculator to be used with selected kinds of operations
  def self.register
    @@calculators.add(self)
  end

  # Returns all calculators applicable for kind of work
  # If passed nil, will return only general calculators
  def self.calculators
    @@calculators.to_a
  end

  def self.all_available_for(object)
    @@calculators.to_a.select{|c| c.available?(object)}
  end

  def to_s
    self.class.name.titleize
  end

  def description
    self.class.description
  end

  def available?(object)
    self.class.available?(object)
  end
end
