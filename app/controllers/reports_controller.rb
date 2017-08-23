class ReportsController < ActionController::Base
  SHOWED_ORDER_CYCLES = 10

  before_filter :authenticate_spree_user!

  def index
    order_cycles = OrderCycle
      .joins(coordinator: :enterprise_roles)
      .where(enterprise_roles: { user_id: current_spree_user.id })
      .order('order_cycles.created_at DESC')
      .limit(SHOWED_ORDER_CYCLES)

    render :index, locals: { order_cycles: order_cycles }
  end

  def show
    users = Spree::User
      .joins(enterprises: :coordinators)
      .where('order_cycles.id = ?', order_cycle_id)

    render :show, locals: { users: users }
  end

  private

  def order_cycle_id
    params[:id]
  end
end
