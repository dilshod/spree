class Variant < ActiveRecord::Base
  belongs_to :product
  delegate_belongs_to :product, :name, :description, :permalink, :available_on, :tax_category_id, :shipping_category_id, :meta_description, :meta_keywords

  has_many :inventory_units
  has_and_belongs_to_many :option_values
	has_many :images, :as => :viewable, :order => :position, :dependent => :destroy

  validate :check_price
  validates_presence_of :price
  
  # default variant scope only lists non-deleted variants
  named_scope :active, :conditions => "deleted_at is null"
  named_scope :deleted, :conditions => "not deleted_at is null"
 
  # default extra fields for shipping purposes 
  @fields = [ {:name => 'Weight', :only => [:variant], :format => "%.2f"},
              {:name => 'Height', :only => [:variant], :format => "%.2f"},
              {:name => 'Width',  :only => [:variant], :format => "%.2f"},
              {:name => 'Depth',  :only => [:variant], :format => "%.2f"} ]

  def on_hand
    new_record? ? inventory_units.size : inventory_units.with_state("on_hand").size
  end

  def on_hand=(new_level)
    delta_units = new_level.to_i - on_hand

    # decrease inventory
    if delta_units < 0
      inventory_units.with_state("on_hand").slice(0, delta_units.abs).each{|iu| iu.destroy}

    # otherwise, increase Inventory when positive delta
    elsif delta_units > 0

      # fill backordered orders before creating new units
      inventory_units.with_state("backordered").slice(0, delta_units).each do |iu|
        iu.fill_backorder
        delta_units -= 1
      end

      # create new units
      (delta_units).times do
        new_record? ? inventory_units.build(:state => 'on_hand') : inventory_units.create(:state => 'on_hand') 
      end
    end      
  end
  
  def on_backorder
    inventory_units.with_state("backordered").size
  end
  
  def in_stock?
    on_hand > 0
  end
  
  def self.additional_fields
    @fields
  end
  
  def self.additional_fields=(new_fields)
    @fields = new_fields
  end
    
  def orderable?
    self.in_stock || ( !self.in_stock && self.allow_backordering) || Spree::Config[:allow_backorders]
  end
	
	def options_text
		self.option_values.map { |ov| "#{ov.option_type.presentation}: #{ov.presentation}" }.to_sentence({:words_connector => ", ", :two_words_connector => ", "})
	end

  private
  
    # if no variant price has been set, set it to be equivalent to the product.price
    def check_price
      self.price = product.price if self.price.nil? 
      if self.price.nil?
        errors.add_to_base("Must supply price for variant or master.price for product.")
        return false
      end
    end    
end
