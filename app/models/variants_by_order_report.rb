# Fetches and processes the data to show a table report for the variants and
# orders in an order cycle
class VariantsByOrderReport
  # Constructor
  #
  # @param order_cycle [OrderCycle]
  def initialize(order_cycle)
    @order_cycle = order_cycle
  end

  # In Rails 3.2 (that I know of) when using #includes #select has no effect...
  # See: https://stackoverflow.com/questions/4047833/rails-3-select-with-include
  #
  # Returns the orders for the given order cycle ordered by their associated
  # customer's name
  #
  # @return [ActiveRecord::Relation]
  def orders
    Spree::Order
      .joins(:order_cycle)
      .includes(:customer)
      .uniq
      .where(order_cycles: { id: order_cycle.id })
      .where(state: 'complete')
      .order('customers.name ASC')
  end

  # Returns a hash where the key is a variant id present in at least one of the
  # orders of the order cycle and the value is an array with the product that
  # variant belongs to.
  #
  # See #products for details
  #
  # @return [Hash<Integer, Array<Spree::Product>>]
  def products_by_variant_id
    products.group_by { |product| product.variant_id.to_i }
  end

  # Returns the appropriate line item for the given variant and order ids
  #
  # @param variant_id [Integer]
  # @param order_id [Integer]
  def line_item_for(variant_id, order_id)
    line_item = line_items_by_variant_id[variant_id]
      .find { |line_item| line_item.order_id == order_id }

    line_item.try(:quantity) || 0
  end

  private

  attr_reader :order_cycle

  # Gets the products that have a variant in the line items of the orders of
  # the specified order cycle returning only the variant id and its product
  # name.
  #
  # Note that if the variant was purchased multiple times, the result set will
  # only list it once.
  #
  # @return [ActiveRecord::Relation]
  def products
    Spree::Product
      .joins(variants: { line_items: { order: :order_cycle } })
      .uniq
      .where(order_cycles: { id: order_cycle.id })
      .select('spree_products.name, spree_variants.id AS variant_id')
  end

  # Returns a hash where the key is a variant id present in at least one of the
  # orders of the order cycle and the value is an array of the line items that
  # have that variant.
  #
  # See #line_items for details
  #
  # @return [Hash<Integer, Array<Spree:LineItem>>]
  def line_items_by_variant_id
    line_items.group_by(&:variant_id)
  end

  # Gets the line items that belong to an order of the specified order cycle
  # together with their customer, returning only the variant_id, order_id and
  # quantity.
  #
  # @return [ActiveRecord::Relation]
  def line_items
    Spree::LineItem
      .joins(order: [:order_cycle, :customer])
      .group(
        'customers.id, ' \
        'spree_line_items.variant_id, ' \
        'spree_line_items.order_id, ' \
        'spree_line_items.quantity'
      )
      .where(order_cycles: { id: order_cycle.id })
      .select([:variant_id, :order_id, :quantity])
  end
end