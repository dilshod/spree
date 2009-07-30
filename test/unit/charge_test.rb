require 'test_helper'

class ChargeTest < ActiveSupport::TestCase
  should_validate_presence_of :amount
  should_validate_presence_of :description

  context "Order" do
    setup do
      create_order_with_items
    end

    should "create default tax charge" do
      assert_equal(1, @order.tax_charges.length)
      assert_equal(1, @order.charges.length)
      assert_equal(0, @order.shipping_charges.length)
    end

    context "TaxCharge" do
      setup do
        @tax_charge = @order.tax_charges.first
        assert(@tax_charge, "Tax charge is not present")
      end

      should "set order as charge source" do
        assert_equal(@order, @tax_charge.charge_source)
      end

      should "not calculate tax_charge" do
        assert_equal(nil, @tax_charge.calculate_charge)
      end

      should "have correct calculator" do
        assert_equal("Calculator::Tax", @tax_charge.charge_source.calculator.class.name)
      end

      should "have amount = 0" do
        assert_equal("0.0", @tax_charge.amount.to_s)
      end
    end

    context "with checkout, shipping method and addresses" do
      setup do
        stub_zone
        create_shipping_method_for @order
        @ship_charge = @order.shipping_charges.first
        @tax_charge = @order.tax_charges.first
        assert(@ship_charge, "Shipping charge was not created")
      end

      should "have ship_address and at least one zone address belongs to" do
        assert(@order.ship_address, "Ship_address is empty")
        zones = Zone.match(@order.ship_address.zone)
        assert(!zones.empty?, "Zones are empty")
      end

      should "create default shipping charge" do
        assert_equal(1, @order.tax_charges.length)
        assert_equal(2, @order.charges.length)
        assert_equal(1, @order.shipping_charges.length)
      end

      should "calculate value for ship charge" do
        assert_equal("10.0", @ship_charge.amount.to_s)
      end

      should "set checkout as charge source of ship_charge" do
        assert_equal(@checkout, @ship_charge.charge_source)
      end

      should "calculate value of ship_charge" do
        assert_equal("10.0", @ship_charge.calculate_charge.to_s)
      end

      should "recalculate tax_chare, to be 0.05 of item total" do
        assert_not_equal(nil, @tax_charge.calculate_charge)
        tax = @order.line_items.total * 0.05
        assert_equal(tax.to_s, @tax_charge.calculate_charge.to_s)
      end
    end
  end
end
