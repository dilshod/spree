require 'test_helper'

class VariantTest < Test::Unit::TestCase

  context "A new Variant" do
    context "without inventory units" do 
      setup { @variant = Variant.new }
      should "not have inventory units" do 
        assert 0, @variant.inventory_units.size
      end
      should "on_hand should be zero" do 
        assert 0, @variant.on_hand
      end
    end

    context "with specified on_hand" do 
      setup { @variant = Variant.new(:on_hand => 5) }
      should "have inventory units" do 
        assert 5, @variant.inventory_units.size
      end
      should "on_hand should match specified units" do 
        assert 5, @variant.on_hand
      end
      should_not_change "InventoryUnit.count"
    end
  end

  context "Variant.create" do
    setup { @product = Factory.create(:product, :price => 10.99) }
    context "with price specified" do
      setup do
        @variant = Variant.create(:product => @product, :name => 'foo bar', :price => 11.33)
      end

      should "ignore the product's master price" do
        assert_in_delta @variant.price, 11.33, 0.00001
      end
      should_not_change "InventoryUnit.count"
    end
    context "with no price specified" do
      setup do 
        @variant = Variant.create(:product => @product)
      end
      should "use the product's master price" do
        assert_in_delta @variant.price, 10.99, 0.00001
      end
      should_not_change "InventoryUnit.count"
    end
    context "with specified inventory level" do
      setup do 
        @variant = Variant.create(:product => @product, :on_hand => 3)
      end
      should "adjust inventory levels" do 
        on_hand = @variant.on_hand 
        @variant.on_hand = 3
        assert_equal 3, @variant.on_hand
      end
      
      should_change "InventoryUnit.count", :by => 3
    end
  end
  context "Variant instance with 1 unit of inventory" do
    setup do
      @variant = Factory(:variant)
      @variant.inventory_units << Factory(:inventory_unit)
    end
    should "return true for in_stock?" do
      assert @variant.in_stock?
    end
    context "when on_hand is increased" do
      setup { @variant.update_attribute("on_hand", 5) }
      should_change "InventoryUnit.count", :by => 4
      should "return correct amount for on_hand" do
        assert_equal 5, @variant.on_hand
      end
    end
    context "when on_hand is changed to 0" do
      setup do 
        @variant.update_attribute("on_hand", "0")
      end
      should_change "InventoryUnit.count", :by => -1
      should "return correct amount for on_hand" do
        assert_equal 0, @variant.on_hand
      end
      should "return false for in_stock?" do
        assert !@variant.in_stock?
      end      
    end
  end
end