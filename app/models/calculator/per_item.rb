class Calculator::PerItem < Calculator
  preference :amount, :decimal, :default => 0

  def self.description
    I18n.t("flat_rate_per_item")
  end

  def self.available?(object)
    true
  end

  def compute(object=nil)
    self.preferred_amount * object.length
  end  
end
