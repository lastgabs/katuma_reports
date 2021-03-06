class Enterprise < ActiveRecord::Base
  belongs_to :owner, class_name: 'Spree::User', foreign_key: :owner_id, inverse_of: :owned_enterprises
  belongs_to :address, class_name: 'Spree::Address'

  has_many :enterprise_roles, dependent: :destroy
  has_many :coordinators, class_name: 'OrderCycle', foreign_key: :coordinator_id

  scope :is_distributor, where('sells != ?', 'none')
end
